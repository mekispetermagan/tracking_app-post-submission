import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:agu_frontend/help/help_scope.dart';
import 'package:agu_frontend/theme/theme_toggle_scope.dart';
import 'package:agu_frontend/widgets/app_bar.dart';

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Afterschool Geekery Uganda',
      packageName: 'org.afterschoolgeekery.agu',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('uses branded title, Home, and an overflow menu for Logout', (
    tester,
  ) async {
    var homePressed = false;
    var logoutPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppTopBar(
            title: const Text('Area'),
            onHome: () => homePressed = true,
            onLogout: () => logoutPressed = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byTooltip('More options'), findsOneWidget);
    final logo = tester.widget<Image>(find.byType(Image));
    expect(
      (logo.image as AssetImage).assetName,
      'assets/images/ag_uganda_logo_no_text_small.png',
    );
    expect(find.text('Area'), findsOneWidget);

    await tester.tap(find.byTooltip('Home'));
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));

    expect(homePressed, isTrue);
    expect(logoutPressed, isTrue);
  });

  testWidgets('opens privacy and support from an app-bar action', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AppTopBar(
            title: Text('Area'),
            showPrivacySupportAction: true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy & support'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Version 0.1.0 (1)'), findsOneWidget);
  });

  testWidgets('uses a back button for the Back role', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppTopBar(title: const Text('Detail'), onBack: () {}),
        ),
      ),
    );

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byIcon(Icons.home), findsNothing);
    expect(find.byTooltip('More options'), findsNothing);
  });

  testWidgets('can show a disabled back button explicitly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AppTopBar(title: Text('Saving'), showBack: true),
        ),
      ),
    );

    expect(
      tester.widget<BackButton>(find.byType(BackButton)).onPressed,
      isNull,
    );
  });
  testWidgets('shows explicit help text in a dismissible modal', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AppTopBar(
            title: Text('Feature'),
            helpText: 'Feature guidance.',
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Feature guidance.'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('reads help from the nearest scope and omits it without one', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HelpScope(
          text: 'Scoped guidance.',
          child: Scaffold(appBar: AppTopBar(title: Text('Scoped'))),
        ),
      ),
    );

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    expect(find.text('Scoped guidance.'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: AppTopBar(title: Text('No help'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('More options'), findsNothing);
  });

  testWidgets('offers the opposite brightness through the overflow menu', (
    tester,
  ) async {
    var toggles = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ThemeToggleScope(
          isDark: true,
          onToggle: () async => toggles++,
          child: const Scaffold(appBar: AppTopBar(title: Text('Area'))),
        ),
      ),
    );

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    expect(find.text('Switch to light mode'), findsOneWidget);
    await tester.tap(find.text('Switch to light mode'));
    await tester.pumpAndSettle();
    expect(toggles, 1);
  });
}
