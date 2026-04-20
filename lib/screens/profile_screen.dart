import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/constants.dart';
import '../core/services/firebase_service.dart';
import '../core/services/tts_service.dart';
import '../core/services/vibration_service.dart';
import '../core/services/voice_command_service.dart';
import '../models/scan_result.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Map<String, String> _profileData = {
    'name': '',
    'age': '',
    'emergencyContact': '',
    'emergencyPhone': '',
    'medicalNotes': '',
  };

  bool _isLoading = true;
  bool _isInterviewing = false;
  String _currentField = '';
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialised = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechInitialised = await _speech.initialize();
    setState(() {});
  }

  Future<void> _loadProfile() async {
    try {
      final data = await FirebaseService.instance.getUserProfile();
      if (data != null && mounted) {
        setState(() {
          _profileData['name'] = data['name'] ?? '';
          _profileData['age'] = data['age']?.toString() ?? '';
          _profileData['emergencyContact'] = data['emergencyContact'] ?? '';
          _profileData['emergencyPhone'] = data['emergencyPhone'] ?? '';
          _profileData['medicalNotes'] = data['medicalNotes'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    await FirebaseService.instance.updateUserProfile(_profileData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
      TtsService.instance.announce('Profile saved successfully.');
    }
  }

  // ── Voice Interview Logic ──────────────────────────────────────────

  Future<void> _startInterview() async {
    if (!_speechInitialised) {
      TtsService.instance.announce('Speech recognition not ready.');
      return;
    }

    setState(() => _isInterviewing = true);
    // Pause global voice service during interview to prevent interference
    VoiceCommandService.instance.stopListening();
    
    TtsService.instance.announce('Starting voice interview. I will ask you four questions.');

    await _askQuestion('name', 'What is your full name?');
    await _askQuestion('age', 'How old are you?');
    await _askQuestion('emergencyContact', 'Who is your emergency contact person?');
    await _askQuestion('emergencyPhone', 'What is their phone number? Only speak the digits.');
    await _askQuestion('medicalNotes', 'Do you have any medical notes or allergies?');

    setState(() => _isInterviewing = false);
    TtsService.instance.announce('Interview complete. Reviewing and saving your profile.');
    _saveProfile();
  }

  Future<void> _askQuestion(String field, String question) async {
    if (!mounted) return;
    setState(() => _currentField = field);
    
    // 1. Ask the question
    await TtsService.instance.announce(question);
    await Future.delayed(const Duration(seconds: 1)); // Buffer

    // 2. Start listening
    final completer = Completer<String>();
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          completer.complete(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 4),
    );

    VibrationService.instance.cameraReady(); // Cue to speak
    
    try {
      final answer = await completer.future.timeout(const Duration(seconds: 12));
      setState(() => _profileData[field] = answer);
      await TtsService.instance.announce('Received: $answer');
    } catch (_) {
      await TtsService.instance.announce('No answer detected for $field. Skipping.');
    }
    
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: AppBar(
        title: const Text('ACCESSIBILITY PROFILE'),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kColorPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(kPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildProfileField('NAME', _profileData['name']!, Icons.person),
                  _buildProfileField('AGE', _profileData['age']!, Icons.cake),
                  _buildProfileField('EMERGENCY CONTACT', _profileData['emergencyContact']!, Icons.emergency),
                  _buildProfileField('EMERGENCY PHONE', _profileData['emergencyPhone']!, Icons.phone_android),
                  _buildProfileField('MEDICAL NOTES', _profileData['medicalNotes']!, Icons.medical_services),
                  const SizedBox(height: 48),
                  _buildSaveButton(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _isInterviewing ? null : _startInterview,
        backgroundColor: _isInterviewing ? Colors.grey : kColorPrimary,
        child: Icon(
          _isInterviewing ? Icons.graphic_eq : Icons.mic_rounded,
          color: Colors.black,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kColorCard,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: kColorPrimary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'VOICE ASSISTANT PROFILE',
            style: TextStyle(color: kColorPrimary, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            _isInterviewing 
                ? 'LISTENING FOR: ${_currentField.toUpperCase()}'
                : 'Tap the microphone to fill your profile using your voice.',
            style: const TextStyle(color: kColorTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon) {
    bool isCurrent = _isInterviewing && _currentField.toLowerCase().contains(label.split(' ')[0].toLowerCase());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCurrent ? kColorPrimary.withOpacity(0.1) : kColorSurface,
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(color: isCurrent ? kColorPrimary : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isCurrent ? kColorPrimary : kColorTextSecondary),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: kColorTextSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? 'Not set' : value,
                    style: TextStyle(
                      color: value.isEmpty ? Colors.white24 : Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isInterviewing ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: kColorPrimary,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
      ),
      child: const Text('SAVE PROFILE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}
