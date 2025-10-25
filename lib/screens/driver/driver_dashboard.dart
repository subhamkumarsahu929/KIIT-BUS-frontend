import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../widgets/title_bar.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _busNumberController = TextEditingController();

  bool isSharing = false;
  Location location = Location();
  LocationData? currentLocation;
  GoogleMapController? _mapController;

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    currentLocation = await location.getLocation();
    setState(() {});
  }

  void _startLocationUpdates(String busNumber) {
    location.onLocationChanged.listen((newLoc) {
      setState(() {
        currentLocation = newLoc;
      });

      // Move camera
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(newLoc.latitude!, newLoc.longitude!),
        ),
      );

     
      dbRef.child("bus_locations").child(busNumber).set({
        'latitude': newLoc.latitude,
        'longitude': newLoc.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  void _stopLocationUpdates(String busNumber) {
    dbRef.child("bus_locations").child(busNumber).remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleBar(title: 'Driver Dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver Control Panel',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _busNumberController,
                decoration: InputDecoration(
                  hintText: 'e.g. BUS-12',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.directions_bus),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter bus number" : null,
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSharing ? Colors.red : Theme.of(context).primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                icon: Icon(
                  isSharing ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                ),
                label: Text(
                  isSharing
                      ? 'Stop Sharing Location'
                      : 'Start Sharing Location',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final busNumber = _busNumberController.text.trim();

                    setState(() => isSharing = !isSharing);

                    if (isSharing) {
                      _startLocationUpdates(busNumber);
                    } else {
                      _stopLocationUpdates(busNumber);
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: currentLocation == null
                  ? const Center(child: Text("Fetching location..."))
                  : GoogleMap(
                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          currentLocation!.latitude!,
                          currentLocation!.longitude!,
                        ),
                        zoom: 16,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: LatLng(
                            currentLocation!.latitude!,
                            currentLocation!.longitude!,
                          ),
                          infoWindow: const InfoWindow(title: 'You'),
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
