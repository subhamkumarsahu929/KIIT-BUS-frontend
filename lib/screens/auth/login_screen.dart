import 'package:flutter/material.dart';
import '../student/student_main_page.dart';
import '../driver/driver_main_page.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.white10),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                 labelStyle: TextStyle(color: Colors.white10),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
               
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentMainPage()),
                );
              },
              child: const Text('Login as Student'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
           
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (_) => const DriverMainPage()),
                // );
              },
              child: const Text('Login as Driver'),
            ),
          ],
        ),
      ),
    );
  }
}
