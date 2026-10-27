# Borno Keyboard

Borno is a Bangla and English keyboard with a Flutter demo and a native Android
input method.

## Enable the Android keyboard

1. Install and open Borno on an Android device.
2. Tap **Install** and choose **Settings-এ Borno enable করুন**.
3. Return to Borno and tap **Borno Keyboard বেছে নিন**.
4. Choose **ফোনেটিক**, **বাংলা**, or **English** from the keyboard's language key.
   Hold a key to open its alternate-character choices. Tap the microphone for
   inline Bangla voice typing; grant microphone permission from the app first.

The Android input method works in other apps' text fields. Password fields
disable suggestions and voice input.

## Build an Android APK

```sh
flutter build apk --release
```

GitHub Actions also builds a release APK on every push to `main`. Download
`android-release-apk` from the workflow run's **Artifacts** section.