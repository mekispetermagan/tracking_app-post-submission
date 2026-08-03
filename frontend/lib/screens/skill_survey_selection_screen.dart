import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/app_bar.dart';
import '../widgets/buttons.dart';

class SkillSurveySelectionScreen extends StatelessWidget {
  const SkillSurveySelectionScreen({
    required this.students,
    required this.courses,
    required this.selectedStudentId,
    required this.selectedCourseId,
    required this.isLoading,
    required this.canContinue,
    required this.message,
    required this.clearMessage,
    required this.onSelectStudent,
    required this.onSelectCourse,
    required this.onContinue,
    required this.onHome,
    required this.onLogout,
    super.key,
  });

  final List<Student> students;
  final List<Course> courses;
  final int? selectedStudentId;
  final int? selectedCourseId;
  final bool isLoading;
  final bool canContinue;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<int> onSelectStudent;
  final ValueChanged<int?> onSelectCourse;
  final VoidCallback onContinue;
  final VoidCallback onHome;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    _showMessage(context);
    return Scaffold(
      appBar: AppTopBar(
        title: const Text('Skill surveys'),
        onHome: onHome,
        onLogout: onLogout,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : students.isEmpty
            ? const Center(child: Text('No students available.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Select a student',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...students.map(
                    (student) => Card(
                      clipBehavior: Clip.antiAlias,
                      child: RadioGroup<int>(
                        groupValue: selectedStudentId,
                        onChanged: (value) {
                          if (value != null) onSelectStudent(value);
                        },
                        child: RadioListTile<int>(
                          value: student.id,
                          title: Text(student.fullName),
                        ),
                      ),
                    ),
                  ),
                  if (selectedStudentId != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Course',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (courses.isEmpty)
                      const Text(
                        'This student is not assigned to an available course.',
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue: selectedCourseId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select course'),
                        items: courses
                            .map(
                              (course) => DropdownMenuItem(
                                value: course.id,
                                child: Text(course.name),
                              ),
                            )
                            .toList(),
                        onChanged: onSelectCourse,
                      ),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LargeActionButton(
            onPressed: canContinue ? onContinue : null,
            icon: const Icon(Icons.arrow_forward),
            text: 'Choose survey',
          ),
        ),
      ),
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
