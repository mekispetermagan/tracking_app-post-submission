import '../api/api.dart';
import '../models/models.dart';
import 'feature_controller.dart';

enum SkillSurveyView { selection, menu, questions, completed }

class SkillSurveyController extends FeatureController {
  SkillSurveyController({
    SharedStudentApi? studentApi,
    SharedCourseApi? courseApi,
    SharedSkillSurveyApi? surveyApi,
    this.activeOnly = true,
    DateTime Function()? today,
  }) : _studentApi = studentApi ?? SharedStudentApi(),
       _courseApi = courseApi ?? SharedCourseApi(),
       _surveyApi = surveyApi ?? SharedSkillSurveyApi(),
       _today = today ?? DateTime.now;

  final SharedStudentApi _studentApi;
  final SharedCourseApi _courseApi;
  final SharedSkillSurveyApi _surveyApi;
  final DateTime Function() _today;
  final bool activeOnly;

  SkillSurveyView _view = SkillSurveyView.selection;
  List<Student> _students = const [];
  List<Course> _courses = const [];
  List<SkillSurveyForm> _forms = const [];
  List<SkillSurveyResult> _results = const [];
  int? _studentId;
  int? _courseId;
  SkillSurveyForm? _form;
  int _questionIndex = 0;
  final Map<int, int> _answers = {};
  SkillSurveyResult? _submittedResult;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _message;

  SkillSurveyView get view => _view;
  List<Student> get students => List.unmodifiable(_students);
  List<Course> get availableCourses {
    final student = selectedStudent;
    if (student == null) {
      return const [];
    }
    return List.unmodifiable(
      _courses.where((course) => student.courseIds.contains(course.id)),
    );
  }

  List<SkillSurveyForm> get forms => List.unmodifiable(_forms);
  int? get selectedStudentId => _studentId;
  int? get selectedCourseId => _courseId;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get message => _message;
  bool get canContinue =>
      selectedStudent != null && selectedCourse != null && !_isLoading;
  Student? get selectedStudent => _findStudent(_studentId);
  Course? get selectedCourse => _findCourse(_courseId);
  SkillSurveyForm? get selectedForm => _form;
  SkillSurveyQuestion? get currentQuestion =>
      _form == null ? null : _form!.questions[_questionIndex];
  int get questionIndex => _questionIndex;
  int get questionCount => _form?.questions.length ?? 0;
  bool get isLastQuestion =>
      _form != null && _questionIndex == _form!.questions.length - 1;
  String? get illustrationAsset => currentQuestion == null
      ? null
      : 'assets/images/skill_survey/${currentQuestion!.illustrationKey}';
  SkillSurveyResult? get submittedResult => _submittedResult;

