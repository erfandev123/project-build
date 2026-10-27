import 'dart:async';

import 'package:flutter/material.dart';

import '../platform/platform_service.dart';
import '../theme/borno_theme.dart';

/// A small, honest voice sheet. Borno does not ship its own speech model:
/// it uses the browser's SpeechRecognition bridge, and tells the user plainly
/// when the browser or device cannot listen in Bangla.
Future<String?> showVoiceSheet(
  BuildContext context, {
  required KeyboardSkin skin,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xC2050B08),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _VoiceSheet(skin: skin),
  );
}

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet({required this.skin});

  final KeyboardSkin skin;

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  Timer? _poll;
  bool _supported = false;
  bool _active = false;
  String _transcript = '';
  String _error = '';
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _supported = PlatformService.voiceSupported;
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  @override
  void dispose() {
    _poll?.cancel();
    if (_started) PlatformService.stopVoice();
    _pulse.dispose();
    super.dispose();
  }

  void _begin() {
    if (!mounted) return;
    if (!_supported) {
      setState(() => _error = 'unsupported');
      return;
    }
    _started = true;
    _transcript = '';
    _error = '';
    PlatformService.startVoice();
    setState(() => _active = true);
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (!mounted) return;
      final transcript = PlatformService.voiceTranscript;
      final active = PlatformService.voiceActive;
      final error = PlatformService.voiceError;
      if (transcript == _transcript && active == _active && error == _error) {
        return;
      }
      setState(() {
        _transcript = transcript;
        _active = active;
        _error = error;
      });
    });
  }

  void _stopAndClose() {
    PlatformService.stopVoice();
    Navigator.of(context).pop();
  }

  void _insert() {
    final cleaned = _transcript.trim();
    if (cleaned.isEmpty) return;
    PlatformService.stopVoice();
    Navigator.of(context).pop(cleaned);
  }

  String get _friendlyError {
    switch (_error) {
      case 'not-allowed':
      case 'service-not-allowed':
        return 'মাইক্রোফোনের অনুমতি দেওয়া হয়নি। ব্রাউজারের অ্যাড্রেস বারের পাশে মাইক আইকন থেকে অনুমতি দিন, তারপর আবার চেষ্টা করুন।';
      case 'no-speech':
        return 'কিছু শোনা যায়নি। মাইকের কাছে একটু জোরে, স্পষ্ট করে বাংলায় বলুন।';
      case 'network':
        return 'স্পিচ সার্ভারে পৌঁছানো যায়নি। ইন্টারনেট চেক করুন, অথবা ফোনে বাংলা অফলাইন স্পিচ প্যাক ইনস্টল করে আবার চেষ্টা করুন।';
      case 'language-not-supported':
        return 'এই ব্রাউজার বা ডিভাইসে বাংলা ভয়েস রিকগনিশন এখনো নেই। Chrome-এ বাংলা স্পিচ প্যাক থাকলে সেটি কাজ করতে পারে।';
      case 'audio-capture':
        return 'মাইক্রোফোন পাওয়া যায়নি। ডিভাইসে মাইক আছে কিনা এবং অন্য অ্যাপ সেটি ব্যবহার করছে কিনা দেখুন।';
      case 'aborted':
        return 'ভয়েস শোনা বন্ধ হয়েছে। আবার শুরু করতে চাইলে নিচের বোতাম চাপুন।';
      case 'unsupported':
        return 'এই ব্রাউজারে ভয়েস রিকগনিশন নেই। Chrome, Edge বা Safari-র নতুন ভার্সনে চেষ্টা করুন—অথবা নিচে টাইপ করে লিখুন।';
      case 'start-failed':
      case 'unknown':
        return 'ভয়েস ইনপুট শুরু করা যায়নি। একবার আবার চেষ্টা করুন।';
      default:
        return _error.isEmpty
            ? ''
            : 'ভয়েস ইনপুটে সমস্যা হয়েছে ($_error)। আবার চেষ্টা করুন।';
    }
  }

  bool get _hasResult => _transcript.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final errorText = _friendlyError;
    final showError = errorText.isNotEmpty && !_hasResult;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            ),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: const Color(0x2EFFFFFF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: skin.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: skin.accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.graphic_eq_rounded,
                                size: 12,
                                color: skin.accent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'VOICE',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 8,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: skin.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _stopAndClose,
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          padding: const EdgeInsets.all(8),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0x0DFFFFFF),
                            side: const BorderSide(color: Color(0x18FFFFFF)),
                          ),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: BornoColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _hasResult ? 'এটাই বলেছিলেন?' : 'বাংলায় বলুন',
                      textAlign: TextAlign.center,
                      style: bengali(
                        size: 25,
                        weight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _hasResult
                          ? 'লেখাটা ঠিক থাকলে ইনসার্ট করুন। দরকার হলে আবার বলতে পারেন।'
                          : 'মাইকে বাংলায় বলুন—Borno আপনার কথাকে লেখায় বদলে দেবে।',
                      textAlign: TextAlign.center,
                      style: bengali(
                        size: 12,
                        weight: FontWeight.w400,
                        color: BornoColors.muted,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: _MicOrb(
                        skin: skin,
                        active: _active,
                        pulse: _pulse,
                        failed: showError && !_supported,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (showError)
                      _ErrorCard(
                        text: errorText,
                        onRetry: _supported ? _begin : null,
                      )
                    else
                      _TranscriptCard(
                        skin: skin,
                        transcript: _transcript,
                        active: _active,
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _stopAndClose,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BornoColors.text,
                              minimumSize: const Size(0, 48),
                              side: const BorderSide(color: Color(0x26FFFFFF)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'HindSiliguri',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('বাতিল'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _hasResult ? _insert : null,
                            icon: const Icon(
                              Icons.keyboard_return_rounded,
                              size: 17,
                            ),
                            label: const Text('লেখায় যোগ করুন'),
                            style: FilledButton.styleFrom(
                              backgroundColor: skin.accent,
                              foregroundColor: skin.onAccent,
                              disabledBackgroundColor: const Color(0x14FFFFFF),
                              disabledForegroundColor: BornoColors.mutedDeep,
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                            'ভয়েস আপনার ব্রাউজারের স্পিচ ইঞ্জিনে চলে। ডিভাইসে বাংলা স্পিচ প্যাক থাকলে ইন্টারনেট ছাড়াও কাজ করতে পারে; নাহলে ব্রাউজার সার্ভিস ব্যবহার হতে পারে।',
                            style: TextStyle(
                              fontFamily: 'HindSiliguri',
                              fontSize: 9.8,
                              height: 1.5,
                              color: BornoColors.mutedDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _MicOrb extends StatelessWidget {
  const _MicOrb({
    required this.skin,
    required this.active,
    required this.pulse,
    required this.failed,
  });

  final KeyboardSkin skin;
  final bool active;
  final Animation<double> pulse;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final color = failed ? const Color(0xFFFF9E86) : skin.accent;
    return SizedBox(
      width: 104,
      height: 104,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final t = pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (active)
                for (var i = 0; i < 2; i++)
                  Container(
                    width: 58 + ((t + i * 0.5) % 1) * 44,
                    height: 58 + ((t + i * 0.5) % 1) * 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(
                          alpha: 0.28 * (1 - ((t + i * 0.5) % 1)),
                        ),
                      ),
                    ),
                  ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: active ? 0.3 : 0.14),
                      blurRadius: 34,
                      spreadRadius: active ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  failed
                      ? Icons.mic_off_rounded
                      : (active ? Icons.graphic_eq_rounded : Icons.mic_rounded),
                  size: 28,
                  color: failed ? const Color(0xFF2B120C) : skin.onAccent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.skin,
    required this.transcript,
    required this.active,
  });

  final KeyboardSkin skin;
  final String transcript;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final hasText = transcript.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0x06FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasText
              ? skin.accent.withValues(alpha: 0.28)
              : const Color(0x16FFFFFF),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasText) ...[
            Row(
              children: [
                if (active)
                  _ListeningDots(skin: skin)
                else
                  Icon(
                    Icons.mic_none_rounded,
                    size: 16,
                    color: BornoColors.muted,
                  ),
                const SizedBox(width: 8),
                Text(
                  active ? 'শুনছি…' : 'ভয়েস শুরু হচ্ছে…',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: BornoColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '“আমি বাংলায় কথা বলি” — এভাবে বলুন।',
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 11.5,
                height: 1.45,
                color: BornoColors.mutedDeep,
              ),
            ),
          ] else
            Text(
              transcript,
              style: bengali(
                size: 17,
                weight: FontWeight.w500,
                color: BornoColors.text,
                height: 1.55,
              ),
            ),
        ],
      ),
    );
  }
}

class _ListeningDots extends StatefulWidget {
  const _ListeningDots({required this.skin});

  final KeyboardSkin skin;

  @override
  State<_ListeningDots> createState() => _ListeningDotsState();
}

class _ListeningDotsState extends State<_ListeningDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Container(
                width: 4,
                height: 4 + 7 * _wave(i),
                decoration: BoxDecoration(
                  color: widget.skin.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  double _wave(int index) {
    final phase = (_controller.value + index * 0.22) % 1;
    return (1 - (phase * 2 - 1).abs()).clamp(0.15, 1.0);
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.text, required this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0x0CFFAD95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2AFF9E86)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mic_off_outlined, size: 16, color: Color(0xFFFFAE98)),
              SizedBox(width: 8),
              Text(
                'ভয়েস কাজ করছে না',
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFCDBF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 11.5,
              height: 1.55,
              color: BornoColors.muted,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRetry,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 13,
                        color: BornoColors.textSoft,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'আবার চেষ্টা করুন',
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: BornoColors.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
