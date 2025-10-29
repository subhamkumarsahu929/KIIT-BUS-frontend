import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../widgets/title_bar.dart';
import '../../theme.dart'; // ✅ use your theme

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _busNumberController = TextEditingController();

  bool isSharing = false;
  bool _disposed = false;
  final Location location = Location();
  LocationData? currentLocation;
  GoogleMapController? _mapController;
  StreamSubscription<LocationData>? _locationSubscription;

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    currentLocation = await location.getLocation();
    setState(() {});
  }

  void _startLocationUpdates(String busNumber) {
    _locationSubscription?.cancel();

    _locationSubscription = location.onLocationChanged.listen((newLoc) {
      if (_disposed ||
          !mounted ||
          newLoc.latitude == null ||
          newLoc.longitude == null)
        return;

      setState(() => currentLocation = newLoc);

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(newLoc.latitude!, newLoc.longitude!)),
      );

      dbRef.child("buses").child(busNumber).set({
        'latitude': newLoc.latitude,
        'longitude': newLoc.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  void _stopLocationUpdates(String busNumber) {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    dbRef.child("buses").child(busNumber).remove();
  }

  @override
  void dispose() {
    _disposed = true;
    _locationSubscription?.cancel();
    _mapController?.dispose();
    _busNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const TitleBar(title: 'Driver Dashboard'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Driver Control Panel',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),

            // Bus Number Input
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _busNumberController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter Bus Number (e.g. BUS-12)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(
                    Icons.directions_bus,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter bus number" : null,
              ),
            ),
            const SizedBox(height: 25),

            // Start/Stop Button
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSharing
                      ? Colors.red
                      : AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(
                  isSharing ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                ),
                label: Text(
                  isSharing
                      ? 'Stop Sharing Location'
                      : 'Start Sharing Location',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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

            // Google Map Section
            Expanded(
              child: currentLocation == null
                  ? const Center(child: CircularProgressIndicator())
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            currentLocation!.latitude!,
                            currentLocation!.longitude!,
                          ),
                          zoom: 16,
                        ),
                        markers: Set<Marker>.from([
                          if (currentLocation?.latitude != null &&
                              currentLocation?.longitude != null &&
                              mounted)
                            Marker(
                              markerId: const MarkerId('driver'),
                              position: LatLng(
                                currentLocation!.latitude!,
                                currentLocation!.longitude!,
                              ),
                              infoWindow: InfoWindow(
                                title: 'Current Location',
                                snippet:
                                    'Lat: ${currentLocation!.latitude?.toStringAsFixed(4)}, Lng: ${currentLocation!.longitude?.toStringAsFixed(4)}',
                                onTap: mounted
                                    ? () {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Updated at: ${DateTime.now().toLocal()}',
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                        ]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
