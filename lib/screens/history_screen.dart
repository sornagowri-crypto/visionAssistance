// ─────────────────────────────────────────────────────────────────────────────
// history_screen.dart — Firestore-backed scan history with TTS playback
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/services/firebase_service.dart';
import '../core/services/tts_service.dart';
import '../core/services/vibration_service.dart';
import '../core/services/voice_command_service.dart';
import '../models/scan_result.dart';
import '../widgets/history_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TtsService _tts = TtsService.instance;
  final VibrationService _vibration = VibrationService.instance;

  @override
  void initState() {
    super.initState();
    _tts.announce('Scan history. Tap any item to hear its description.');
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
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  void _onTileTap(ScanResult scan) {
    _vibration.buttonTap();
    Navigator.pushNamed(context, '/result', arguments: scan);
  }

  void _onDeleteTap(BuildContext context, ScanResult scan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kColorCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        title: const Text(
          'Delete Scan',
          style: TextStyle(color: kColorTextPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete the scan of "${scan.objectName}"?',
          style: const TextStyle(color: kColorTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kColorTextSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseService.instance.deleteScan(scan);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scan deleted.')),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not delete. Try again.'),
                      backgroundColor: kColorError,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: kColorError)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: AppBar(
        title: const Text(kHistoryLabel),
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
            label: 'Stop reading',
            button: true,
            child: IconButton(
              onPressed: () => _tts.stop(),
              icon: const Icon(Icons.stop_rounded),
              tooltip: 'Stop TTS',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ScanResult>>(
        stream: FirebaseService.instance.scanHistoryStream(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kColorPrimary),
                  SizedBox(height: 16),
                  Text(
                    'Loading history…',
                    style: TextStyle(color: kColorTextSecondary),
                  ),
                ],
              ),
            );
          }

          // Error
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final scans = snapshot.data ?? [];

          // Empty state
          if (scans.isEmpty) {
            return _buildEmptyState();
          }

          // History list
          return RefreshIndicator(
            color: kColorPrimary,
            backgroundColor: kColorCard,
            onRefresh: () async {
              // Stream auto-refreshes; just add a short delay for UX
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Column(
              children: [
                // Stats banner
                _buildStatsBanner(scans.length),

                // List
                Expanded(
                  child: ListView.builder(
                    itemCount: scans.length,
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    itemBuilder: (context, index) {
                      final scan = scans[index];
                      return HistoryTile(
                        scan: scan,
                        onTap: () => _onTileTap(scan),
                        onDelete: () => _onDeleteTap(context, scan),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsBanner(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(kPadding, 12, kPadding, 4),
      padding: const EdgeInsets.symmetric(horizontal: kPadding, vertical: 12),
      decoration: BoxDecoration(
        color: kColorCard,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: kColorDivider),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: kColorPrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count object${count == 1 ? '' : 's'} scanned',
              style: const TextStyle(
                fontSize: kFontSizeBody,
                fontWeight: FontWeight.w600,
                color: kColorTextPrimary,
              ),
            ),
          ),
          Text(
            'Pull to refresh',
            style: TextStyle(
              fontSize: 12,
              color: kColorTextSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kColorCard,
                border: Border.all(color: kColorDivider, width: 2),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: kColorTextSecondary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No scans yet',
              style: TextStyle(
                fontSize: kFontSizeTitle,
                fontWeight: FontWeight.w700,
                color: kColorTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Objects you scan will appear here.\nGo back and tap SCAN to get started.',
              style: TextStyle(
                fontSize: kFontSizeCaption,
                color: kColorTextSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Go to Camera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: kColorError, size: 56),
            const SizedBox(height: 20),
            const Text(
              'Couldn\'t load history',
              style: TextStyle(
                fontSize: kFontSizeTitle,
                fontWeight: FontWeight.w700,
                color: kColorTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check your internet connection and try again.',
              style: const TextStyle(
                fontSize: kFontSizeCaption,
                color: kColorTextSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
