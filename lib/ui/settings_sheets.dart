import 'package:flutter/material.dart';

import '../platform/platform_service.dart';
import '../theme/borno_theme.dart';
import 'keyboard_data.dart';

class FeedbackSettings {
  const FeedbackSettings({
    required this.soundOn,
    required this.hapticsOn,
    required this.previewOn,
  });

  final bool soundOn;
  final bool hapticsOn;
  final bool previewOn;
}

Future<InputMode?> showLayoutPickerSheet(
  BuildContext context, {
  required InputMode selected,
}) {
  return showModalBottomSheet<InputMode>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xC2050B08),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _LayoutSheet(selected: selected),
  );
}

Future<int?> showThemePickerSheet(
  BuildContext context, {
  required int selected,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xC2050B08),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ThemeSheet(selected: selected),
  );
}

Future<FeedbackSettings?> showKeyboardSettingsSheet(
  BuildContext context, {
  required bool soundOn,
  required bool hapticsOn,
  required bool previewOn,
}) {
  return showModalBottomSheet<FeedbackSettings>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xC2050B08),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _SettingsSheet(
      soundOn: soundOn,
      hapticsOn: hapticsOn,
      previewOn: previewOn,
    ),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: height * 0.9),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: BornoColors.panel,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: BornoColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 48,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 38,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: const Color(0x2EFFFFFF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9.5,
                    height: 1.2,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: BornoColors.muted,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  style: bengali(
                    size: 22,
                    weight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: bengali(
                    size: 12,
                    weight: FontWeight.w400,
                    color: BornoColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          _CloseButton(onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      padding: const EdgeInsets.all(8),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x0DFFFFFF),
        side: const BorderSide(color: Color(0x18FFFFFF)),
      ),
      icon: const Icon(Icons.close_rounded, color: BornoColors.muted),
    );
  }
}

class _LayoutSheet extends StatelessWidget {
  const _LayoutSheet({required this.selected});

