/// Borno's offline Bangla phonetic engine.
///
/// It follows the familiar Avro/Ridmik style of typing Bangla with English
/// letters. Common words are handled by a curated dictionary; everything else
/// goes through a fast, deterministic syllable converter.
library;

class _Vowel {
  const _Vowel(this.standalone, this.sign);

  final String standalone;
  final String sign;
}

class _Token {
  const _Token(this.text, this.kind, [this.vowel]);

  final String text;
  final _TokenKind kind;
  final _Vowel? vowel;
}

enum _TokenKind { consonant, vowel, sign, inherentO, finalO }

class BanglaPhonetic {
  BanglaPhonetic._();

  static final RegExp _letterRun = RegExp(r'[A-Za-z]+');
  static final Map<String, _Token> _tokens = _buildTokens();
  static final List<String> _tokenOrder = _tokens.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  /// Converts a full line while preserving spaces and punctuation.
  static String convert(String text) {
    if (text.isEmpty) return text;
    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in _letterRun.allMatches(text)) {
      if (match.start > cursor) {
        buffer.write(text.substring(cursor, match.start));
      }
      buffer.write(convertWord(match.group(0)!));
      cursor = match.end;
    }
    if (cursor < text.length) buffer.write(text.substring(cursor));
    return buffer.toString();
  }

  /// Converts one romanised word. Already-Bangla text is returned untouched.
  static String convertWord(String word) {
    if (word.isEmpty) return '';

    final known = WordBank.phonetic[word.toLowerCase()];
    if (known != null) return known;

    // If the user is already writing Bangla, do not touch the word.
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(word)) return word;

    final lower = word.toLowerCase();
    if (lower != word) {
      final lowerKnown = WordBank.phonetic[lower];
      if (lowerKnown != null) return lowerKnown;
    }

    final output = StringBuffer();
    var previousWasConsonant = false;
    var index = 0;

    while (index < word.length) {
      _Token? matched;
      for (final token in _tokenOrder) {
        if (word.startsWith(token, index)) {
          matched = _tokens[token];
          break;
        }
      }

      if (matched == null) {
        output.write(word[index]);
        previousWasConsonant = false;
        index++;
        continue;
      }

      final atEnd = index + matched.text.length >= word.length;

      switch (matched.kind) {
        case _TokenKind.consonant:
          output.write(matched.text);
          previousWasConsonant = true;
          break;
        case _TokenKind.vowel:
          final vowel = matched.vowel!;
          if (previousWasConsonant) {
            output.write(vowel.sign);
          } else {
            output.write(vowel.standalone);
          }
          previousWasConsonant = false;
          break;
        case _TokenKind.inherentO:
          if (previousWasConsonant && atEnd) {
            output.write('ো');
          }
          // In the middle of a word "o" is the inherent vowel: no glyph.
          previousWasConsonant = false;
          break;
        case _TokenKind.finalO:
          if (previousWasConsonant) {
            output.write('ো');
          } else {
            output.write('ও');
          }
          previousWasConsonant = false;
          break;
        case _TokenKind.sign:
          output.write(matched.text);
          previousWasConsonant = false;
          break;
      }

      index += matched.text.length;
    }

    return output.toString();
  }

  static Map<String, _Token> _buildTokens() {
    const vowels = <String, _Vowel>{
      'aa': _Vowel('আ', 'া'),
      'ii': _Vowel('ঈ', 'ী'),
      'uu': _Vowel('ঊ', 'ূ'),
      'rri': _Vowel('ঋ', 'ৃ'),
      'oi': _Vowel('ঐ', 'ৈ'),
      'OI': _Vowel('ঐ', 'ৈ'),
      'ou': _Vowel('ঔ', 'ৌ'),
      'OU': _Vowel('ঔ', 'ৌ'),
      'a': _Vowel('আ', 'া'),
      'A': _Vowel('আ', 'া'),
      'i': _Vowel('ই', 'ি'),
      'I': _Vowel('ঈ', 'ী'),
      'u': _Vowel('উ', 'ু'),
      'U': _Vowel('ঊ', 'ূ'),
      'e': _Vowel('এ', 'ে'),
      'E': _Vowel('এ', 'ে'),
      'O': _Vowel('ও', 'ো'),
    };

    const consonants = <String, String>{
      // Conjuncts that need an explicit hasanta.
      'kkh': 'ক্ষ',
      'ksh': 'ক্ষ',
      'str': 'স্ত্র',
      'ndh': 'ন্ধ',
      'shr': 'শ্র',
      'gy': 'জ্ঞ',
      'nd': 'ন্দ',
      'nt': 'ন্ত',
      'mp': 'ম্প',
      'mb': 'ম্ব',
      'kk': 'ক্ক',
      'tt': 'ত্ত',
      'll': 'ল্ল',
      'nn': 'ন্ন',
      'mm': 'ম্ম',
      'pp': 'প্প',
      'bb': 'ব্ব',
      'ss': 'স্স',
      'st': 'স্ত',
      'sk': 'স্ক',
      'sl': 'স্ল',
      'sm': 'স্ম',
      'sn': 'স্ন',
      'sp': 'স্প',
      'pr': 'প্র',
      'kr': 'ক্র',
      'tr': 'ত্র',
      'br': 'ব্র',
      'dr': 'দ্র',
      'gr': 'গ্র',
      'bhr': 'ভ্র',
      'pl': 'প্ল',
      'kl': 'ক্ল',
      'bl': 'ব্ল',
      'gl': 'গ্ল',
      'fl': 'ফ্ল',
      'x': 'ক্স',
      // Consonants.
      'kh': 'খ',
      'gh': 'ঘ',
      'chh': 'ছ',
      'ch': 'চ',
      'jh': 'ঝ',
      'NY': 'ঞ',
      'n^': 'ঞ',
      'Th': 'ঠ',
      'th': 'থ',
      'Dh': 'ঢ',
      'dh': 'ধ',
      'ph': 'ফ',
      'bh': 'ভ',
      'Sh': 'ষ',
      'sh': 'শ',
      'Rh': 'ঢ়',
      'Ng': 'ঙ',
      'k': 'ক',
      'g': 'গ',
      'c': 'চ',
      'j': 'জ',
      'T': 'ট',
      't': 'ত',
      'D': 'ড',
      'd': 'দ',
      'N': 'ণ',
      'n': 'ন',
      'p': 'প',
      'f': 'ফ',
      'b': 'ব',
      'v': 'ভ',
      'm': 'ম',
      'z': 'য',
      'Z': 'য',
      'r': 'র',
      'l': 'ল',
      'S': 'শ',
      's': 'স',
      'h': 'হ',
      'R': 'ড়',
      'y': 'য়',
      'Y': 'য়',
      'q': 'ক',
      'w': 'ৱ',
    };

    final result = <String, _Token>{};
    for (final entry in consonants.entries) {
      result[entry.key] = _Token(entry.value, _TokenKind.consonant);
    }
    for (final entry in vowels.entries) {
      result[entry.key] = _Token(entry.key, _TokenKind.vowel, entry.value);
    }
    result['ng'] = const _Token('ং', _TokenKind.sign);
    result['NG'] = const _Token('ং', _TokenKind.sign);
    result[':'] = const _Token('ঃ', _TokenKind.sign);
    result['^'] = const _Token('ঁ', _TokenKind.sign);
    result['o'] = const _Token('o', _TokenKind.inherentO);
    return result;
  }
}

