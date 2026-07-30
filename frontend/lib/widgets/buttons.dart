import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LargeFilledButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final double fontSize;
  final VoidCallback? onPressed;
  final Icon? icon;
  const LargeFilledButton({
    this.text,
    this.child,
    this.fontSize = 18,
    this.icon,
    this.onPressed,
    super.key,
  }) : assert(text != null || child != null);

  @override
  Widget build(BuildContext context) {
    final label = Padding(
      padding: const EdgeInsets.all(6),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        child: child ?? Text(text!),
      ),
    );

    return icon == null
        ? FilledButton(onPressed: onPressed, child: label)
        : FilledButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}

class AppBarIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  const AppBarIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 30,
      color: Theme.of(context).colorScheme.primary,
      tooltip: tooltip,
    );
  }
}

abstract final class BuildWeekDemo {
  static const webUrl = "https://mekis.dev/tracking/";
  static const mentorPhone = "0123456789";
  static const mentorPin = "123456";
  static const adminPhone = "0987654321";
  static const adminPassword = "Judge123";
}

class BuildWeekInfoButton extends StatelessWidget {
  const BuildWeekInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showBuildWeekInfo(context),
      icon: const Icon(Icons.info_outline),
      label: const Text("Build Week info"),
    );
  }
}

Future<void> showBuildWeekInfo(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Build Week demo"),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "All names, phone numbers, and records in this demo are fictional.",
            ),
            SizedBox(height: 20),
            _CopyableValue(label: "Web app", value: BuildWeekDemo.webUrl),
            SizedBox(height: 20),
            Text(
              "Mentor account",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _CopyableValue(label: "Phone", value: BuildWeekDemo.mentorPhone),
            _CopyableValue(label: "PIN", value: BuildWeekDemo.mentorPin),
            SizedBox(height: 20),
            Text(
              "Administrator account",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _CopyableValue(label: "Phone", value: BuildWeekDemo.adminPhone),
            _CopyableValue(
              label: "Password",
              value: BuildWeekDemo.adminPassword,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}

class _CopyableValue extends StatelessWidget {
  final String label;
  final String value;

  const _CopyableValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SelectableText([label, value].join(": "))),
        IconButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text([label, "copied"].join(" "))),
              );
          },
          icon: const Icon(Icons.copy),
          tooltip: ["Copy", label].join(" "),
        ),
      ],
    );
  }
}
