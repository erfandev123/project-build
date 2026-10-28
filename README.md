# Borno Keyboard

Borno is a Bangla and English keyboard with a Flutter demo and a native Android
input method. It works offline and keeps the Probhat layout, phonetic typing,
word suggestions, and Bangla voice input.

## Install the Android keyboard

1. Download `borno-vX.Y.Z.apk` from the latest
   [GitHub Release](https://github.com/erfandev123/project-build/releases).
2. Open the APK and allow installs from your browser or file manager if Android
   asks.
3. Open Borno and tap **Install**.
4. In Android settings, enable **Borno** under virtual keyboards.
5. Return to Borno and tap **Borno Keyboard বেছে নিন**.
6. Choose **ফোনেটিক**, **বাংলা**, or **English** from the keyboard's language key.

> **Updating from an old build:** earlier APKs were signed with a throwaway debug
> key, so Android may reject the new APK with a signature/package error. If that
> happens, uninstall the old Borno once and install the new APK. Every build from
> now on uses the same committed release key, so later updates install normally
> without uninstalling.

### Keyboard gestures

- Tap a key to type it with a soft zoom animation.
- Press and hold a key to see the magnified preview and alternate characters.
- Hold **Backspace** and swipe left to select text; release to delete the
  selection.
- Tap the microphone for inline Bangla voice typing. Grant microphone permission
  from the app first.

Password fields disable suggestions and voice input.

## Build an Android APK

```sh
flutter pub get
flutter test
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

### Signing

`android/app/borno-release.jks` is a stable demo release key committed to this
repository so that GitHub Actions builds can update each other. To sign with your
own key, copy `android/key.properties.example` to `android/key.properties` and
fill in your keystore details. `android/key.properties` is ignored by Git.

> Replace the committed demo key with your own private keystore before publishing
> on the Play Store, and never share your production passwords.

## GitHub Actions releases

Every push to `main` builds and tests the APK and uploads it as the
`android-release-apk` workflow artifact. Pushing a version tag creates a GitHub
Release with a directly downloadable APK:

```sh
git tag v1.1.0
git push origin v1.1.0
```

The workflow also prints the APK's SHA-256 checksum in the build log.
