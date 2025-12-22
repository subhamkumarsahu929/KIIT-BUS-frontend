import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../widgets/title_bar.dart';
import '../../theme.dart';
import '../../api_services/notification_service.dart';

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
          newLoc.longitude == null) {
        return;
      }

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Control Panel',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _busNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter Bus Number (digits only)',
                  prefixIcon: const Icon(Icons.directions_bus),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter bus number';
                  }
                  if (!RegExp(r'^\d{1,3}$').hasMatch(value)) {
                    return 'Give number only';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

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
                        markers: {
                          Marker(
                            markerId: const MarkerId('driver'),
                            position: LatLng(
                              currentLocation!.latitude!,
                              currentLocation!.longitude!,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen,
                            ),
                          ),
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSharing
                      ? Colors.red
                      : AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
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
                      NotificationService.showNotification(
                        title: " Location Sharing Started",
                        body: "Your bus location is now live",
                      );
                    } else {
                      _stopLocationUpdates(busNumber);
                      NotificationService.showNotification(
                        title: " Location Sharing Stopped",
                        body: "Your bus location is no longer shared",
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
