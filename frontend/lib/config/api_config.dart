import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String developmentBaseUrl = 'http://127.0.0.1:8000';
  static const String productionBaseUrl = 'https://tracking.mekis.dev';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl => selectBaseUrl(
    isRelease: kReleaseMode,
    configuredBaseUrl: _configuredBaseUrl,
  );

  @visibleForTesting
  static String selectBaseUrl({
    required bool isRelease,
    String configuredBaseUrl = '',
  }) {
    final configured = configuredBaseUrl.trim();
    final selected = configured.isNotEmpty
        ? configured
        : isRelease
        ? productionBaseUrl
        : developmentBaseUrl;
    final uri = Uri.tryParse(selected);

    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw ArgumentError.value(selected, 'API_BASE_URL', 'Invalid URL');
    }
    if (uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw ArgumentError.value(
        selected,
        'API_BASE_URL',
        'Must not contain credentials, a query, or a fragment',
      );
    }
    if (isRelease && uri.scheme != 'https') {
      throw ArgumentError.value(
        selected,
        'API_BASE_URL',
        'Release builds require HTTPS',
      );
    }

    return selected.endsWith('/')
        ? selected.substring(0, selected.length - 1)
        : selected;
  }

  static String resolveApiUrl(String value) {
    final uri = Uri.parse(value);
    if (uri.isAbsolute || uri.hasAuthority) return value;

    return Uri.parse('$baseUrl/').resolveUri(uri).toString();
  }
}
