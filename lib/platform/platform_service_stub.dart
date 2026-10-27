import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native (non-web) fallback. The web build selects the richer implementation.
class PlatformService {
  PlatformService._();

  static const _keyboardChannel = MethodChannel(
    'com.erfandev.bongo_board/keyboard',
  );

  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static Future<void> openInputMethodSettings() async {
    if (isAndroid) {
      await _keyboardChannel.invokeMethod<void>('openInputMethodSettings');
    }
  }

  static Future<void> showInputMethodPicker() async {
    if (isAndroid) {
      await _keyboardChannel.invokeMethod<void>('showInputMethodPicker');
    }
  }

  static Future<bool> requestMicrophonePermission() async {
    if (!isAndroid) return false;
    return await _keyboardChannel.invokeMethod<bool>(
          'requestMicrophonePermission',
        ) ??
        false;
  }

  static void clickSound() {}

  static void haptic() {
    HapticFeedback.selectionClick();
  }

  static bool get voiceSupported => false;

  static bool get voiceActive => false;

  static String get voiceTranscript => '';

  static String get voiceError => '';

  static void startVoice() {}

  static void stopVoice() {}

  static bool get pwaCanInstall => false;

  static bool get pwaStandalone => false;

  static bool installPwa() => false;

  static String getPreference(String key) => '';

  static void setPreference(String key, String value) {}
}
