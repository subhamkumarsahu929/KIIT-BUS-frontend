import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'screens/splash/splash_screen.dart';
import 'firebase_options.dart';

void main() {
  // Run the app inside a guarded zone so we can capture errors during
  // initialization (including Firebase initialization) and at runtime.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        // Forward to the default handler which prints to console
        FlutterError.presentError(details);
        // You can also report to your error tracking here
        debugPrint(
          'FlutterError caught by FlutterError.onError: ${details.exception}',
        );
      };

      // Initialize Firebase safely. Some device environments or missing
      // configuration can cause initialization to throw; catch and log it.
      try {
        // Prefer using the generated options for consistency across platforms.
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase initialized with DefaultFirebaseOptions');
      } catch (e, st) {
        debugPrint('Primary Firebase.initializeApp failed: $e');
        debugPrint('Stack: $st');
        // Fallback: try default initialization which reads google-services.json
        try {
          await Firebase.initializeApp();
          debugPrint('Firebase initialized with default (no options) fallback');
        } catch (e2, st2) {
          debugPrint('Firebase fallback initialize failed: $e2');
          debugPrint('Stack: $st2');
          // We continue launching the app so the UI can show an error message
        }
      }

      // Get stored login type (if any)
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('userType'); // "student" or "driver"

      runApp(KiitBusApp(userType: userType));
    },
    (error, stack) {
      // This catches any uncaught errors in the zone.
      debugPrint('Uncaught zone error: $error');
      debugPrint('Stack: $stack');
      // Show a minimal error UI so the app doesn't crash silently.
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Fatal error during app startup. Check logs.'),
            ),
          ),
        ),
      );
    },
  );
}

class KiitBusApp extends StatelessWidget {
  final String? userType;
  const KiitBusApp({super.key, this.userType});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KIIT BUS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
