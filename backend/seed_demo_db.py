"""Create the fictional, disposable public demonstration database.

This script drops every table in the configured database.  As a guard against
running it against a real deployment, DATABASE_URL must contain ``demo``.
"""

from datetime import UTC, date, datetime, time, timedelta
from math import ceil, floor
from random import Random

from pwdlib import PasswordHash

from config import settings
from database import Base, SessionLocal, engine
from models import (
    Account,
    AdminProfile,
    CompletionStatus,
    Country,
    Course,
    CourseVisitAction,
    CourseVisitActionCategory,
    CourseVisitAnswer,
    CourseVisitEnvironmentStatus,
    CourseVisitLearnerEngagement,
    CourseVisitMentor,
    CourseVisitMentorRole,
    CourseVisitReport,
    CourseVisitSessionStatus,
    CourseVisitStudent,
    CourseVisitStudentEnjoyment,
    CourseVisitStudentLearning,
    CourseVisitStudentSafety,
    MentorProfile,
    ProjectType,
    SessionLog,
    SessionLogMentor,
    SessionLogMentorRole,
    SessionPhoto,
    Story,
    StoryMentorRating,
    StoryOfMonth,
    StoryPhoto,
    Student,
)
from skill_survey_seed import seed_skill_surveys

random = Random(20260721)
password_hash = PasswordHash.recommended()

JUDGE_MENTOR_PHONE = "0123456789"
JUDGE_MENTOR_PIN = "123456"
JUDGE_ADMIN_PHONE = "0987654321"
JUDGE_ADMIN_PASSWORD = "Judge123"

SESSION_START = date(2026, 6, 1)
SESSION_END = date(2026, 7, 21)

MENTORS = (
    ("Judge", "Mentor", JUDGE_MENTOR_PHONE),
    ("Amina", "Namusoke", "0700000001"),
    ("Brian", "Ssemanda", "0700000002"),
    ("Catherine", "Adoch", "0700000003"),
    ("Daniel", "Mugerwa", "0700000004"),
    ("Esther", "Nabirye", "0700000005"),
)

ADMINS = (
    ("Judge", "Administrator", JUDGE_ADMIN_PHONE, JUDGE_ADMIN_PASSWORD),
    ("Demo", "Coordinator", "0799999999", "DemoAdmin123"),
)

COURSES = (
    ("Kawempe Community Lab", "Kawempe", 0, time(15, 30), (1, 2)),
    ("Busega Learning Hub", "Busega", 1, time(14, 0), (0, 3)),
    ("Nansana Digital Club", "Nansana", 2, time(15, 0), (2, 4)),
    ("Kasangati Code Club", "Kasangati", 3, time(14, 30), (1, 5)),
    ("Kira Young Makers", "Kira", 4, time(15, 30), (3, 4)),
    ("Luwero Skills Lab", "Luwero", 5, time(10, 0), (2, 5)),
    ("Katalemwa Creative Computing", "Katalemwa", 6, time(14, 0), (1, 3)),
    ("Wakiso Robotics Club", "Wakiso", 0, time(15, 0), (4, 5)),
    ("Mukono Community Coders", "Mukono", 1, time(15, 30), (0, 2)),
    ("Gayaza Girls in Technology", "Gayaza", 2, time(14, 0), (3, 5)),
    ("Matugga Innovation Club", "Matugga", 3, time(15, 0), (1, 4)),
    ("Entebbe Junior Makers", "Entebbe", 5, time(11, 0), (2, 3)),
)

HOSTS = (
    "a local primary school",
    "a parish church community hall",
    "a youth-focused NGO",
    "the Subcounty Headquarters",
)

FEMALE_NAMES = (
    "Achen", "Aisha", "Atim", "Brenda", "Doreen", "Esther",
    "Faith", "Flavia", "Gloria", "Immaculate", "Joan", "Juliet",
)
MALE_NAMES = (
    "Abas", "Andrew", "Brian", "David", "Emmanuel", "Isaac",
    "Ivan", "Joel", "Joshua", "Martin", "Moses", "Samuel",
)
SURNAMES = (
    "Akello", "Kato", "Kisembo", "Lwanga", "Mugisha", "Mukasa",
    "Nakato", "Namatovu", "Nsubuga", "Okello", "Sserwadda", "Tumusiime",
)

