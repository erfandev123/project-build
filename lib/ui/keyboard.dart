import 'package:flutter/material.dart';

import '../platform/platform_service.dart';
import '../theme/borno_theme.dart';
import 'key_button.dart';
import 'keyboard_data.dart';

class BornoKeyboard extends StatelessWidget {
  const BornoKeyboard({
    super.key,
    required this.skin,
    required this.mode,
    required this.page,
    required this.shift,
    required this.suggestions,
    required this.soundOn,
    required this.hapticsOn,
    required this.previewOn,
    required this.canSend,
    required this.onCharacter,
    required this.onBackspace,
    required this.onShift,
    required this.onSpace,
    required this.onSend,
    required this.onPageChanged,
    required this.onCycleMode,
    required this.onSuggestion,
    required this.onVoice,
    required this.onOpenLayouts,
    required this.onOpenThemes,
    required this.onOpenSettings,
    required this.onToggleSound,
    this.voiceStatus = '',
    this.onCloseVoice,
    this.onFeedback,
  });

  final KeyboardSkin skin;
  final InputMode mode;
  final KeyboardPage page;
  final bool shift;
  final List<String> suggestions;
  final bool soundOn;
  final bool hapticsOn;
  final bool previewOn;
  final bool canSend;
  final ValueChanged<String> onCharacter;
  final VoidCallback onBackspace;
  final VoidCallback onShift;
  final VoidCallback onSpace;
  final VoidCallback onSend;
  final ValueChanged<KeyboardPage> onPageChanged;
  final VoidCallback onCycleMode;
  final ValueChanged<String> onSuggestion;
  final VoidCallback onVoice;
  final VoidCallback onOpenLayouts;
  final VoidCallback onOpenThemes;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleSound;
  final String voiceStatus;
  final VoidCallback? onCloseVoice;
  final VoidCallback? onFeedback;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gap = width < 350 ? 4.0 : 5.0;
        final keyHeight = width < 330 ? 42.0 : (width < 370 ? 45.0 : 48.0);
        final actionHeight = width < 330 ? 41.0 : 45.0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [skin.keyboard, skin.keyboardDeep],
            ),
            border: Border(top: BorderSide(color: skin.divider)),
          ),
          padding: EdgeInsets.fromLTRB(gap, 5, gap, 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToolbar(width),
              const SizedBox(height: 3),
              _buildSuggestionRow(width),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 130),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.025),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey('${page.name}-${mode.name}-$shift'),
                  child: _buildContentRows(
                    width: width,
                    gap: gap,
                    keyHeight: keyHeight,
                  ),
                ),
              ),
              SizedBox(height: gap),
              _buildBottomRow(width: width, gap: gap, height: actionHeight),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(double width) {
    return SizedBox(
      height: 29,
      child: Row(
        children: [
          _LayoutChip(skin: skin, mode: mode, onTap: onOpenLayouts),
          const Spacer(),
          KeyboardToolIcon(
            skin: skin,
            icon: soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            tooltip: soundOn
                ? 'ক্লিক সাউন্ড বন্ধ করুন'
                : 'ক্লিক সাউন্ড চালু করুন',
            active: soundOn,
            size: 28,
            iconSize: 16,
            onTap: onToggleSound,
          ),
          const SizedBox(width: 1),
          KeyboardToolIcon(
            skin: skin,
            icon: Icons.palette_outlined,
            tooltip: 'কীবোর্ড থিম',
            size: 28,
            iconSize: 16,
            onTap: onOpenThemes,
          ),
          const SizedBox(width: 1),
          KeyboardToolIcon(
            skin: skin,
            icon: Icons.tune_rounded,
            tooltip: 'কীবোর্ড সেটিংস',
            size: 28,
            iconSize: 16,
            onTap: onOpenSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionRow(double width) {
    final showSuggestions = page == KeyboardPage.letters;
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: voiceStatus.isNotEmpty
                ? Row(
                    children: [
                      Icon(Icons.mic_rounded, size: 15, color: skin.accent),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          voiceStatus,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: mode.isBangla
                                ? 'HindSiliguri'
                                : 'Manrope',
                            fontSize: 11,
                            color: skin.keyText,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        onPressed: onCloseVoice,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: skin.keyHint,
                        ),
                      ),
                    ],
                  )
                : showSuggestions
                ? Row(
                    children: [
                      for (var i = 0; i < suggestions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        Expanded(
                          child: SuggestionChip(
                            skin: skin,
                            label: suggestions[i],
                            onTap: () => onSuggestion(suggestions[i]),
                          ),
                        ),
                      ],
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Row(
                      children: [
                        Icon(
                          page == KeyboardPage.emoji
                              ? Icons.emoji_emotions_outlined
                              : Icons.dialpad_rounded,
                          size: 14,
                          color: skin.accent.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          mode.isBangla ? page.banglaTitle : page.englishTitle,
                          style: TextStyle(
                            fontFamily: mode.isBangla
                                ? 'HindSiliguri'
                                : 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: skin.keyHint.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (voiceStatus.isEmpty) ...[
            const SizedBox(width: 6),
            _MicButton(
              skin: skin,
              onTap: onVoice,
              soundOn: soundOn,
              hapticsOn: hapticsOn,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentRows({
    required double width,
    required double gap,
    required double keyHeight,
  }) {
    if (page == KeyboardPage.emoji) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < 3; row++) ...[
            if (row > 0) SizedBox(height: gap),
            _emojiRow(row, gap: gap, height: keyHeight),
          ],
        ],
      );
    }

    if (page == KeyboardPage.numbers) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _digitRow(gap: gap, height: keyHeight),
          SizedBox(height: gap),
          _specRow(
            KeyboardData.symbolsRow1,
            gap: gap,
            height: keyHeight,
            showHint: false,
          ),
          SizedBox(height: gap),
          Row(
            children: [
              for (var i = 0; i < KeyboardData.symbolsRow2.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  flex: 2,
                  child: _symbolKey(
                    KeyboardData.symbolsRow2[i],
                    height: keyHeight,
                    showHint: false,
                  ),
                ),
              ],
              SizedBox(width: gap),
              Expanded(flex: 3, child: _backspaceKey(height: keyHeight)),
            ],
          ),
        ],
      );
    }

    final isBengali = mode == InputMode.bengali;

    if (isBengali) {
      final rows = KeyboardData.bengaliRows;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _bengaliRow(rows[0], gap: gap, height: keyHeight),
          SizedBox(height: gap),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              child: _bengaliRow(rows[1], gap: gap, height: keyHeight),
            ),
          ),
          SizedBox(height: gap),
          _bengaliThirdRow(rows[2], gap: gap, height: keyHeight),
        ],
      );
    }

    final rows = mode == InputMode.phonetic
        ? [
            KeyboardData.phoneticRow1,
            KeyboardData.phoneticRow2,
            KeyboardData.phoneticRow3,
          ]
        : [
            const [
              KeySpec('q'),
              KeySpec('w'),
              KeySpec('e'),
              KeySpec('r'),
              KeySpec('t'),
              KeySpec('y'),
              KeySpec('u'),
              KeySpec('i'),
              KeySpec('o'),
              KeySpec('p'),
            ],
            const [
              KeySpec('a'),
              KeySpec('s'),
              KeySpec('d'),
              KeySpec('f'),
              KeySpec('g'),
              KeySpec('h'),
              KeySpec('j'),
              KeySpec('k'),
              KeySpec('l'),
            ],
            const [
              KeySpec('z'),
              KeySpec('x'),
              KeySpec('c'),
              KeySpec('v'),
              KeySpec('b'),
              KeySpec('n'),
              KeySpec('m'),
            ],
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _specRow(
          rows[0],
          gap: gap,
          height: keyHeight,
          showHint: mode == InputMode.phonetic && !shift,
          phonetic: mode == InputMode.phonetic,
        ),
        SizedBox(height: gap),
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.9,
            child: _specRow(
              rows[1],
              gap: gap,
              height: keyHeight,
              showHint: mode == InputMode.phonetic && !shift,
              phonetic: mode == InputMode.phonetic,
            ),
          ),
        ),
        SizedBox(height: gap),
        _thirdRow(
          rows[2],
          gap: gap,
          height: keyHeight,
          showHint: mode == InputMode.phonetic && !shift,
          phonetic: mode == InputMode.phonetic,
        ),
      ],
    );
  }

  Widget _digitRow({required double gap, required double height}) {
    final digits = mode.isBangla
        ? KeyboardData.bengaliDigits
        : KeyboardData.englishDigits;
    return Row(
      children: [
        for (var i = 0; i < digits.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: _plainCharKey(
              digits[i],
              output: digits[i],
              height: height,
              preview: digits[i],
            ),
          ),
        ],
      ],
    );
  }

  Widget _emojiRow(int index, {required double gap, required double height}) {
    final start = index * 9;
    return Row(
      children: [
        for (var i = 0; i < 9; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: BornoKey(
              skin: skin,
              label: KeyboardData.emojis[start + i],
              emoji: true,
              height: height,
              soundOn: soundOn,
              hapticsOn: hapticsOn,
              previewOn: false,
              semanticLabel: 'ইমোজি ${KeyboardData.emojis[start + i]}',
              onTap: () => onCharacter(KeyboardData.emojis[start + i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _specRow(
    List<KeySpec> specs, {
    required double gap,
    required double height,
    required bool showHint,
    bool phonetic = false,
  }) {
    return Row(
      children: [
        for (var i = 0; i < specs.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            flex: specs[i].flex,
            child: _letterKey(
              specs[i],
              height: height,
              showHint: showHint,
              phonetic: phonetic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _thirdRow(
    List<KeySpec> specs, {
    required double gap,
    required double height,
    required bool showHint,
    bool phonetic = false,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: BornoKey(
            skin: skin,
            icon: shift
                ? Icons.keyboard_capslock_rounded
                : Icons.arrow_upward_rounded,
            action: true,
            selected: shift,
            height: height,
            soundOn: soundOn,
            hapticsOn: hapticsOn,
            previewOn: false,
            iconSize: 18,
            semanticLabel: shift ? 'শিফট বন্ধ করুন' : 'শিফট চালু করুন',
            onTap: onShift,
          ),
        ),
        SizedBox(width: gap),
        for (var i = 0; i < specs.length; i++) ...[
          Expanded(
            flex: 2,
            child: _letterKey(
              specs[i],
              height: height,
              showHint: showHint,
              phonetic: phonetic,
            ),
          ),
          SizedBox(width: gap),
        ],
        Expanded(flex: 3, child: _backspaceKey(height: height)),
      ],
    );
  }

  Widget _bengaliRow(
    List<BengaliKey> keys, {
    required double gap,
    required double height,
  }) {
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: _bengaliKey(keys[i], height: height)),
        ],
      ],
    );
  }

  Widget _bengaliThirdRow(
    List<BengaliKey> keys, {
    required double gap,
    required double height,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: BornoKey(
            skin: skin,
            icon: shift
                ? Icons.keyboard_capslock_rounded
                : Icons.arrow_upward_rounded,
            action: true,
            selected: shift,
            height: height,
            soundOn: soundOn,
            hapticsOn: hapticsOn,
            previewOn: false,
            iconSize: 18,
            semanticLabel: shift ? 'শিফট বন্ধ করুন' : 'শিফট চালু করুন',
            onTap: onShift,
          ),
        ),
        SizedBox(width: gap),
        for (var i = 0; i < keys.length; i++) ...[
          Expanded(flex: 2, child: _bengaliKey(keys[i], height: height)),
          SizedBox(width: gap),
        ],
        Expanded(flex: 3, child: _backspaceKey(height: height)),
      ],
    );
  }

  Widget _bengaliKey(BengaliKey key, {required double height}) {
    final label = key.primaryFor(shift);
    final primaryIndex = key.primaryIndex(shift);
    final hasChoices = key.hasChoices;

    return BornoKey(
      skin: skin,
      label: label,
      hint: hasChoices ? key.characters[1] : null,
      height: height,
      soundOn: soundOn,
      hapticsOn: hapticsOn,
      previewOn: previewOn && !hasChoices,
      previewText: label,
      choices: key.characters,
      choiceStartIndex: primaryIndex,
      onChoiceSelected: onCharacter,
      semanticLabel: hasChoices
          ? '$label — স্লাইড করে ${key.characters.length}টি অক্ষরের যেকোনোটি বাছুন'
          : label,
      onTap: () => onCharacter(label),
    );
  }

  Widget _letterKey(
    KeySpec spec, {
    required double height,
    required bool showHint,
    required bool phonetic,
  }) {
    String label;
    String output;
    final isEnglish = mode == InputMode.english;

    if (phonetic) {
      label = shift ? spec.label.toUpperCase() : spec.label;
      output = spec.label;
    } else if (isEnglish) {
      label = shift ? spec.label.toUpperCase() : spec.label;
      output = label;
    } else {
      label = spec.label;
      output = spec.label;
    }

    final hint = showHint
        ? (phonetic
              ? spec.hint
              : (spec.alternate.isNotEmpty ? spec.alternate : null))
        : (mode == InputMode.bengali && spec.alternate.isNotEmpty
              ? spec.alternate
              : null);

    return BornoKey(
      skin: skin,
      label: label,
      hint: hint,
      height: height,
      soundOn: soundOn,
      hapticsOn: hapticsOn,
      previewOn: previewOn,
      previewText: label,
      semanticLabel: spec.alternate.isNotEmpty
          ? '$label, লং প্রেসে ${spec.alternate}'
          : label,
      onTap: () => onCharacter(output),
      onLongPress: spec.alternate.isNotEmpty
          ? () => onCharacter(spec.alternate)
          : null,
    );
  }

  Widget _symbolKey(
    KeySpec spec, {
    required double height,
    required bool showHint,
  }) {
    return BornoKey(
      skin: skin,
      label: spec.label,
      hint: showHint && spec.alternate.isNotEmpty ? spec.alternate : null,
      height: height,
      soundOn: soundOn,
      hapticsOn: hapticsOn,
      previewOn: previewOn,
      previewText: spec.label,
      onTap: () => onCharacter(spec.label),
      onLongPress: spec.alternate.isNotEmpty
          ? () => onCharacter(spec.alternate)
          : null,
    );
  }

  Widget _plainCharKey(
    String label, {
    required String output,
    required double height,
    required String preview,
  }) {
    return BornoKey(
      skin: skin,
      label: label,
      height: height,
      soundOn: soundOn,
      hapticsOn: hapticsOn,
      previewOn: previewOn,
      previewText: preview,
      onTap: () => onCharacter(output),
    );
  }

  Widget _backspaceKey({required double height}) {
    return BornoKey(
      skin: skin,
      icon: Icons.backspace_outlined,
      action: true,
      height: height,
      soundOn: soundOn,
      hapticsOn: hapticsOn,
      previewOn: false,
      iconSize: 18,
      semanticLabel: 'মুছুন',
      repeatOnHold: true,
      onTap: onBackspace,
    );
  }

  Widget _buildBottomRow({
    required double width,
    required double gap,
    required double height,
  }) {
    final isEmojiPage = page == KeyboardPage.emoji;
    final pageLabel = page == KeyboardPage.letters
        ? (mode.isBangla ? '১২৩' : '123')
        : 'ABC';
    final punctuation = mode.isBangla ? '।' : '.';
    final punctuationAlternative = mode.isBangla ? '.' : '।';

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: BornoKey(
            skin: skin,
            label: pageLabel,
            fontSize: pageLabel == 'ABC' ? 13 : 12,
            action: true,
            height: height,
            soundOn: soundOn,
            hapticsOn: hapticsOn,
            previewOn: false,
            semanticLabel: page == KeyboardPage.letters ? 'সংখ্যা' : 'অক্ষর',
            onTap: () => onPageChanged(
              page == KeyboardPage.letters
                  ? KeyboardPage.numbers
                  : KeyboardPage.letters,
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 3,
          child: isEmojiPage
              ? _backspaceKey(height: height)
              : BornoKey(
                  skin: skin,
                  icon: Icons.emoji_emotions_outlined,
                  action: true,
                  height: height,
                  soundOn: soundOn,
                  hapticsOn: hapticsOn,
                  previewOn: false,
                  iconSize: 19,
                  semanticLabel: 'ইমোজি',
                  onTap: () => onPageChanged(KeyboardPage.emoji),
                ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 3,
          child: BornoKey(
            skin: skin,
            icon: Icons.language_rounded,
            action: true,
            height: height,
            soundOn: soundOn,
            hapticsOn: hapticsOn,
            previewOn: false,
            iconSize: 19,
            semanticLabel: 'ভাষা বদলান',
            onTap: onCycleMode,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 10,
          child: BornoKey(
            skin: skin,
            label: mode.isBangla ? 'স্পেস' : 'space',
            fontSize: 10.5,
            height: height,
            soundOn: soundOn,
            hapticsOn: hapticsOn,
            previewOn: false,
            semanticLabel: 'স্পেস',
            onTap: onSpace,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 3,
          child: BornoKey(
            skin: skin,
            label: punctuation,
            action: true,
            height: height,
            soundOn: soundOn,
            hapticsOn: hapticsOn,
            previewOn: false,
            semanticLabel: mode.isBangla ? 'দাঁড়ি' : 'ফুলস্টপ',
            onTap: () => onCharacter(punctuation),
            onLongPress: () => onCharacter(punctuationAlternative),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 4,
          child: BornoKey(
            skin: skin,
            icon: Icons.arrow_upward_rounded,
            action: true,
            accent: canSend,
            height: height,
            soundOn: soundOn,
            hapticsOn: hapticsOn,
            previewOn: false,
            iconSize: 19,
            semanticLabel: 'পাঠান',
            onTap: onSend,
          ),
        ),
      ],
    );
  }
}

class _LayoutChip extends StatefulWidget {
  const _LayoutChip({
    required this.skin,
    required this.mode,
    required this.onTap,
  });

  final KeyboardSkin skin;
  final InputMode mode;
  final VoidCallback onTap;

  @override
  State<_LayoutChip> createState() => _LayoutChipState();
}

class _LayoutChipState extends State<_LayoutChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    return Tooltip(
      message: 'কীবোর্ড লেআউট বদলান',
      waitDuration: const Duration(milliseconds: 450),
      child: Semantics(
        button: true,
        label: 'বর্তমান লেআউট ${widget.mode.chipLabel}, বদলাতে চাপুন',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 27,
              padding: const EdgeInsets.fromLTRB(3, 0, 7, 0),
              decoration: BoxDecoration(
                color: _hovered
                    ? skin.key.withValues(alpha: 0.9)
                    : skin.key.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: skin.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 21,
                    height: 21,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: skin.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.mode.glyph,
                      style: TextStyle(
                        fontFamily: widget.mode == InputMode.english
                            ? 'Manrope'
                            : 'NotoBengali',
                        fontSize: 11,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: skin.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.mode.chipLabel,
                    style: TextStyle(
                      fontFamily: widget.mode == InputMode.english
                          ? 'Manrope'
                          : 'HindSiliguri',
                      fontSize: 10.5,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: skin.keyText.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 12,
                    color: skin.keyHint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.skin,
    required this.onTap,
    required this.soundOn,
    required this.hapticsOn,
  });

  final KeyboardSkin skin;
  final VoidCallback onTap;
  final bool soundOn;
  final bool hapticsOn;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    return Tooltip(
      message: 'বাংলা ভয়েস ইনপুট',
      waitDuration: const Duration(milliseconds: 450),
      child: Semantics(
        button: true,
        label: 'বাংলা ভয়েস ইনপুট',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              setState(() => _pressed = true);
              if (widget.soundOn) PlatformService.clickSound();
              if (widget.hapticsOn) PlatformService.haptic();
            },
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 0.98 : 1,
              duration: const Duration(milliseconds: 110),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _hovered
                      ? Color.lerp(skin.accent, Colors.white, 0.1)
                      : skin.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: skin.accent.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: skin.accent.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.mic_rounded, size: 18, color: skin.onAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
