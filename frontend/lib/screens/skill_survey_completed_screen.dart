import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/app_bar.dart';
import '../widgets/buttons.dart';

class SkillSurveyCompletedScreen extends StatelessWidget {
  const SkillSurveyCompletedScreen({
    required this.result,
    required this.onDone,
    super.key,
  });
  final SkillSurveyResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppTopBar(title: Text('Survey completed')),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 80),
              const SizedBox(height: 16),
              Text(
                '${result.surveyName} completed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${result.correctAnswers} of ${result.totalQuestions} correct',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              LargeActionButton(onPressed: onDone, text: 'Back to surveys'),
            ],
          ),
        ),
      ),
    ),
  );
}