PROJECTS = (
    (ProjectType.SCRATCH, "Dancing animation"),
    (ProjectType.SCRATCH, "Crazy letters"),
    (ProjectType.SCRATCH, "Chasing game"),
    (ProjectType.SCRATCH, "Dino game"),
    (ProjectType.SCRATCH, "Flower rain"),
    (ProjectType.SCRATCH, "Growing flower"),
    (ProjectType.ROBOTICS, "Puppy"),
    (ProjectType.ROBOTICS, "Simple human"),
    (ProjectType.ROBOTICS, "Advanced human"),
    (ProjectType.ROBOTICS, "Simple car"),
    (ProjectType.ROBOTICS, "Advanced car"),
    (ProjectType.APP_INVENTOR, "Click counter"),
    (ProjectType.APP_INVENTOR, "Color mixer"),
    (ProjectType.APP_INVENTOR, "Piano"),
    (ProjectType.APP_INVENTOR, "Drawing app"),
    (ProjectType.APP_INVENTOR, "Translator app"),
    (ProjectType.WEB_DEVELOPMENT, "Community notice board"),
    (ProjectType.WEB_DEVELOPMENT, "School club website"),
    (ProjectType.ROBOTICS, "Automatic night light"),
    (ProjectType.SCRATCH, "Road safety quiz"),
)

SKILL_GAMES = (
    "Mixed letters", "Reading game", "Logic game", "Math train",
    "Guess the operator", "Word card memory", "Number swarm",
)

ISSUES = (
    "Two laptops had an equipment failure, so learners shared devices.",
    "A power outage shortened device time; the group continued unplugged.",
    "A mobile network outage delayed downloading the starter files.",
    "Local officials harassed the venue host about permission to meet; "
    "the partner resolved it and the children remained supervised and safe.",
)

STORY_TEXTS = (
    "A learner who was initially afraid to touch the laptop built a complete "
    "animation and then showed two classmates how to debug theirs.",
    "When electricity failed, the group arranged paper Scratch blocks into "
    "programs and acted out each instruction before power returned.",
    "A quiet student designed a robot attachment from leftover pieces and "
    "confidently explained the idea to the whole group.",
    "Three learners stayed after the session to improve their community "
    "notice-board page and added information for parents in two languages.",
    "A parent arrived early and watched her daughter lead a debugging team; "
    "she later asked how the club could welcome more girls.",
    "Learners turned a broken sensor into a lesson on testing: they isolated "
    "the fault, documented it, and completed the project with another sensor.",
)


def _assert_demo_database():
    if "demo" not in settings.database_url.lower():
        raise RuntimeError(
            "Refusing to destroy a database whose DATABASE_URL does not contain 'demo'."
        )


def _account(db, country, first, last, phone, *, pin=None, password=None):
    account = Account(
        first_name=first,
        last_name=last,
        phone=phone,
        country=country,
        preferred_language="en",
    )
    db.add(account)
    db.flush()
    if pin:
        account.mentor_profile = MentorProfile(
            pin_hash=password_hash.hash(pin),
            must_change_pin=False,
            temporary_pin_expires_at=None,
        )
    if password:
        account.admin_profile = AdminProfile(
            password_hash=password_hash.hash(password),
            must_change_password=False,
            temporary_password_expires_at=None,
        )
    db.flush()
    return account


def _students(db, country, course, course_index):
    result = []
    for index in range(10):
        female = index < 5
        names = FEMALE_NAMES if female else MALE_NAMES
        name_index = (course_index * 5 + index % 5) % len(names)
        surname_index = (course_index * 7 + index) % len(SURNAMES)
        student = Student(
            first_name=names[name_index],
            last_name=SURNAMES[surname_index],
            origin_country=country,
            birth_year=2012 + ((course_index + index) % 5),
            gender="F" if female else "M",
            courses=[course],
        )
        db.add(student)
        result.append(student)
    return result


def _matching_dates(day_of_week):
    current = SESSION_START + timedelta(
        days=(day_of_week - SESSION_START.weekday()) % 7
    )
    dates = []
    while current <= SESSION_END:
        dates.append(current)
        current += timedelta(days=7)
    return dates


