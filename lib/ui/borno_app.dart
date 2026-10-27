import 'package:flutter/material.dart';

import '../theme/borno_theme.dart';
import 'home_page.dart';

class BornoApp extends StatelessWidget {
  const BornoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Borno — বাংলা লেখা, নিজের ছন্দে',
      debugShowCheckedModeBanner: false,
      theme: buildBornoTheme(),
      scrollBehavior: const _BornoScrollBehavior(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scaled = media.textScaler.scale(1).clamp(0.9, 1.22);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scaled)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomePage(),
    );
  }
}

class _BornoScrollBehavior extends ScrollBehavior {
  const _BornoScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
