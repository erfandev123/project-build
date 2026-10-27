import 'package:flutter/material.dart';

import '../platform/platform_service.dart';
import '../theme/borno_theme.dart';
import 'install_help.dart';
import 'keyboard_demo.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _demoKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _offlineKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      alignment: 0.035,
    );
  }

  void _scrollTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 640),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _install() => installBorno(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BornoColors.page,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Atmosphere(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(
                  onHome: _scrollTop,
                  onDemo: () => _scrollTo(_demoKey),
                  onFeatures: () => _scrollTo(_featuresKey),
                  onOffline: () => _scrollTo(_offlineKey),
                  onInstall: _install,
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          _HeroSection(
                            demoKey: _demoKey,
                            onStart: () => _scrollTo(_demoKey),
                            onFeatures: () => _scrollTo(_featuresKey),
                          ),
                          _FeatureSection(key: _featuresKey),
                          _OfflineSection(
                            key: _offlineKey,
                            onInstall: _install,
                          ),
                          _Footer(
                            onTop: _scrollTop,
                            onDemo: () => _scrollTo(_demoKey),
                            onFeatures: () => _scrollTo(_featuresKey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageWidth extends StatelessWidget {
  const _PageWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 28),
          child: child,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onHome,
    required this.onDemo,
    required this.onFeatures,
    required this.onOffline,
    required this.onInstall,
  });

  final VoidCallback onHome;
  final VoidCallback onDemo;
  final VoidCallback onFeatures;
  final VoidCallback onOffline;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showNav = width >= 880;
    final showTagline = width >= 470;
    final installed = PlatformService.pwaStandalone;

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xF207110C),
        border: Border(bottom: BorderSide(color: BornoColors.lineSoft)),
      ),
      child: _PageWidth(
        child: Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onHome,
                child: Semantics(
                  button: true,
                  label: 'Borno হোম',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BornoMark(size: 34, radiusFactor: 0.29),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Borno',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 18,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: BornoColors.text,
                            ),
                          ),
                          if (showTagline) ...[
                            const SizedBox(height: 3),
                            const Text(
                              'বাংলা কী-বোর্ড',
                              style: TextStyle(
                                fontFamily: 'HindSiliguri',
                                fontSize: 9,
                                height: 1.1,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                                color: BornoColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showTagline) ...[
              const SizedBox(width: 18),
              Container(width: 1, height: 22, color: BornoColors.lineSoft),
              const SizedBox(width: 16),
              const Text(
                'টাইপিং, নরম করে ভালো',
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 10.5,
                  height: 1.2,
                  fontWeight: FontWeight.w400,
                  color: BornoColors.mutedDeep,
                ),
              ),
            ],
            const Spacer(),
            if (showNav) ...[
              _NavLink(label: 'লাইভ ডেমো', onTap: onDemo),
              const SizedBox(width: 4),
              _NavLink(label: 'ফিচার', onTap: onFeatures),
              const SizedBox(width: 4),
              _NavLink(label: 'অফলাইন', onTap: onOffline),
              const SizedBox(width: 18),
            ],
            _HeaderInstallButton(
              installed: installed,
              onTap: onInstall,
              compact: width < 420,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          label: widget.label,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: _hovered ? BornoColors.text : BornoColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: _hovered ? 14 : 0,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: BornoColors.lime,
                    borderRadius: BorderRadius.circular(99),
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

class _HeaderInstallButton extends StatefulWidget {
  const _HeaderInstallButton({
    required this.installed,
    required this.onTap,
    required this.compact,
  });

  final bool installed;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_HeaderInstallButton> createState() => _HeaderInstallButtonState();
}

class _HeaderInstallButtonState extends State<_HeaderInstallButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          label: widget.installed
              ? 'Borno ইনস্টল করা আছে'
              : 'Borno ইনস্টল করুন',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 38,
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 11 : 14),
            decoration: BoxDecoration(
              color: _hovered ? BornoColors.limeSoft : BornoColors.lime,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: BornoColors.lime.withValues(
                    alpha: _hovered ? 0.2 : 0.1,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.installed
                      ? Icons.check_rounded
                      : Icons.download_rounded,
                  size: 15,
                  color: BornoColors.onLime,
                ),
                if (!widget.compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.installed ? 'ইনস্টলড' : 'ইনস্টল',
                    style: const TextStyle(
                      fontFamily: 'HindSiliguri',
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: BornoColors.onLime,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.demoKey,
    required this.onStart,
    required this.onFeatures,
  });

  final GlobalKey demoKey;
  final VoidCallback onStart;
  final VoidCallback onFeatures;

  @override
  Widget build(BuildContext context) {
    return _PageWidth(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          return Padding(
            padding: EdgeInsets.fromLTRB(0, wide ? 54 : 38, 0, wide ? 76 : 56),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Reveal(
                          child: _HeroCopy(
                            onStart: onStart,
                            onFeatures: onFeatures,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                      SizedBox(
                        width: 410,
                        child: KeyedSubtree(
                          key: demoKey,
                          child: _Reveal(
                            delay: const Duration(milliseconds: 120),
                            child: const KeyboardDemo(phoneHeight: 770),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _Reveal(
                        child: _HeroCopy(
                          onStart: onStart,
                          onFeatures: onFeatures,
                        ),
                      ),
                      const SizedBox(height: 30),
                      KeyedSubtree(
                        key: demoKey,
                        child: Column(
                          children: [
                            const _DemoCaption(),
                            const SizedBox(height: 14),
                            _Reveal(
                              delay: const Duration(milliseconds: 90),
                              child: const KeyboardDemo(phoneHeight: 750),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onStart, required this.onFeatures});

  final VoidCallback onStart;
  final VoidCallback onFeatures;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleSize = constraints.maxWidth > 620
            ? 62.0
            : (constraints.maxWidth > 430 ? 50.0 : 38.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeroBadge(),
            const SizedBox(height: 22),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'বাংলায় লিখুন,\n'),
                  const TextSpan(text: 'নিজের '),
                  TextSpan(
                    text: 'ছন্দে।',
                    style: TextStyle(
                      color: BornoColors.lime,
                      shadows: [
                        Shadow(
                          color: BornoColors.lime.withValues(alpha: 0.18),
                          blurRadius: 32,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              style: bengali(
                size: titleSize,
                weight: FontWeight.w700,
                height: 1.16,
                color: BornoColors.text,
              ).copyWith(letterSpacing: -0.4),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Text(
                'Ridmik-স্টাইল ফোনেটিক বাংলা, পূর্ণ বর্ণমালা আর English—সব একটাই কীবোর্ডে। নরম ক্লিক, ঝলমলে কী-প্রিভিউ আর শূন্য ল্যাগের টাইপিং।',
                style: bengali(
                  size: constraints.maxWidth > 520 ? 15.5 : 13.5,
                  weight: FontWeight.w400,
                  color: BornoColors.muted,
                  height: 1.75,
                ),
              ),
            ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionButton(
                  label: 'এখনই টাইপ করুন',
                  icon: Icons.keyboard_alt_outlined,
                  trailingIcon: Icons.arrow_downward_rounded,
                  onPressed: onStart,
                ),
                ActionButton(
                  label: 'ফিচার দেখুন',
                  icon: Icons.auto_awesome_outlined,
                  primary: false,
                  onPressed: onFeatures,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _HeroStat(icon: Icons.grid_view_rounded, label: '৩টি লেআউট'),
                _HeroStat(icon: Icons.palette_outlined, label: '৪টি থিম'),
                _HeroStat(icon: Icons.wifi_off_rounded, label: '১০০% অফলাইন'),
              ],
            ),
            const SizedBox(height: 15),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mic_none_rounded, size: 14, color: BornoColors.lime),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'ভয়েস দিয়ে বাংলা লিখুন · ডেস্কটপে সরাসরি টাইপ করুন',
                    style: TextStyle(
                      fontFamily: 'HindSiliguri',
                      fontSize: 10.5,
                      height: 1.5,
                      color: BornoColors.mutedDeep,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: BornoColors.lime,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'নতুন',
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 9.5,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: BornoColors.onLime,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              compact ? 'ভয়েস ও অফলাইন' : 'বাংলা ভয়েস + সম্পূর্ণ অফলাইন',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: BornoColors.textSoft,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: BornoColors.lime,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BornoColors.lime.withValues(alpha: 0.45),
                  blurRadius: 7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: BornoColors.mutedDeep),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 10.5,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: BornoColors.muted,
          ),
        ),
      ],
    );
  }
}

class _DemoCaption extends StatelessWidget {
  const _DemoCaption();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!compact) ...[
              Container(width: 30, height: 1, color: BornoColors.line),
              const SizedBox(width: 10),
            ],
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: BornoColors.lime,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BornoColors.lime.withValues(alpha: 0.45),
                    blurRadius: 7,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'লাইভ ডেমো · কী চেপে দেখুন',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 10.5,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: BornoColors.muted,
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 10),
              Container(width: 30, height: 1, color: BornoColors.line),
            ],
          ],
        );
      },
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BornoColors.lineSoft)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x05000000), Color(0x0A0E1B13)],
        ),
      ),
      child: _PageWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 66),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionEyebrow(text: 'যা আছে ভেতরে'),
                      const SizedBox(height: 14),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'ছোট্ট কীবোর্ড,\n'),
                            TextSpan(
                              text: 'বড় একটু যত্ন।',
                              style: TextStyle(color: BornoColors.lime),
                            ),
                          ],
                        ),
                        style: bengali(
                          size: wide ? 36 : 30,
                          weight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  );
                  final paragraph = ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      'প্রতিটি কী, প্রতিটি শব্দ আর প্রতিটি ফিডব্যাক—বাংলা লেখার জন্যই বানানো। কোনো বাড়তি জিনিস নেই, শুধু নরম আর দ্রুত।',
                      style: bengali(
                        size: 12,
                        weight: FontWeight.w400,
                        color: BornoColors.muted,
                        height: 1.7,
                      ),
                    ),
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: heading),
                        const SizedBox(width: 36),
                        paragraph,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading, const SizedBox(height: 15), paragraph],
                  );
                },
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 955
                      ? 3
                      : (constraints.maxWidth >= 620 ? 2 : 1);
                  final features = _features();
                  final rows = <Widget>[];
                  for (
                    var start = 0;
                    start < features.length;
                    start += columns
                  ) {
                    final end = start + columns > features.length
                        ? features.length
                        : start + columns;
                    final row = features.sublist(start, end);
                    rows.add(
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < columns; i++) ...[
                              if (i > 0) const SizedBox(width: 13),
                              Expanded(
                                child: i < row.length
                                    ? _FeatureCard(feature: row[i])
                                    : const SizedBox(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                    if (end < features.length) {
                      rows.add(const SizedBox(height: 13));
                    }
                  }
                  return Column(children: rows);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_FeatureData> _features() {
    return [
      const _FeatureData(
        icon: Icons.translate_rounded,
        tag: 'RIDMIK STYLE',
        title: 'বাংলিশেই বাংলা',
        description: 'ami → আমি, kemon acho → কেমন আছো। চেনা ইংরেজি অক্ষরে লিখুন, সাথে সাথে বাংলা হয়ে যাবে।',
        visual: _PhoneticVisual(),
      ),
      const _FeatureData(
        icon: Icons.sort_by_alpha_rounded,
        tag: 'FULL ALPHABET',
        title: 'পূর্ণ বর্ণমালা',
        description: 'অ থেকে ঔ, ক থেকে হ—সব বর্ণ, কার-চিহ্ন, যুক্তাক্ষর আর আলাদা Shift স্তরসহ।',
        visual: _AlphabetVisual(),
      ),
      const _FeatureData(
        icon: Icons.graphic_eq_rounded,
        tag: 'SMOOTH FEEDBACK',
        title: 'নরম, দ্রুত স্পর্শ',
        description: 'WebAudio-তে তৈরি মিষ্টি ক্লিক, হালকা ভাইব্রেশন আর কী-প্রিভিউ জুম—সবই সাথে সাথে।',
        visual: _FeedbackVisual(),
      ),
      const _FeatureData(
        icon: Icons.wifi_off_rounded,
        tag: 'OFFLINE FIRST',
        title: 'নেট ছাড়াই চলে',
        description: 'প্রথম লোডের পর কীবোর্ড, সাজেশন আর থিম সম্পূর্ণ ডিভাইসে থাকে। কোনো সার্ভার লাগে না।',
        visual: _OfflineVisual(),
      ),
      const _FeatureData(
        icon: Icons.mic_none_rounded,
        tag: 'BANGLA VOICE',
        title: 'বাংলা ভয়েস',
        description: 'মাইকে বাংলায় বলুন। ব্রাউজারের স্পিচ ইঞ্জিন কথাকে সরাসরি লেখায় বদলে দেবে।',
        visual: _VoiceVisual(),
      ),
      const _FeatureData(
        icon: Icons.palette_outlined,
        tag: 'FOUR MOODS',
        title: 'চারটি মুড',
        description: 'মিডনাইট, ক্রিম, লেগুন আর ব্লসম—থিম বদলালে কীবোর্ড, চ্যাট আর ক্লিকের গ্লোও বদলায়।',
        visual: _ThemesVisual(),
      ),
    ];
  }
}

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.tag,
    required this.title,
    required this.description,
    required this.visual,
  });

  final IconData icon;
  final String tag;
  final String title;
  final String description;
  final Widget visual;
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature});

  final _FeatureData feature;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2.5 : 0, 0),
        padding: const EdgeInsets.fromLTRB(19, 18, 19, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _hovered
                ? [const Color(0xFF17251C), const Color(0xFF0D1711)]
                : [BornoColors.panelRaised, BornoColors.panel],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? BornoColors.lime.withValues(alpha: 0.26)
                : BornoColors.line,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: BornoColors.lime.withValues(alpha: 0.085),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: BornoColors.lime.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(
                        widget.feature.icon,
                        size: 17,
                        color: BornoColors.lime,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.feature.tag,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 7.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.05,
                        color: BornoColors.mutedDeep,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  widget.feature.title,
                  style: bengali(
                    size: 18,
                    weight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.feature.description,
                  style: bengali(
                    size: 11.2,
                    weight: FontWeight.w400,
                    color: BornoColors.muted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Container(
                height: 78,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x05FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x10FFFFFF)),
                ),
                child: widget.feature.visual,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualKey extends StatelessWidget {
  const _VisualKey({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF223027),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          height: 1,
          fontWeight: FontWeight.w600,
          color: BornoColors.textSoft,
        ),
      ),
    );
  }
}

