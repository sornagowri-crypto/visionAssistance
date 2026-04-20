# Build Instructions — Vision Assistant

Instructions for building and running Vision Assistant on Android and iOS.

---

## Prerequisites

### Required Tools

| Tool | Minimum Version | Download |
|---|---|---|
| Flutter SDK | 3.16+ | https://flutter.dev/docs/get-started/install |
| Dart SDK | 3.1+ | Bundled with Flutter |
| Android Studio | Hedgehog (2023.1.1)+ | https://developer.android.com/studio |
| Xcode (iOS only) | 15.0+ | Mac App Store |
| CocoaPods (iOS only) | 1.13+ | `sudo gem install cocoapods` |

### Verify your setup:
```bash
flutter doctor -v
```
All checkmarks should be green. Fix any issues shown.

---

## Initial Setup

```bash
# 1. Navigate to the project directory
cd path/to/vision_assistant

# 2. Install all Flutter dependencies
flutter pub get

# 3. iOS only — install CocoaPods dependencies
cd ios && pod install && cd ..
```

---

## Running in Debug Mode

### Android (fastest for development)

```bash
# List connected devices
flutter devices

# Run on connected Android device or emulator
flutter run

# Run on a specific device
flutter run -d <device-id>
```

### iOS (requires Mac with Xcode)

```bash
# Open iOS project in Xcode (first time only, to set signing)
open ios/Runner.xcworkspace

# Run from terminal
flutter run -d <ios-device-id>
```

---

## Building Release APK (Android)

### Debug APK (no signing required — for testing)

```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (for distribution)

**Step 1 — Create a keystore (first time only):**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
Remember the passwords you set!

**Step 2 — Create `android/key.properties`:**
```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-your-keystore>/upload-keystore.jks
```

**Step 3 — Update `android/app/build.gradle`** to reference the keystore:
```groovy
// Add before android { } block:
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

// Inside android { } block, add:
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

**Step 4 — Build the release APK:**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Build App Bundle (recommended for Google Play):**
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Building iOS IPA

> Requires a Mac with Xcode and an Apple Developer account.

```bash
# Build iOS release
flutter build ios --release

# Open in Xcode to archive and export IPA
open ios/Runner.xcworkspace
```

Then in Xcode:
1. Select `Product` → `Archive`
2. In the Organizer, click `Distribute App`
3. Choose distribution method (Ad Hoc / App Store)

---

## Common Commands

| Command | Purpose |
|---|---|
| `flutter clean` | Clean build cache |
| `flutter pub get` | Fetch dependencies |
| `flutter pub upgrade` | Upgrade dependencies |
| `flutter analyze` | Static code analysis |
| `flutter build apk` | Build Android APK |
| `flutter build ios` | Build iOS |
| `flutter install` | Install APK on connected device |
| `flutter logs` | View device logs |

---

## Enable MLKit Offline Model (Android)

MLKit downloads the object detection model on first use. To pre-bundle it:

Add to `android/app/build.gradle` inside `defaultConfig`:
```groovy
// Bundle MLKit model in the APK
manifestPlaceholders = [
    "com.google.mlkit.vision.DEPENDENCIES": "object_detection"
]
```

---

## App Installation via ADB (Android)

```bash
# Install debug APK directly to connected device
adb install build/app/outputs/flutter-apk/app-debug.apk

# Install and launch
adb install build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.visionassistant.app/.MainActivity
```

---

## Troubleshooting Builds

| Error | Fix |
|---|---|
| `Gradle build failed` | Run `flutter clean && flutter pub get` |
| `minSdkVersion too low` | Ensure `minSdkVersion 21` in `app/build.gradle` |
| `Google services file missing` | Place `google-services.json` in `android/app/` |
| `CocoaPods error` | Run `cd ios && pod deintegrate && pod install` |
| `Xcode signing error` | Open `Xcode → Signing & Capabilities` and select your team |
| `Permission denied at runtime` | Add permission handling in app (already done in camera screen) |
| `MLKit model not found` | First run requires internet to download MLKit model |
