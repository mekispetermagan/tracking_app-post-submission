import 'package:agu_frontend/models/models.dart';
import 'package:agu_frontend/widgets/student_record_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _record = StudentRecord(
  studentId: 1,
  firstName: 'Dorian',
  lastName: 'Nakalema',
  attendedSessions: 2,
  overallActivityScore: 1,
  projectGroups: [],
  skillGames: [],
);

Widget _app(List<SkillSurveyResult> results) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: StudentRecordViewer(
          studentRecord: _record,
          skillSurveyResults: results,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows an empty survey result message', (tester) async {
    await tester.pumpWidget(_app(const []));

    expect(find.text('Skill surveys'), findsOneWidget);
    expect(find.text('No survey results yet.'), findsOneWidget);
  });

  testWidgets('shows survey name, date, and correct/total counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app([
        SkillSurveyResult(
          submissionId: 1,
          studentId: 1,
          courseId: 2,
          surveyDate: DateTime(2026, 8, 3),
          surveySlug: 'math',
          surveyName: 'Math',
          ageGroup: 'under_12',
          formVersion: 1,
          correctAnswers: 16,
          totalQuestions: 20,
          createdAt: DateTime(2026, 8, 3),
        ),
      ]),
    );

    expect(find.text('Math'), findsOneWidget);
    expect(find.text('03-08-2026'), findsOneWidget);
    expect(find.text('16/20'), findsOneWidget);
    expect(find.text('No survey results yet.'), findsNothing);
  });
}
