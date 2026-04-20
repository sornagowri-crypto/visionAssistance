// ─────────────────────────────────────────────────────────────────────────────
// scan_button.dart — Large, accessible, animated scan button
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/constants.dart';

class ScanButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isScanning;

  const ScanButton({
    super.key,
    required this.onPressed,
    this.isScanning = false,
  });

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Scan button. Double tap to capture object.',
      button: true,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              if (!widget.isScanning)
                Transform.scale(
                  scale: _scaleAnim.value * 1.25,
                  child: Container(
                    width: kScanButtonSize,
                    height: kScanButtonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kColorPrimary.withOpacity(_opacityAnim.value),
                    ),
                  ),
                ),
              // Middle ring
              Transform.scale(
                scale: widget.isScanning ? 1.0 : _scaleAnim.value * 1.1,
                child: Container(
                  width: kScanButtonSize,
                  height: kScanButtonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kColorPrimary.withOpacity(0.2),
                    border: Border.all(color: kColorPrimary, width: 2),
                  ),
                ),
              ),
              // Main button
              GestureDetector(
                onTap: widget.onPressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: kScanButtonSize,
                  height: kScanButtonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isScanning ? kColorPrimaryDark : kColorPrimary,
                    boxShadow: [
                      BoxShadow(
                        color: kColorPrimary.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: widget.isScanning
                      ? const Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 3,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.black,
                              size: 40,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'SCAN',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
