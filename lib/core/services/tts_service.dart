// ─────────────────────────────────────────────────────────────────────────────
// tts_service.dart — Text-to-Speech wrapper for accessibility
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  String _lastSpoken = '';
  bool _isInitialised = false;

  // ── Initialisation ───────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_isInitialised) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);  // Slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Use a clear, high-quality voice if available
    final voices = await _tts.getVoices as List?;
    if (voices != null) {
      final preferred = voices.firstWhere(
        (v) => (v['name'] as String? ?? '').toLowerCase().contains('google'),
        orElse: () => null,
      );
      if (preferred != null) {
        await _tts.setVoice({'name': preferred['name'], 'locale': 'en-US'});
      }
    }

    _isInitialised = true;
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Speak [text] aloud, stopping any ongoing speech first.
  Future<void> speak(String text) async {
    await init();
    _lastSpoken = text;
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Repeat the last spoken text.
  Future<void> repeat() async {
    if (_lastSpoken.isEmpty) return;
    await speak(_lastSpoken);
  }

  /// Stop any ongoing speech immediately.
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Announce a short status message (e.g., "Camera ready", "Processing…")
  Future<void> announce(String message) async {
    await init();
    await _tts.stop();
    await _tts.speak(message);
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────────

  void onComplete(VoidCallback callback) {
    _tts.setCompletionHandler(callback);
  }

  void onError(Function(String) callback) {
    _tts.setErrorHandler((msg) => callback(msg));
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
