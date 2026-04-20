// ─────────────────────────────────────────────────────────────────────────────
// voice_command_service.dart — Continuous voice command listener
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import '../constants.dart';
import 'vibration_service.dart';

enum VoiceCommand { scan, repeat, stop, history, share, unknown }

typedef VoiceCommandCallback = void Function(VoiceCommand command);

class VoiceCommandService {
  VoiceCommandService._();
  static final VoiceCommandService instance = VoiceCommandService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialised = false;
  VoiceCommandCallback? _onCommand;
  Timer? _restartTimer;

  // ── Initialisation ────────────────────────────────────────────────────────────

  Future<bool> init() async {
    if (_isInitialised) return true;
    _isInitialised = await _speech.initialize(
      onError: (error) => _onSpeechError(error.errorMsg),
      onStatus: _onSpeechStatus,
    );
    return _isInitialised;
  }

  // ── Public API ────────────────────────────────────────────────────────────────

  bool get isListening => _isListening;

  /// Start listening for voice commands. Calls [onCommand] when a keyword is detected.
  /// If already listening, it updates the callback to the new listener.
  Future<void> startListening(VoiceCommandCallback onCommand) async {
    _onCommand = onCommand;
    if (!await init()) return;
    
    // If already listening, we don't start a new session, but the callback is now updated.
    if (!_isListening) {
      _startSession();
    }
  }

  /// Stop all voice listening and clear callbacks.
  Future<void> stopListening() async {
    _onCommand = null;
    _restartTimer?.cancel();
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Manually force a restart of the session (useful when returning to a screen).
  Future<void> refresh() async {
    if (_onCommand == null) return;
    await _speech.stop();
    _isListening = false;
    _restartTimer?.cancel();
    _startSession();
  }

  // ── Private ───────────────────────────────────────────────────────────────────

  void _startSession() {
    if (!_isInitialised || _onCommand == null) {
      _isListening = false;
      return;
    }

    // High-reliability settings from the ProfileScreen interview
    _speech.listen(
      onResult: _handleResult,
      listenFor: const Duration(seconds: 45), // Maximum window
      pauseFor: const Duration(seconds: 15),  // Long pause tolerance
      localeId: 'en_US',
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.confirmation, // Higher precision
    );
    _isListening = true;
  }

  void _handleResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.toLowerCase().trim();
    if (words.isEmpty) return;

    final command = _classify(words);
    if (command != VoiceCommand.unknown) {
      // Immediate tactile feedback
      VibrationService.instance.cameraReady();
      
      _onCommand?.call(command);
      
      // Stop and reset to ensure the next session starts fresh with a clear buffer
      _speech.stop();
      _isListening = false;
    }
  }

  VoiceCommand _classify(String words) {
    if (kVoiceScan.any((w) => words.contains(w))) return VoiceCommand.scan;
    if (kVoiceRepeat.any((w) => words.contains(w))) return VoiceCommand.repeat;
    if (kVoiceStop.any((w) => words.contains(w))) return VoiceCommand.stop;
    if (kVoiceHistory.any((w) => words.contains(w))) return VoiceCommand.history;
    if (kVoiceShare.any((w) => words.contains(w))) return VoiceCommand.share;
    return VoiceCommand.unknown;
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      // Auto-restart listening after a short delay to maintain "Always On" capability
      if (_onCommand != null) {
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(milliseconds: 300), _startSession);
      }
    }
  }

  void _onSpeechError(String error) {
    _isListening = false;
    // Silently restart on common transient errors (timeout, network blink)
    if (_onCommand != null) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(seconds: 1), _startSession);
    }
  }

  Future<void> dispose() async {
    _restartTimer?.cancel();
    await stopListening();
  }
}
