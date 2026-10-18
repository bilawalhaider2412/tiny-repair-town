import 'package:test/test.dart';
import 'package:tiny_repair_town/core/localization.dart';

void main() {
  group('Localization', () {
    test('sample strings from spec section 13', () {
      expect(tr('letsPlay', 'en'), 'Let\'s play');
      expect(tr('letsPlay', 'ur'), 'آؤ کھیلیں');
      expect(tr('choosePiece', 'ur'), 'ایک ٹکڑا چنیں');
      expect(tr('tryAgain', 'ur'), 'دوبارہ کوشش کریں');
      expect(tr('wellDone', 'ur'), 'شاباش!');
      expect(tr('needHint', 'ur'), 'اشارہ چاہیے؟');
      expect(tr('forParents', 'ur'), 'والدین کے لیے');
      expect(tr('backToTown', 'ur'), 'شہر میں واپس جائیں');
    });

    test('Urdu is RTL, English is LTR', () {
      expect(isRtl('ur'), isTrue);
      expect(isRtl('en'), isFalse);
    });

    test('fallback to English, then to key', () {
      expect(tr('wellDone', 'fr'), 'Well done!'); // unknown lang -> en
      expect(tr('nonexistent_key', 'en'), 'nonexistent_key');
      expect(tr('nonexistent_key', 'ur'), 'nonexistent_key');
    });

    test('every key has both en and ur', () {
      for (final entry in AppStrings.values.entries) {
        expect(entry.value.containsKey('en'), isTrue, reason: entry.key);
        expect(entry.value.containsKey('ur'), isTrue, reason: entry.key);
        expect(entry.value['en'], isNotEmpty, reason: entry.key);
        expect(entry.value['ur'], isNotEmpty, reason: entry.key);
      }
    });

    test('gameplay strings present', () {
      for (final key in ['thatFits', 'tryAnotherPiece', 'choosePiece', 'needHint', 'moreInParents', 'dragOrTap']) {
        expect(tr(key, 'en'), isNotEmpty);
        expect(tr(key, 'ur'), isNotEmpty);
      }
    });
  });
}
