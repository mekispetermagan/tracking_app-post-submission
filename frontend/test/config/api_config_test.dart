import 'package:agu_frontend/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('API base URL selection', () {
    test('defaults debug builds to localhost', () {
      expect(
        ApiConfig.selectBaseUrl(isRelease: false),
        ApiConfig.developmentBaseUrl,
      );
    });

    test('defaults release builds to the production HTTPS server', () {
      expect(
        ApiConfig.selectBaseUrl(isRelease: true),
        ApiConfig.productionBaseUrl,
      );
    });

    test('accepts an explicit HTTPS release server and removes one slash', () {
      expect(
        ApiConfig.selectBaseUrl(
          isRelease: true,
          configuredBaseUrl: ' https://demo-tracking.mekis.dev/ ',
        ),
        'https://demo-tracking.mekis.dev',
      );
    });

    test('rejects insecure release servers', () {
      expect(
        () => ApiConfig.selectBaseUrl(
          isRelease: true,
          configuredBaseUrl: 'http://tracking.mekis.dev',
        ),
        throwsArgumentError,
      );
    });

    test('rejects credentials, queries, fragments, and malformed URLs', () {
      for (final value in [
        'tracking.mekis.dev',
        'https://user@tracking.mekis.dev',
        'https://tracking.mekis.dev?debug=true',
        'https://tracking.mekis.dev#debug',
      ]) {
        expect(
          () => ApiConfig.selectBaseUrl(
            isRelease: false,
            configuredBaseUrl: value,
          ),
          throwsArgumentError,
          reason: value,
        );
      }
    });
  });

  test('resolves relative media paths and preserves absolute URLs', () {
    expect(
      ApiConfig.resolveApiUrl('/compressed_photos/example.jpg'),
      '${ApiConfig.baseUrl}/compressed_photos/example.jpg',
    );
    expect(
      ApiConfig.resolveApiUrl('compressed_photos/example.jpg?size=small'),
      '${ApiConfig.baseUrl}/compressed_photos/example.jpg?size=small',
    );
    expect(
      ApiConfig.resolveApiUrl('https://cdn.example.org/example.jpg'),
      'https://cdn.example.org/example.jpg',
    );
  });
}
