import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../platform/platform_service.dart';
import '../theme/borno_theme.dart';

class BornoKey extends StatefulWidget {
  const BornoKey({
    super.key,
    required this.skin,
    required this.onTap,
    this.label,
    this.hint,
    this.icon,
    this.semanticLabel,
    this.previewText,
    this.height = 48,
    this.flex = 1,
    this.action = false,
    this.accent = false,
    this.selected = false,
    this.soundOn = true,
    this.hapticsOn = true,
    this.previewOn = true,
    this.onLongPress,
    this.repeatOnHold = false,
    this.emoji = false,
    this.fontSize,
    this.iconSize,
    this.choices = const <String>[],
    this.choiceStartIndex = 0,
    this.onChoiceSelected,
  });

  final KeyboardSkin skin;
  final String? label;
  final String? hint;
  final String? semanticLabel;
  final String? previewText;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool repeatOnHold;
  final bool action;
  final bool accent;
  final bool selected;
  final bool soundOn;
  final bool hapticsOn;
  final bool previewOn;
  final bool emoji;
  final double height;
  final int flex;
  final double? fontSize;
  final double? iconSize;

  /// Ordered choices for the touch-and-slide selection popup. When this has
  /// more than one entry and [onChoiceSelected] is provided, the key switches
  /// to the multi-character interaction instead of the simple key preview.
  final List<String> choices;

  /// The choice highlighted when the selection starts. Usually 0, or the
  /// Shift-layer primary inside the same ordered group.
  final int choiceStartIndex;

  final ValueChanged<String>? onChoiceSelected;

  @override
  State<BornoKey> createState() => _BornoKeyState();
}

