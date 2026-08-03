import 'package:flutter/widgets.dart';

class ThemeToggleScope extends InheritedWidget {
  const ThemeToggleScope({
    required this.isDark,
    required this.onToggle,
    required super.child,
    super.key,
  });

  final bool isDark;
  final Future<void> Function() onToggle;

  static ThemeToggleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeToggleScope>();
  }

  @override
  bool updateShouldNotify(ThemeToggleScope oldWidget) {
    return isDark != oldWidget.isDark || onToggle != oldWidget.onToggle;
  }
}
