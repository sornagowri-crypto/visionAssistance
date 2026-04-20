// ─────────────────────────────────────────────────────────────────────────────
// scan_overlay.dart — Animated scanning overlay shown during image processing
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/constants.dart';

/// A full-screen animated overlay that appears while the app is scanning.
/// Shows a pulsing ring, spinning arc, and status text.
class ScanOverlay extends StatefulWidget {
  final String statusText;

  const ScanOverlay({super.key, required this.statusText});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _spinController;
  late final AnimationController _fadeController;

  late final Animation<double> _pulseAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Pulse ring animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Spinner animation
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Fade-in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spinController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black.withOpacity(0.72),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing ring with spinner
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsing ring
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kColorPrimary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    // Spinning arc
                    RotationTransition(
                      turns: _spinController,
                      child: CustomPaint(
                        size: const Size(110, 110),
                        painter: _ArcPainter(color: kColorPrimary),
                      ),
                    ),

                    // Centre eye icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kColorPrimary.withOpacity(0.12),
                        border: Border.all(
                          color: kColorPrimary.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.remove_red_eye_rounded,
                        color: kColorPrimary,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Status text
              Semantics(
                liveRegion: true,
                label: widget.statusText,
                child: Text(
                  widget.statusText,
                  style: const TextStyle(
                    color: kColorTextPrimary,
                    fontSize: kFontSizeBody,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Please hold the camera steady',
                style: TextStyle(
                  color: kColorTextSecondary.withOpacity(0.7),
                  fontSize: kFontSizeCaption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Arc painter — spinning arc around the eye icon ────────────────────────────

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw two arcs — creates a "dashed" spinning feel
    canvas.drawArc(rect, 0, 1.4, false, paint);
    paint.color = color.withOpacity(0.3);
    canvas.drawArc(rect, 1.6, 1.4, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
