from datetime import date, datetime

from pydantic import BaseModel, Field

from models import SkillSurveyAgeGroup


class SkillSurveyQuestionOut(BaseModel):
    id: int
    position: int
    code: str
    prompt: str
    illustration_key: str
    options: list[int] = Field(default_factory=lambda: [1, 2, 3])


class SkillSurveyFormOut(BaseModel):
    id: int
    survey_slug: str
    survey_name: str
    age_group: SkillSurveyAgeGroup
    version: int
    questions: list[SkillSurveyQuestionOut]


class SkillSurveyAnswerCreate(BaseModel):
    question_id: int
    selected_option: int = Field(ge=1, le=3)


class SkillSurveySubmissionCreate(BaseModel):
    student_id: int
    course_id: int
    form_id: int
    survey_date: date
    answers: list[SkillSurveyAnswerCreate] = Field(min_length=1)


class SkillSurveyResultOut(BaseModel):
    submission_id: int
    student_id: int
    course_id: int
    survey_date: date
    survey_slug: str
    survey_name: str
    age_group: SkillSurveyAgeGroup
    form_version: int
    correct_answers: int
    total_questions: int
    created_at: datetime
