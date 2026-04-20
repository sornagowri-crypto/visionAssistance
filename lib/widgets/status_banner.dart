// ─────────────────────────────────────────────────────────────────────────────
// status_banner.dart — Status overlay displayed on the camera preview
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/constants.dart';

enum ScanStatus {
  idle,
  cameraReady,
  voiceListening,
  capturing,
  uploading,
  processing,
  descriptionReady,
  offline,
  error,
}

extension ScanStatusLabel on ScanStatus {
  String get label {
    switch (this) {
      case ScanStatus.idle:            return 'Initialising…';
      case ScanStatus.cameraReady:     return '📷  Camera Ready — Tap SCAN or say "Scan"';
      case ScanStatus.voiceListening:  return '🎙️  Listening for voice commands…';
      case ScanStatus.capturing:       return '📸  Capturing image…';
      case ScanStatus.uploading:       return '☁️  Uploading image…';
      case ScanStatus.processing:      return '🤖  AI is analysing…';
      case ScanStatus.descriptionReady:return '✅  Description ready — listening now';
      case ScanStatus.offline:         return '📴  Offline — using on-device detection';
      case ScanStatus.error:           return '⚠️  Something went wrong';
    }
  }

  Color get color {
    switch (this) {
      case ScanStatus.idle:            return kColorTextSecondary;
      case ScanStatus.cameraReady:     return kColorSuccess;
      case ScanStatus.voiceListening:  return kColorAccent;
      case ScanStatus.capturing:       return kColorPrimary;
      case ScanStatus.uploading:       return kColorPrimary;
      case ScanStatus.processing:      return kColorPrimary;
      case ScanStatus.descriptionReady:return kColorSuccess;
      case ScanStatus.offline:         return kColorAccent;
      case ScanStatus.error:           return kColorError;
    }
  }
}

class StatusBanner extends StatelessWidget {
  final ScanStatus status;
  final String? customMessage;

  const StatusBanner({
    super.key,
    required this.status,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final message = customMessage ?? status.label;
    final color = status.color;

    return Semantics(
      label: message,
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(message),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: kPadding,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: kColorBackground.withOpacity(0.85),
            border: Border(
              top: BorderSide(color: color.withOpacity(0.6), width: 2),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontSize: kFontSizeCaption,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
