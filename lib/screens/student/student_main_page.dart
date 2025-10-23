import 'package:flutter/material.dart';
import 'student_dashboard.dart';
import 'bus_schedule.dart';

class StudentMainPage extends StatelessWidget {
  const StudentMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KIIT BUS'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor, // ✅ keep green

        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: Colors.black, // ✅ only icon is black
            ),
            tooltip: 'About',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: Row(
                    children: const [
                      Icon(Icons.directions_bus, color: Colors.green, size: 30),
                      SizedBox(width: 10),
                      Text('About KIIT BUS'),
                    ],
                  ),
                  content: const Text(
                    'KIIT BUS helps students track live bus locations and view schedules.\n\n'
                    'Developed as a demonstration app for the KIIT Transport System.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK',
                          style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      body: const Center(
        child: Text(
          'Welcome to Student Portal',
          style: TextStyle(fontSize: 18),
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.dashboard, color: Colors.white),
                label: const Text(
                  'Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (_) => const StudentDashboard()),
                  // );
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.schedule, color: Colors.white),
                label: const Text(
                  'Schedule',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (_) => const BusSchedulePage()),
                  // );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
