import 'feature_controller.dart';

import '../api/api.dart';
import '../models/models.dart';

class StudentRecordController extends FeatureController {
  final SharedStudentRecordApi _studentRecordApi;
  final SharedSkillSurveyApi _skillSurveyApi;

  StudentRecordController({
    SharedStudentRecordApi? studentRecordApi,
    SharedSkillSurveyApi? skillSurveyApi,
  }) : _studentRecordApi = studentRecordApi ?? SharedStudentRecordApi(),
       _skillSurveyApi = skillSurveyApi ?? SharedSkillSurveyApi();

  StudentRecord? _studentRecord;
  List<SkillSurveyResult> _skillSurveyResults = [];
  bool _isLoading = false;
  String? _message;

  StudentRecord? get studentRecord => _studentRecord;
  List<SkillSurveyResult> get skillSurveyResults =>
      List.unmodifiable(_skillSurveyResults);
  bool get isLoading => _isLoading;
  String? get message => _message;

  Future<bool> load({
    required String accessToken,
    required int studentId,
  }) async {
    final request = beginRequest();
    _studentRecord = null;
    _skillSurveyResults = [];
    _isLoading = true;
    _message = null;
    notifyListeners();

    final recordFuture = _studentRecordApi.fetchStudentRecord(
      accessToken: accessToken,
      studentId: studentId,
    );
    final surveysFuture = _skillSurveyApi.fetchResults(
      accessToken: accessToken,
      studentId: studentId,
    );
    final result = await recordFuture;
    final surveysResult = await surveysFuture;

    if (!requestIsCurrent(request)) return false;

    if (result.studentRecord != null) {
      _studentRecord = result.studentRecord;
      _skillSurveyResults = surveysResult.results ?? [];
      if (surveysResult.results == null) {
        _message =
            surveysResult.message ??
            _messageForSurveyFailure(surveysResult.failure);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);

    _isLoading = false;
    notifyListeners();
    return false;
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
    _studentRecord = null;
    _skillSurveyResults = [];
    _isLoading = false;
    _message = null;
    notifyListeners();
  }

  String _messageForFailure(SharedStudentRecordFailure? failure) {
    return switch (failure) {
      SharedStudentRecordFailure.unauthorized => 'Login expired.',
      SharedStudentRecordFailure.forbidden => 'Student record access denied.',
      SharedStudentRecordFailure.notFound => 'Student not found.',
      SharedStudentRecordFailure.invalidData => 'Invalid server data.',
      SharedStudentRecordFailure.serverError => 'Server error.',
      SharedStudentRecordFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }

  String _messageForSurveyFailure(SharedSkillSurveyFailure? failure) {
    return switch (failure) {
      SharedSkillSurveyFailure.badRequest => 'Cannot load survey results.',
      SharedSkillSurveyFailure.unauthorized => 'Login expired.',
      SharedSkillSurveyFailure.forbidden => 'Survey result access denied.',
      SharedSkillSurveyFailure.notFound => 'Student not found.',
      SharedSkillSurveyFailure.conflict => 'Cannot load survey results.',
      SharedSkillSurveyFailure.invalidData => 'Invalid survey result data.',
      SharedSkillSurveyFailure.serverError => 'Cannot load survey results.',
      SharedSkillSurveyFailure.networkError => 'Cannot load survey results.',
      null => 'Cannot load survey results.',
    };
  }
}
