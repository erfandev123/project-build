import 'package:flutter/material.dart';

import '../theme/borno_theme.dart';

class BornoMark extends StatelessWidget {
  const BornoMark({
    super.key,
    this.size = 40,
    this.radiusFactor = 0.28,
    this.showDot = true,
  });

  final double size;
  final double radiusFactor;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Borno',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * radiusFactor),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE1FF9A), BornoColors.lime],
          ),
          boxShadow: [
            BoxShadow(
              color: BornoColors.lime.withValues(alpha: 0.12),
              blurRadius: size * 0.6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, -size * 0.025),
              child: Text(
                'ব',
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: size * 0.62,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: BornoColors.onLime,
                ),
              ),
            ),
            if (showDot)
              Positioned(
                right: size * 0.16,
                bottom: size * 0.16,
                child: Container(
                  width: size * 0.085,
                  height: size * 0.085,
                  decoration: const BoxDecoration(
                    color: BornoColors.onLime,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = true,
    this.compact = false,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool primary;
  final bool compact;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 44.0 : 54.0;
    final foreground = widget.primary ? BornoColors.onLime : BornoColors.text;

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.018 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: height,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 18 : 22,
                ),
                decoration: BoxDecoration(
                  color: widget.primary
                      ? (_hovered ? BornoColors.limeSoft : BornoColors.lime)
                      : (_hovered
                            ? const Color(0x14FFFFFF)
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(14),
                  border: widget.primary
                      ? null
                      : Border.all(
                          color: _hovered
                              ? const Color(0x45FFFFFF)
                              : const Color(0x24FFFFFF),
                        ),
                  boxShadow: widget.primary
                      ? [
                          BoxShadow(
                            color: BornoColors.lime.withValues(alpha: 0.16),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: widget.compact ? 17 : 19,
                        color: foreground,
                      ),
                      SizedBox(width: widget.compact ? 8 : 10),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: widget.compact ? 14 : 15.5,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ),
                    if (widget.trailingIcon != null) ...[
                      const SizedBox(width: 9),
                      Icon(
                        widget.trailingIcon,
                        size: widget.compact ? 16 : 18,
                        color: foreground.withValues(alpha: 0.8),
                      ),
                    ],
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

class OutlinePill extends StatelessWidget {
  const OutlinePill({
    super.key,
    required this.label,
    this.icon,
    this.dotColor = BornoColors.lime,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color dotColor;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x1CFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 13, color: BornoColors.muted)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.45),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: BornoColors.textSoft,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}

class MiniKeycap extends StatelessWidget {
  const MiniKeycap({
    super.key,
    required this.label,
    this.size = 34,
    this.background = const Color(0xFF223027),
    this.foreground = const Color(0xFFF7F4EA),
    this.borderColor,
    this.borderRadius = 9,
    this.fontFamily = 'HindSiliguri',
    this.fontSize,
    this.boxShadow,
  });

  final String label;
  final double size;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final double borderRadius;
  final String fontFamily;
  final double? fontSize;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? const Color(0x10FFFFFF)),
        boxShadow: boxShadow,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize ?? size * 0.42,
          height: 1,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class SectionEyebrow extends StatelessWidget {
  const SectionEyebrow({
    super.key,
    required this.text,
    this.icon,
    this.color = BornoColors.lime,
  });

  final String text;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 7),
        ] else ...[
          Container(width: 16, height: 1, color: color.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
        ],
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10.5,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.7,
            color: color,
          ),
        ),
      ],
    );
  }
}

void showBornoToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      ),
    );
}
