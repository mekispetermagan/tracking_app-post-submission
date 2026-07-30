import 'package:agu_frontend/config/curriculum_url_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('trusted curriculum URLs', () {
    test('accepts only the exact HTTPS curriculum origin', () {
      final uri = Uri.parse(
        'https://curriculum.afterschool-geekery.org/chapter.html?chapter=motors',
      );

      expect(CurriculumUrlPolicy.isTrusted(uri), isTrue);
      expect(CurriculumUrlPolicy.trustedUri(uri.toString()), uri);
      expect(
        CurriculumUrlPolicy.isTrusted(
          Uri.parse(
            'https://curriculum.afterschool-geekery.org:443/chapter.html',
          ),
        ),
        isTrue,
      );
    });

    test('rejects HTTP, lookalike hosts, credentials, and other ports', () {
      for (final value in [
        'http://curriculum.afterschool-geekery.org/chapter.html',
        'https://curriculum.afterschool-geekery.org.evil.test/chapter.html',
        'https://user@curriculum.afterschool-geekery.org/chapter.html',
        'https://curriculum.afterschool-geekery.org:444/chapter.html',
      ]) {
        expect(CurriculumUrlPolicy.trustedUri(value), isNull, reason: value);
      }
    });
  });

  test('allows only HTTPS links to leave the curriculum WebView', () {
    expect(
      CurriculumUrlPolicy.isSafeExternal(
        Uri.parse('https://www.youtube.com/watch?v=example'),
      ),
      isTrue,
    );
    expect(
      CurriculumUrlPolicy.isSafeExternal(Uri.parse('http://example.org')),
      isFalse,
    );
    expect(
      CurriculumUrlPolicy.isSafeExternal(Uri.parse('javascript:alert(1)')),
      isFalse,
    );
    expect(
      CurriculumUrlPolicy.isSafeExternal(Uri.parse('intent://example.org')),
      isFalse,
    );
  });

  test('recognizes only the plain about:blank document', () {
    expect(CurriculumUrlPolicy.isAboutBlank(Uri.parse('about:blank')), isTrue);
    expect(
      CurriculumUrlPolicy.isAboutBlank(Uri.parse('about:blank#payload')),
      isFalse,
    );
  });
}
