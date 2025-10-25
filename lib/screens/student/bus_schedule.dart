import 'package:flutter/material.dart';
import '../../widgets/title_bar.dart';

class BusSchedulePage extends StatelessWidget {
  const BusSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleBar(title: 'Bus Schedule'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bus Schedule',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _busSchedules.length,
                itemBuilder: (context, index) {
                  final schedule = _busSchedules[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.directions_bus,
                        color: Theme.of(context).primaryColor,
                        size: 40,
                      ),
                      title: Text(
                        schedule['busNumber']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${schedule['route']}\nDeparture: ${schedule['time']}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final List<Map<String, String>> _busSchedules = [
    {
      'busNumber': 'BUS-01',
      'route': 'Campus 1 → Campus 7',
      'time': '07:00 AM',
    },
    {
      'busNumber': 'BUS-02',
      'route': 'Campus 7 → Campus 1',
      'time': '08:00 AM',
    },
    {
      'busNumber': 'BUS-03',
      'route': 'Campus 1 → Campus 15',
      'time': '09:00 AM',
    },
    {
      'busNumber': 'BUS-04',
      'route': 'Campus 15 → Campus 1',
      'time': '10:00 AM',
    },
  ];
}