  Future<void> initialize({required String accessToken}) async {
    final request = beginRequest();
    _clearAll();
    _isLoading = true;
    notifyListeners();
    final studentsFuture = _studentApi.fetchStudents(
      accessToken: accessToken,
      activeOnly: activeOnly,
    );
    final coursesFuture = _courseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: activeOnly,
    );
    final studentsResult = await studentsFuture;
    final coursesResult = await coursesFuture;
    if (!requestIsCurrent(request)) {
      return;
    }
    if (studentsResult.students == null || coursesResult.courses == null) {
      _message =
          studentsResult.message ??
          coursesResult.message ??
          'Could not load survey participants.';
    } else {
      _students = studentsResult.students!;
      _courses = coursesResult.courses!;
    }
    _isLoading = false;
    notifyListeners();
  }

  void selectStudent(int id) {
    if (_isLoading || _findStudent(id) == null) {
      return;
    }
    _studentId = id;
    final courses = availableCourses;
    _courseId = courses.length == 1 ? courses.single.id : null;
    _message = null;
    notifyListeners();
  }

  void selectCourse(int? id) {
    if (_isLoading ||
        id == null ||
        !availableCourses.any((course) => course.id == id)) {
      return;
    }
    _courseId = id;
    _message = null;
    notifyListeners();
  }

  Future<void> openSurveyMenu({required String accessToken}) async {
    final student = selectedStudent;
    final course = selectedCourse;
    if (student == null || course == null) {
      _message = 'Select a student and course.';
      notifyListeners();
      return;
    }
    final request = beginRequest();
    _isLoading = true;
    _message = null;
    notifyListeners();
    final date = _dateOnly(_today());
    final formsFuture = _surveyApi.fetchForms(
      accessToken: accessToken,
      studentId: student.id,
      courseId: course.id,
      surveyDate: date,
    );
    final resultsFuture = _surveyApi.fetchResults(
      accessToken: accessToken,
      studentId: student.id,
      courseId: course.id,
    );
    final formsResult = await formsFuture;
    final resultsResult = await resultsFuture;
    if (!requestIsCurrent(request)) {
      return;
    }
    if (formsResult.forms == null || resultsResult.results == null) {
      _message =
          formsResult.message ??
          resultsResult.message ??
          'Could not load surveys.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    _forms = formsResult.forms!;
    _results = resultsResult.results!;
    _view = SkillSurveyView.menu;
    _isLoading = false;
    notifyListeners();
  }

  bool completedToday(SkillSurveyForm form) => _results.any(
    (result) =>
        result.surveySlug == form.surveySlug &&
        _sameDate(result.surveyDate, _today()),
  );

  SkillSurveyResult? latestResult(SkillSurveyForm form) {
    final matching = _results
        .where((result) => result.surveySlug == form.surveySlug)
        .toList();
    return matching.isEmpty ? null : matching.last;
  }

  void startSurvey(SkillSurveyForm form) {
    if (!_forms.contains(form) || completedToday(form)) {
      return;
    }
    _form = form;
    _questionIndex = 0;
    _answers.clear();
    _submittedResult = null;
    _message = null;
    _view = SkillSurveyView.questions;
    notifyListeners();
  }

  Future<void> answerCurrentQuestion({
    required String accessToken,
    required int questionId,
    required int option,
  }) async {
    final question = currentQuestion;
    if (question == null ||
        question.id != questionId ||
        !question.options.contains(option) ||
        _isSubmitting ||
        _answers.containsKey(question.id)) {
      return;
    }
    _answers[question.id] = option;
    _message = null;
    if (isLastQuestion) {
      await _submit(accessToken: accessToken);
    } else {
      _questionIndex++;
      notifyListeners();
    }
  }

  Future<void> _submit({required String accessToken}) async {
    final form = _form;
    final student = selectedStudent;
    final course = selectedCourse;
    if (form == null || student == null || course == null || !isLastQuestion) {
      return;
    }
    if (_answers.length != form.questions.length) {
      _message = 'Answer every question before submitting.';
      notifyListeners();
      return;
    }
    _isSubmitting = true;
    _message = null;
    notifyListeners();
    final response = await _surveyApi.submit(
      accessToken: accessToken,
      request: SkillSurveySubmissionRequest(
        studentId: student.id,
        courseId: course.id,
        formId: form.id,
        surveyDate: _dateOnly(_today()),
        answers: form.questions
            .map(
              (question) => SkillSurveyAnswerRequest(
                questionId: question.id,
                selectedOption: _answers[question.id]!,
              ),
            )
            .toList(),
      ),
    );
    if (response.result == null) {
      _answers.remove(currentQuestion?.id);
      _message = response.message ?? _failureMessage(response.failure);
      _isSubmitting = false;
      notifyListeners();
      return;
    }
    _submittedResult = response.result;
    _results = [..._results, response.result!];
    _view = SkillSurveyView.completed;
    _isSubmitting = false;
    notifyListeners();
  }

  void back() {
    switch (_view) {
      case SkillSurveyView.selection:
        return;
      case SkillSurveyView.menu:
        _view = SkillSurveyView.selection;
        break;
      case SkillSurveyView.questions:
        _view = SkillSurveyView.menu;
        _form = null;
        _answers.clear();
        break;
      case SkillSurveyView.completed:
        _view = SkillSurveyView.menu;
        _form = null;
        _answers.clear();
        break;
    }
    _message = null;
    notifyListeners();
  }

  void clearMessage() {
    if (_message == null) {
      return;
    }
    _message = null;
    notifyListeners();
  }

  void reset() {
    invalidateRequests();
    _clearAll();
    notifyListeners();
  }

  void _clearAll() {
    _view = SkillSurveyView.selection;
    _students = const [];
    _courses = const [];
    _forms = const [];
    _results = const [];
    _studentId = null;
    _courseId = null;
    _form = null;
    _questionIndex = 0;
    _answers.clear();
    _submittedResult = null;
    _isLoading = false;
    _isSubmitting = false;
    _message = null;
  }

  Student? _findStudent(int? id) {
    if (id == null) {
      return null;
    }
    for (final student in _students) {
      if (student.id == id) {
        return student;
      }
    }
    return null;
  }

  Course? _findCourse(int? id) {
    if (id == null) {
      return null;
    }
    for (final course in _courses) {
      if (course.id == id) {
        return course;
      }
    }
    return null;
  }

  String _failureMessage(SharedSkillSurveyFailure? failure) =>
      switch (failure) {
        SharedSkillSurveyFailure.badRequest => 'Invalid survey submission.',
        SharedSkillSurveyFailure.unauthorized => 'Login expired.',
        SharedSkillSurveyFailure.forbidden => 'Survey access denied.',
        SharedSkillSurveyFailure.notFound => 'Survey not found.',
        SharedSkillSurveyFailure.conflict =>
          'This survey has already been submitted today.',
        SharedSkillSurveyFailure.invalidData => 'Invalid server data.',
        SharedSkillSurveyFailure.serverError => 'Server error.',
        SharedSkillSurveyFailure.networkError => 'Cannot connect to server.',
        null => 'Unknown error.',
      };
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
bool _sameDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
