import 'package:agu_frontend/models/models.dart';
import 'package:agu_frontend/screens/curriculum_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rejects an untrusted chapter URL before creating a WebView', (
    tester,
  ) async {
    const chapter = CurriculumChapter(
      slug: 'motors',
      titles: {'eng': 'Motors'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumScreen(
          categories: const [],
          selectedChapter: chapter,
          selectedChapterUrl:
              'http://curriculum.afterschool-geekery.org/chapter.html',
          isLoading: false,
          message: null,
          clearMessage: () {},
          onReload: () async {},
          onSelectChapter: (_) {},
          onCloseChapter: () {},
          onBack: () {},
        ),
      ),
    );

    expect(find.text('Invalid chapter URL.'), findsOneWidget);
  });
}
