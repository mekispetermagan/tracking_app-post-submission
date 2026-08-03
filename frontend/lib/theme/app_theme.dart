import 'package:flutter/material.dart';

const mentorSeedColor = Colors.green;
const adminSeedColor = Colors.teal;
const startSeedColor = mentorSeedColor;

ColorScheme buildStartColorScheme() {
  return ColorScheme.fromSeed(
    seedColor: startSeedColor,
    brightness: Brightness.dark,
  );
}

ColorScheme buildMentorColorScheme({Brightness brightness = Brightness.dark}) {
  return ColorScheme.fromSeed(
    seedColor: mentorSeedColor,
    brightness: brightness,
  );
}

ColorScheme buildAdminColorScheme({Brightness brightness = Brightness.light}) {
  return ColorScheme.fromSeed(
    seedColor: adminSeedColor,
    brightness: brightness,
  );
}

ThemeData buildStartTheme() => buildAppTheme(buildStartColorScheme());

ThemeData buildMentorTheme({Brightness brightness = Brightness.dark}) =>
    buildAppTheme(buildMentorColorScheme(brightness: brightness));

ThemeData buildAdminTheme({Brightness brightness = Brightness.light}) =>
    buildAppTheme(buildAdminColorScheme(brightness: brightness));

ThemeData buildAppTheme(ColorScheme colorScheme) {
  final baseTheme = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    fontFamily: 'Nunito',
  );
  final textTheme = baseTheme.textTheme;

  TextStyle? headingStyle(TextStyle? style) {
    return style?.copyWith(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.w600,
    );
  }

  return baseTheme.copyWith(
    textTheme: textTheme.copyWith(
      displayLarge: headingStyle(textTheme.displayLarge),
      displayMedium: headingStyle(textTheme.displayMedium),
      displaySmall: headingStyle(textTheme.displaySmall),
      headlineLarge: headingStyle(textTheme.headlineLarge),
      headlineMedium: headingStyle(textTheme.headlineMedium),
      headlineSmall: headingStyle(textTheme.headlineSmall),
      titleLarge: headingStyle(textTheme.titleLarge),
    ),
  );
}