def _session_logs(db, course, course_index):
    logs = []
    students = list(course.students)
    mentors = list(course.mentors)
    minimum = ceil(len(students) * 0.8)
    maximum = floor(len(students) * 0.9)
    for index, session_date in enumerate(_matching_dates(course.day_of_week)):
        lead = mentors[index % 2]
        support = mentors[(index + 1) % 2]
        project_type, project_title = PROJECTS[(course_index * 3 + index) % len(PROJECTS)]
        challenge = ISSUES[(course_index + index) % len(ISSUES)] if index % 3 == 1 else None
        log = SessionLog(
            submitted_by=lead,
            mentor_participations=[
                SessionLogMentor(mentor=lead, role=SessionLogMentorRole.TEACHING),
                SessionLogMentor(mentor=support, role=SessionLogMentorRole.SUPPORTING),
            ],
            course=course,
            date=session_date,
            project_title=project_title,
            project_type=project_type,
            games_played=SKILL_GAMES[(course_index + index) % len(SKILL_GAMES)],
            completion_status=(
                CompletionStatus.PARTLY_COMPLETED
                if challenge else CompletionStatus.COMPLETED
            ),
            what_worked=(
                "Pair work kept learners engaged, and most completed the main task independently."
            ),
            challenges=challenge,
            next_step=(
                "Review the difficult step, then add one feature and allow time for testing."
            ),
            students=random.sample(students, random.randint(minimum, maximum)),
        )
        db.add(log)
        logs.append(log)
    return logs


def _session_photos(db, logs_by_course):
    filenames = []
    for course_index in (0, 1, 4, 8, 10):
        log = logs_by_course[course_index][-2]
        uploader = log.mentor_participations[0].mentor
        for number in range(1, 4):
            filename = (
                f"demo_session_c{course_index + 1:02d}_"
                f"{log.date:%Y%m%d}_{number:02d}.jpg"
            )
            db.add(
                SessionPhoto(
                    session_log=log,
                    mentor=uploader,
                    photo_number=number,
                    original_path=f"original_photos/{filename}",
                    compressed_path=f"compressed_photos/{filename}",
                    uploaded_at=datetime.combine(log.date, time(18), tzinfo=UTC),
                )
            )
            filenames.append(filename)
    return filenames


def _stories(db, courses, mentors, admins):
    stories = []
    filenames = []
    for month_index, month in enumerate((6, 7)):
        for mentor_index, mentor in enumerate(mentors):
            eligible_courses = [course for course in courses if mentor in course.mentors]
            course = eligible_courses[month_index % len(eligible_courses)]
            submitted_at = datetime(2026, month, 5 + mentor_index * 2, 16, 0, tzinfo=UTC)
            filename = f"demo_story_2026{month:02d}_m{mentor_index + 1:02d}.jpg"
            story = Story(
                submitted_by=mentor,
                course=course,
                text=STORY_TEXTS[(mentor_index + month_index) % len(STORY_TEXTS)],
                submission_month=date(2026, month, 1),
                created_at=submitted_at,
                updated_at=submitted_at,
                photo=StoryPhoto(
                    original_path=f"original_story_photos/{filename}",
                    compressed_path=f"compressed_story_photos/{filename}",
                    uploaded_at=submitted_at,
                ),
            )
            db.add(story)
            stories.append(story)
            filenames.append(filename)
    db.flush()
    for story_index, story in enumerate(stories):
        for offset in (1, 2, 3):
            rater = mentors[(story_index + offset) % len(mentors)]
            if rater is story.submitted_by:
                continue
            db.add(
                StoryMentorRating(
                    story=story,
                    mentor=rater,
                    rating=4 + ((story_index + offset) % 2),
                )
            )
    db.add_all(
        [
            StoryOfMonth(
                month=date(2026, 6, 1),
                story=stories[2],
                selected_by=admins[1],
                selected_at=datetime(2026, 7, 1, 9, 0, tzinfo=UTC),
            ),
            StoryOfMonth(
                month=date(2026, 7, 1),
                story=stories[9],
                selected_by=admins[0],
                selected_at=datetime(2026, 7, 21, 17, 0, tzinfo=UTC),
            ),
        ]
    )
    return filenames


