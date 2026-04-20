# Vision Assistant — Flutter App for Visually Impaired Users

An accessible, AI-powered Flutter application that provides **real-time object recognition** with detailed **audio descriptions** via Google Gemini Vision.

---

## ✨ Features

| Feature | Details |
|---|---|
| 📷 **Live Camera** | Auto-starts on launch, full-screen preview |
| 🤖 **AI Descriptions** | Object name, appearance, use, safety via Gemini |
| 🔊 **Text-to-Speech** | Descriptions read aloud automatically |
| 📴 **Offline Mode** | On-device MLKit fallback when no internet |
| 🎙️ **Voice Commands** | "Scan", "Repeat", "Stop", "History" |
| 📳 **Vibration** | 3 distinct patterns for camera/capture/result |
| 📜 **Scan History** | Firebase Firestore with real-time stream |
| 🔐 **Google Sign-In** | Or anonymous access — your choice |
| 🎨 **High-Contrast UI** | Black + yellow, large buttons, accessible |

---

## 📁 Project Structure

```
lib/
├── main.dart                          # Entry point, routing, auth gate
├── core/
│   ├── constants.dart                 # API keys, colors, strings
│   ├── theme.dart                     # High-contrast dark theme
│   └── services/
│       ├── gemini_service.dart        # Gemini Vision API
│       ├── tts_service.dart           # Text-to-Speech
│       ├── vibration_service.dart     # Haptic feedback
│       ├── firebase_service.dart      # Auth + Firestore + Storage
│       ├── mlkit_service.dart         # Offline detection
│       └── voice_command_service.dart # Voice commands
├── models/
│   └── scan_result.dart               # Data model
├── screens/
│   ├── login_screen.dart              # Google Sign-In / skip
│   ├── camera_screen.dart             # Main camera + scan
│   ├── result_screen.dart             # Description display
│   └── history_screen.dart            # Past scans
└── widgets/
    ├── scan_button.dart               # Large animated button
    ├── status_banner.dart             # Camera status overlay
    └── history_tile.dart              # History list item
```

---

## 🚀 Quick Start

### 1. Prerequisites
```bash
flutter doctor -v   # ensure all green
```

### 2. Get dependencies
```bash
flutter pub get
```

### 3. Configure Gemini API Key
- Get a free key at https://aistudio.google.com/app/apikey  
- Edit `lib/core/constants.dart`:
  ```dart
  const String kGeminiApiKey = 'YOUR_KEY_HERE';
  ```

### 4. Configure Firebase (for history & auth)
See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for full instructions.

### 5. Run the app
```bash
flutter run
```

---

## 🎙️ Voice Commands

| Say | Action |
|---|---|
| `"Scan"` | Capture and identify object |
| `"Repeat"` | Re-read the last description |
| `"Stop"` | Stop reading |
| `"History"` | Open scan history |

---

## 📲 Build APK

See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for detailed steps.

```bash
# Debug (quick testing)
flutter build apk --debug

# Release
flutter build apk --release
```

---

## 🔒 Privacy

- Camera images are stored in **your own** Firebase Storage bucket
- No images are sent to any server other than Gemini API and your Firebase project
- Anonymous auth creates a temporary account with no personal data
