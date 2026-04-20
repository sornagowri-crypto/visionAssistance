// ─────────────────────────────────────────────────────────────────────────────
// settings_screen.dart — Accessibility settings: TTS, vibration, font, contrast
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/services/settings_service.dart';
import '../core/services/tts_service.dart';
import '../core/services/vibration_service.dart';
import '../core/services/voice_command_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService.instance;
  final TtsService _tts = TtsService.instance;
  final VibrationService _vibration = VibrationService.instance;

  // Local state mirrors for smooth slider interaction
  late double _ttsSpeed;
  late double _fontScale;
  late bool _vibrationOn;
  late bool _highContrast;
  late bool _autoSpeak;

  @override
  void initState() {
    super.initState();
    _syncFromSettings();
    _tts.announce('Settings. Adjust TTS speed, vibration, and display preferences.');
    _initVoiceCommands();
  }

  void _initVoiceCommands() {
    VoiceCommandService.instance.startListening((command) {
      if (!mounted) return;
      switch (command) {
        case VoiceCommand.scan:
          Navigator.pop(context); // Go back to camera
          break;
        case VoiceCommand.stop:
          _tts.stop();
          break;
        case VoiceCommand.history:
          Navigator.pushReplacementNamed(context, '/history');
          break;
        default:
          break;
      }
    });
  }

  void _syncFromSettings() {
    _ttsSpeed    = _settings.ttsSpeed;
    _fontScale   = _settings.fontScale;
    _vibrationOn = _settings.vibrationOn;
    _highContrast = _settings.highContrast;
    _autoSpeak   = _settings.autoSpeak;
  }

  Future<void> _saveAll() async {
    await _settings.setTtsSpeed(_ttsSpeed);
    await _settings.setFontScale(_fontScale);
    await _settings.setVibrationOn(_vibrationOn);
    await _settings.setHighContrast(_highContrast);
    await _settings.setAutoSpeak(_autoSpeak);

    // Apply TTS speed immediately
    await _tts.init();

    await _vibration.success();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved'),
          backgroundColor: kColorSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      _tts.announce('Settings saved.');
    }
  }

  Future<void> _resetAll() async {
    await _settings.resetAll();
    setState(_syncFromSettings);
    await _vibration.buttonTap();
    _tts.announce('Settings reset to defaults.');
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
        leading: Semantics(
          label: 'Go back',
          button: true,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        actions: [
          Semantics(
            label: 'Reset all settings to defaults',
            button: true,
            child: TextButton(
              onPressed: _resetAll,
              child: const Text(
                'Reset',
                style: TextStyle(color: kColorTextSecondary),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPadding),
        children: [
          // ── Account Section ──────────────────────────────────────────────────
          _buildSectionHeader(
            icon: Icons.account_circle_rounded,
            title: 'Account & Profile',
            color: kColorPrimary,
          ),

          _buildCard(children: [
            ListTile(
              leading: const Icon(Icons.person_rounded, color: kColorPrimary),
              title: const Text(
                'Accessibility Profile',
                style: TextStyle(color: kColorTextPrimary, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Emergency contact, medical notes, and voice setup',
                style: TextStyle(color: kColorTextSecondary, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: kColorTextSecondary),
              onTap: () {
                _vibration.buttonTap();
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ]),

          const SizedBox(height: kPadding),

          // ── TTS Section ─────────────────────────────────────────────────────
          _buildSectionHeader(
            icon: Icons.record_voice_over_rounded,
            title: 'Speech',
            color: kColorAccent,
          ),

          _buildCard(children: [
            // TTS Speed
            _buildSliderTile(
              semanticLabel: 'TTS speed: ${(_ttsSpeed * 100).round()} percent',
              label: 'Speech Speed',
              value: _ttsSpeed,
              min: 0.2,
              max: 1.0,
              divisions: 8,
              leftLabel: 'Slow',
              rightLabel: 'Fast',
              onChanged: (v) => setState(() => _ttsSpeed = v),
              onChangeEnd: (_) async {
                await _settings.setTtsSpeed(_ttsSpeed);
                _tts.announce(
                    'Speed set to ${(_ttsSpeed * 100).round()} percent. Testing.');
              },
            ),

            _buildDivider(),

            // Auto-speak
            _buildSwitchTile(
              semanticLabel: 'Auto-speak descriptions',
              icon: Icons.auto_awesome_rounded,
              label: 'Auto-Speak Results',
              subtitle: 'Automatically read descriptions aloud after scanning',
              value: _autoSpeak,
              onChanged: (v) {
                setState(() => _autoSpeak = v);
                _settings.setAutoSpeak(v);
                _vibration.buttonTap();
                _tts.announce(v ? 'Auto-speak on.' : 'Auto-speak off.');
              },
            ),
          ]),

          const SizedBox(height: kPadding),

          // ── Haptics Section ─────────────────────────────────────────────────
          _buildSectionHeader(
            icon: Icons.vibration_rounded,
            title: 'Haptics',
            color: kColorSuccess,
          ),

          _buildCard(children: [
            _buildSwitchTile(
              semanticLabel: 'Vibration feedback toggle',
              icon: Icons.vibration_rounded,
              label: 'Vibration Feedback',
              subtitle: 'Feel pulses for camera-ready, captures, and errors',
              value: _vibrationOn,
              onChanged: (v) {
                setState(() => _vibrationOn = v);
                _settings.setVibrationOn(v);
                if (v) _vibration.success();
                _tts.announce(v ? 'Vibration on.' : 'Vibration off.');
              },
            ),
          ]),

          const SizedBox(height: kPadding),

          // ── Display Section ─────────────────────────────────────────────────
          _buildSectionHeader(
            icon: Icons.display_settings_rounded,
            title: 'Display',
            color: kColorPrimary,
          ),

          _buildCard(children: [
            // Font Scale
            _buildSliderTile(
              semanticLabel:
                  'Font size: ${(_fontScale * 100).round()} percent',
              label: 'Text Size',
              value: _fontScale,
              min: 0.8,
              max: 1.6,
              divisions: 8,
              leftLabel: 'Smaller',
              rightLabel: 'Larger',
              onChanged: (v) => setState(() => _fontScale = v),
              onChangeEnd: (_) => _settings.setFontScale(_fontScale),
            ),

            _buildDivider(),

            // High contrast
            _buildSwitchTile(
              semanticLabel: 'High contrast mode toggle',
              icon: Icons.contrast_rounded,
              label: 'High Contrast Mode',
              subtitle: 'Increases border visibility and colour saturation',
              value: _highContrast,
              onChanged: (v) {
                setState(() => _highContrast = v);
                _settings.setHighContrast(v);
                _vibration.buttonTap();
                _tts.announce(
                    v ? 'High contrast on.' : 'High contrast off.');
              },
            ),
          ]),

          const SizedBox(height: kPadding * 1.5),

          // Save button
          Semantics(
            label: 'Save all settings',
            button: true,
            child: ElevatedButton.icon(
              onPressed: _saveAll,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ),

          const SizedBox(height: kPadding),

          // Voice command hint
          const _HintCard(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: kColorCard,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: kColorDivider),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFF2C2C2C));
  }

  Widget _buildSliderTile({
    required String semanticLabel,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String leftLabel,
    required String rightLabel,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Semantics(
      label: semanticLabel,
      slider: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kPadding, 16, kPadding, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: kFontSizeCaption,
                fontWeight: FontWeight.w600,
                color: kColorTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: kColorPrimary,
                inactiveTrackColor: kColorDivider,
                thumbColor: kColorPrimary,
                overlayColor: kColorPrimary.withOpacity(0.12),
                trackHeight: 4,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(leftLabel,
                      style: const TextStyle(
                          fontSize: 11, color: kColorTextSecondary)),
                  Text(rightLabel,
                      style: const TextStyle(
                          fontSize: 11, color: kColorTextSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String semanticLabel,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Semantics(
      label: semanticLabel,
      toggled: value,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: kPadding, vertical: 4),
        leading: Icon(icon,
            color: value ? kColorPrimary : kColorTextSecondary, size: 24),
        title: Text(
          label,
          style: const TextStyle(
            color: kColorTextPrimary,
            fontSize: kFontSizeCaption,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: kColorTextSecondary,
            fontSize: 13,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: kColorPrimary,
          inactiveTrackColor: kColorDivider,
        ),
      ),
    );
  }
}

// ── Hint card ─────────────────────────────────────────────────────────────────

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kPadding),
      decoration: BoxDecoration(
        color: kColorAccent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: kColorAccent.withOpacity(0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: kColorAccent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Voice commands work on every screen.\n'
              'Say "Scan", "Repeat", "Stop", or "History" at any time.',
              style: TextStyle(
                color: kColorAccent,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
