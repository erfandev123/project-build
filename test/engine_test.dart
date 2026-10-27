import 'package:flutter_test/flutter_test.dart';

import 'package:borno_keyboard/engine/phonetic_engine.dart';

void main() {
  group('Bangla phonetic engine', () {
    test('converts common Banglish words from the offline word bank', () {
      expect(BanglaPhonetic.convertWord('ami'), 'আমি');
      expect(BanglaPhonetic.convertWord('kemon'), 'কেমন');
      expect(BanglaPhonetic.convertWord('dhonnobad'), 'ধন্যবাদ');
      expect(BanglaPhonetic.convertWord('bhalobasha'), 'ভালোবাসা');
      expect(BanglaPhonetic.convertWord('oneek'), 'অনেক');
    });

    test('keeps spaces and punctuation while converting a sentence', () {
      expect(BanglaPhonetic.convert('ami bhalo achhi.'), 'আমি ভালো আছি.');
    });

    test('falls back to deterministic syllable transliteration', () {
      final result = BanglaPhonetic.convertWord('kkh');
      expect(result, 'ক্ষ');
      final sentence = BanglaPhonetic.convert('borno likhi');
      expect(RegExp(r'[\u0980-\u09FF]').hasMatch(sentence), isTrue);
    });

    test('leaves existing Bangla text untouched', () {
      expect(BanglaPhonetic.convertWord('বাংলা'), 'বাংলা');
    });

    test('provides ranked suggestions for a partial word', () {
      final suggestions = WordBank.suggestions(
        roman: 'bhal',
        banglaWord: '',
        english: false,
      );
      expect(suggestions, isNotEmpty);
      expect(suggestions.first, 'ভালো');

      final locationSuggestions = WordBank.suggestions(
        roman: 'ekh',
        banglaWord: '',
        english: false,
      );
      expect(locationSuggestions, contains('এখানে'));
    });

    test('returns English defaults when no query is present', () {
      final suggestions = WordBank.suggestions(
        roman: '',
        banglaWord: '',
        english: true,
      );
      expect(suggestions, contains('I'));
      expect(suggestions.length, lessThanOrEqualTo(3));
    });
  });
}
