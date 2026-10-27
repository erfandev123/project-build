import 'package:flutter/material.dart';

import '../theme/borno_theme.dart';

enum InputMode { phonetic, bengali, english }

enum KeyboardPage { letters, numbers, emoji }

extension InputModeInfo on InputMode {
  bool get isBangla => this != InputMode.english;

  bool get isPhonetic => this == InputMode.phonetic;

  String get chipLabel => switch (this) {
    InputMode.phonetic => 'ফোনেটিক',
    InputMode.bengali => 'বর্ণমালা',
    InputMode.english => 'English',
  };

  String get title => switch (this) {
    InputMode.phonetic => 'ফোনেটিক বাংলা',
    InputMode.bengali => 'বাংলা বর্ণমালা',
    InputMode.english => 'English QWERTY',
  };

  String get subtitle => switch (this) {
    InputMode.phonetic => 'বাংলিশে লিখুন — Ridmik-স্টাইলে সাথে সাথে বাংলা হবে।',
    InputMode.bengali =>
      'সরাসরি বাংলা অক্ষরে লিখুন। Shift চাপলে আরও বর্ণ পাবেন।',
    InputMode.english => 'নিখুঁত স্পেসিংসহ দ্রুত ইংরেজি টাইপিং।',
  };

  String get glyph => switch (this) {
    InputMode.phonetic => 'অ',
    InputMode.bengali => 'ক',
    InputMode.english => 'A',
  };

  String get prefValue => name;

  static InputMode fromPref(String value) {
    return InputMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => InputMode.phonetic,
    );
  }
}

extension KeyboardPageInfo on KeyboardPage {
  String get banglaTitle => switch (this) {
    KeyboardPage.letters => 'প্রিয় শব্দ',
    KeyboardPage.numbers => 'সংখ্যা ও যতিচিহ্ন',
    KeyboardPage.emoji => 'মুড অনুযায়ী ইমোজি',
  };

  String get englishTitle => switch (this) {
    KeyboardPage.letters => 'Quick words',
    KeyboardPage.numbers => 'Numbers & symbols',
    KeyboardPage.emoji => 'Emoji',
  };
}

class KeySpec {
  const KeySpec(
    this.label, {
    this.hint = '',
    this.alternate = '',
    this.flex = 1,
  });

  final String label;
  final String hint;
  final String alternate;
  final int flex;
}

/// A single Bengali key and every character it can produce.
///
/// [characters] is the exact, ordered selection group shown in the touch
/// popup. The first entry is the normal primary character. [shiftIndex] points
/// at the alternate primary used while Shift is held, without reordering the
/// group or changing the key's position.
class BengaliKey {
  const BengaliKey(this.characters, {this.shiftIndex = 0});

  final List<String> characters;
  final int shiftIndex;

  String get primary => characters.first;

  bool get hasChoices => characters.length > 1;

  int primaryIndex(bool shift) {
    if (!shift || shiftIndex <= 0 || shiftIndex >= characters.length) {
      return 0;
    }
    return shiftIndex;
  }

  String primaryFor(bool shift) => characters[primaryIndex(shift)];
}

class KeyboardData {
  KeyboardData._();

  static const phoneticRow1 = [
    KeySpec('q', hint: 'ক'),
    KeySpec('w', hint: 'ৱ'),
    KeySpec('e', hint: 'এ'),
    KeySpec('r', hint: 'র'),
    KeySpec('t', hint: 'ত'),
    KeySpec('y', hint: 'য়'),
    KeySpec('u', hint: 'উ'),
    KeySpec('i', hint: 'ই'),
    KeySpec('o', hint: 'অ'),
    KeySpec('p', hint: 'প'),
  ];

  static const phoneticRow2 = [
    KeySpec('a', hint: 'আ'),
    KeySpec('s', hint: 'স'),
    KeySpec('d', hint: 'দ'),
    KeySpec('f', hint: 'ফ'),
    KeySpec('g', hint: 'গ'),
    KeySpec('h', hint: 'হ'),
    KeySpec('j', hint: 'জ'),
    KeySpec('k', hint: 'ক'),
    KeySpec('l', hint: 'ল'),
  ];

  static const phoneticRow3 = [
    KeySpec('z', hint: 'য'),
    KeySpec('x', hint: 'ক্স'),
    KeySpec('c', hint: 'চ'),
    KeySpec('v', hint: 'ভ'),
    KeySpec('b', hint: 'ব'),
    KeySpec('n', hint: 'ন'),
    KeySpec('m', hint: 'ম'),
  ];