class _BornoKeyState extends State<BornoKey> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _keyBoxKey = GlobalKey();
  Timer? _holdTimer;
  Timer? _repeatTimer;
  bool _pressed = false;
  bool _hovered = false;
  bool _skipNextTap = false;

  int? _choicePointer;
  Offset? _choiceStart;
  bool _choiceSelecting = false;
  bool _choiceCancelled = false;
  bool _choiceInserted = false;
  int _choiceIndex = 0;
  Rect _choiceKeyRect = Rect.zero;
  Rect _choicePopupRect = Rect.zero;
  double _choiceTileWidth = 46;
  double _choicePopupPadding = 6;
  double _choicePopupHeight = 62;

  @override
  void dispose() {
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
    if (_portal.isShowing) _portal.hide();
    super.dispose();
  }

  bool get _canPreview {
    if (!widget.previewOn) return false;
    if (widget.icon != null) return false;
    return (widget.previewText ?? widget.label ?? '').isNotEmpty;
  }

  bool get _isChoiceKey =>
      widget.choices.length > 1 && widget.onChoiceSelected != null;

  int get _initialChoiceIndex {
    final index = widget.choiceStartIndex;
    if (index < 0 || index >= widget.choices.length) return 0;
    return index;
  }

  Rect get _choiceValidRegion {
    final popup = _choicePopupRect;
    final key = _choiceKeyRect;
    return Rect.fromLTRB(
      math.min(popup.left, key.left) - 28,
      popup.top - 26,
      math.max(popup.right, key.right) + 28,
      key.bottom + 34,
    );
  }

  void _beginChoice(PointerDownEvent event) {
    if (!_isChoiceKey || _choicePointer != null) return;

    final keyBox = _keyBoxKey.currentContext?.findRenderObject();
    final overlayBox = Overlay.of(context).context.findRenderObject();
    if (keyBox is! RenderBox ||
        !keyBox.hasSize ||
        overlayBox is! RenderBox ||
        !overlayBox.hasSize) {
      return;
    }

    _choicePointer = event.pointer;
    _choiceStart = event.position;
    _choiceSelecting = true;
    _choiceCancelled = false;
    _choiceInserted = false;
    _choiceIndex = _initialChoiceIndex;

    final keyTopLeft = overlayBox.globalToLocal(
      keyBox.localToGlobal(Offset.zero),
    );
    final keyRect = keyTopLeft & keyBox.size;
    final screen = overlayBox.size;
    final count = widget.choices.length;
    final compact = screen.width < 360;
    final preferredTile = compact ? 40.0 : 46.0;
    final padding = compact ? 5.0 : 6.0;
    final popupHeight = compact ? 56.0 : 62.0;
    final maxWidth = math.max(120.0, screen.width - 16);
    final popupWidth = math.min(count * preferredTile + padding * 2, maxWidth);
    final tileWidth = (popupWidth - padding * 2) / count;

    // Keep the active character centred over the key when there is room.
    final activeCenter = padding + _choiceIndex * tileWidth + tileWidth / 2;
    final maxLeft = math.max(8.0, screen.width - popupWidth - 8);
    final left = (keyRect.center.dx - activeCenter)
        .clamp(8.0, maxLeft)
        .toDouble();

    final showAbove = keyRect.top >= popupHeight + 12;
    final desiredTop = showAbove
        ? keyRect.top - popupHeight - 8
        : keyRect.bottom + 8;
    final maxTop = math.max(8.0, screen.height - popupHeight - 8);
    final top = desiredTop.clamp(8.0, maxTop).toDouble();

    _choiceKeyRect = keyRect;
    _choicePopupRect = Rect.fromLTWH(left, top, popupWidth, popupHeight);
    _choiceTileWidth = tileWidth;
    _choicePopupPadding = padding;
    _choicePopupHeight = popupHeight;

    setState(() => _pressed = true);
    if (!_portal.isShowing) _portal.show();

    if (widget.soundOn) PlatformService.clickSound();
    if (widget.hapticsOn) PlatformService.haptic();
  }

  void _updateChoice(PointerMoveEvent event) {
    if (!_choiceSelecting || event.pointer != _choicePointer) return;
    if (_choiceCancelled || _choiceInserted) return;

    if (!_choiceValidRegion.contains(event.position)) {
      _cancelChoice();
      return;
    }

    final start = _choiceStart;
    if (start == null) return;
    final steps = ((event.position.dx - start.dx) / _choiceTileWidth).round();
    final next = math.max(
      0,
      math.min(widget.choices.length - 1, _initialChoiceIndex + steps),
    );
    if (next != _choiceIndex) {
      setState(() => _choiceIndex = next);
    }
  }

  void _endChoice(PointerUpEvent event) {
    if (event.pointer != _choicePointer) return;

    final shouldInsert =
        !_choiceCancelled &&
        !_choiceInserted &&
        _choiceValidRegion.contains(event.position);
    final selected = _choiceIndex;

    if (shouldInsert) _choiceInserted = true;
    _finishChoice();

    if (shouldInsert) {
      widget.onChoiceSelected?.call(widget.choices[selected]);
    }
  }

  void _cancelChoice([PointerCancelEvent? event]) {
    if (event != null && event.pointer != _choicePointer) return;
    if (!_choiceSelecting) return;
    _choiceCancelled = true;
    _finishChoice();
  }

  void _finishChoice() {
    if (_portal.isShowing) _portal.hide();
    _choicePointer = null;
    _choiceStart = null;
    _choiceSelecting = false;
    if (mounted && _pressed) {
      setState(() => _pressed = false);
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (_pressed) return;
    setState(() => _pressed = true);
    if (_canPreview && !_portal.isShowing) _portal.show();

    if (widget.soundOn) PlatformService.clickSound();
    if (widget.hapticsOn) PlatformService.haptic();

    if (widget.repeatOnHold) {
      _holdTimer?.cancel();
      _holdTimer = Timer(const Duration(milliseconds: 360), () {
        if (!_pressed) return;
        _skipNextTap = true;
        widget.onTap();
        _repeatTimer?.cancel();
        _repeatTimer = Timer.periodic(const Duration(milliseconds: 64), (_) {
          widget.onTap();
        });
      });
    }
  }

  void _endPress() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    if (_portal.isShowing) _portal.hide();
    if (mounted && _pressed) {
      setState(() => _pressed = false);
    }
  }

  void _handleTap() {
    if (_skipNextTap) {
      _skipNextTap = false;
      return;
    }
    widget.onTap();
  }

  void _handleLongPress() {
    if (!widget.previewOn && _portal.isShowing) _portal.hide();
    if (_portal.isShowing) _portal.hide();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final isAccent = widget.accent || widget.selected;
    final baseColor = isAccent
        ? skin.accent
        : (widget.action ? skin.actionKey : skin.key);
    final hoveredColor = Color.alphaBlend(
      (skin.isLight ? Colors.white : Colors.white).withValues(
        alpha: isAccent ? 0.06 : 0.05,
      ),
      baseColor,
    );
    final fill = _pressed
        ? skin.keyPressed
        : (_hovered ? hoveredColor : baseColor);
    final foreground = isAccent
        ? skin.onAccent
        : (widget.action ? skin.actionText : skin.keyText);
    final borderColor = isAccent
        ? skin.accent.withValues(alpha: 0.55)
        : (skin.isLight ? const Color(0x0F1A211B) : const Color(0x0DFFFFFF));
    final hintColor = isAccent
        ? skin.onAccent.withValues(alpha: 0.7)
        : skin.keyHint.withValues(alpha: 0.86);

    final keyVisual = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _pressed ? 0.91 : 1,
        duration: Duration(milliseconds: _pressed ? 65 : 140),
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: AnimatedContainer(
          key: _keyBoxKey,
          duration: const Duration(milliseconds: 110),
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(widget.action ? 9 : 8),
            border: Border.all(color: borderColor),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  Colors.white.withValues(alpha: skin.isLight ? 0.16 : 0.04),
                  fill,
                ),
                fill,
              ],
            ),
            boxShadow: _pressed
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: skin.isLight ? 0.08 : 0.14,
                      ),
                      blurRadius: 1.5,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
          ),
          child: _KeyFace(
            label: widget.label,
            hint: widget.hint,
            icon: widget.icon,
            foreground: foreground,
            hintColor: hintColor,
            emoji: widget.emoji,
            fontSize: widget.fontSize,
            iconSize: widget.iconSize,
          ),
        ),
      ),
    );

    final Widget child;
    if (_isChoiceKey) {
      child = Semantics(
        button: true,
        label: widget.semanticLabel ?? widget.label ?? 'কী',
        onTap: () =>
            widget.onChoiceSelected?.call(widget.choices[_initialChoiceIndex]),
        excludeSemantics: true,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _beginChoice,
          onPointerMove: _updateChoice,
          onPointerUp: _endChoice,
          onPointerCancel: _cancelChoice,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Claim horizontal drags so a parent list/browser cannot scroll
            // while the character strip is being scrubbed.
            onHorizontalDragStart: (_) {},
            onHorizontalDragUpdate: (_) {},
            child: keyVisual,
          ),
        ),
      );
    } else {
      child = Semantics(
        button: true,
        label: widget.semanticLabel ?? widget.label ?? widget.hint ?? 'কী',
        excludeSemantics: true,
        child: CompositedTransformTarget(
          link: _link,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _onTapDown,
            onTapUp: (_) => _endPress(),
            onTapCancel: _endPress,
            onTap: _handleTap,
            onLongPress: widget.onLongPress == null ? null : _handleLongPress,
            child: keyVisual,
          ),
        ),
      );
    }

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        if (_isChoiceKey) {
          final rect = _choicePopupRect;
          if (rect.isEmpty) return const SizedBox.shrink();
          return Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: IgnorePointer(
              child: _ChoicePopup(
                skin: skin,
                choices: widget.choices,
                selectedIndex: _choiceIndex,
                primaryIndex: _initialChoiceIndex,
                tileWidth: _choiceTileWidth,
                padding: _choicePopupPadding,
                height: _choicePopupHeight,
                emoji: widget.emoji,
              ),
            ),
          );
        }

        return IgnorePointer(
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -7),
            child: _KeyPreview(
              label: widget.previewText ?? widget.label ?? '',
              skin: skin,
              emoji: widget.emoji,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _KeyFace extends StatelessWidget {
  const _KeyFace({
    this.label,
    this.hint,
    this.icon,
    required this.foreground,
    required this.hintColor,
    required this.emoji,
    this.fontSize,
    this.iconSize,
  });

  final String? label;
  final String? hint;
  final IconData? icon;
  final Color foreground;
  final Color hintColor;
  final bool emoji;
  final double? fontSize;
  final double? iconSize;

  static final RegExp _bengali = RegExp(r'[\u0980-\u09FF]');
  static final RegExp _multiWide = RegExp(r'[\u0980-\u09FF]{2,}');

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Icon(icon, size: iconSize ?? 20, color: foreground);
    }
    final text = label ?? '';
    final isBengali = _bengali.hasMatch(text);
    final isWide = _multiWide.hasMatch(text) || text.runes.length > 2;
    final calculatedSize =
        fontSize ??
        (emoji
            ? 22
            : isBengali
            ? (isWide ? 17 : 20.5)
            : (isWide ? 16 : 18.5));

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hint != null && hint!.isNotEmpty)
          Positioned(
            top: 4.5,
            right: 6,
            child: Text(
              hint!,
              style: TextStyle(
                fontFamily: 'NotoBengali',
                fontSize: 8.5,
                height: 1,
                fontWeight: FontWeight.w500,
                color: hintColor,
              ),
            ),
          ),
        Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: hint != null && hint!.isNotEmpty ? 5 : 0,
              left: 2,
              right: 2,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: emoji
                      ? null
                      : isBengali
                      ? 'NotoBengali'
                      : 'Manrope',
                  fontSize: calculatedSize,
                  height: 1.05,
                  fontWeight: emoji
                      ? FontWeight.w400
                      : (isBengali ? FontWeight.w600 : FontWeight.w500),
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyPreview extends StatelessWidget {
  const _KeyPreview({
    required this.label,
    required this.skin,
    required this.emoji,
  });

  final String label;
  final KeyboardSkin skin;
  final bool emoji;

  static final RegExp _bengali = RegExp(r'[\u0980-\u09FF]');

  @override
  Widget build(BuildContext context) {
    final size = math.max(
      42.0,
      math.min(64.0, 22.0 + label.runes.length * 14.0),
    );
    final isBengali = _bengali.hasMatch(label);
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: skin.keyPressed,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: skin.accent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          if (!skin.isLight)
            BoxShadow(
              color: skin.accent.withValues(alpha: 0.08),
              blurRadius: 16,
            ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: emoji
              ? null
              : isBengali
              ? 'NotoBengali'
              : 'Manrope',
          fontSize: emoji ? 26 : (isBengali ? 26 : 23),
          height: 1,
          fontWeight: FontWeight.w600,
          color: skin.keyText,
        ),
      ),
    );
  }
}

