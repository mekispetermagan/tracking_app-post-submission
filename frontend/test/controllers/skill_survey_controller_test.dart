import 'package:agu_frontend/api/api.dart';
import 'package:agu_frontend/controllers/controllers.dart';
import 'package:agu_frontend/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('owns selection, question navigation, and submission state', () async {
    final surveyApi = _SurveyApi();
    final controller = SkillSurveyController(
      studentApi: _StudentApi(),
      courseApi: _CourseApi(),
      surveyApi: surveyApi,
      today: () => DateTime(2026, 8, 3),
    );

    await controller.initialize(accessToken: 'token');
    expect(controller.view, SkillSurveyView.selection);
    expect(controller.students, hasLength(1));

    controller.selectStudent(1);
    expect(controller.selectedCourseId, 2);
    expect(controller.canContinue, isTrue);

    await controller.openSurveyMenu(accessToken: 'token');
    expect(controller.view, SkillSurveyView.menu);
    expect(controller.completedToday(controller.forms.single), isFalse);

    controller.startSurvey(controller.forms.single);
    expect(controller.currentQuestion!.position, 1);
    expect(controller.illustrationAsset, endsWith('math_1_en/1.webp'));
    await controller.answerCurrentQuestion(
      accessToken: 'token',
      questionId: 10,
      option: 2,
    );
    expect(controller.currentQuestion!.position, 2);
    await controller.answerCurrentQuestion(
      accessToken: 'token',
      questionId: 11,
      option: 1,
    );

    expect(controller.view, SkillSurveyView.completed);
    expect(controller.submittedResult!.correctAnswers, 2);
    expect(
      surveyApi.submission!.answers.map((answer) => answer.selectedOption),
      [2, 1],
    );

    controller.back();
    expect(controller.view, SkillSurveyView.menu);
    expect(controller.completedToday(controller.forms.single), isTrue);
  });
}

const _student = Student(
  id: 1,
  firstName: 'Dorian',
  lastName: 'Nakalema',
  originCountryId: 1,
  birthYear: 2015,
  gender: null,
  active: true,
  courseIds: [2],
);
const _course = Course(
  id: 2,
  name: 'Course',
  description: '',
  countryId: 1,
  dayOfWeek: 1,
  startTime: '10:00',
  active: true,
  mentorIds: [],
  studentIds: [1],
);
const _form = SkillSurveyForm(
  id: 3,
  surveySlug: 'math',
  surveyName: 'Math',
  ageGroup: 'under_12',
  version: 1,
  questions: [
    SkillSurveyQuestion(
      id: 10,
      position: 1,
      code: 'math_01',
      prompt: 'One?',
      illustrationKey: 'math_1_en/1.webp',
      options: [1, 2, 3],
    ),
    SkillSurveyQuestion(
      id: 11,
      position: 2,
      code: 'math_02',
      prompt: 'Two?',
      illustrationKey: 'math_1_en/2.webp',
      options: [1, 2, 3],
    ),
  ],
);

class _StudentApi extends SharedStudentApi {
  @override
  Future<SharedStudentListResult> fetchStudents({
    required String accessToken,
    bool activeOnly = true,
    int? courseId,
  }) async => const SharedStudentListResult.success(students: [_student]);
}

class _CourseApi extends SharedCourseApi {
  @override
  Future<SharedCourseListResult> fetchCourses({
    required String accessToken,
    bool activeOnly = true,
  }) async => const SharedCourseListResult.success(courses: [_course]);
}

class _SurveyApi extends SharedSkillSurveyApi {
  SkillSurveySubmissionRequest? submission;

  @override
  Future<SharedSkillSurveyFormsResult> fetchForms({
    required String accessToken,
    required int studentId,
    required int courseId,
    required DateTime surveyDate,
  }) async => const SharedSkillSurveyFormsResult.success(forms: [_form]);

  @override
  Future<SharedSkillSurveyResultsResult> fetchResults({
    required String accessToken,
    required int studentId,
    int? courseId,
  }) async => const SharedSkillSurveyResultsResult.success(results: []);

  @override
  Future<SharedSkillSurveySubmissionResult> submit({
    required String accessToken,
    required SkillSurveySubmissionRequest request,
  }) async {
    submission = request;
    return SharedSkillSurveySubmissionResult.success(
      result: SkillSurveyResult(
        submissionId: 20,
        studentId: request.studentId,
        courseId: request.courseId,
        surveyDate: request.surveyDate,
        surveySlug: 'math',
        surveyName: 'Math',
        ageGroup: 'under_12',
        formVersion: 1,
        correctAnswers: 2,
        totalQuestions: 2,
        createdAt: DateTime(2026, 8, 3),
      ),
    );
  }
}
