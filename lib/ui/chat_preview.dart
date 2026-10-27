import 'package:flutter/material.dart';

import '../theme/borno_theme.dart';
import 'widgets.dart';

class DemoMessage {
  const DemoMessage(this.text, {required this.mine});

  final String text;
  final bool mine;
}

class ChatPreview extends StatefulWidget {
  const ChatPreview({
    super.key,
    required this.skin,
    required this.messages,
    required this.text,
    required this.romanBuffer,
    required this.canSend,
    required this.onSend,
    required this.onReset,
    required this.onRequestFocus,
  });

  final KeyboardSkin skin;
  final List<DemoMessage> messages;
  final String text;
  final String romanBuffer;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onReset;
  final VoidCallback onRequestFocus;

  @override
  State<ChatPreview> createState() => _ChatPreviewState();
}

class _ChatPreviewState extends State<ChatPreview> {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = widget.messages.length;
  }

  @override
  void didUpdateWidget(ChatPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != _lastMessageCount) {
      _lastMessageCount = widget.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    return ColoredBox(
      color: skin.screen,
      child: Column(
        children: [
          _StatusBar(skin: skin),
          _ChatHeader(skin: skin, onReset: widget.onReset),
          Divider(height: 1, thickness: 1, color: skin.divider),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  bottom: 44,
                  child: IgnorePointer(
                    child: Text(
                      'অ',
                      style: TextStyle(
                        fontFamily: 'NotoBengali',
                        fontSize: 152,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: skin.screenText.withValues(alpha: 0.028),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: _buildMessages(skin)),
              ],
            ),
          ),
          _Composer(
            skin: skin,
            text: widget.text,
            romanBuffer: widget.romanBuffer,
            canSend: widget.canSend,
            onSend: widget.onSend,
            onTap: widget.onRequestFocus,
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(KeyboardSkin skin) {
    final count = widget.messages.length;
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      physics: const ClampingScrollPhysics(),
      itemCount: count + 1,
      itemBuilder: (context, index) {
        if (index == count) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: skin.screenRaised,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: skin.divider),
                ),
                child: Text(
                  'আজ · লাইভ ডেমো',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: skin.muted,
                  ),
                ),
              ),
            ),
          );
        }
        final message = widget.messages[count - 1 - index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _Bubble(skin: skin, message: message),
        );
      },
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.skin});

  final KeyboardSkin skin;

  @override
  Widget build(BuildContext context) {
    final color = skin.screenText.withValues(alpha: 0.72);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 4),
      child: Row(
        children: [
          Text(
            '9:41',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10.5,
              height: 1.2,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Spacer(),
          Icon(Icons.signal_cellular_alt_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Icon(Icons.wifi_rounded, size: 12.5, color: color),
          const SizedBox(width: 4),
          Icon(Icons.battery_5_bar_rounded, size: 13, color: color),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.skin, required this.onReset});

  final KeyboardSkin skin;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 10, 9),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const BornoMark(size: 35, radiusFactor: 0.3),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF65E08A),
                    shape: BoxShape.circle,
                    border: Border.all(color: skin.screen, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'বর্ণ',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: skin.screenText,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'লাইভ কী-বোর্ড ডেমো',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: skin.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: skin.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: skin.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: skin.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 8,
                    height: 1.1,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                    color: skin.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 3),
          Tooltip(
            message: 'ডেমো রিসেট করুন',
            child: IconButton(
              onPressed: onReset,
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              padding: const EdgeInsets.all(5),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(
                Icons.restart_alt_rounded,
                color: skin.muted,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.skin, required this.message});

  final KeyboardSkin skin;
  final DemoMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 282),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? skin.bubbleOut : skin.bubbleIn,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(mine ? 15 : 4),
            bottomRight: Radius.circular(mine ? 4 : 15),
          ),
          border: mine
              ? null
              : Border.all(
                  color: skin.isLight
                      ? const Color(0x0D172019)
                      : const Color(0x0AFFFFFF),
                ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 13.2,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: mine ? skin.bubbleOutText : skin.bubbleInText,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.skin,
    required this.text,
    required this.romanBuffer,
    required this.canSend,
    required this.onSend,
    required this.onTap,
  });

  final KeyboardSkin skin;
  final String text;
  final String romanBuffer;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.fromLTRB(13, 8, 8, 8),
          decoration: BoxDecoration(
            color: skin.composer,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: skin.composerBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: skin.isLight ? 0.04 : 0.12,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (romanBuffer.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 10,
                              color: skin.accent,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                'Banglish  $romanBuffer',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 8.5,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                  color: skin.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _LiveText(text: text, skin: skin, onTap: onTap),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _SendButton(skin: skin, enabled: canSend, onTap: onSend),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveText extends StatefulWidget {
  const _LiveText({
    required this.text,
    required this.skin,
    required this.onTap,
  });

  final String text;
  final KeyboardSkin skin;
  final VoidCallback onTap;

  @override
  State<_LiveText> createState() => _LiveTextState();
}

class _LiveTextState extends State<_LiveText> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(_LiveText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpTo(_controller.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final isEmpty = widget.text.isEmpty;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 26, maxHeight: 76),
      child: SingleChildScrollView(
        controller: _controller,
        physics: const ClampingScrollPhysics(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: isEmpty ? 'বাংলায় কিছু লিখুন…' : widget.text,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: isEmpty ? 13.5 : 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: isEmpty ? skin.muted : skin.screenText,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 1.5),
                    child: _Caret(color: skin.accent),
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

class _Caret extends StatefulWidget {
  const _Caret({required this.color});

  final Color color;

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween<double>(1), weight: 45),
        TweenSequenceItem(tween: ConstantTween<double>(0), weight: 55),
      ]).animate(_controller),
      child: Container(
        width: 1.6,
        height: 15,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.skin,
    required this.enabled,
    required this.onTap,
  });

  final KeyboardSkin skin;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'বার্তা পাঠান',
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.enabled
                  ? (_hovered
                        ? Color.lerp(skin.accent, Colors.white, 0.1)
                        : skin.accent)
                  : skin.screenRaised,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.enabled
                    ? skin.accent.withValues(alpha: 0.4)
                    : skin.divider,
              ),
            ),
            child: AnimatedRotation(
              turns: widget.enabled ? 0 : 0.02,
              duration: const Duration(milliseconds: 160),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: widget.enabled ? skin.onAccent : skin.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
