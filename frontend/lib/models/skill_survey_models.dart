import '_model_utils.dart';

class SkillSurveyQuestion {
  final int id;
  final int position;
  final String code;
  final String prompt;
  final String illustrationKey;
  final List<int> options;

  const SkillSurveyQuestion({
    required this.id,
    required this.position,
    required this.code,
    required this.prompt,
    required this.illustrationKey,
    required this.options,
  });

  factory SkillSurveyQuestion.fromJson(Map<String, dynamic> json) =>
      SkillSurveyQuestion(
        id: json['id'] as int,
        position: json['position'] as int,
        code: json['code'] as String,
        prompt: json['prompt'] as String,
        illustrationKey: json['illustration_key'] as String,
        options: List<int>.from(json['options'] as List),
      );
}

class SkillSurveyForm {
  final int id;
  final String surveySlug;
  final String surveyName;
  final String ageGroup;
  final int version;
  final List<SkillSurveyQuestion> questions;

  const SkillSurveyForm({
    required this.id,
    required this.surveySlug,
    required this.surveyName,
    required this.ageGroup,
    required this.version,
    required this.questions,
  });

  factory SkillSurveyForm.fromJson(Map<String, dynamic> json) =>
      SkillSurveyForm(
        id: json['id'] as int,
        surveySlug: json['survey_slug'] as String,
        surveyName: json['survey_name'] as String,
        ageGroup: json['age_group'] as String,
        version: json['version'] as int,
        questions: (json['questions'] as List<dynamic>)
            .map(
              (item) =>
                  SkillSurveyQuestion.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}

class SkillSurveyAnswerRequest {
  final int questionId;
  final int selectedOption;
  const SkillSurveyAnswerRequest({
    required this.questionId,
    required this.selectedOption,
  });
  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'selected_option': selectedOption,
  };
}

class SkillSurveySubmissionRequest {
  final int studentId;
  final int courseId;
  final int formId;
  final DateTime surveyDate;
  final List<SkillSurveyAnswerRequest> answers;
  const SkillSurveySubmissionRequest({
    required this.studentId,
    required this.courseId,
    required this.formId,
    required this.surveyDate,
    required this.answers,
  });
  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'course_id': courseId,
    'form_id': formId,
    'survey_date': modelDate(surveyDate),
    'answers': answers.map((answer) => answer.toJson()).toList(),
  };
}

class SkillSurveyResult {
  final int submissionId;
  final int studentId;
  final int courseId;
  final DateTime surveyDate;
  final String surveySlug;
  final String surveyName;
  final String ageGroup;
  final int formVersion;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime createdAt;

  const SkillSurveyResult({
    required this.submissionId,
    required this.studentId,
    required this.courseId,
    required this.surveyDate,
    required this.surveySlug,
    required this.surveyName,
    required this.ageGroup,
    required this.formVersion,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.createdAt,
  });

  factory SkillSurveyResult.fromJson(Map<String, dynamic> json) {
    return SkillSurveyResult(
      submissionId: json['submission_id'] as int,
      studentId: json['student_id'] as int,
      courseId: json['course_id'] as int,
      surveyDate: DateTime.parse(json['survey_date'] as String),
      surveySlug: json['survey_slug'] as String,
      surveyName: json['survey_name'] as String,
      ageGroup: json['age_group'] as String,
      formVersion: json['form_version'] as int,
      correctAnswers: json['correct_answers'] as int,
      totalQuestions: json['total_questions'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
