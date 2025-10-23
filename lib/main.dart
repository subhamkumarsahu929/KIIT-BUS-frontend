import 'package:flutter/material.dart';
import 'theme.dart';

// Import all screens
import 'screens/splash/splash_screen.dart';
// import 'screens/auth/login_screen.dart';
// import 'screens/student/student_dashboard.dart';
// import 'screens/student/bus_schedule.dart';
// import 'screens/driver/driver_dashboard.dart';

void main() => runApp(const KiitBusApp());

class KiitBusApp extends StatelessWidget {
  const KiitBusApp({super.key});

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
