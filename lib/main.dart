import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'screens/splash/splash_screen.dart';
import 'firebase_options.dart';

void main() {
 
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

     
      try {
      
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
       
      } catch (e ) {
        debugPrint('Primary Firebase.initializeApp failed: $e');
      
      
      }

      
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('userType');

      runApp(KiitBusApp(userType: userType));
    },
    (error, stack) {
     
      debugPrint('Uncaught zone error: $error');
      debugPrint('Stack: $stack');
      
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