class _PhoneticVisual extends StatelessWidget {
  const _PhoneticVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _VisualKey(label: ['a', 'm', 'i'][i]),
        ],
        const SizedBox(width: 9),
        const Icon(
          Icons.arrow_forward_rounded,
          size: 14,
          color: BornoColors.mutedDeep,
        ),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: BornoColors.lime.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BornoColors.lime.withValues(alpha: 0.26)),
          ),
          child: Text(
            'আমি',
            style: bengali(
              size: 16,
              weight: FontWeight.w600,
              color: BornoColors.lime,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlphabetVisual extends StatelessWidget {
  const _AlphabetVisual();

  @override
  Widget build(BuildContext context) {
    const letters = ['অ', 'আ', 'ক', 'খ', 'গ', 'ত', 'ন', 'ম'];
    return Row(
      children: [
        for (var i = 0; i < letters.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == 2
                    ? BornoColors.sky.withValues(alpha: 0.12)
                    : const Color(0xFF223027),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: i == 2
                      ? BornoColors.sky.withValues(alpha: 0.28)
                      : const Color(0x12FFFFFF),
                ),
              ),
              child: Text(
                letters[i],
                style: TextStyle(
                  fontFamily: 'NotoBengali',
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: i == 2 ? BornoColors.sky : BornoColors.textSoft,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeedbackVisual extends StatelessWidget {
  const _FeedbackVisual();

  @override
  Widget build(BuildContext context) {
    const heights = [9.0, 18.0, 13.0, 26.0, 17.0, 23.0, 11.0, 20.0, 14.0];
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF304235), Color(0xFF223027)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x22FFFFFF)),
            boxShadow: [
              BoxShadow(
                color: BornoColors.lime.withValues(alpha: 0.1),
                blurRadius: 16,
              ),
            ],
          ),
          child: Text(
            'ক',
            style: bengali(
              size: 22,
              weight: FontWeight.w600,
              color: BornoColors.text,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < heights.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Container(
                width: 3,
                height: heights[i],
                decoration: BoxDecoration(
                  color: BornoColors.orange.withValues(
                    alpha: 0.35 + (heights[i] / 26) * 0.55,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: BornoColors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: BornoColors.orange.withValues(alpha: 0.2),
            ),
          ),
          child: const Text(
            '৮ms',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 8,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: BornoColors.orange,
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineVisual extends StatelessWidget {
  const _OfflineVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: BornoColors.lime.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BornoColors.lime.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BornoColors.lime.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 15,
              color: BornoColors.lime,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'অফলাইন রেডি',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 11.5,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: BornoColors.text,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'কীবোর্ড · সাজেশন · থিম',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 8.5,
                    height: 1.2,
                    color: BornoColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: BornoColors.lime.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

class _VoiceVisual extends StatelessWidget {
  const _VoiceVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BornoColors.rose.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: BornoColors.rose.withValues(alpha: 0.24)),
          ),
          child: const Icon(
            Icons.mic_rounded,
            size: 19,
            color: BornoColors.rose,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(9),
                bottomLeft: Radius.circular(9),
                bottomRight: Radius.circular(9),
              ),
              border: Border.all(color: const Color(0x12FFFFFF)),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '“আমি বাংলায় বলি”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bengali(
                      size: 10.5,
                      weight: FontWeight.w500,
                      color: BornoColors.textSoft,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Container(
                    width: 2.5,
                    height: [8.0, 14.0, 10.0, 6.0][i],
                    decoration: BoxDecoration(
                      color: BornoColors.rose.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemesVisual extends StatelessWidget {
  const _ThemesVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < keyboardSkins.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: keyboardSkins[i].keyboard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: i == 0
                      ? BornoColors.lime.withValues(alpha: 0.6)
                      : const Color(0x14FFFFFF),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var col = 0; col < 3; col++) ...[
                        if (col > 0) const SizedBox(width: 3),
                        Expanded(
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              color: col == 2
                                  ? keyboardSkins[i].accent
                                  : keyboardSkins[i].key,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var col = 0; col < 4; col++) ...[
                        if (col > 0) const SizedBox(width: 3),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: keyboardSkins[i].key.withValues(
                                alpha: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: keyboardSkins[i].bubbleOut,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OfflineSection extends StatelessWidget {
  const _OfflineSection({super.key, required this.onInstall});

  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return _PageWidth(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 66),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF14251A), Color(0xFF0B1610)],
            ),
            border: Border.all(color: BornoColors.lime.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: BornoColors.lime.withValues(alpha: 0.035),
                blurRadius: 80,
                spreadRadius: 20,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: -100,
                  top: -120,
                  child: IgnorePointer(
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            BornoColors.lime.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 860;
                      final copy = _OfflineCopy(onInstall: onInstall);
                      final preview = _OfflinePreview(onInstall: onInstall);
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 11, child: copy),
                            const SizedBox(width: 44),
                            Expanded(flex: 9, child: Center(child: preview)),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          copy,
                          const SizedBox(height: 28),
                          Center(child: preview),
                        ],
                      );
                    },
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

class _OfflineCopy extends StatelessWidget {
  const _OfflineCopy({required this.onInstall});

  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionEyebrow(
          text: 'Offline first',
          icon: Icons.wifi_off_rounded,
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'নেট নেই?\n'),
              TextSpan(
                text: 'তবুও লিখুন।',
                style: TextStyle(color: BornoColors.lime),
              ),
            ],
          ),
          style: bengali(size: 34, weight: FontWeight.w700, height: 1.28),
        ),
        const SizedBox(height: 13),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Text(
            'Borno একবার লোড হলেই কীবোর্ড, শব্দভান্ডার আর থিম আপনার ডিভাইসে থেকে যায়। বিমানে, মেট্রোতে বা নেট খারাপের দিনেও বাংলা থামে না।',
            style: bengali(
              size: 12,
              weight: FontWeight.w400,
              color: BornoColors.muted,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _OfflinePoint('কীবোর্ড ইঞ্জিন ও সাজেশন সম্পূর্ণ ডিভাইসে'),
        const _OfflinePoint('প্রথম লোডের পর PWA হিসেবে অফলাইন'),
        const _OfflinePoint('কোনো কী-লগ, ট্র্যাকিং বা বিজ্ঞাপন নেই'),
        const _OfflinePoint('হোম স্ক্রিনে ইনস্টল করে অ্যাপের মতো খুলুন'),
        const SizedBox(height: 21),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionButton(
              label: 'Borno ইনস্টল করুন',
              icon: Icons.download_rounded,
              onPressed: onInstall,
            ),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_iphone_rounded,
                  size: 13,
                  color: BornoColors.mutedDeep,
                ),
                SizedBox(width: 5),
                Text(
                  'Chrome · Edge · Safari',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    height: 1.2,
                    color: BornoColors.mutedDeep,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'ওয়েব অ্যাপ হিসেবে ইনস্টল · আলাদা অ্যাপ স্টোর ডাউনলোড নেই',
          style: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 9.5,
            height: 1.45,
            color: BornoColors.mutedDeep,
          ),
        ),
      ],
    );
  }
}

class _OfflinePoint extends StatelessWidget {
  const _OfflinePoint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: BornoColors.lime,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: bengali(
                size: 11.5,
                weight: FontWeight.w400,
                color: BornoColors.textSoft,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflinePreview extends StatelessWidget {
  const _OfflinePreview({required this.onInstall});

  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A140E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x19FFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 9),
              child: Row(
                children: [
                  for (final color in [
                    Color(0x33FFFFFF),
                    Color(0x22FFFFFF),
                    Color(0x14FFFFFF),
                  ]) ...[
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const SizedBox(width: 7),
                  Expanded(
                    child: Container(
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x08FFFFFF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0x10FFFFFF)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 10,
                            color: BornoColors.mutedDeep,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Borno · অফলাইন',
                            style: TextStyle(
                              fontFamily: 'HindSiliguri',
                              fontSize: 8.5,
                              height: 1.2,
                              color: BornoColors.mutedDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF17251C), Color(0xFF0E1712)],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const BornoMark(size: 44, radiusFactor: 0.27),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Borno',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 16,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: BornoColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'বাংলা লেখা, নিজের ছন্দে',
                              style: bengali(
                                size: 9.5,
                                weight: FontWeight.w400,
                                color: BornoColors.muted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Borno ইনস্টল করুন',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onInstall,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: BornoColors.lime,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 12,
                                    color: BornoColors.onLime,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'ইনস্টল',
                                    style: TextStyle(
                                      fontFamily: 'HindSiliguri',
                                      fontSize: 9.5,
                                      height: 1.1,
                                      fontWeight: FontWeight.w700,
                                      color: BornoColors.onLime,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Container(height: 1, color: const Color(0x12FFFFFF)),
                  const SizedBox(height: 10),
                  const _PreviewRow(
                    icon: Icons.keyboard_alt_outlined,
                    label: 'কীবোর্ড ও সাজেশন',
                    status: 'লোকাল',
                  ),
                  const SizedBox(height: 7),
                  const _PreviewRow(
                    icon: Icons.palette_outlined,
                    label: 'চারটি থিম',
                    status: 'লোকাল',
                  ),
                  const SizedBox(height: 7),
                  const _PreviewRow(
                    icon: Icons.shield_outlined,
                    label: 'আপনার লেখা',
                    status: 'প্রাইভেট',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: BornoColors.lime.withValues(alpha: 0.065),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: BornoColors.lime.withValues(alpha: 0.14),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.offline_bolt_rounded,
                          size: 13,
                          color: BornoColors.lime,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'প্রথম লোডের পর · অফলাইন প্রস্তুত',
                            style: TextStyle(
                              fontFamily: 'HindSiliguri',
                              fontSize: 8.8,
                              height: 1.3,
                              color: BornoColors.limeSoft,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: BornoColors.lime,
                        ),
                      ],
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

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: BornoColors.mutedDeep),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 9.5,
              height: 1.2,
              color: BornoColors.muted,
            ),
          ),
        ),
        Text(
          status,
          style: const TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 8.5,
            height: 1.2,
            color: BornoColors.mutedDeep,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onTop,
    required this.onDemo,
    required this.onFeatures,
  });

  final VoidCallback onTop;
  final VoidCallback onDemo;
  final VoidCallback onFeatures;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BornoColors.lineSoft)),
      ),
      child: _PageWidth(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            30,
            0,
            28 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (width >= 720)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const BornoMark(size: 30, radiusFactor: 0.3),
                    const SizedBox(width: 9),
                    const Text(
                      'Borno',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: BornoColors.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 16,
                      color: BornoColors.lineSoft,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ভালো বাংলা লেখার ছোট্ট চেষ্টা।',
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 10.5,
                        height: 1.3,
                        color: BornoColors.mutedDeep,
                      ),
                    ),
                    const Spacer(),
                    _FooterLink(label: 'লাইভ ডেমো', onTap: onDemo),
                    _FooterLink(label: 'ফিচার', onTap: onFeatures),
                    _FooterLink(label: 'উপরে ফিরুন', onTap: onTop),
                  ],
                )
              else
                Row(
                  children: [
                    const BornoMark(size: 30, radiusFactor: 0.3),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'ভালো বাংলা লেখার ছোট্ট চেষ্টা।',
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 10.5,
                          height: 1.3,
                          color: BornoColors.mutedDeep,
                        ),
                      ),
                    ),
                    _FooterLink(label: 'উপরে', onTap: onTop),
                  ],
                ),
              const SizedBox(height: 24),
              Container(height: 1, color: const Color(0x0DFFFFFF)),
              const SizedBox(height: 18),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: BornoColors.mutedDeep,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Borno একটি ওয়েব ডেমো ও PWA—Android-এর সিস্টেম-ওয়াইড কীবোর্ড নয়। সিস্টেম IME হিসেবে ব্যবহার করতে আলাদা নেটিভ Android অ্যাপ প্রয়োজন। কীবোর্ড ইঞ্জিন, সাজেশন ও থিম সম্পূর্ণ লোকাল।',
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 9.5,
                        height: 1.55,
                        color: BornoColors.mutedDeep,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '© ${DateTime.now().year} Borno',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            height: 1.2,
                            color: BornoColors.mutedDeep,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 2,
                          decoration: const BoxDecoration(
                            color: BornoColors.mutedDeep,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Text(
                          'Made with Flutter',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            height: 1.2,
                            color: BornoColors.mutedDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x06FFFFFF),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0x12FFFFFF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 9,
                          color: BornoColors.mutedDeep,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PWA',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 7,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                            color: BornoColors.mutedDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: _hovered ? BornoColors.text : BornoColors.mutedDeep,
            ),
          ),
        ),
      ),
    );
  }
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF091710),
                  BornoColors.page,
                  BornoColors.pageDeep,
                ],
                stops: [0, 0.46, 1],
              ),
            ),
          ),
          const Positioned(
            top: -280,
            right: -190,
            child: _Glow(size: 700, color: Color(0x1ACEfa6d)),
          ),
          const Positioned(
            top: 430,
            left: -330,
            child: _Glow(size: 620, color: Color(0x0D79e6d8)),
          ),
          const Positioned(
            bottom: -260,
            right: -80,
            child: _Glow(size: 700, color: Color(0x0FCEfa6d)),
          ),
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          const Positioned(
            top: 190,
            right: 24,
            child: IgnorePointer(
              child: Text(
                'অ',
                style: TextStyle(
                  fontFamily: 'NotoBengali',
                  fontSize: 280,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0x05FFFFFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0, 1],
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 38.0;
    final paint = Paint()..color = const Color(0x08FFFFFF);
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 760) + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayedValue = delay == Duration.zero
            ? value
            : ((value * (760 + delay.inMilliseconds) - delay.inMilliseconds) /
                      760)
                  .clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(delayedValue);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - eased)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
