import 'package:flutter/material.dart';

class BornoColors {
  BornoColors._();

  static const page = Color(0xFF07110C);
  static const pageDeep = Color(0xFF050B08);
  static const panel = Color(0xFF0E1913);
  static const panelRaised = Color(0xFF142219);
  static const line = Color(0xFF223229);
  static const lineSoft = Color(0x14FFFFFF);
  static const text = Color(0xFFF5F2E8);
  static const textSoft = Color(0xFFD7DDD4);
  static const muted = Color(0xFF93A398);
  static const mutedDeep = Color(0xFF647368);
  static const lime = Color(0xFFCEFA6D);
  static const limeSoft = Color(0xFFDEFCA0);
  static const onLime = Color(0xFF0A150D);
  static const orange = Color(0xFFFF9E76);
  static const rose = Color(0xFFFFB4C6);
  static const sky = Color(0xFF87E8DC);
}

class KeyboardSkin {
  const KeyboardSkin({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.screen,
    required this.screenRaised,
    required this.keyboard,
    required this.keyboardDeep,
    required this.key,
    required this.keyPressed,
    required this.keyText,
    required this.keyHint,
    required this.actionKey,
    required this.actionText,
    required this.accent,
    required this.onAccent,
    required this.screenText,
    required this.muted,
    required this.divider,
    required this.bubbleIn,
    required this.bubbleInText,
    required this.bubbleOut,
    required this.bubbleOutText,
    required this.composer,
    required this.composerBorder,
    required this.isLight,
  });

  final String id;
  final String nameBn;
  final String nameEn;
  final Color screen;
  final Color screenRaised;
  final Color keyboard;
  final Color keyboardDeep;
  final Color key;
  final Color keyPressed;
  final Color keyText;
  final Color keyHint;
  final Color actionKey;
  final Color actionText;
  final Color accent;
  final Color onAccent;
  final Color screenText;
  final Color muted;
  final Color divider;
  final Color bubbleIn;
  final Color bubbleInText;
  final Color bubbleOut;
  final Color bubbleOutText;
  final Color composer;
  final Color composerBorder;
  final bool isLight;

  Color get keyboardText => keyText;
  Color get keyboardMuted => keyHint;
}

const midnightSkin = KeyboardSkin(
  id: 'midnight',
  nameBn: 'মিডনাইট',
  nameEn: 'Midnight',
  screen: Color(0xFF0B1510),
  screenRaised: Color(0xFF101D15),
  keyboard: Color(0xFF0E1812),
  keyboardDeep: Color(0xFF0A120D),
  key: Color(0xFF223027),
  keyPressed: Color(0xFF304235),
  keyText: Color(0xFFF7F4EA),
  keyHint: Color(0xFFA7C0AD),
  actionKey: Color(0xFF19261E),
  actionText: Color(0xFFE8E7DE),
  accent: Color(0xFFCEFA6D),
  onAccent: Color(0xFF0B150E),
  screenText: Color(0xFFF6F3E9),
  muted: Color(0xFF92A598),
  divider: Color(0x14FFFFFF),
  bubbleIn: Color(0xFF1C2A21),
  bubbleInText: Color(0xFFEFF2E9),
  bubbleOut: Color(0xFFCEFA6D),
  bubbleOutText: Color(0xFF0C160E),
  composer: Color(0xFF17231B),
  composerBorder: Color(0x1FFFFFFF),
  isLight: false,
);

const creamSkin = KeyboardSkin(
  id: 'cream',
  nameBn: 'ক্রিম',
  nameEn: 'Cream',
  screen: Color(0xFFF2EBDD),
  screenRaised: Color(0xFFFAF5EB),
  keyboard: Color(0xFFE7DECD),
  keyboardDeep: Color(0xFFDED3BF),
  key: Color(0xFFFCF8F0),
  keyPressed: Color(0xFFFFFFFF),
  keyText: Color(0xFF253229),
  keyHint: Color(0xFFB26542),
  actionKey: Color(0xFFD6CAB6),
  actionText: Color(0xFF2B392E),
  accent: Color(0xFFE86A42),
  onAccent: Color(0xFFFFFAF3),
  screenText: Color(0xFF243128),
  muted: Color(0xFF7D8378),
  divider: Color(0x1A1C2B21),
  bubbleIn: Color(0xFFE4D9C6),
  bubbleInText: Color(0xFF26342A),
  bubbleOut: Color(0xFF2D5A47),
  bubbleOutText: Color(0xFFFBF8F0),
  composer: Color(0xFFFBF6EC),
  composerBorder: Color(0x1F3A493D),
  isLight: true,
);

