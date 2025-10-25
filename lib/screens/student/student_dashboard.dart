import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/title_bar.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final TextEditingController _busNumberController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? busLocation;

  final dbRef = FirebaseDatabase.instance.ref("bus_locations");

  void _trackBus(String busNumber) {
    dbRef.child(busNumber).onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && data.containsKey('latitude')) {
        setState(() {
          busLocation =
              LatLng(data['latitude'] as double, data['longitude'] as double);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(busLocation!),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleBar(title: 'Student Dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Student Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _busNumberController,
              decoration: InputDecoration(
                hintText: 'Enter Bus Number (e.g. BUS-12)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.directions_bus),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  final busNumber = _busNumberController.text.trim();
                  if (busNumber.isNotEmpty) {
                    _trackBus(busNumber);
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text("View Live Location"),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: busLocation == null
                  ? const Center(
                      child: Text(
                        "No bus location yet...",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : GoogleMap(
                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: busLocation!,
                        zoom: 16,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('bus'),
                          position: busLocation!,
                          infoWindow:
                              const InfoWindow(title: "Bus Current Location"),
                        ),
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