class _ChoicePopup extends StatelessWidget {
  const _ChoicePopup({
    required this.skin,
    required this.choices,
    required this.selectedIndex,
    required this.primaryIndex,
    required this.tileWidth,
    required this.padding,
    required this.height,
    required this.emoji,
  });

  final KeyboardSkin skin;
  final List<String> choices;
  final int selectedIndex;
  final int primaryIndex;
  final double tileWidth;
  final double padding;
  final double height;
  final bool emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('bengali-choice-popup'),
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 5),
      decoration: BoxDecoration(
        color: skin.keyPressed,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          if (!skin.isLight)
            BoxShadow(
              color: skin.accent.withValues(alpha: 0.09),
              blurRadius: 16,
            ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: skin.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < choices.length; i++)
            SizedBox(
              width: tileWidth,
              height: height - 10,
              child: _ChoiceTile(
                index: i,
                label: choices[i],
                skin: skin,
                selected: i == selectedIndex,
                primary: i == primaryIndex,
                emoji: emoji,
                height: height - 10,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.index,
    required this.label,
    required this.skin,
    required this.selected,
    required this.primary,
    required this.emoji,
    required this.height,
  });

  final int index;
  final String label;
  final KeyboardSkin skin;
  final bool selected;
  final bool primary;
  final bool emoji;
  final double height;

  static final RegExp _bengali = RegExp(r'[\u0980-\u09FF]');

  @override
  Widget build(BuildContext context) {
    final isBengali = _bengali.hasMatch(label);
    final fontSize = math.max(19.0, math.min(25.0, height * 0.45));
    return Container(
      key: ValueKey('choice-item-$index'),
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: selected ? skin.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: selected
            ? Border.all(color: skin.onAccent.withValues(alpha: 0.16))
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 3, 2, 9),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: emoji
                        ? null
                        : isBengali
                        ? 'NotoBengali'
                        : 'Manrope',
                    fontSize: emoji ? 24 : fontSize,
                    height: 1,
                    fontWeight: primary ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? skin.onAccent : skin.keyText,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 5,
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected
                      ? skin.onAccent.withValues(alpha: 0.8)
                      : skin.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuggestionChip extends StatefulWidget {
  const SuggestionChip({
    super.key,
    required this.skin,
    required this.label,
    required this.onTap,
  });

  final KeyboardSkin skin;
  final String label;
  final VoidCallback onTap;

  @override
  State<SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<SuggestionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    return Semantics(
      button: true,
      label: 'সাজেশন: ${widget.label}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 32,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _hovered
                  ? skin.key
                  : skin.key.withValues(alpha: skin.isLight ? 0.58 : 0.48),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered
                    ? skin.accent.withValues(alpha: 0.26)
                    : skin.divider,
              ),
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: RegExp(r'[\u0980-\u09FF]').hasMatch(widget.label)
                    ? 'HindSiliguri'
                    : 'Manrope',
                fontSize: 12.5,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: skin.keyText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KeyboardToolIcon extends StatefulWidget {
  const KeyboardToolIcon({
    super.key,
    required this.skin,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.size = 28,
    this.iconSize = 16,
  });

  final KeyboardSkin skin;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final double size;
  final double iconSize;

  @override
  State<KeyboardToolIcon> createState() => _KeyboardToolIconState();
}

class _KeyboardToolIconState extends State<KeyboardToolIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hovered
                    ? skin.key.withValues(alpha: 0.7)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.active
                    ? skin.accent
                    : skin.keyHint.withValues(alpha: _hovered ? 1 : 0.82),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
