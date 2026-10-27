import 'dart:js_interop';

/// Thin bridge to the tiny, dependency-free JavaScript runtime in index.html.
class PlatformService {
  PlatformService._();

  static void clickSound() {
    try {
      _click();
    } catch (_) {
      // Audio is a progressive enhancement and must never break typing.
    }
  }

  static void haptic() {
    try {
      _vibrate();
    } catch (_) {}
  }

  static bool get voiceSupported {
    try {
      return _voiceSupported();
    } catch (_) {
      return false;
    }
  }

  static bool get voiceActive {
    try {
      return _voiceActive();
    } catch (_) {
      return false;
    }
  }

  static String get voiceTranscript {
    try {
      return _voiceTranscript();
    } catch (_) {
      return '';
    }
  }

  static String get voiceError {
    try {
      return _voiceError();
    } catch (_) {
      return '';
    }
  }

  static void startVoice() {
    try {
      _startVoice();
    } catch (_) {}
  }

  static void stopVoice() {
    try {
      _stopVoice();
    } catch (_) {}
  }

  static bool get pwaCanInstall {
    try {
      return _pwaCanInstall();
    } catch (_) {
      return false;
    }
  }

  static bool get pwaStandalone {
    try {
      return _pwaStandalone();
    } catch (_) {
      return false;
    }
  }

  static bool installPwa() {
    try {
      return _pwaInstall();
    } catch (_) {
      return false;
    }
  }

  static String getPreference(String key) {
    try {
      final value = _getPreference(key.toJS);
      return value.toDart;
    } catch (_) {
      return '';
    }
  }

  static void setPreference(String key, String value) {
    try {
      _setPreference(key.toJS, value.toJS);
    } catch (_) {}
  }
}

@JS('bornoTap')
external void _click();

@JS('bornoVibrate')
external void _vibrate();

@JS('bornoVoiceSupported')
external bool _voiceSupported();

@JS('bornoVoiceActive')
external bool _voiceActive();

@JS('bornoVoiceTranscript')
external String _voiceTranscript();

@JS('bornoVoiceError')
external String _voiceError();

@JS('bornoStartVoice')
external void _startVoice();

@JS('bornoStopVoice')
external void _stopVoice();

@JS('bornoPwaCanInstall')
external bool _pwaCanInstall();

@JS('bornoPwaStandalone')
external bool _pwaStandalone();

@JS('bornoPwaInstall')
external bool _pwaInstall();

@JS('bornoGetPreference')
external JSString _getPreference(JSString key);

@JS('bornoSetPreference')
external void _setPreference(JSString key, JSString value);
