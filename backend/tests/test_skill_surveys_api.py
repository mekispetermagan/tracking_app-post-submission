from datetime import UTC, date, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from jose import jwt
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from config import settings
from database import Base, get_db
from main import app
from models import (
    Account,
    AdminProfile,
    Country,
    Course,
    MentorProfile,
    SkillSurveyAnswer,
    SkillSurveyForm,
    Student,
    StudentCourse,
)
from skill_survey_seed import seed_skill_surveys


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    testing_session = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    Base.metadata.create_all(bind=engine)
    db = testing_session()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def client(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.clear()


def token(account, role, profile) -> str:
    claims = {
        "sub": str(account.id),
        "type": role,
        "exp": datetime.now(UTC) + timedelta(hours=1),
        f"{role}_profile_id": profile.id,
    }
    return jwt.encode(claims, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def auth_header(value: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {value}"}


@pytest.fixture()
def seeded(db_session):
    country = Country(code="UG", name="Uganda")
    mentor_account = Account(
        phone="0700000001", first_name="Mentor", last_name="One", country=country
    )
    mentor = MentorProfile(
        account=mentor_account, pin_hash="hash", must_change_pin=False
    )
    other_account = Account(
        phone="0700000002", first_name="Mentor", last_name="Two", country=country
    )
    other_mentor = MentorProfile(
        account=other_account, pin_hash="hash", must_change_pin=False
    )
    admin_account = Account(
        phone="0700000003", first_name="Admin", last_name="One", country=country
    )
    admin = AdminProfile(
        account=admin_account, password_hash="hash", must_change_password=False
    )
    course = Course(
        name="Course", description="", country=country, day_of_week=1,
        start_time=datetime.min.time(), mentors=[mentor],
    )
    other_course = Course(
        name="Other", description="", country=country, day_of_week=2,
        start_time=datetime.min.time(), mentors=[other_mentor],
    )
    student = Student(
        first_name="Dorian", last_name="Nakalema", origin_country=country,
        birth_year=date.today().year - 11, gender="F", courses=[course],
    )
    other_student = Student(
        first_name="Other", last_name="Student", origin_country=country,
        birth_year=date.today().year - 13, gender="M", courses=[other_course],
    )
    db_session.add_all([student, other_student])
    db_session.flush()
    seed_skill_surveys(db_session)
    db_session.commit()
    return {
        "mentor_token": token(mentor_account, "mentor", mentor),
        "admin_token": token(admin_account, "admin", admin),
        "course": course,
        "other_course": other_course,
        "student": student,
        "other_student": other_student,
    }


def get_forms(client, seeded, token_name="mentor_token"):
    response = client.get(
        "/api/shared/skill-surveys/forms",
        params={"student_id": seeded["student"].id, "course_id": seeded["course"].id},
        headers=auth_header(seeded[token_name]),
    )
    assert response.status_code == 200
    return response.json()


def submission_payload(seeded, form, selected_option=1):
    return {
        "student_id": seeded["student"].id,
        "course_id": seeded["course"].id,
        "form_id": form["id"],
        "survey_date": date.today().isoformat(),
        "answers": [
            {"question_id": question["id"], "selected_option": selected_option}
            for question in form["questions"]
        ],
    }


def test_forms_are_age_selected_and_hide_answer_keys(client, seeded):
    forms = get_forms(client, seeded)
    assert {form["survey_slug"] for form in forms} == {"math", "coding"}
    assert {form["age_group"] for form in forms} == {"under_12"}
    assert {form["survey_slug"]: len(form["questions"]) for form in forms} == {
        "math": 20,
        "coding": 15,
    }
    question = forms[0]["questions"][0]
    assert question["options"] == [1, 2, 3]
    assert "correct_option" not in question


def test_submission_scores_server_side_locks_age_and_lists_result(
    client, seeded, db_session
):
    form = next(form for form in get_forms(client, seeded) if form["survey_slug"] == "coding")
    payload = submission_payload(seeded, form)
    response = client.post(
        "/api/shared/skill-surveys/submissions",
        json=payload,
        headers=auth_header(seeded["mentor_token"]),
    )
    assert response.status_code == 201
    result = response.json()
    assert result["correct_answers"] == 4
    assert result["total_questions"] == 15
    assert "score" not in result

    enrollment = db_session.get(
        StudentCourse, (seeded["student"].id, seeded["course"].id)
    )
    assert enrollment.survey_age_group.value == "under_12"
    answers = db_session.query(SkillSurveyAnswer).all()
    assert len(answers) == 15
    assert all(answer.selected_option == 1 for answer in answers)

    history = client.get(
        "/api/shared/skill-surveys/results",
        params={"student_id": seeded["student"].id},
        headers=auth_header(seeded["mentor_token"]),
    )
    assert history.status_code == 200
    assert history.json() == [result]


def test_submission_requires_every_question_and_prevents_duplicate(client, seeded):
    form = get_forms(client, seeded)[0]
    payload = submission_payload(seeded, form)
    incomplete = {**payload, "answers": payload["answers"][:-1]}
    response = client.post(
        "/api/shared/skill-surveys/submissions",
        json=incomplete,
        headers=auth_header(seeded["mentor_token"]),
    )
    assert response.status_code == 400

    first = client.post(
        "/api/shared/skill-surveys/submissions",
        json=payload,
        headers=auth_header(seeded["mentor_token"]),
    )
    assert first.status_code == 201
    duplicate = client.post(
        "/api/shared/skill-surveys/submissions",
        json=payload,
        headers=auth_header(seeded["mentor_token"]),
    )
    assert duplicate.status_code == 409


def test_mentor_cannot_survey_student_outside_assigned_active_course(client, seeded):
    response = client.get(
        "/api/shared/skill-surveys/forms",
        params={
            "student_id": seeded["other_student"].id,
            "course_id": seeded["other_course"].id,
        },
        headers=auth_header(seeded["mentor_token"]),
    )
    assert response.status_code == 403


def test_admin_can_access_any_students_course(client, seeded):
    response = client.get(
        "/api/shared/skill-surveys/forms",
        params={
            "student_id": seeded["other_student"].id,
            "course_id": seeded["other_course"].id,
        },
        headers=auth_header(seeded["admin_token"]),
    )
    assert response.status_code == 200
    assert {form["age_group"] for form in response.json()} == {"age_12_plus"}