  /// The complete Probhat/Ridmik-style Bengali layout.
  ///
  /// Row order, key order and the order inside every group are intentional.
  /// The `shiftIndex` of each key is the alternate primary shown while Shift
  /// is active. Both layers keep the same key positions and the same groups.
  ///
  /// Special sequences use their canonical Unicode forms:
  /// * র‍্য = র + ZWJ + ্ + য
  /// * ্র   = ্ + র
  /// * র্   = র + ্
  /// * ্য   = ্ + য
  static const bengaliRows = <List<BengaliKey>>[
    // Row 1 — 12 keys.
    [
      BengaliKey(['দ', 'ধ'], shiftIndex: 1),
      BengaliKey(['ূ', 'ঊ'], shiftIndex: 1),
      BengaliKey(['ী', 'ঈ'], shiftIndex: 1),
      BengaliKey(['র', 'ড়', '্র', 'র্', 'র‍্য'], shiftIndex: 1),
      BengaliKey(['ট', 'ঠ'], shiftIndex: 1),
      BengaliKey(['এ', 'ঐ', 'ঞ'], shiftIndex: 1),
      BengaliKey(['ু', 'উ', 'ৎ'], shiftIndex: 1),
      BengaliKey(['ি', 'ই'], shiftIndex: 1),
      BengaliKey(['ও', 'ঔ'], shiftIndex: 1),
      BengaliKey(['প', 'ফ'], shiftIndex: 1),
      BengaliKey(['ে', 'ৈ'], shiftIndex: 1),
      BengaliKey(['ো', 'ৌ'], shiftIndex: 1),
    ],
    // Row 2 — 9 keys, centred under row 1.
    [
      BengaliKey(['া', 'অ'], shiftIndex: 1),
      BengaliKey(['স', 'ষ'], shiftIndex: 1),
      BengaliKey(['ড', 'ঢ'], shiftIndex: 1),
      BengaliKey(['ত', 'থ'], shiftIndex: 1),
      BengaliKey(['গ', 'ঘ'], shiftIndex: 1),
      BengaliKey(['হ', 'ঃ'], shiftIndex: 1),
      BengaliKey(['জ', 'ঝ'], shiftIndex: 1),
      BengaliKey(['ক', 'খ'], shiftIndex: 1),
      BengaliKey(['ল', 'ং'], shiftIndex: 1),
    ],
    // Row 3 — 9 keys between Shift and Backspace.
    [
      BengaliKey(['য়', '্য', 'র‍্য', 'য'], shiftIndex: 3),
      BengaliKey(['শ', 'ঢ়'], shiftIndex: 1),
      BengaliKey(['চ', 'ছ'], shiftIndex: 1),
      BengaliKey(['আ', 'ঋ'], shiftIndex: 1),
      BengaliKey(['ব', 'ভ'], shiftIndex: 1),
      BengaliKey(['ন', 'ণ'], shiftIndex: 1),
      BengaliKey(['ম', 'ঙ'], shiftIndex: 1),
      BengaliKey(['ৃ']),
      BengaliKey(['্', '়', 'ঁ'], shiftIndex: 2),
    ],
  ];

  static const symbolsRow1 = [
    KeySpec('@'),
    KeySpec('#', alternate: '№'),
    KeySpec(r'$'),
    KeySpec('%', alternate: '‰'),
    KeySpec('&', alternate: '§'),
    KeySpec('*', alternate: '×'),
    KeySpec('(', alternate: '['),
    KeySpec(')', alternate: ']'),
    KeySpec('-', alternate: '–'),
    KeySpec('+', alternate: '±'),
  ];

  static const symbolsRow2 = [
    KeySpec('_', alternate: '~'),
    KeySpec('=', alternate: '≠'),
    KeySpec(':', alternate: 'ঃ'),
    KeySpec(';'),
    KeySpec(',', alternate: "'"),
    KeySpec('.', alternate: '"'),
    KeySpec('?', alternate: '¿'),
    KeySpec('!', alternate: '¡'),
    KeySpec('/', alternate: '\\'),
  ];

  static const bengaliDigits = [
    '১',
    '২',
    '৩',
    '৪',
    '৫',
    '৬',
    '৭',
    '৮',
    '৯',
    '০',
  ];
  static const englishDigits = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
  ];

  static const emojis = [
    '😀',
    '😂',
    '🥰',
    '😍',
    '😎',
    '🤗',
    '😅',
    '😇',
    '😊',
    '🙃',
    '🤩',
    '🥳',
    '😴',
    '😋',
    '👍',
    '👏',
    '🙏',
    '❤️',
    '💚',
    '💛',
    '💙',
    '🔥',
    '✨',
    '🎉',
    '🌸',
    '🌙',
    '☀️',
  ];

  static Color actionKeyBackground(KeyboardSkin skin, bool active) {
    if (active) return skin.accent;
    return skin.actionKey;
  }

  static Color actionKeyForeground(KeyboardSkin skin, bool active) {
    return active ? skin.onAccent : skin.actionText;
  }
}
