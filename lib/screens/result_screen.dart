// ─────────────────────────────────────────────────────────────────────────────
// result_screen.dart — Displays AI description and plays it via TTS
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../core/services/tts_service.dart';
import '../core/services/vibration_service.dart';
import '../core/services/voice_command_service.dart';
import '../models/scan_result.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late ScanResult _scan;
  bool _isSpeaking = false;
  bool _hasSpoken = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  final TtsService _tts = TtsService.instance;
  final VibrationService _vibration = VibrationService.instance;
  final VoiceCommandService _voice = VoiceCommandService.instance;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );

    // Set up TTS callbacks before speaking
    _tts.onComplete(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _tts.onError((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });

    // Voice commands on result screen
    _voice.startListening((command) {
      if (!mounted) return;
      switch (command) {
        case VoiceCommand.repeat:
          _speakDescription();
          break;
        case VoiceCommand.stop:
          _stopSpeaking();
          break;
        case VoiceCommand.scan:
          Navigator.pop(context);
          break;
        default:
          break;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scan = ModalRoute.of(context)!.settings.arguments as ScanResult;

    if (!_hasSpoken) {
      _hasSpoken = true;
      _slideController.forward();
      // Auto-speak after a short animation delay
      Future.delayed(const Duration(milliseconds: 700), _speakDescription);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _tts.stop();
    // Do NOT stop the global voice service here, as we want it to 
    // remain active when we return to the Camera screen.
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  Future<void> _speakDescription() async {
    if (!mounted) return;
    setState(() => _isSpeaking = true);
    await _tts.speak(_scan.description);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _shareDescription() async {
    final text = '👁 Vision Assistant identified: ${_scan.objectName}\n\n'
        '${_scan.description}\n\n'
        'Scanned on ${_scan.timestamp.toLocal().toString().split(".").first}';
    await Share.share(
      text,
      subject: 'Vision Assistant Scan: ${_scan.objectName}',
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      body: Stack(
        children: [
          // Background subtle gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D0D0D), kColorBackground],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(context),

                // Scrollable content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(kPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail image (pinch-to-zoom)
                            _buildImage(),
                            const SizedBox(height: kPadding),

                            // Object name
                            _buildObjectName(),
                            const SizedBox(height: kPadding),

                            // Description card
                            _buildDescriptionCard(),
                            const SizedBox(height: kPadding * 1.5),

                            // Offline badge
                            if (_scan.isOffline) _buildOfflineBadge(),
                            if (_scan.isOffline) const SizedBox(height: kPadding),

                            // Action buttons
                            _buildActions(context),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, kPadding, 0),
      child: Row(
        children: [
          Semantics(
            label: 'Go back to camera',
            button: true,
            child: IconButton(
              onPressed: () {
                _tts.stop();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: kColorTextPrimary),
            ),
          ),
          const Expanded(
            child: Text(
              'Scan Result',
              style: TextStyle(
                fontSize: kFontSizeTitle,
                fontWeight: FontWeight.w700,
                color: kColorPrimary,
              ),
            ),
          ),
          // History button
          Semantics(
            label: 'View scan history',
            button: true,
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              icon: const Icon(Icons.history_rounded, color: kColorTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    ImageProvider? imageProvider;

    if (_scan.imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(_scan.imageUrl);
    } else if (_scan.localPath.isNotEmpty && File(_scan.localPath).existsSync()) {
      imageProvider = FileImage(File(_scan.localPath));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(kBorderRadius),
      child: Container(
        width: double.infinity,
        height: 220,
        color: kColorCard,
        child: imageProvider != null
            ? Semantics(
                label: 'Scanned image of ${_scan.objectName}. Pinch to zoom.',
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  clipBehavior: Clip.hardEdge,
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  ),
                ),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const Center(
      child: Icon(Icons.image_not_supported_outlined,
          color: kColorTextSecondary, size: 48),
    );
  }

  Widget _buildObjectName() {
    return Semantics(
      header: true,
      label: 'Object identified: ${_scan.objectName}',
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, color: kColorPrimary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _scan.objectName,
              style: const TextStyle(
                fontSize: kFontSizeHero,
                fontWeight: FontWeight.w900,
                color: kColorTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Semantics(
      label: 'Description: ${_scan.description}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(kPadding),
        decoration: BoxDecoration(
          color: kColorCard,
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(color: kColorDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description_outlined, color: kColorAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: kFontSizeCaption,
                    fontWeight: FontWeight.w700,
                    color: kColorAccent,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _scan.description,
              style: const TextStyle(
                fontSize: kFontSizeBody,
                color: kColorTextPrimary,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kColorAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorAccent.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, color: kColorAccent, size: 18),
          SizedBox(width: 8),
          Text(
            'Offline detection — connect for a richer AI description',
            style: TextStyle(color: kColorAccent, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Speak / Stop toggle
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isSpeaking
              ? ElevatedButton.icon(
                  key: const ValueKey('stop'),
                  onPressed: _stopSpeaking,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop Reading'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kColorError,
                    foregroundColor: Colors.white,
                  ),
                )
              : ElevatedButton.icon(
                  key: const ValueKey('speak'),
                  onPressed: _speakDescription,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Read Description'),
                ),
        ),

        const SizedBox(height: 14),

        // Repeat
        Semantics(
          label: 'Repeat description button',
          button: true,
          child: OutlinedButton.icon(
            onPressed: _speakDescription,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Repeat'),
          ),
        ),

        const SizedBox(height: 14),

        // Share description
        Semantics(
          label: 'Share description button',
          button: true,
          child: OutlinedButton.icon(
            onPressed: _shareDescription,
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share Description'),
          ),
        ),

        const SizedBox(height: 14),

        // Scan Again
        Semantics(
          label: 'Scan another object button',
          button: true,
          child: OutlinedButton.icon(
            onPressed: () {
              _tts.stop();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Scan Another Object'),
          ),
        ),

        const SizedBox(height: 16),

        // Voice command hint
        Semantics(
          label: 'Voice commands: say Repeat, Stop, or Scan',
          child: Center(
            child: Text(
              '🎙️  Say "Repeat", "Stop", or "Scan" to use voice commands',
              style: TextStyle(
                fontSize: 13,
                color: kColorTextSecondary.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
