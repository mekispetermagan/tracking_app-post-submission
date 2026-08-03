import 'package:flutter/material.dart';

import '../help/help_scope.dart';
import '../theme/theme_toggle_scope.dart';
import 'buttons.dart';
import 'privacy_support.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final VoidCallback? onHome;
  final VoidCallback? onBack;
  final bool showBack;
  final VoidCallback? onLogout;
  final String? helpText;
  final bool showPrivacySupportAction;
  final List<Widget> actions;

  const AppTopBar({
    required this.title,
    this.onHome,
    this.onBack,
    this.showBack = false,
    this.onLogout,
    this.helpText,
    this.showPrivacySupportAction = false,
    this.actions = const [],
    super.key,
  }) : assert(
         onHome == null || (!showBack && onBack == null),
         'An app bar cannot show both Home and Back as its leading action.',
       );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final effectiveHelpText = helpText ?? HelpScope.maybeTextOf(context);
    final themeToggle = ThemeToggleScope.maybeOf(context);
    final hasOverflowMenu =
        showPrivacySupportAction ||
        effectiveHelpText != null ||
        themeToggle != null ||
        onLogout != null;

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            'assets/images/ag_uganda_logo_no_text_small.png',
            height: 28,
          ),
          const SizedBox(width: 12),
          Expanded(child: title),
        ],
      ),
      leading: onHome != null
          ? AppBarIconButton(
              onPressed: onHome!,
              icon: Icons.home,
              tooltip: 'Home',
            )
          : showBack || onBack != null
          ? BackButton(onPressed: onBack)
          : null,
      actions: [
        ...actions,
        if (hasOverflowMenu)
          PopupMenuButton<_AppBarMenuAction>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleMenuAction(
              context,
              action,
              effectiveHelpText,
              themeToggle,
            ),
            itemBuilder: (context) => [
              if (themeToggle != null)
                PopupMenuItem(
                  value: _AppBarMenuAction.toggleTheme,
                  child: _MenuItem(
                    icon: themeToggle.isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    label: themeToggle.isDark
                        ? 'Switch to light mode'
                        : 'Switch to dark mode',
                  ),
                ),
              if (effectiveHelpText != null)
                const PopupMenuItem(
                  value: _AppBarMenuAction.help,
                  child: _MenuItem(icon: Icons.help_outline, label: 'Help'),
                ),
              if (showPrivacySupportAction)
                const PopupMenuItem(
                  value: _AppBarMenuAction.privacySupport,
                  child: _MenuItem(
                    icon: Icons.info_outline,
                    label: 'Privacy & support',
                  ),
                ),
              if (onLogout != null)
                const PopupMenuItem(
                  value: _AppBarMenuAction.logout,
                  child: _MenuItem(icon: Icons.logout, label: 'Log out'),
                ),
            ],
          ),
      ],
    );
  }

  void _handleMenuAction(
    BuildContext context,
    _AppBarMenuAction action,
    String? effectiveHelpText,
    ThemeToggleScope? themeToggle,
  ) {
    switch (action) {
      case _AppBarMenuAction.toggleTheme:
        themeToggle?.onToggle();
      case _AppBarMenuAction.help:
        if (effectiveHelpText != null) _showHelp(context, effectiveHelpText);
      case _AppBarMenuAction.privacySupport:
        showPrivacySupport(context);
      case _AppBarMenuAction.logout:
        onLogout?.call();
    }
  }

  Future<void> _showHelp(BuildContext context, String text) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

enum _AppBarMenuAction { toggleTheme, help, privacySupport, logout }

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    );
  }
}
