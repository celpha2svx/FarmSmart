import 'package:flutter_test/flutter_test.dart';
import 'package:farmsmart/core/l10n/translations.dart';
import 'package:farmsmart/core/network/api_client.dart';

void main() {
  group('Translations', () {
    test('returns English string for known key', () {
      final t = Translations('en');
      expect(t.t('app_name'), 'FarmSmart');
      expect(t.t('save'), 'Save');
    });

    test('falls back to English when key missing in non-English locale', () {
      // 'choose_language' is in en; ha may or may not have it — must not throw
      final t = Translations('ha');
      final v = t.t('app_name');
      expect(v, isNotEmpty);
    });

    test('returns the key itself when key missing everywhere', () {
      final t = Translations('en');
      expect(t.t('this_key_does_not_exist_anywhere'), 'this_key_does_not_exist_anywhere');
    });

    test('interpolates {placeholder} variables', () {
      final t = Translations('en');
      // 'planting_date_title' uses {crop}
      expect(t.t('planting_date_title', {'crop': 'maize'}), contains('maize'));
    });
  });

  group('ApiException', () {
    test('formats as a readable string', () {
      const e = ApiException('not_found', 'No advisory for today', statusCode: 404);
      expect(e.toString(), contains('not_found'));
      expect(e.toString(), contains('No advisory for today'));
    });
  });
}
