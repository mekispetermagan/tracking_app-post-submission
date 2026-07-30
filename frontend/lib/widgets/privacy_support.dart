import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class PrivacySupportLinks {
  static final privacyPolicy = Uri.parse(
    'https://afterschool-geekery.org/privacy/',
  );
  static final support = Uri(
    scheme: 'mailto',
    path: 'mekis.peter@gmail.com',
    queryParameters: {'subject': 'Afterschool Geekery Uganda support'},
  );
  static final dataRequest = Uri(
    scheme: 'mailto',
    path: 'mekis.peter@gmail.com',
    queryParameters: {
      'subject': 'Afterschool Geekery Uganda account or data request',
    },
  );
}

class PrivacySupportButton extends StatelessWidget {
  const PrivacySupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => showPrivacySupport(context),
      icon: const Icon(Icons.privacy_tip_outlined),
      label: const Text('Privacy & support'),
    );
  }
}

Future<void> showPrivacySupport(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _PrivacySupportDialog(),
  );
}

class _PrivacySupportDialog extends StatefulWidget {
  const _PrivacySupportDialog();

  @override
  State<_PrivacySupportDialog> createState() => _PrivacySupportDialogState();
}

class _PrivacySupportDialogState extends State<_PrivacySupportDialog> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Privacy & support'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Privacy information and support for '
              'Afterschool Geekery Uganda.',
            ),
            const SizedBox(height: 12),
            _LinkTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy policy',
              subtitle: 'Read how information is handled',
              uri: PrivacySupportLinks.privacyPolicy,
            ),
            _LinkTile(
              icon: Icons.person_remove_outlined,
              title: 'Request account or data deletion',
              subtitle: 'Email a deletion or data request',
              uri: PrivacySupportLinks.dataRequest,
            ),
            _LinkTile(
              icon: Icons.email_outlined,
              title: 'Contact support',
              subtitle: 'mekis.peter@gmail.com',
              uri: PrivacySupportLinks.support,
            ),
            const SizedBox(height: 12),
            FutureBuilder<PackageInfo>(
              future: _packageInfo,
              builder: (context, snapshot) {
                final info = snapshot.data;
                if (info == null) {
                  return const Text('Version unavailable');
                }

                return Text(
                  'Version ${info.version} (${info.buildNumber})',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Uri uri;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.uri,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new),
      onTap: () => _openUri(context),
    );
  }

  Future<void> _openUri(BuildContext context) async {
    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Could not open link.')));
  }
}
