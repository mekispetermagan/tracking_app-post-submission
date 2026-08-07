from datetime import UTC, date, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError

from models import (
    Course, SkillSurveyAnswer, SkillSurveyForm, SkillSurveyFormStatus,
    SkillSurveySubmission, Student, StudentCourse,
)
from routers._management import (
    course_visible_to_mentor,
    mentor_course_ids,
    skill_survey_age_group,
    student_visible_to_mentor,
)
from routers.shared import Actor, get_current_actor
from schemas.skill_surveys import (
    SkillSurveyFormOut, SkillSurveyQuestionOut, SkillSurveyResultOut,
    SkillSurveySubmissionCreate,
)

router = APIRouter(prefix="/skill-surveys")


def _enrollment_for_actor(actor: Actor, student_id: int, course_id: int):
    student = actor.db.get(Student, student_id)
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    course = actor.db.get(Course, course_id)
    if course is None:
        raise HTTPException(status_code=404, detail="Course not found")
    enrollment = actor.db.get(StudentCourse, (student_id, course_id))
    if enrollment is None:
        raise HTTPException(status_code=400, detail="Student is not assigned to course")
    if actor.role == "mentor":
        if not student.active or not course.active:
            raise HTTPException(status_code=403, detail="Student or course is inactive")
        if not course_visible_to_mentor(course, actor.profile):
            raise HTTPException(status_code=403, detail="Course not available")
    return student, course, enrollment


def _form_to_out(form: SkillSurveyForm) -> SkillSurveyFormOut:
    return SkillSurveyFormOut(
        id=form.id,
        survey_slug=form.survey.slug,
        survey_name=form.survey.name,
        age_group=form.age_group,
        version=form.version,
        questions=[
            SkillSurveyQuestionOut(
                id=question.id,
                position=question.position,
                code=question.code,
                prompt=question.prompt,
                illustration_key=question.illustration_key,
            )
            for question in form.questions
        ],
    )


def _submission_to_result(submission: SkillSurveySubmission) -> SkillSurveyResultOut:
    return SkillSurveyResultOut(
        submission_id=submission.id,
        student_id=submission.student_id,
        course_id=submission.course_id,
        survey_date=submission.survey_date,
        survey_slug=submission.form.survey.slug,
        survey_name=submission.form.survey.name,
        age_group=submission.form.age_group,
        form_version=submission.form.version,
        correct_answers=sum(answer.correct for answer in submission.answers),
        total_questions=len(submission.answers),
        created_at=submission.created_at,
    )


@router.get("/forms", response_model=list[SkillSurveyFormOut])
def get_skill_survey_forms(
    student_id: int,
    course_id: int,
    survey_date: date | None = None,
    actor: Actor = Depends(get_current_actor),
):
    student, _, enrollment = _enrollment_for_actor(actor, student_id, course_id)
    age_group = enrollment.survey_age_group or skill_survey_age_group(
        student.birth_year, survey_date or date.today()
    )
    forms = (
        actor.db.query(SkillSurveyForm)
        .join(SkillSurveyForm.survey)
        .filter(
            SkillSurveyForm.age_group == age_group,
            SkillSurveyForm.status == SkillSurveyFormStatus.PUBLISHED,
        )
        .order_by(SkillSurveyForm.survey_id, SkillSurveyForm.version.desc())
        .all()
    )
    latest_forms = {}
    for form in forms:
        if form.survey.active:
            latest_forms.setdefault(form.survey_id, form)
    return [_form_to_out(form) for form in latest_forms.values()]


@router.post(
    "/submissions",
    response_model=SkillSurveyResultOut,
    status_code=status.HTTP_201_CREATED,
)
def create_skill_survey_submission(
    data: SkillSurveySubmissionCreate,
    actor: Actor = Depends(get_current_actor),
):
    maximum_survey_date = datetime.now(UTC).date() + timedelta(days=1)
    if data.survey_date > maximum_survey_date:
        raise HTTPException(
            status_code=400,
            detail="Survey date is too far in the future",
        )
    student, _, enrollment = _enrollment_for_actor(
        actor, data.student_id, data.course_id
    )
    form = actor.db.get(SkillSurveyForm, data.form_id)
    if form is None or form.status != SkillSurveyFormStatus.PUBLISHED or not form.survey.active:
        raise HTTPException(status_code=400, detail="Survey form is not available")
    if enrollment.survey_age_group is None:
        enrollment.survey_age_group = skill_survey_age_group(
            student.birth_year, data.survey_date
        )
    if form.age_group != enrollment.survey_age_group:
        raise HTTPException(status_code=400, detail="Survey form has wrong age group")

    existing = (
        actor.db.query(SkillSurveySubmission)
        .join(SkillSurveySubmission.form)
        .filter(
            SkillSurveySubmission.student_id == student.id,
            SkillSurveySubmission.course_id == data.course_id,
            SkillSurveySubmission.survey_date == data.survey_date,
            SkillSurveyForm.survey_id == form.survey_id,
        )
        .first()
    )
    if existing is not None:
        raise HTTPException(status_code=409, detail="Survey already submitted")

    answers_by_question = {answer.question_id: answer for answer in data.answers}
    question_ids = {question.id for question in form.questions}
    if len(answers_by_question) != len(data.answers):
        raise HTTPException(status_code=400, detail="Duplicate survey answer")
    if set(answers_by_question) != question_ids:
        raise HTTPException(status_code=400, detail="All survey questions must be answered")

    submission = SkillSurveySubmission(
        student_id=student.id,
        course_id=data.course_id,
        form=form,
        administered_by_account_id=actor.account.id,
        survey_date=data.survey_date,
        answers=[
            SkillSurveyAnswer(
                question=question,
                selected_option=answers_by_question[question.id].selected_option,
                correct=(answers_by_question[question.id].selected_option == question.correct_option),
            )
            for question in form.questions
        ],
    )
    actor.db.add(submission)
    try:
        actor.db.commit()
    except IntegrityError:
        actor.db.rollback()
        raise HTTPException(status_code=409, detail="Survey already submitted")
    actor.db.refresh(submission)
    return _submission_to_result(submission)


@router.get("/results", response_model=list[SkillSurveyResultOut])
def get_skill_survey_results(
    student_id: int,
    course_id: int | None = None,
    actor: Actor = Depends(get_current_actor),
):
    query = actor.db.query(SkillSurveySubmission).filter(
        SkillSurveySubmission.student_id == student_id
    )
    if course_id is not None:
        _enrollment_for_actor(actor, student_id, course_id)
        query = query.filter(SkillSurveySubmission.course_id == course_id)
    else:
        student = actor.db.get(Student, student_id)
        if student is None:
            raise HTTPException(status_code=404, detail="Student not found")
        if actor.role == "mentor":
            if not student_visible_to_mentor(student, actor.profile):
                raise HTTPException(status_code=403, detail="Student not available")
            query = query.filter(
                SkillSurveySubmission.course_id.in_(mentor_course_ids(actor.profile))
            )
    submissions = query.order_by(
        SkillSurveySubmission.survey_date,
        SkillSurveySubmission.id,
    ).all()
    return [_submission_to_result(submission) for submission in submissions]
