import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';
import '_api_support.dart';
import 'api_result.dart';

enum SharedSkillSurveyFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class SharedSkillSurveyFormsResult
    extends ApiResult<List<SkillSurveyForm>, SharedSkillSurveyFailure> {
  final List<SkillSurveyForm>? forms;
  @override
  final SharedSkillSurveyFailure? failure;
  @override
  final String? message;
  const SharedSkillSurveyFormsResult.success({required this.forms})
    : failure = null,
      message = null;
  const SharedSkillSurveyFormsResult.failure({
    required this.failure,
    this.message,
  }) : forms = null;
}

class SharedSkillSurveySubmissionResult
    extends ApiResult<SkillSurveyResult, SharedSkillSurveyFailure> {
  final SkillSurveyResult? result;
  @override
  final SharedSkillSurveyFailure? failure;
  @override
  final String? message;
  const SharedSkillSurveySubmissionResult.success({required this.result})
    : failure = null,
      message = null;
  const SharedSkillSurveySubmissionResult.failure({
    required this.failure,
    this.message,
  }) : result = null;
}

class SharedSkillSurveyResultsResult
    extends ApiResult<List<SkillSurveyResult>, SharedSkillSurveyFailure> {
  final List<SkillSurveyResult>? results;
  @override
  final SharedSkillSurveyFailure? failure;
  @override
  final String? message;

  const SharedSkillSurveyResultsResult.success({required this.results})
    : failure = null,
      message = null;
  const SharedSkillSurveyResultsResult.failure({
    required this.failure,
    this.message,
  }) : results = null;
}

class SharedSkillSurveyApi {
  final http.Client _client;
  SharedSkillSurveyApi({http.Client? client})
    : _client = client ?? http.Client();

  Future<SharedSkillSurveyResultsResult> fetchResults({
    required String accessToken,
    required int studentId,
    int? courseId,
  }) async {
    final query = {'student_id': studentId.toString()};
    if (courseId != null) query['course_id'] = courseId.toString();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/skill-surveys/results',
    ).replace(queryParameters: query);
    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);
      if (response.statusCode == 200) {
        return SharedSkillSurveyResultsResult.success(
          results: (data as List<dynamic>)
              .map(
                (item) =>
                    SkillSurveyResult.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
        );
      }
      return SharedSkillSurveyResultsResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedSkillSurveyResultsResult.failure(
          failure: SharedSkillSurveyFailure.invalidData,
        );
      }
      return const SharedSkillSurveyResultsResult.failure(
        failure: SharedSkillSurveyFailure.networkError,
      );
    }
  }

  Future<SharedSkillSurveyFormsResult> fetchForms({
    required String accessToken,
    required int studentId,
    required int courseId,
    required DateTime surveyDate,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/shared/skill-surveys/forms')
        .replace(
          queryParameters: {
            'student_id': studentId.toString(),
            'course_id': courseId.toString(),
            'survey_date': _dateOnly(surveyDate),
          },
        );
    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);
      if (response.statusCode == 200) {
        return SharedSkillSurveyFormsResult.success(
          forms: (data as List<dynamic>)
              .map(
                (item) =>
                    SkillSurveyForm.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
        );
      }
      return SharedSkillSurveyFormsResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedSkillSurveyFormsResult.failure(
          failure: SharedSkillSurveyFailure.invalidData,
        );
      }
      return const SharedSkillSurveyFormsResult.failure(
        failure: SharedSkillSurveyFailure.networkError,
      );
    }
  }

  Future<SharedSkillSurveySubmissionResult> submit({
    required String accessToken,
    required SkillSurveySubmissionRequest request,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/skill-surveys/submissions',
    );
    try {
      final response = await _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );
      final data = decodeJsonBody(response.body);
      if (response.statusCode == 201) {
        return SharedSkillSurveySubmissionResult.success(
          result: SkillSurveyResult.fromJson(data as Map<String, dynamic>),
        );
      }
      return SharedSkillSurveySubmissionResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedSkillSurveySubmissionResult.failure(
          failure: SharedSkillSurveyFailure.invalidData,
        );
      }
      return const SharedSkillSurveySubmissionResult.failure(
        failure: SharedSkillSurveyFailure.networkError,
      );
    }
  }

  SharedSkillSurveyFailure _failureFromStatusCode(int statusCode) =>
      switch (statusCode) {
        400 || 422 => SharedSkillSurveyFailure.badRequest,
        401 => SharedSkillSurveyFailure.unauthorized,
        403 => SharedSkillSurveyFailure.forbidden,
        404 => SharedSkillSurveyFailure.notFound,
        409 => SharedSkillSurveyFailure.conflict,
        _ => SharedSkillSurveyFailure.serverError,
      };
}

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