  final InputMode selected;

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHeader(
              eyebrow: 'Keyboard layouts',
              title: 'লেখার ধরন বেছে নিন',
              description: 'একই কীবোর্ডে বাংলিশ, বাংলা বর্ণমালা আর English—যেটা আপনার হাতে বেশি মানায়।',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final mode in InputMode.values) ...[
                    _LayoutOption(
                      mode: mode,
                      selected: mode == selected,
                      onTap: () => Navigator.of(context).pop(mode),
                    ),
                    if (mode != InputMode.values.last)
                      const SizedBox(height: 9),
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: BornoColors.muted,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'টিপস: গ্লোব কী চেপে দ্রুত লেআউট বদলাতে পারবেন।',
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 11.5,
                        height: 1.4,
                        color: BornoColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutOption extends StatefulWidget {
  const _LayoutOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final InputMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LayoutOption> createState() => _LayoutOptionState();
}

class _LayoutOptionState extends State<_LayoutOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final mode = widget.mode;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? BornoColors.lime.withValues(alpha: 0.075)
                : (_hovered
                      ? const Color(0x0CFFFFFF)
                      : const Color(0x05FFFFFF)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? BornoColors.lime.withValues(alpha: 0.42)
                  : const Color(0x14FFFFFF),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? BornoColors.lime : const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: selected
                      ? null
                      : Border.all(color: const Color(0x1AFFFFFF)),
                ),
                child: Text(
                  mode.glyph,
                  style: TextStyle(
                    fontFamily: mode == InputMode.english
                        ? 'Manrope'
                        : 'NotoBengali',
                    fontSize: 19,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: selected ? BornoColors.onLime : BornoColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            mode.title,
                            style: bengali(size: 15, weight: FontWeight.w600),
                          ),
                        ),
                        if (mode == InputMode.phonetic) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BornoColors.lime.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'RIDMIK STYLE',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 6.5,
                                letterSpacing: 0.7,
                                fontWeight: FontWeight.w800,
                                color: BornoColors.lime,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mode.subtitle,
                      style: bengali(
                        size: 10.8,
                        weight: FontWeight.w400,
                        color: BornoColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? BornoColors.lime : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? BornoColors.lime
                        : const Color(0x30FFFFFF),
                    width: 1.3,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: BornoColors.onLime,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHeader(
              eyebrow: 'Four moods',
              title: 'আজ কোন মুডে লিখবেন?',
              description: 'প্রতিটি থিমে বদলে যায় কীবোর্ড, চ্যাট স্ক্রিন আর ক্লিকের গ্লো।',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 420 ? 2 : 4;
                  final gap = 10.0;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (var i = 0; i < keyboardSkins.length; i++)
                        SizedBox(
                          width: width,
                          child: _ThemeCard(
                            skin: keyboardSkins[i],
                            selected: i == selected,
                            onTap: () => Navigator.of(context).pop(i),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: BornoColors.lime,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'সব থিমেই বাংলা গ্লিফ, সাজেশন আর সফট ফিডব্যাক একইরকম নিখুঁত।',
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 11.5,
                        height: 1.4,
                        color: BornoColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  const _ThemeCard({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final KeyboardSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0x05FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected
                  ? BornoColors.lime.withValues(alpha: 0.6)
                  : const Color(0x14FFFFFF),
              width: widget.selected ? 1.2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 82,
                  color: skin.keyboard,
                  padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
                  child: Column(
                    children: [
                      Container(
                        height: 7,
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: skin.key.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      for (var row = 0; row < 3; row++) ...[
                        if (row > 0) const SizedBox(height: 4),
                        Row(
                          children: [
                            for (var col = 0; col < 4; col++) ...[
                              if (col > 0) const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: (row == 2 && col == 3)
                                        ? skin.accent
                                        : skin.key,
                                    borderRadius: BorderRadius.circular(3.5),
                                    border: Border.all(
                                      color: skin.divider,
                                      width: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      skin.nameBn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bengali(size: 12, weight: FontWeight.w600),
                    ),
                  ),
                  if (widget.selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: BornoColors.lime,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                skin.nameEn.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 7.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: BornoColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _Swatch(color: skin.accent),
                  const SizedBox(width: 3),
                  _Swatch(color: skin.key),
                  const SizedBox(width: 3),
                  _Swatch(color: skin.bubbleIn, border: skin.divider),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, this.border});

  final Color color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: border ?? const Color(0x22FFFFFF)),
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({
    required this.soundOn,
    required this.hapticsOn,
    required this.previewOn,
  });

  final bool soundOn;
  final bool hapticsOn;
  final bool previewOn;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late bool _soundOn = widget.soundOn;
  late bool _hapticsOn = widget.hapticsOn;
  late bool _previewOn = widget.previewOn;

  void _testFeedback() {
    if (_soundOn) PlatformService.clickSound();
    if (_hapticsOn) PlatformService.haptic();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHeader(
            eyebrow: 'Feel & feedback',
            title: 'কীবোর্ড সেটিংস',
            description: 'আপনার টাইপিং যেন হাতে গেঁথে থাকে—ঠিক যেমন চান।',
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0x05FFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x14FFFFFF)),
                    ),
                    child: Column(
                      children: [
                        _SettingRow(
                          icon: Icons.volume_up_rounded,
                          title: 'সফট ক্লিক সাউন্ড',
                          subtitle: 'প্রতিটি কী ট্যাপে হালকা, মিষ্টি ক্লিক',
                          value: _soundOn,
                          onChanged: (value) =>
                              setState(() => _soundOn = value),
                        ),
                        _RowDivider(),
                        _SettingRow(
                          icon: Icons.vibration_rounded,
                          title: 'হ্যাপটিক ফিডব্যাক',
                          subtitle: 'হালকা ভাইব্রেশন, চোখ না তুলেই বুঝবেন',
                          value: _hapticsOn,
                          onChanged: (value) =>
                              setState(() => _hapticsOn = value),
                        ),
                        _RowDivider(),
                        _SettingRow(
                          icon: Icons.zoom_in_rounded,
                          title: 'কী প্রিভিউ জুম',
                          subtitle:
                              'কী চাপলে বড় প্রিভিউ আর স্প্রিং অ্যানিমেশন',
                          value: _previewOn,
                          onChanged: (value) =>
                              setState(() => _previewOn = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: BornoColors.lime.withValues(alpha: 0.055),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BornoColors.lime.withValues(alpha: 0.17),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: BornoColors.lime.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 17,
                            color: BornoColors.lime,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'আপনার লেখা শুধু আপনারই',
                                style: TextStyle(
                                  fontFamily: 'HindSiliguri',
                                  fontSize: 12.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: BornoColors.text,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'কীবোর্ড ও সাজেশন সম্পূর্ণ লোকাল। কোনো কী-লগ নেই, কোনো ট্র্যাকিং নেই।',
                                style: TextStyle(
                                  fontFamily: 'HindSiliguri',
                                  fontSize: 10.2,
                                  height: 1.45,
                                  color: BornoColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.mic_none_rounded,
                        size: 13,
                        color: BornoColors.muted,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ভয়েস ইনপুট আপনার ব্রাউজার বা ডিভাইসের স্পিচ ইঞ্জিনে চলে। অন-ডিভাইস বাংলা স্পিচ প্যাক থাকলে ইন্টারনেট ছাড়াও ব্যবহার করা যায়।',
                          style: TextStyle(
                            fontFamily: 'HindSiliguri',
                            fontSize: 9.8,
                            height: 1.45,
                            color: BornoColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_soundOn || _hapticsOn)
                              ? _testFeedback
                              : null,
                          icon: const Icon(Icons.graphic_eq_rounded, size: 16),
                          label: const Text('ফিডব্যাক টেস্ট'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BornoColors.text,
                            minimumSize: const Size(0, 48),
                            side: const BorderSide(color: Color(0x26FFFFFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'HindSiliguri',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(
                            FeedbackSettings(
                              soundOn: _soundOn,
                              hapticsOn: _hapticsOn,
                              previewOn: _previewOn,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: BornoColors.lime,
                            foregroundColor: BornoColors.onLime,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'HindSiliguri',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('সেভ করুন'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 52, color: Color(0x12FFFFFF));
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: BornoColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: bengali(
                        size: 13,
                        weight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: bengali(
                        size: 10.2,
                        weight: FontWeight.w400,
                        color: BornoColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SoftSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftSwitch extends StatelessWidget {
  const _SoftSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 24,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? BornoColors.lime : const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? BornoColors.onLime : BornoColors.muted,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
