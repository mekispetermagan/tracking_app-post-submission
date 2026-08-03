from datetime import UTC, datetime

from models import SkillSurvey, SkillSurveyAgeGroup, SkillSurveyForm, SkillSurveyFormStatus, SkillSurveyQuestion

MATH_SOLUTIONS = (2, 1, 3, 3, 1, 3, 2, 1, 3, 2, 1, 3, 3, 1, 3, 1, 3, 2, 3, 1)
CODING_SOLUTIONS = (1, 2, 3, 2, 3, 1, 3, 3, 3, 1, 2, 2, 1, 3, 2)

MATH_UNDER_12 = (
    "Which is the shortest way?", "Which pond has more fish?", "Which is the fourth in the sequence?",
    "How many edges does a Stop sign have?", "Which sentence has the most letters?",
    "Which number is between 79 and 81?", "Which is the longest?", "Which square fits in the image?",
    "Which is the shortest pencil?", "How many minutes are in an hour?",
    "June 24 is Friday. What day is June 25?", "How many apples would be in the fourth picture?",
    "Which is the longest?", "Are there more light or more dark windows?", "How much is an orange?",
    "It's 6 o'clock now. What was the time 1 hour ago?", "What year is it now?",
    "How much money is there in the image?", "How much are the two altogether?",
    "We payed ten thousand. How much is the balance?",
)
MATH_12_PLUS = (
    "Which is the shortest way?", "Which pond has more fish?", "Which is the fourth in the sequence?",
    "How many edges does this unusual Stop sign have?", "Which sentence has the most letters?",
    "Which number is in the middle?", "Which is the longest?", "Which square fits in the image?",
    "Which is the second longest pencil?", "How many minutes are in three hours?",
    "June 24 is Friday. What day is June 27?", "How many apples would be in the fourth picture?",
    "Which is the longest?", "Are there more light or more dark windows?", "How much is an orange?",
    "It's 6 o'clock now. What was the time 7 hours ago?", "What year was it five years ago?",
    "How much money is there in the image?", "How much are the three altogether?",
    "We payed ten thousand. How much is the balance?",
)
CODING_UNDER_12 = (
    "How do you start a Scratch project?", "Which tool was used to draw this man?",
    "What does a sprite with this code do?", "Which code moves a sprite to the right?",
    "Where does changing y position move a sprite?", "What does this script draw?",
    "What CANNOT be created with Scratch?", "What is the missing block that will make the Ballerina dance?",
    "What is the missing step that will make the instructions complete?", "What is wrong with these instructions?",
    "What should you do at 7 pm?", "What is the result of the following procedure?",
    "What is the result of the following procedure?", "What is the result of the following procedure?",
    "From which square to which square does this chess piece move?",
)
CODING_12_PLUS = (
    "How do you start a Scratch project?", "Which tools were used to draw this?",
    "What does a sprite with this code do?", 'What is the difference between "Go to" and "Glide" blocks?',
    "A sprite moved 100 steps right and 100 steps down from the center. Where is it now?",
    "What does this script draw?", "What CANNOT be created with Scratch?",
    "What is the missing block that will make the Ballerina dance?",
    "What is the missing step that will make the instructions complete?", "What is wrong with these instructions?",
    "What happens if the temperature is 26˚C?", "What is the result of the following procedure?",
    "What is the result of the following procedure?", "What is the result of the following procedure?",
    "From which square to which square does this chess piece move?",
)

FORM_DATA = (
    ("math", "Math", SkillSurveyAgeGroup.UNDER_12, "math_1_en", MATH_UNDER_12, MATH_SOLUTIONS),
    ("math", "Math", SkillSurveyAgeGroup.AGE_12_PLUS, "math_2_en", MATH_12_PLUS, MATH_SOLUTIONS),
    ("coding", "Coding", SkillSurveyAgeGroup.UNDER_12, "coding_1_en", CODING_UNDER_12, CODING_SOLUTIONS),
    ("coding", "Coding", SkillSurveyAgeGroup.AGE_12_PLUS, "coding_2_en", CODING_12_PLUS, CODING_SOLUTIONS),
)


def seed_skill_surveys(db) -> None:
    surveys = {}
    for slug, name, age_group, asset_dir, prompts, solutions in FORM_DATA:
        survey = surveys.get(slug) or db.query(SkillSurvey).filter_by(slug=slug).first()
        if survey is None:
            survey = SkillSurvey(slug=slug, name=name)
            db.add(survey)
            db.flush()
        surveys[slug] = survey
        if db.query(SkillSurveyForm).filter_by(survey_id=survey.id, age_group=age_group, version=1).first():
            continue
        if len(prompts) != len(solutions):
            raise ValueError(f"Mismatched question and solution count for {slug}")
        db.add(SkillSurveyForm(
            survey=survey, age_group=age_group, version=1,
            status=SkillSurveyFormStatus.PUBLISHED, published_at=datetime.now(UTC),
            questions=[SkillSurveyQuestion(
                position=position, code=f"{slug}_{position:02d}", prompt=prompt,
                illustration_key=f"{asset_dir}/{position}.webp", correct_option=correct_option,
            ) for position, (prompt, correct_option) in enumerate(zip(prompts, solutions), start=1)],
        ))
