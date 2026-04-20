// ─────────────────────────────────────────────────────────────────────────────
// vibration_service.dart — Haptic and vibration feedback for accessibility
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../constants.dart';

class VibrationService {
  VibrationService._();
  static final VibrationService instance = VibrationService._();

  bool? _hasVibrator;

  // ── Private ───────────────────────────────────────────────────────────────────

  Future<bool> _canVibrate() async {
    _hasVibrator ??= await Vibration.hasVibrator() ?? false;
    return _hasVibrator!;
  }

  Future<void> _vibrate(List<int> pattern) async {
    if (await _canVibrate()) {
      Vibration.vibrate(pattern: pattern);
    } else {
      // Fallback to HapticFeedback (works on iOS)
      HapticFeedback.mediumImpact();
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Single short pulse — camera is ready and live
  Future<void> cameraReady() => _vibrate(kVibrateCameraReady);

  /// Two short pulses — image captured successfully
  Future<void> imageCaptured() => _vibrate(kVibrateImageCaptured);

  /// One long pulse — AI description is ready to hear
  Future<void> descriptionReady() => _vibrate(kVibrateDescriptionReady);

  /// Three rapid pulses — an error occurred
  Future<void> error() => _vibrate(kVibrateError);

  /// Light tap for button presses
  Future<void> buttonTap() async {
    if (await _canVibrate()) {
      Vibration.vibrate(duration: 30);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Gentle double-tap — positive confirmation (settings saved, toggle changed)
  Future<void> success() async {
    if (await _canVibrate()) {
      Vibration.vibrate(pattern: [0, 40, 80, 40]);
    } else {
      HapticFeedback.mediumImpact();
    }
  }
}
