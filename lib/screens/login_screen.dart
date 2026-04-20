// ─────────────────────────────────────────────────────────────────────────────
// login_screen.dart — Google Sign-In and anonymous access entry point
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/services/firebase_service.dart';
import '../core/services/tts_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();

    // Welcome announcement for screen readers / TTS
    Future.delayed(const Duration(milliseconds: 600), () {
      TtsService.instance.announce(
        'Welcome to Vision Assistant. '
        'Sign in with Google to save your scan history, '
        'or continue without signing in.',
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Auth Actions ──────────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await FirebaseService.instance.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/camera');
      } else {
        setState(() => _isLoading = false);
      }
    } on FirebaseServiceException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sign-in failed. Please try again.';
      });
    }
  }

  Future<void> _continueAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseService.instance.signInAnonymously();
      if (mounted) Navigator.pushReplacementNamed(context, '/camera');
    } catch (_) {
      // Even if anonymous auth fails, still go to camera
      if (mounted) Navigator.pushReplacementNamed(context, '/camera');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF111111),
                  kColorBackground,
                ],
              ),
            ),
          ),

          // Yellow glowing orb — top right
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kColorPrimary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kPadding * 1.5),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // App icon / logo
                      _buildLogo(),

                      const SizedBox(height: 28),

                      // Title
                      const Text(
                        kAppName,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: kColorPrimary,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        kTagline,
                        style: TextStyle(
                          fontSize: kFontSizeBody,
                          color: kColorTextSecondary,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(flex: 2),

                      // Feature pills
                      _buildFeaturePills(),

                      const Spacer(flex: 3),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kColorError.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kColorError.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber, color: kColorError, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: kColorError,
                                    fontSize: kFontSizeCaption,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Google Sign-In Button
                      Semantics(
                        label: 'Sign in with Google button',
                        button: true,
                        child: _isLoading
                            ? const SizedBox(
                                height: 64,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: kColorPrimary,
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _signInWithGoogle,
                                icon: const _GoogleIcon(),
                                label: const Text(kSignInLabel),
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Anonymous / Skip button
                      Semantics(
                        label: 'Continue without sign-in button',
                        button: true,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _continueAnonymously,
                          child: const Text(kSkipLabel),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Disclaimer
                      Text(
                        'By signing in, history and scans are saved to your account.',
                        style: TextStyle(
                          fontSize: 13,
                          color: kColorTextSecondary.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kColorPrimary.withOpacity(0.12),
        border: Border.all(color: kColorPrimary.withOpacity(0.4), width: 2),
      ),
      child: const Center(
        child: Icon(
          Icons.remove_red_eye_rounded,
          color: kColorPrimary,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildFeaturePills() {
    final features = [
      ('🔍', 'AI Object Detection'),
      ('🔊', 'Audio Descriptions'),
      ('📵', 'Works Offline'),
      ('📜', 'Scan History'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: features
          .map(
            (f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kColorCard,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kColorDivider),
              ),
              child: Text(
                '${f.$1}  ${f.$2}',
                style: const TextStyle(
                  fontSize: kFontSizeCaption,
                  color: kColorTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Google icon placeholder ───────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
