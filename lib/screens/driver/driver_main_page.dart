import 'package:flutter/material.dart';
import 'driver_dashboard.dart';

class DriverMainPage extends StatelessWidget {
  const DriverMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Main Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => const DriverDashboard()),
          //   );
          },
          child: const Text('Go to Dashboard'),
        ),
      ),
    );
  }
}
