import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/app_bar.dart';
import '../widgets/buttons.dart';

class SkillSurveyMenuScreen extends StatelessWidget {
  const SkillSurveyMenuScreen({
    required this.student,
    required this.course,
    required this.forms,
    required this.completedToday,
    required this.latestResult,
    required this.onSelect,
    required this.onBack,
    required this.onLogout,
    super.key,
  });

  final Student student;
  final Course course;
  final List<SkillSurveyForm> forms;
  final bool Function(SkillSurveyForm) completedToday;
  final SkillSurveyResult? Function(SkillSurveyForm) latestResult;
  final ValueChanged<SkillSurveyForm> onSelect;
  final VoidCallback onBack;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: const Text('Choose survey'),
        onBack: onBack,
        onLogout: onLogout,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              student.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(course.name),
            const SizedBox(height: 24),
            if (forms.isEmpty)
              const Text('No surveys are available.')
            else
              ...forms.map((form) {
                final completed = completedToday(form);
                final latest = latestResult(form);
                final status = completed
                    ? 'Completed today · ${latest!.correctAnswers}/${latest.totalQuestions}'
                    : latest == null
                    ? 'Not taken yet'
                    : 'Latest: ${latest.correctAnswers}/${latest.totalQuestions}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: LargeActionButton(
                    onPressed: completed ? null : () => onSelect(form),
                    child: Column(
                      children: [
                        Text(form.surveyName),
                        const SizedBox(height: 4),
                        Text(
                          status,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
