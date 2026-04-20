// ─────────────────────────────────────────────────────────────────────────────
// settings_service.dart — SharedPreferences-backed user settings
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  SharedPreferences? _prefs;

  // ── Keys ─────────────────────────────────────────────────────────────────────

  static const _kTtsSpeed      = 'tts_speed';
  static const _kVibrationOn   = 'vibration_on';
  static const _kFontScale     = 'font_scale';
  static const _kHighContrast  = 'high_contrast';
  static const _kAutoSpeak     = 'auto_speak';

  // ── Defaults ─────────────────────────────────────────────────────────────────

  static const double defaultTtsSpeed    = 0.45;
  static const bool   defaultVibration   = true;
  static const double defaultFontScale   = 1.0;
  static const bool   defaultHighContrast = false;
  static const bool   defaultAutoSpeak   = true;

  // ── Initialisation ────────────────────────────────────────────────────────────

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Getters ───────────────────────────────────────────────────────────────────

  double get ttsSpeed    => _prefs?.getDouble(_kTtsSpeed)   ?? defaultTtsSpeed;
  bool   get vibrationOn => _prefs?.getBool(_kVibrationOn)  ?? defaultVibration;
  double get fontScale   => _prefs?.getDouble(_kFontScale)  ?? defaultFontScale;
  bool   get highContrast => _prefs?.getBool(_kHighContrast) ?? defaultHighContrast;
  bool   get autoSpeak   => _prefs?.getBool(_kAutoSpeak)    ?? defaultAutoSpeak;

  // ── Setters ───────────────────────────────────────────────────────────────────

  Future<void> setTtsSpeed(double value) async {
    await _prefs?.setDouble(_kTtsSpeed, value);
    notifyListeners();
  }

  Future<void> setVibrationOn(bool value) async {
    await _prefs?.setBool(_kVibrationOn, value);
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    await _prefs?.setDouble(_kFontScale, value);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    await _prefs?.setBool(_kHighContrast, value);
    notifyListeners();
  }

  Future<void> setAutoSpeak(bool value) async {
    await _prefs?.setBool(_kAutoSpeak, value);
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _prefs?.remove(_kTtsSpeed);
    await _prefs?.remove(_kVibrationOn);
    await _prefs?.remove(_kFontScale);
    await _prefs?.remove(_kHighContrast);
    await _prefs?.remove(_kAutoSpeak);
    notifyListeners();
  }
}
