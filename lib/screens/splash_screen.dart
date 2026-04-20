import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/services/firebase_service.dart';
import 'camera_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Pulsing Animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // 2. Initialise and Navigate
    _startTime();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _startTime() async {
    const duration = Duration(milliseconds: 2500);
    return Timer(duration, _navigationPage);
  }

  void _navigationPage() {
    final user = FirebaseService.instance.currentUser;
    
    // Smooth transition to next screen
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            user != null ? const CameraScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Matching project theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.05).animate(_animation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.8, end: 1.0).animate(_animation),
                child: Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 180,
                    height: 180,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            // App Name
            Text(
              kAppName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'RESTORING SIGHT THROUGH SOUND',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 64),
            // Minimal Loading Indicator
            const SizedBox(
              width: 40,
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                color: Colors.white30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
