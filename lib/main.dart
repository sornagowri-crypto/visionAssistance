// ─────────────────────────────────────────────────────────────
// main.dart — FIXED VERSION (CRASH SAFE)
// ─────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'core/theme.dart';
import 'core/services/settings_service.dart';

import 'screens/splash_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/history_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await SettingsService.instance.init();

  // ✅ SAFE FIREBASE INIT
  bool firebaseReady = false;

  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(VisionAssistantApp(firebaseReady: firebaseReady));
}

class VisionAssistantApp extends StatelessWidget {
  final bool firebaseReady;

  const VisionAssistantApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision Assistant',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routes: {
        '/': (_) => const SplashScreen(),
        '/camera': (_) => const CameraScreen(),
        '/result': (_) => const ResultScreen(),
        '/history': (_) => const HistoryScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
      initialRoute: '/',
    );
  }
}
