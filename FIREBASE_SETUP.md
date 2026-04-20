# Firebase Setup Guide — Vision Assistant

Complete step-by-step instructions for connecting the app to Firebase.
Estimated time: **15–20 minutes**.

---

## Prerequisites

- A Google account
- The completed Vision Assistant Flutter project
- Flutter SDK installed (verify with `flutter doctor`)

---

## Step 1 — Create a Firebase Project

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `vision-assistant` (or any name)
4. Disable Google Analytics if you don't need it (optional)
5. Click **"Create project"** and wait for it to finish

---

## Step 2 — Add Android App to Firebase

1. In the Firebase Console, click the **Android icon** (➕ Add app)
2. Fill in the details:
   | Field | Value |
   |---|---|
   | Android package name | `com.visionassistant.app` |
   | App nickname | `Vision Assistant Android` |
   | Debug signing certificate SHA-1 | See below ↓ |

3. **Get your SHA-1 key** (required for Google Sign-In):
   ```bash
   # Run this in your terminal:
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   Copy the **SHA1** value and paste it into Firebase.

4. Click **"Register app"**
5. Download **`google-services.json`**
6. Move the file to: `android/app/google-services.json`

---

## Step 3 — Add iOS App to Firebase

1. In Firebase Console, click **➕ Add app** → **iOS icon**
2. Fill in details:
   | Field | Value |
   |---|---|
   | iOS bundle ID | `com.visionassistant.app` |
   | App nickname | `Vision Assistant iOS` |

3. Click **"Register app"**
4. Download **`GoogleService-Info.plist`**
5. In Xcode, drag the file into `ios/Runner/` (ensure "Copy items if needed" is checked)
6. Open `ios/Runner/Info.plist`, find `REVERSED_CLIENT_ID_FROM_GOOGLESERVICE_INFO_PLIST` and replace it with the `REVERSED_CLIENT_ID` value from `GoogleService-Info.plist`

---

## Step 4 — Enable Firebase Services

### 4a. Firestore (scan history)

1. In Firebase Console → **Firestore Database** → **Create database**
2. Choose **"Start in test mode"** (for development)
3. Select a server location close to your users
4. Click **"Enable"**

**Security Rules (update after testing):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /scans/{scanId} {
      // Users can only read/write their own scans
      allow read, write: if request.auth != null 
                         && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

### 4b. Firebase Storage (image uploads)

1. In Firebase Console → **Storage** → **Get started**
2. Start in test mode → choose a location → **Done**

**Storage Security Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /scan_images/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
  }
}
```

### 4c. Authentication

1. In Firebase Console → **Authentication** → **Get started**
2. Click **"Sign-in method"** tab
3. Enable **Google** provider:
   - Click Google → Toggle Enable
   - Enter a support email
   - Click **Save**
4. Enable **Anonymous** provider:
   - Click Anonymous → Toggle Enable → **Save**

---

## Step 5 — Configure Gemini API Key

1. Get a **free** API key at: https://aistudio.google.com/app/apikey
2. Open `lib/core/constants.dart`
3. Replace:
   ```dart
   const String kGeminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```
   with:
   ```dart
   const String kGeminiApiKey = 'AIzaSy...your_actual_key...';
   ```

> ⚠️ **Never commit your API key to a public repository.** Consider using a `.env` file or Flutter's `--dart-define` flag for production builds.

---

## Step 6 — Verify Setup

Run the app and verify:
- [ ] App opens to Login screen (if Firebase configured correctly)
- [ ] Google Sign-In works
- [ ] Camera opens after sign-in
- [ ] Scan button captures an image and calls Gemini
- [ ] Description appears and is read aloud
- [ ] Scan appears in History screen
- [ ] History screen shows past scans from Firestore

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `google-services.json not found` | Ensure file is at `android/app/google-services.json` |
| Google Sign-In fails on device | Add device's SHA-1 to Firebase Console |
| `FirebaseException: permission-denied` | Update Firestore security rules |
| Gemini API returns 403 | Check API key is correct in `constants.dart` |
| App crashes on start | Run `flutter clean && flutter pub get` |
| iOS build fails | Run `cd ios && pod install` |