const lagoonSkin = KeyboardSkin(
  id: 'lagoon',
  nameBn: 'লেগুন',
  nameEn: 'Lagoon',
  screen: Color(0xFF06171D),
  screenRaised: Color(0xFF0B222A),
  keyboard: Color(0xFF081A21),
  keyboardDeep: Color(0xFF06131A),
  key: Color(0xFF12303A),
  keyPressed: Color(0xFF1B4550),
  keyText: Color(0xFFECFDFF),
  keyHint: Color(0xFF87DCD3),
  actionKey: Color(0xFF0E252D),
  actionText: Color(0xFFDDF8F8),
  accent: Color(0xFF79E6D8),
  onAccent: Color(0xFF05201F),
  screenText: Color(0xFFECFDFF),
  muted: Color(0xFF8FB5B8),
  divider: Color(0x16FFFFFF),
  bubbleIn: Color(0xFF11303A),
  bubbleInText: Color(0xFFE9FAFA),
  bubbleOut: Color(0xFF79E6D8),
  bubbleOutText: Color(0xFF05201F),
  composer: Color(0xFF0E252D),
  composerBorder: Color(0x24FFFFFF),
  isLight: false,
);

const roseSkin = KeyboardSkin(
  id: 'rose',
  nameBn: 'ব্লসম',
  nameEn: 'Blossom',
  screen: Color(0xFF1A1013),
  screenRaised: Color(0xFF23151A),
  keyboard: Color(0xFF1B1115),
  keyboardDeep: Color(0xFF140C0F),
  key: Color(0xFF342128),
  keyPressed: Color(0xFF483037),
  keyText: Color(0xFFFFF2F4),
  keyHint: Color(0xFFF1B9C5),
  actionKey: Color(0xFF28181E),
  actionText: Color(0xFFFFE8EC),
  accent: Color(0xFFFFA8BC),
  onAccent: Color(0xFF2A0F17),
  screenText: Color(0xFFFFF3F5),
  muted: Color(0xFFC8A6AE),
  divider: Color(0x18FFFFFF),
  bubbleIn: Color(0xFF322028),
  bubbleInText: Color(0xFFFFECEF),
  bubbleOut: Color(0xFFFFA8BC),
  bubbleOutText: Color(0xFF2A0F17),
  composer: Color(0xFF28181E),
  composerBorder: Color(0x26FFFFFF),
  isLight: false,
);

const List<KeyboardSkin> keyboardSkins = [
  midnightSkin,
  creamSkin,
  lagoonSkin,
  roseSkin,
];

ThemeData buildBornoTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'HindSiliguri',
    scaffoldBackgroundColor: BornoColors.page,
    colorScheme: const ColorScheme.dark(
      primary: BornoColors.lime,
      onPrimary: BornoColors.onLime,
      secondary: BornoColors.orange,
      surface: BornoColors.panel,
      onSurface: BornoColors.text,
      error: Color(0xFFFF8D80),
    ),
    splashFactory: NoSplash.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: BornoColors.text,
      displayColor: BornoColors.text,
    ),
    iconTheme: const IconThemeData(color: BornoColors.text, size: 20),
    dividerTheme: const DividerThemeData(
      color: BornoColors.lineSoft,
      thickness: 1,
      space: 1,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: BornoColors.panelRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BornoColors.line),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Manrope',
        color: BornoColors.text,
        fontSize: 12,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(const Color(0x337E9584)),
      radius: const Radius.circular(99),
      thickness: WidgetStateProperty.all(5),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
      modalBarrierColor: Color(0xB3050B08),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BornoColors.lime,
      contentTextStyle: const TextStyle(
        color: BornoColors.onLime,
        fontFamily: 'HindSiliguri',
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
    ),
  );
}

const TextStyle labelStyle = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.15,
  color: BornoColors.muted,
);

const TextStyle latinStyle = TextStyle(
  fontFamily: 'Manrope',
  color: BornoColors.text,
);

TextStyle bengali({
  double size = 16,
  FontWeight weight = FontWeight.w500,
  Color color = BornoColors.text,
  double height = 1.45,
}) {
  return TextStyle(
    fontFamily: 'HindSiliguri',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}
