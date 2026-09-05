// ─────────────────────────────────────────────────────────────────────────────
// constants.dart — App-wide constants for Vision Assistant
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── API Keys ──────────────────────────────────────────────────────────────────
// TODO: Replace with your Gemini API key.
// Get a FREE key at: https://aistudio.google.com/app/apikey
const String kGeminiApiKey = 'AIzaSyD36R4RbXNpqm4TFqHKGhsqQzP7uZDWKl8';

// ── Gemini API ────────────────────────────────────────────────────────────────
const String kGeminiBaseUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

// Accessibility-optimised prompt for visually impaired users
const String kGeminiPrompt = '''
You are an accessibility assistant helping a visually impaired person. 
Describe the main object(s) in this image with high detail and vivid clarity.

Structure your response as follows:
OBJECT: [Name of the main object]
APPEARANCE: [Detailed description of colors, shape, and size. CRITICAL: If the object has a cover, picture, or design (like a notebook cover or a poster), describe the imagery, characters, patterns, and art style in detail.]
USE: [What it is used for — 1-2 sentences]
SAFETY: [Any safety considerations, or "No safety concerns" if none]

Focus on what makes this specific object unique (e.g., "A blue notebook with a gold foil dragon on the cover" instead of just "A notebook").
Keep the total response under 150 words. Use simple, clear language.
''';

// ── Firebase ──────────────────────────────────────────────────────────────────
const String kScansCollection = 'scans';
const String kStorageBucket = 'scan_images';
const String kUsersCollection = 'users';
const String kGoogleWebClientId = '338893916768-2vmaj72mmpb8bi7noe8et4canh05t46i.apps.googleusercontent.com';

// ── App Strings ───────────────────────────────────────────────────────────────
const String kAppName = 'Vision Assistant';
const String kTagline = 'See the world through AI';

const String kScanLabel = 'SCAN';
const String kRepeatLabel = 'Repeat Description';
const String kHistoryLabel = 'Scan History';
const String kSignInLabel = 'Sign in with Google';
const String kSkipLabel = 'Continue without sign-in';

// Voice command trigger words
const List<String> kVoiceScan = [
  'scan',
  'capture',
  'describe',
  'what is this',
  'scan the object',
  'identify',
  'tell me what you see',
];
const List<String> kVoiceRepeat = [
  'repeat',
  'again',
  'say it again',
  'one more time',
  'repeat description',
  'replay',
];
const List<String> kVoiceStop = [
  'stop',
  'shut up',
  'quiet',
  'cancel',
  'silence',
];
const List<String> kVoiceHistory = ['history', 'previous', 'past', 'last scan'];
const List<String> kVoiceShare = ['share', 'send', 'post', 'message', 'export'];

// ── Vibration Patterns (milliseconds) ──────────────────────────────────────────
const List<int> kVibrateCameraReady = [0, 80];             // 1 short pulse
const List<int> kVibrateImageCaptured = [0, 80, 100, 80]; // 2 short pulses
const List<int> kVibrateDescriptionReady = [0, 400];       // 1 long pulse
const List<int> kVibrateError = [0, 80, 50, 80, 50, 80];  // 3 rapid pulses

// ── High-Contrast Color Palette ───────────────────────────────────────────────
const Color kColorBackground   = Color(0xFF0A0A0A); // near-black
const Color kColorSurface      = Color(0xFF1A1A1A); // dark surface
const Color kColorCard         = Color(0xFF242424); // elevated card
const Color kColorPrimary      = Color(0xFFFFD600); // vivid yellow
const Color kColorPrimaryDark  = Color(0xFFC7A500); // darker yellow
const Color kColorAccent       = Color(0xFF00E5FF); // cyan accent
const Color kColorSuccess      = Color(0xFF69F0AE); // green
const Color kColorError        = Color(0xFFFF5252); // red
const Color kColorTextPrimary  = Color(0xFFFFFFFF); // white
const Color kColorTextSecondary = Color(0xFFB0B0B0); // grey
const Color kColorDivider      = Color(0xFF333333);

// ── Typography Sizes (accessibility-first: larger than usual) ──────────────────
const double kFontSizeHero    = 32.0;
const double kFontSizeTitle   = 24.0;
const double kFontSizeBody    = 20.0;
const double kFontSizeCaption = 16.0;

// ── Sizing ────────────────────────────────────────────────────────────────────
const double kScanButtonSize  = 112.0; // large, accessible tap target
const double kBorderRadius    = 20.0;
const double kPadding         = 20.0;