/// A small, carefully ordered offline word bank. Insertion order doubles as
/// ranking for suggestions, so common words stay close to the top.
class WordBank {
  WordBank._();

  static const Map<String, String> phonetic = {
    'ami': 'আমি',
    'tumi': 'তুমি',
    'apni': 'আপনি',
    'amra': 'আমরা',
    'tara': 'তারা',
    'se': 'সে',
    'tini': 'তিনি',
    'amar': 'আমার',
    'tomar': 'তোমার',
    'apnar': 'আপনার',
    'amader': 'আমাদের',
    'tomader': 'তোমাদের',
    'tar': 'তার',
    'ki': 'কি',
    'keno': 'কেন',
    'kothay': 'কোথায়',
    'kemon': 'কেমন',
    'achen': 'আছেন',
    'acho': 'আছো',
    'achhi': 'আছি',
    'achhe': 'আছে',
    'chilo': 'ছিল',
    'hobe': 'হবে',
    'holo': 'হলো',
    'hoy': 'হয়',
    'korte': 'করতে',
    'kore': 'করে',
    'koro': 'করো',
    'korbo': 'করব',
    'koren': 'করেন',
    'korchen': 'করছেন',
    'korsi': 'করেছি',
    'bhalo': 'ভালো',
    'valo': 'ভালো',
    'bhalobasha': 'ভালোবাসা',
    'bhalobasi': 'ভালোবাসি',
    'bhalobeshe': 'ভালোবেসে',
    'dhonnobad': 'ধন্যবাদ',
    'shuvo': 'শুভ',
    'sokal': 'সকাল',
    'bikal': 'বিকেল',
    'bikale': 'বিকেলে',
    'rat': 'রাত',
    'raat': 'রাত',
    'dupur': 'দুপুর',
    'aj': 'আজ',
    'kal': 'কাল',
    'agamikal': 'আগামীকাল',
    'bangla': 'বাংলা',
    'bangladesh': 'বাংলাদেশ',
    'bhasha': 'ভাষা',
    'bornomala': 'বর্ণমালা',
    'kivabe': 'কিভাবে',
    'kibhabe': 'কীভাবে',
    'bari': 'বাড়ি',
    'basha': 'বাসা',
    'bondhu': 'বন্ধু',
    'bandhu': 'বন্ধু',
    'ma': 'মা',
    'baba': 'বাবা',
    'bhai': 'ভাই',
    'bon': 'বোন',
    'khela': 'খেলা',
    'gan': 'গান',
    'chobi': 'ছবি',
    'chhobi': 'ছবি',
    'boi': 'বই',
    'golpo': 'গল্প',
    'kaj': 'কাজ',
    'office': 'অফিস',
    'school': 'স্কুল',
    'college': 'কলেজ',
    'porasona': 'পড়াশোনা',
    'pani': 'পানি',
    'khabar': 'খাবার',
    'cha': 'চা',
    'onek': 'অনেক',
    'khub': 'খুব',
    'sundor': 'সুন্দর',
    'shundor': 'সুন্দর',
    'kotha': 'কথা',
    'proshno': 'প্রশ্ন',
    'uttor': 'উত্তর',
    'ha': 'হ্যাঁ',
    'hyan': 'হ্যাঁ',
    'na': 'না',
    'mon': 'মন',
    'jon': 'জন',
    'dhon': 'ধন',
    'kon': 'কোন',
    'choto': 'ছোট',
    'chhoto': 'ছোট',
    'boro': 'বড়',
    'ashol': 'আসল',
    'prithibi': 'পৃথিবী',
    'akash': 'আকাশ',
    'nod': 'নদী',
    'nodi': 'নদী',
    'ful': 'ফুল',
    'pakhi': 'পাখি',
    'golap': 'গোলাপ',
    'brishti': 'বৃষ্টি',
    'rod': 'রোদ',
    'shanto': 'শান্ত',
    'shanti': 'শান্তি',
    'hasho': 'হাসো',
    'hashi': 'হাসি',
    'anondo': 'আনন্দ',
    'swopno': 'স্বপ্ন',
    'shopno': 'স্বপ্ন',
    'sotti': 'সত্যি',
    'sotyi': 'সত্যি',
    'kemonachen': 'কেমন আছেন',
    'shubhosokal': 'শুভ সকাল',
    'shubhoratri': 'শুভ রাত্রি',
    'alhamdulillah': 'আলহামদুলিল্লাহ',
    'inshaallah': 'ইনশাআল্লাহ',
    'assalamualaikum': 'আসসালামু আলাইকুম',
    'salam': 'সালাম',
  };

