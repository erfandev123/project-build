import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/phonetic_engine.dart';
import '../platform/platform_service.dart';
import '../theme/borno_theme.dart';
import 'chat_preview.dart';
import 'install_help.dart';
import 'keyboard.dart';
import 'keyboard_data.dart';
import 'settings_sheets.dart';
import 'voice_sheet.dart';
import 'widgets.dart';

class KeyboardDemo extends StatefulWidget {
  const KeyboardDemo({super.key, this.phoneHeight = 760});

  final double phoneHeight;

  @override
  State<KeyboardDemo> createState() => _KeyboardDemoState();
}

class _KeyboardDemoState extends State<KeyboardDemo> {
  static const List<DemoMessage> _initialMessages = [
    DemoMessage('আসসালামু আলাইকুম! কেমন আছেন?', mine: false),
    DemoMessage('ভালো আছি। এই কীবোর্ডটা একবার চাপ দিয়ে দেখুন।', mine: true),
    DemoMessage(
      'নিচের কী-গুলো ট্যাপ করুন — Banglish-এ লিখলেই বাংলা হবে ✨',
      mine: false,
    ),
  ];

  static const List<String> _banglaReplies = [
    'বাহ! বাংলা লেখাটা দারুণ লাগছে। ✨',
    'পেয়েছি! আরও লিখে দেখুন — উপরের সাজেশনগুলোও চাপতে পারেন।',
    'একদম পরিষ্কার! Borno-তে বাংলা লিখতে ভালো লাগছে না?',
  ];

  static const List<String> _englishReplies = [
    'That looks great! Try the Banglish layout — type “ami” and watch it become বাংলা.',
    'Got it! Tap a suggestion above the keys if you want to write even faster.',
  ];

  final FocusNode _focusNode = FocusNode(debugLabel: 'Borno hardware keyboard');

  List<DemoMessage> _messages = List.of(_initialMessages);
  String _text = '';
  String _roman = '';
  InputMode _mode = InputMode.phonetic;
  KeyboardPage _page = KeyboardPage.letters;
  int _skinIndex = 0;
  bool _shift = false;
  bool _soundOn = true;
  bool _hapticsOn = true;
  bool _previewOn = true;
  bool _hardwareFocused = false;
  Timer? _replyTimer;
  int _replyIndex = 0;