def _visit(db, course, admin, visit_date, index):
    students = list(course.students)
    mentors = list(course.mentors)
    problems = (
        "Two laptop batteries failed and reduced hands-on time.",
        "A power outage interrupted the planned robotics demonstration.",
        "Mobile network coverage was unavailable for part of the session.",
        "Local officials questioned the venue host; the partner clarified permission calmly.",
    )
    categories = (
        CourseVisitActionCategory.EQUIPMENT,
        CourseVisitActionCategory.VENUE_SCHEDULING,
        CourseVisitActionCategory.CURRICULUM_SUPPORT,
        CourseVisitActionCategory.PARTNER_DISCUSSION,
    )
    return CourseVisitReport(
        submitted_by=admin,
        course=course,
        date=visit_date,
        session_status=CourseVisitSessionStatus.FULLY_HELD,
        teaching_took_place=CourseVisitAnswer.YES,
        session_followed_plan=CourseVisitAnswer.PARTLY,
        learner_engagement=CourseVisitLearnerEngagement.MOST,
        equipment_adequate=CourseVisitAnswer.PARTLY,
        environment_status=CourseVisitEnvironmentStatus.SAFE_AND_RESPECTFUL,
        what_happened=(
            "Learners worked in pairs, built the planned project, and demonstrated it to peers."
        ),
        main_strength=(
            "Mentors used clear demonstrations and gave patient individual support."
        ),
        main_problem=problems[index],
        support_provided=(
            "The observer reorganized groups, reviewed the session plan, and agreed follow-up actions."
        ),
        course_health_rating=4 if index < 3 else 3,
        safeguarding_concern=False,
        mentors=[
            CourseVisitMentor(
                mentor=mentors[0],
                role=CourseVisitMentorRole.TEACHING,
                performance_rating=4,
            ),
            CourseVisitMentor(
                mentor=mentors[1],
                role=CourseVisitMentorRole.SUPPORTING,
                performance_rating=4,
            ),
        ],
        students=[
            CourseVisitStudent(
                student=student,
                interviewed=student_index < 3,
                enjoyment=(CourseVisitStudentEnjoyment.YES if student_index < 3 else None),
                learning=(CourseVisitStudentLearning.CLEARLY if student_index < 3 else None),
                feels_safe=(CourseVisitStudentSafety.YES if student_index < 3 else None),
                note=(
                    "The learner described the project confidently and identified the next improvement."
                    if student_index < 3 else None
                ),
            )
            for student_index, student in enumerate(students[:8])
        ],
        actions=[
            CourseVisitAction(
                category=categories[index],
                description=(
                    "Resolve the identified constraint before the next scheduled session."
                ),
                responsible_person=(
                    f"{mentors[0].account.first_name} {mentors[0].account.last_name}"
                ),
                target_date=visit_date + timedelta(days=7),
                completed=index < 2,
                completed_at=(
                    datetime.combine(visit_date + timedelta(days=5), time(12), tzinfo=UTC)
                    if index < 2 else None
                ),
            )
        ],
    )


def main():
    _assert_demo_database()
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        uganda = Country(code="UG", name="Uganda")
        db.add(uganda)
        db.flush()
        mentor_accounts = [
            _account(db, uganda, first, last, phone, pin=JUDGE_MENTOR_PIN)
            for first, last, phone in MENTORS
        ]
        admin_accounts = [
            _account(db, uganda, first, last, phone, password=password)
            for first, last, phone, password in ADMINS
        ]
        mentors = [account.mentor_profile for account in mentor_accounts]
        admins = [account.admin_profile for account in admin_accounts]

        courses = []
        for index, (name, location, day, start, mentor_indexes) in enumerate(COURSES):
            course = Course(
                name=name,
                description=(
                    f"A digital learning course in {location}, hosted by "
                    f"{HOSTS[index % len(HOSTS)]}. Churches, schools, NGOs, and "
                    "Subcounty Headquarters are welcome to host and support sessions."
                ),
                country=uganda,
                day_of_week=day,
                start_time=start,
                mentors=[mentors[mentor_index] for mentor_index in mentor_indexes],
            )
            db.add(course)
            db.flush()
            _students(db, uganda, course, index)
            courses.append(course)
        db.flush()

        logs_by_course = [
            _session_logs(db, course, index) for index, course in enumerate(courses)
        ]
        session_photo_filenames = _session_photos(db, logs_by_course)
        story_photo_filenames = _stories(db, courses, mentors, admins)
        visits = (
            (courses[0], admins[1], date(2026, 6, 15)),
            (courses[1], admins[0], date(2026, 6, 23)),
            (courses[4], admins[1], date(2026, 7, 10)),
            (courses[8], admins[0], date(2026, 7, 21)),
        )
        db.add_all(
            [_visit(db, course, admin, visit_date, index) for index, (course, admin, visit_date) in enumerate(visits)]
        )
        seed_skill_surveys(db)
        db.commit()

        print("Demo database created.")
        print(f"Judge mentor: {JUDGE_MENTOR_PHONE} / {JUDGE_MENTOR_PIN}")
        print(f"Judge admin: {JUDGE_ADMIN_PHONE} / {JUDGE_ADMIN_PASSWORD}")
        print("Photo files required in both original and compressed directories:")
        for filename in session_photo_filenames:
            print(f"  session: {filename}")
        for filename in story_photo_filenames:
            print(f"  story:   {filename}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
