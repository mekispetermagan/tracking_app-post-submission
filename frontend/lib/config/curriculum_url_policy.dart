abstract final class CurriculumUrlPolicy {
  static const host = 'curriculum.afterschool-geekery.org';

  static Uri? trustedUri(String? value) {
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    return uri != null && isTrusted(uri) ? uri : null;
  }

  static bool isTrusted(Uri uri) {
    return uri.scheme == 'https' &&
        uri.host == host &&
        uri.userInfo.isEmpty &&
        (!uri.hasPort || uri.port == 443);
  }

  static bool isAboutBlank(Uri uri) {
    return uri.scheme == 'about' &&
        uri.path == 'blank' &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty;
  }

  static bool isSafeExternal(Uri uri) {
    return uri.scheme == 'https' &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }
}