  KeyboardSkin get _skin => keyboardSkins[_skinIndex];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _loadPreferences();
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (_hardwareFocused != _focusNode.hasFocus) {
      setState(() => _hardwareFocused = _focusNode.hasFocus);
    }
  }

  void _loadPreferences() {
    try {
      _soundOn = _readBool('sound', true);
      _hapticsOn = _readBool('haptics', true);
      _previewOn = _readBool('preview', true);
      _mode = InputModeInfo.fromPref(PlatformService.getPreference('mode'));
      final skinId = PlatformService.getPreference('skin');
      final index = keyboardSkins.indexWhere((skin) => skin.id == skinId);
      if (index >= 0) _skinIndex = index;
    } catch (_) {
      // Preferences are a nicety; never block the keyboard.
    }
  }

  bool _readBool(String key, bool fallback) {
    final value = PlatformService.getPreference(key);
    if (value.isEmpty) return fallback;
    return value == '1';
  }

  void _writeBool(String key, bool value) {
    PlatformService.setPreference(key, value ? '1' : '0');
  }

  String get _displayText {
    if (_mode.isPhonetic && _roman.isNotEmpty) {
      return '$_text${BanglaPhonetic.convertWord(_roman)}';
    }
    return _text;
  }

  String get _currentWord {
    if (_mode == InputMode.english) {
      return RegExp(r"[A-Za-z']+$").firstMatch(_text)?.group(0) ?? '';
    }
    return RegExp(r'[\u0980-\u09FF]+$').firstMatch(_text)?.group(0) ?? '';
  }

  List<String> get _suggestions {
    if (_page != KeyboardPage.letters) return const [];
    if (_mode == InputMode.phonetic) {
      return WordBank.suggestions(
        roman: _roman,
        banglaWord: _currentWord,
        english: false,
      );
    }
    return WordBank.suggestions(
      roman: '',
      banglaWord: _currentWord,
      english: _mode == InputMode.english,
    );
  }

  String _withRomanCommitted() {
    if (_mode.isPhonetic && _roman.isNotEmpty) {
      return '$_text${BanglaPhonetic.convertWord(_roman)}';
    }
    return _text;
  }

  bool get _canSend => _withRomanCommitted().trim().isNotEmpty;

  void _insertCharacter(String character) {
    if (character.isEmpty) return;
    if (_mode.isPhonetic && _isLatin(character)) {
      setState(() => _roman += character);
      return;
    }

    setState(() {
      if (_mode.isPhonetic && _roman.isNotEmpty) {
        _text = _withRomanCommitted();
        _roman = '';
      }
      _text += character;
    });
  }

  bool _isLatin(String character) {
    if (character.length != 1) return false;
    final code = character.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  void _onBackspace() {
    if (_mode.isPhonetic && _roman.isNotEmpty) {
      setState(() => _roman = _roman.substring(0, _roman.length - 1));
      return;
    }
    if (_text.isEmpty) return;
    setState(() {
      final chars = _text.characters;
      _text = chars.take(chars.length - 1).join();
    });
  }

  void _onSpace() {
    setState(() {
      if (_mode.isPhonetic && _roman.isNotEmpty) {
        _text = '${_withRomanCommitted()} ';
        _roman = '';
      } else if (_text.isEmpty || !_text.endsWith(' ')) {
        _text += ' ';
      }
    });
  }

  void _onSuggestion(String suggestion) {
    final cleaned = suggestion.trim();
    if (cleaned.isEmpty) return;
    setState(() {
      if (_mode.isPhonetic && _roman.isNotEmpty) {
        _text += '$cleaned ';
        _roman = '';
      } else if (_mode == InputMode.english && _currentWord.isNotEmpty) {
        _replaceTrailingWord(RegExp(r"[A-Za-z']+$"), '$cleaned ');
      } else if (_mode == InputMode.bengali && _currentWord.isNotEmpty) {
        _replaceTrailingWord(RegExp(r'[\u0980-\u09FF]+$'), '$cleaned ');
      } else {
        _text += cleaned;
        if (!_text.endsWith(' ')) _text += ' ';
      }
    });
  }

  void _replaceTrailingWord(RegExp pattern, String replacement) {
    final match = pattern.firstMatch(_text);
    if (match == null) {
      _text += replacement;
      return;
    }
    _text = '${_text.substring(0, match.start)}$replacement';
  }

  void _send() {
    final text = _withRomanCommitted().trim();
    if (text.isEmpty) return;
    setState(() {
      _messages = [..._messages, DemoMessage(text, mine: true)];
      _text = '';
      _roman = '';
      _page = KeyboardPage.letters;
    });

    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(milliseconds: 820), () {
      if (!mounted) return;
      final hasBangla = RegExp(r'[\u0980-\u09FF]').hasMatch(text);
      final pool = hasBangla ? _banglaReplies : _englishReplies;
      final reply = pool[_replyIndex % pool.length];
      _replyIndex++;
      setState(() {
        _messages = [..._messages, DemoMessage(reply, mine: false)];
      });
    });
  }

  void _resetChat() {
    _replyTimer?.cancel();
    setState(() {
      _messages = List.of(_initialMessages);
      _text = '';
      _roman = '';
      _page = KeyboardPage.letters;
      _shift = false;
    });
    showBornoToast(context, 'ডেমো আবার শুরু থেকে।');
  }

  void _setMode(InputMode mode) {
    if (mode == _mode) return;
    setState(() {
      _text = _withRomanCommitted();
      _roman = '';
      _mode = mode;
      _page = KeyboardPage.letters;
      _shift = false;
    });
    PlatformService.setPreference('mode', mode.prefValue);
  }

  void _cycleMode() {
    final values = InputMode.values;
    final next = values[(values.indexOf(_mode) + 1) % values.length];
    _setMode(next);
  }

  void _setSkin(int index) {
    if (index == _skinIndex || index < 0 || index >= keyboardSkins.length) {
      return;
    }
    setState(() => _skinIndex = index);
    PlatformService.setPreference('skin', keyboardSkins[index].id);
  }

  Future<void> _openLayouts() async {
    final selected = await showLayoutPickerSheet(context, selected: _mode);
    if (!mounted || selected == null) return;
    _setMode(selected);
  }

  Future<void> _openThemes() async {
    final selected = await showThemePickerSheet(context, selected: _skinIndex);
    if (!mounted || selected == null) return;
    _setSkin(selected);
  }

  Future<void> _openSettings() async {
    final result = await showKeyboardSettingsSheet(
      context,
      soundOn: _soundOn,
      hapticsOn: _hapticsOn,
      previewOn: _previewOn,
    );
    if (!mounted || result == null) return;
    setState(() {
      _soundOn = result.soundOn;
      _hapticsOn = result.hapticsOn;
      _previewOn = result.previewOn;
    });
    _writeBool('sound', result.soundOn);
    _writeBool('haptics', result.hapticsOn);
    _writeBool('preview', result.previewOn);
  }

  void _toggleSound() {
    setState(() => _soundOn = !_soundOn);
    _writeBool('sound', _soundOn);
    if (_soundOn) PlatformService.clickSound();
  }

  Future<void> _openVoice() async {
    if (_page != KeyboardPage.letters) {
      setState(() => _page = KeyboardPage.letters);
    }
    final phrase = await showVoiceSheet(context, skin: _skin);
    if (!mounted || phrase == null || phrase.trim().isEmpty) return;
    setState(() {
      final committed = _withRomanCommitted();
      _roman = '';
      final needsSpace = committed.isNotEmpty && !committed.endsWith(' ');
      _text = '$committed${needsSpace ? ' ' : ''}${phrase.trim()}';
    });
    _focusNode.requestFocus();
  }

  Future<void> _onInstall() => installBorno(context);

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _onBackspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _send();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      _onSpace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _focusNode.unfocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) return KeyEventResult.ignored;

    final character = event.character;
    if (character == null || character.isEmpty) return KeyEventResult.ignored;
    if (character.runes.any((rune) => rune < 0x20)) {
      return KeyEventResult.ignored;
    }
    _insertCharacter(character);
    return KeyEventResult.handled;
  }

  void _requestHardwareFocus() {
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 420.0;
        final phoneWidth = math.min(maxWidth, 398.0);
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final phoneHeight = math.max(
          600.0,
          math.min(widget.phoneHeight, math.max(660.0, viewportHeight - 48)),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PhoneStage(
              width: phoneWidth,
              height: phoneHeight,
              skin: _skin,
              focusNode: _focusNode,
              onPointerDown: _requestHardwareFocus,
              onKeyEvent: _onKeyEvent,
              child: Column(
                children: [
                  Expanded(
                    child: ChatPreview(
                      skin: _skin,
                      messages: _messages,
                      text: _displayText,
                      romanBuffer: _mode.isPhonetic ? _roman : '',
                      canSend: _canSend,
                      onSend: _send,
                      onReset: _resetChat,
                      onRequestFocus: _requestHardwareFocus,
                    ),
                  ),
                  BornoKeyboard(
                    skin: _skin,
                    mode: _mode,
                    page: _page,
                    shift: _shift,
                    suggestions: _suggestions,
                    soundOn: _soundOn,
                    hapticsOn: _hapticsOn,
                    previewOn: _previewOn,
                    canSend: _canSend,
                    onCharacter: _insertCharacter,
                    onBackspace: _onBackspace,
                    onShift: () => setState(() => _shift = !_shift),
                    onSpace: _onSpace,
                    onSend: _send,
                    onPageChanged: (page) => setState(() => _page = page),
                    onCycleMode: _cycleMode,
                    onSuggestion: _onSuggestion,
                    onVoice: _openVoice,
                    onOpenLayouts: _openLayouts,
                    onOpenThemes: _openThemes,
                    onOpenSettings: _openSettings,
                    onToggleSound: _toggleSound,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DemoDock(
              width: phoneWidth,
              skin: _skin,
              mode: _mode,
              skinIndex: _skinIndex,
              hardwareFocused: _hardwareFocused,
              onMode: _setMode,
              onSkin: _setSkin,
              onInstall: _onInstall,
            ),
          ],
        );
      },
    );
  }
}