  /// Common suggestions when the user has not started a word yet.
  static const List<String> banglaDefaults = [
    'আমি',
    'ভালোবাসা',
    'ধন্যবাদ',
    'বাংলা',
    'কেমন আছো',
    'শুভ সকাল',
    'অনেক',
  ];

  static const List<String> englishDefaults = [
    'I',
    'you',
    'love',
    'hello',
    'thanks',
    'Bangla',
  ];

  static const List<String> banglaAlphabet = [
    'অ',
    'আ',
    'ই',
    'ঈ',
    'উ',
    'ঊ',
    'ঋ',
    'এ',
    'ঐ',
    'ও',
    'ঔ',
    'ক',
    'খ',
    'গ',
    'ঘ',
    'ঙ',
    'চ',
    'ছ',
    'জ',
    'ঝ',
    'ঞ',
    'ট',
    'ঠ',
    'ড',
    'ঢ',
    'ণ',
    'ত',
    'থ',
    'দ',
    'ধ',
    'ন',
    'প',
    'ফ',
    'ব',
    'ভ',
    'ম',
    'য',
    'র',
    'ল',
    'শ',
    'ষ',
    'স',
    'হ',
    'ড়',
    'ঢ়',
    'য়',
    'ৎ',
    'ং',
    'ঃ',
    'ঁ',
    '্',
    'া',
    'ি',
    'ী',
    'ু',
    'ূ',
    'ৃ',
    'ে',
    'ৈ',
    'ো',
    'ৌ',
  ];

  static List<String> suggestions({
    required String roman,
    required String banglaWord,
    required bool english,
    int limit = 3,
  }) {
    final output = <String>[];
    final seen = <String>{};

    void add(String value) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) return;
      if (seen.add(cleaned)) output.add(cleaned);
    }

    if (english) {
      final query = banglaWord.toLowerCase();
      for (final word in englishDefaults) {
        if (query.isEmpty || word.toLowerCase().startsWith(query)) add(word);
      }
      if (query.isEmpty) {
        for (final word in englishDefaults) {
          add(word);
        }
      }
    } else {
      if (roman.isNotEmpty) {
        final query = roman.toLowerCase();
        // Dictionary completions are more useful than the raw syllable-by-
        // syllable rendering, so they come first and the fallback follows.
        for (final entry in phonetic.entries) {
          if (entry.key.startsWith(query)) add(entry.value);
          if (output.length >= limit * 3) break;
        }
        final converted = BanglaPhonetic.convertWord(roman);
        add(converted);
        if (converted.isNotEmpty) {
          for (final entry in phonetic.entries) {
            if (entry.value.startsWith(converted)) add(entry.value);
          }
        }
      } else {
        final query = banglaWord;
        if (query.isNotEmpty) {
          for (final entry in phonetic.entries) {
            if (entry.value.startsWith(query)) add(entry.value);
          }
        }
        for (final word in banglaDefaults) {
          add(word);
        }
      }
    }

    return output.take(limit).toList(growable: false);
  }
}
