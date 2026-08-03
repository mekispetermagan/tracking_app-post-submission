import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/skill_survey_theme.dart';
import '../widgets/app_bar.dart';

class SkillSurveyQuestionScreen extends StatelessWidget {
  const SkillSurveyQuestionScreen({
    required this.form,
    required this.question,
    required this.questionIndex,
    required this.questionCount,
    required this.illustrationAsset,
    required this.isSubmitting,
    required this.message,
    required this.clearMessage,
    required this.onSelectOption,
    required this.onBack,
    super.key,
  });

  final SkillSurveyForm form;
  final SkillSurveyQuestion question;
  final int questionIndex;
  final int questionCount;
  final String illustrationAsset;
  final bool isSubmitting;
  final String? message;
  final VoidCallback clearMessage;
  final Future<void> Function(int questionId, int option) onSelectOption;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    _showMessage(context);
    return Scaffold(
      appBar: AppTopBar(
        title: Text('${form.surveyName}: ${questionIndex + 1}/$questionCount'),
        onBack: onBack,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LinearProgressIndicator(value: (questionIndex + 1) / questionCount),
            const SizedBox(height: 20),
            Text(
              question.prompt,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: Image.asset(illustrationAsset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Row(
              children: question.options
                  .map(
                    (option) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilledButton(
                          onPressed: isSubmitting
                              ? null
                              : () => onSelectOption(question.id, option),
                          style: _optionStyle(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              String.fromCharCode(64 + option),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _optionStyle(int option) {
    final color = skillSurveyOptionColors[option]!;
    final foregroundColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: color.withValues(alpha: 0.55),
      disabledForegroundColor: foregroundColor.withValues(alpha: 0.7),
      elevation: 2,
    );
  }

  void _showMessage(BuildContext context) {
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message!)));
      clearMessage();
    });
  }
}