class _PhoneStage extends StatelessWidget {
  const _PhoneStage({
    required this.width,
    required this.height,
    required this.skin,
    required this.focusNode,
    required this.onPointerDown,
    required this.onKeyEvent,
    required this.child,
  });

  final double width;
  final double height;
  final KeyboardSkin skin;
  final FocusNode focusNode;
  final VoidCallback onPointerDown;
  final KeyEventResult Function(FocusNode, KeyEvent) onKeyEvent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height + 10,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 38,
            left: -22,
            right: -22,
            bottom: -6,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  gradient: RadialGradient(
                    colors: [
                      skin.accent.withValues(alpha: 0.16),
                      skin.accent.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.46, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height,
            child: Focus(
              focusNode: focusNode,
              onKeyEvent: onKeyEvent,
              child: Listener(
                onPointerDown: (_) => onPointerDown(),
                child: _DeviceShell(skin: skin, child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceShell extends StatelessWidget {
  const _DeviceShell({required this.skin, required this.child});

  final KeyboardSkin skin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(47),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF252B27), Color(0xFF0C0F0D), Color(0xFF272D29)],
              stops: [0, 0.5, 1],
            ),
            border: Border.all(color: const Color(0x24FFFFFF), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 48,
                offset: const Offset(0, 26),
              ),
              BoxShadow(
                color: skin.accent.withValues(alpha: 0.06),
                blurRadius: 70,
                spreadRadius: 12,
              ),
            ],
          ),
          padding: const EdgeInsets.all(7),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Stack(
              children: [
                Positioned.fill(child: child),
                Positioned(
                  top: 9,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 88,
                      height: 23,
                      decoration: BoxDecoration(
                        color: const Color(0xFF050706),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFF171A18)),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 9),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF17211C),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0x3312FF9D),
                                width: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: -2.2,
          top: 138,
          child: _SideButton(height: 30, color: skin.keyboardDeep),
        ),
        Positioned(
          left: -2.2,
          top: 180,
          child: _SideButton(height: 52, color: skin.keyboardDeep),
        ),
        Positioned(
          left: -2.2,
          top: 240,
          child: _SideButton(height: 52, color: skin.keyboardDeep),
        ),
        Positioned(
          right: -2.2,
          top: 190,
          child: _SideButton(height: 74, color: skin.keyboardDeep),
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(2),
          right: Radius.circular(2),
        ),
        border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
      ),
    );
  }
}

