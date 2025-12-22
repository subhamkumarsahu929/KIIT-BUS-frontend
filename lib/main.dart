import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/splash/splash_screen.dart';
import 'api_services/notification_service.dart';

Future<void> main() async {
  var ensureInitialized = WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initNotifications();

  final prefs = await SharedPreferences.getInstance();
  final userType = prefs.getString('userType');

  runApp(KiitBusApp(userType: userType));
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
