// ─────────────────────────────────────────────────────────────────────────────
// camera_screen.dart — Main live camera preview and scan screen
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/services/firebase_service.dart';
import '../core/services/gemini_service.dart';
import '../core/services/mlkit_service.dart';
import '../core/services/settings_service.dart';
import '../core/services/tts_service.dart';
import '../core/services/vibration_service.dart';
import '../core/services/voice_command_service.dart';
import '../models/scan_result.dart';
import '../widgets/scan_button.dart';
import '../widgets/scan_overlay.dart';
import '../widgets/status_banner.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  // ── Camera state ─────────────────────────────────────────────────────────────
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _cameraInitialised = false;
  bool _cameraPermissionDenied = false;

  // ── UI state ──────────────────────────────────────────────────────────────────
  ScanStatus _status = ScanStatus.idle;
  bool _isScanning = false;
  bool _voiceEnabled = true;
  String _lastDescription = ''; // Track for "Repeat" command

  final VibrationService _vibration = VibrationService.instance;
  final TtsService _tts = TtsService.instance;
  final VoiceCommandService _voice = VoiceCommandService.instance;
  final Uuid _uuid = const Uuid();

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _initVoiceCommands();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _voice.stopListening();
    super.dispose();
  }

  // ── Camera initialisation ─────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        setState(() => _cameraPermissionDenied = true);
      }
      _tts.announce('Camera permission is required. Please enable it in settings.');
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _tts.announce('No camera found on this device.');
        return;
      }

      _controller = CameraController(
        _cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _cameraInitialised = true;
          _status = ScanStatus.cameraReady;
        });
        await _vibration.cameraReady();
        await _tts.announce('Camera ready. Tap the SCAN button or say "Scan" to identify an object.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = ScanStatus.error);
        _tts.announce('Camera failed to start. Please restart the app.');
      }
    }
  }

  // ── Voice commands ────────────────────────────────────────────────────────────

  Future<void> _initVoiceCommands() async {
    final ok = await Permission.microphone.request();
    if (!ok.isGranted) return;

    await _voice.startListening((command) {
      if (!mounted || _isScanning) return;
      switch (command) {
        case VoiceCommand.scan:
          _captureAndDescribe();
          break;
        case VoiceCommand.repeat:
          if (_lastDescription.isNotEmpty) {
            _tts.announce(_lastDescription);
          } else {
            _tts.announce('Nothing to repeat yet. Scan an object first.');
          }
          break;
        case VoiceCommand.stop:
          _tts.stop();
          break;
        case VoiceCommand.share:
          if (_lastDescription.isNotEmpty) {
            _shareToDirectContact(); // Direct sharing logic
          } else {
            _tts.announce('Nothing to share yet.');
          }
          break;
        case VoiceCommand.history:
          Navigator.pushNamed(context, '/history');
          break;
        case VoiceCommand.unknown:
          break;
      }
    });
  }

  // ── Image capture and description pipeline ────────────────────────────────────

  Future<void> _captureAndDescribe() async {
    if (!_cameraInitialised || _isScanning || _controller == null) return;

    _tts.announce('Scanning...'); // Universal feedback (Button & Voice)

    setState(() {
      _isScanning = true;
      _status = ScanStatus.capturing;
    });

    // 1. Capture image
    XFile? xFile;
    try {
      xFile = await _controller!.takePicture();
    } catch (e) {
      _handleError('Failed to capture image. Try again.');
      return;
    }

    await _vibration.imageCaptured();
    final imageFile = File(xFile.path);

    // 2. Check connectivity (connectivity_plus v5 returns List<ConnectivityResult>)
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty &&
        !connectivityResults.contains(ConnectivityResult.none);

    String description;
    String objectName;
    String imageUrl = '';
    bool isOffline = false;

    if (isOnline) {
      // ── Online: Gemini Vision ──────────────────────────────────────────────

      // 3a. Upload image to Firebase Storage
      setState(() => _status = ScanStatus.uploading);
      try {
        imageUrl = await FirebaseService.instance.uploadImage(imageFile);
      } catch (_) {
        // Non-fatal — continue without a remote URL
        imageUrl = '';
      }

      // 3b. Call Gemini API
      setState(() => _status = ScanStatus.processing);
      try {
        final result = await GeminiService.instance.describe(imageFile);
        description = result.fullDescription;
        objectName = result.objectName;
        await _tts.announce('I can see $objectName.');
      } on GeminiException catch (e) {
        _handleError(e.message);
        return;
      }
    } else {
      // ── Offline: MLKit ──────────────────────────────────────────────────────
      setState(() => _status = ScanStatus.offline);
      isOffline = true;
      try {
        final result = await MlKitService.instance.detect(imageFile);
        description = result.description;
        objectName = result.objectName;
      } on MlKitException catch (e) {
        _handleError(e.message);
        return;
      }
    }

    // 4. Vibrate to signal description ready
    await _vibration.descriptionReady();
    setState(() => _status = ScanStatus.descriptionReady);

    // 5. Build and save ScanResult
    final uid = FirebaseService.instance.currentUser?.uid ?? 'anonymous';
    final scan = ScanResult(
      id:          _uuid.v4(),
      imageUrl:    imageUrl,
      localPath:   xFile.path,
      description: description,
      objectName:  objectName,
      timestamp:   DateTime.now(),
      isOffline:   isOffline,
      userId:      uid,
    );

    // Save to Firestore (non-blocking)
    if (isOnline) {
      FirebaseService.instance.saveScan(scan).catchError((_) {
        return '';
      });
    }

    // 6. Navigate to result screen
    if (mounted) {
      _lastDescription = description; // Save for Repeat/Share
      setState(() => _isScanning = false);
      
      // Stop current listening session while we navigate
      _voice.stopListening(); 

      await Navigator.pushNamed(context, '/result', arguments: scan);
      
      // Re-initialize voice commands when we return to camera
      if (mounted) {
        setState(() => _status = ScanStatus.cameraReady);
        _initVoiceCommands();
      }
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _status = ScanStatus.error;
    });
    _vibration.error();
    _tts.announce(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kColorError,
        duration: const Duration(seconds: 4),
      ),
    );
    // Reset to ready after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _status = ScanStatus.cameraReady);
    });
  }

  Future<void> _shareToDirectContact() async {
    if (_lastDescription.isEmpty) return;

    // 1. Get profile data
    final profile = await FirebaseService.instance.getUserProfile();
    final name = profile?['emergencyContact'] as String? ?? '';
    final phone = profile?['emergencyPhone'] as String? ?? '';

    if (phone.isNotEmpty) {
      // 2. Direct Sharing via SMS (Accessibility improvement)
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: <String, String>{
          'body': 'Vision Assistant Scan Result: $_lastDescription',
        },
      );

      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          // Only announce success if intent actually launched
          _tts.announce('Opening message to $name. Shared successfully.');
        } else {
          _shareDescription(); // Fallback to standard share
        }
      } catch (e) {
        _shareDescription(); // Fallback
      }
    } else {
      // 3. Fallback to standard share sheet if no contact saved
      _shareDescription();
    }
  }

  Future<void> _shareDescription() async {
    if (_lastDescription.isEmpty) return;
    try {
      await Share.share(_lastDescription, subject: 'Vision Assistant Scan');
      // Note: On Android, we can't reliably confirm the user hit Send,
      // but we announce after the sheet opens.
      _tts.announce('Opening share menu.');
    } catch (e) {
      _tts.announce('Sharing failed.');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview / placeholder
          _buildCameraPreview(),

          // Top bar (app name + menu)
          _buildTopBar(),

          // Status banner — bottom of screen
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan button (Restored)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ScanButton(
                    onPressed: _isScanning ? null : _captureAndDescribe,
                    isScanning: _isScanning,
                  ),
                ),

                // Pulsing Mic UI
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: _MicPulse(
                    isListening: _voiceEnabled && !_isScanning,
                    isScanning: _isScanning,
                  ),
                ),

                // Action row — voice toggle / history
                _buildActionRow(),

                // Status banner
                StatusBanner(status: _status),

                // Safe area spacer
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),

          // Animated scan overlay (shown while scanning)
          if (_isScanning)
            Positioned.fill(
              child: ScanOverlay(
                statusText: _scanStatusLabel(_status),
              ),
            ),
        ],
      ),
    );
  }

  String _scanStatusLabel(ScanStatus status) {
    switch (status) {
      case ScanStatus.capturing:    return 'Capturing image…';
      case ScanStatus.uploading:    return 'Uploading…';
      case ScanStatus.processing:   return 'Analysing with AI…';
      case ScanStatus.offline:      return 'Detecting offline…';
      case ScanStatus.descriptionReady: return 'Description ready!';
      default:                      return 'Processing…';
    }
  }

  Widget _buildCameraPreview() {
    if (_cameraPermissionDenied) {
      return _buildPlaceholder(
        Icons.no_photography_rounded,
        'Camera permission denied.\nPlease open Settings and allow camera access.',
      );
    }

    if (!_cameraInitialised || _controller == null) {
      return _buildPlaceholder(
        Icons.camera,
        'Starting camera…',
        showSpinner: true,
      );
    }

    return Positioned.fill(
      child: CameraPreview(_controller!),
    );
  }

  Widget _buildPlaceholder(
    IconData icon,
    String message, {
    bool showSpinner = false,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            const CircularProgressIndicator(color: kColorPrimary)
          else
            Icon(icon, color: kColorTextSecondary, size: 64),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              style: const TextStyle(
                color: kColorTextSecondary,
                fontSize: kFontSizeCaption,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_cameraPermissionDenied) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: openAppSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kPadding,
            vertical: 8,
          ),
          child: Row(
            children: [
              // App title
              const Text(
                kAppName,
                style: TextStyle(
                  color: kColorPrimary,
                  fontSize: kFontSizeTitle,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),

              // Settings button
              Semantics(
                label: 'Accessibility settings',
                button: true,
                child: IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: kColorTextPrimary,
                    size: 26,
                  ),
                  tooltip: 'Settings',
                ),
              ),

              // History button
              Semantics(
                label: 'View scan history',
                button: true,
                child: IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/history'),
                  icon: const Icon(
                    Icons.history_rounded,
                    color: kColorTextPrimary,
                    size: 28,
                  ),
                  tooltip: 'Scan History',
                ),
              ),

              // Profile button
              Semantics(
                label: 'User account',
                button: true,
                child: IconButton(
                  onPressed: _showUserMenu,
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: kColorPrimary.withOpacity(0.2),
                    foregroundImage: FirebaseService.instance.photoUrl != null
                        ? NetworkImage(FirebaseService.instance.photoUrl!)
                        : null,
                    child: const Icon(
                      Icons.person,
                      color: kColorPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kPadding, 0, kPadding, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Voice toggle
          _ActionChip(
            icon: _voiceEnabled
                ? Icons.mic_rounded
                : Icons.mic_off_rounded,
            label: _voiceEnabled ? 'Voice ON' : 'Voice OFF',
            color: _voiceEnabled ? kColorSuccess : kColorTextSecondary,
            onTap: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              if (_voiceEnabled) {
                _initVoiceCommands();
                _tts.announce('Voice commands enabled.');
              } else {
                _voice.stopListening();
                _tts.announce('Voice commands disabled.');
              }
            },
          ),
          const SizedBox(width: 12),

          // Camera switch (if multiple cameras)
          if (_cameras.length > 1)
            _ActionChip(
              icon: Icons.flip_camera_ios_rounded,
              label: 'Flip',
              color: kColorTextSecondary,
              onTap: _flipCamera,
            ),
        ],
      ),
    );
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    final currentIndex = _cameras.indexOf(_controller!.description);
    final nextIndex = (currentIndex + 1) % _cameras.length;
    await _controller?.dispose();
    _controller = CameraController(_cameras[nextIndex], ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kColorCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(kPadding * 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kColorDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: kColorPrimary.withOpacity(0.2),
              foregroundImage: FirebaseService.instance.photoUrl != null
                  ? NetworkImage(FirebaseService.instance.photoUrl!)
                  : null,
              child: const Icon(Icons.person, color: kColorPrimary, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              FirebaseService.instance.displayName,
              style: const TextStyle(
                fontSize: kFontSizeBody,
                fontWeight: FontWeight.w700,
                color: kColorTextPrimary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await FirebaseService.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              icon: const Icon(Icons.logout, color: kColorError),
              label: const Text('Sign Out', style: TextStyle(color: kColorError)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Action chip helper ─────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kColorCard.withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// _MicPulse — Animated mic icon shown for voice-first UI
// ─────────────────────────────────────────────────────────────────────────────

class _MicPulse extends StatefulWidget {
  final bool isListening;
  final bool isScanning;

  const _MicPulse({required this.isListening, required this.isScanning});

  @override
  State<_MicPulse> createState() => _MicPulseState();
}

class _MicPulseState extends State<_MicPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isScanning) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(color: kColorPrimary, strokeWidth: 4),
      );
    }

    if (!widget.isListening) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: kColorDivider,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic_off_rounded, color: kColorTextSecondary, size: 28),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Container(
            width: 64 * _scale.value,
            height: 64 * _scale.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: kColorPrimary.withOpacity(_opacity.value),
                width: 2,
              ),
            ),
          ),
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: kColorPrimary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kColorPrimary.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.black, size: 30),
        ),
      ],
    );
  }
}