class _DemoDock extends StatelessWidget {
  const _DemoDock({
    required this.width,
    required this.skin,
    required this.mode,
    required this.skinIndex,
    required this.hardwareFocused,
    required this.onMode,
    required this.onSkin,
    required this.onInstall,
  });

  final double width;
  final KeyboardSkin skin;
  final InputMode mode;
  final int skinIndex;
  final bool hardwareFocused;
  final ValueChanged<InputMode> onMode;
  final ValueChanged<int> onSkin;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: BornoColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BornoColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: skin.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: skin.accent.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'লাইভ কী-বোর্ড',
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: BornoColors.textSoft,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.keyboard_alt_outlined,
                size: 12,
                color: hardwareFocused ? skin.accent : BornoColors.mutedDeep,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  hardwareFocused ? 'সরাসরি টাইপ করুন' : 'ফোনে ট্যাপ করুন',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 9.5,
                    height: 1.2,
                    color: hardwareFocused
                        ? skin.accent
                        : BornoColors.mutedDeep,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _DockIconButton(
                icon: Icons.download_rounded,
                tooltip: 'Borno ইনস্টল করুন',
                onTap: onInstall,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (var i = 0; i < InputMode.values.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: _ModePill(
                    mode: InputMode.values[i],
                    active: mode == InputMode.values[i],
                    skin: skin,
                    onTap: () => onMode(InputMode.values[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) {
              final showEngineLabel = constraints.maxWidth >= 300;
              return Row(
                children: [
                  const Text(
                    'থিম',
                    style: TextStyle(
                      fontFamily: 'HindSiliguri',
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: BornoColors.muted,
                    ),
                  ),
                  const SizedBox(width: 9),
                  for (var i = 0; i < keyboardSkins.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _SkinDot(
                      skin: keyboardSkins[i],
                      selected: i == skinIndex,
                      onTap: () => onSkin(i),
                    ),
                  ],
                  if (showEngineLabel) ...[
                    const Spacer(),
                    const Icon(
                      Icons.bolt_rounded,
                      size: 12,
                      color: BornoColors.mutedDeep,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'অফলাইন ইঞ্জিন',
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 9,
                        height: 1.2,
                        color: BornoColors.mutedDeep,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.mode,
    required this.active,
    required this.skin,
    required this.onTap,
  });

  final InputMode mode;
  final bool active;
  final KeyboardSkin skin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: mode.subtitle,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: active
                  ? skin.accent.withValues(alpha: 0.12)
                  : const Color(0x06FFFFFF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: active
                    ? skin.accent.withValues(alpha: 0.4)
                    : const Color(0x12FFFFFF),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mode.glyph,
                  style: TextStyle(
                    fontFamily: mode == InputMode.english
                        ? 'Manrope'
                        : 'NotoBengali',
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: active ? skin.accent : BornoColors.muted,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    mode.chipLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: mode == InputMode.english
                          ? 'Manrope'
                          : 'HindSiliguri',
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: active ? BornoColors.text : BornoColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkinDot extends StatelessWidget {
  const _SkinDot({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final KeyboardSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${skin.nameBn} থিম',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? BornoColors.lime : const Color(0x24FFFFFF),
                width: selected ? 1.4 : 0.8,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: skin.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? BornoColors.onLime.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  const _DockIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Icon(icon, size: 13, color: BornoColors.muted),
        ),
      ),
    );
  }
}
