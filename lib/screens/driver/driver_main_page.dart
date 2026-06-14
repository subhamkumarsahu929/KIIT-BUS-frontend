import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../widgets/title_bar.dart';
import '../../theme.dart';
import '../../api_services/notification_service.dart';

class DriverMainPage extends StatefulWidget {
  const DriverMainPage({super.key});

  @override
  State<DriverMainPage> createState() => _DriverMainPageState();
}

class _DriverMainPageState extends State<DriverMainPage> {
  // Driver Info State
  String username = "Loading...";
  String email = "";
  bool isLoading = true;

  // Location & Sharing State
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
    _fetchDriverData();
    _checkLocationPermission();
  }

  Future<void> _fetchDriverData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("No user logged in");
        setState(() {
          username = "No user found";
          isLoading = false;
        });
        return;
      }

      debugPrint("Fetching data for driver: ${user.uid}");
      final ref = FirebaseDatabase.instance.ref("users/${user.uid}");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        debugPrint("Found driver data: ${snapshot.value}");
        if (snapshot.value is Map) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);

          if (data['role'] != 'driver') {
            debugPrint("Warning: User is not a driver");
          }

          setState(() {
            username = data['username'] ?? "Unknown";
            email = data['email'] ?? user.email ?? "No email";
            isLoading = false;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);
          await prefs.setString('email', email);
          debugPrint(
            "Updated SharedPreferences with username: $username, email: $email",
          );
        }
      } else {
        debugPrint("No data found for driver ${user.uid}");

        setState(() {
          username = user.displayName ?? "Unknown Driver";
          email = user.email ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching driver data: $e");
      setState(() {
        username = "Error loading data";
        email = "";
        isLoading = false;
      });
    }
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
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF0F111A)
        : const Color(0xFFF0F2F5);

    return Scaffold(
      appBar: const TitleBar(title: 'KIIT BUS'),
      backgroundColor: backgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.9),
                          isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.white.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(
                          alpha: isDark ? 0.3 : 0.5,
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.1,
                          ),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.2,
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              size: 30,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  email,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bus Number Input Form
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
                          borderRadius: BorderRadius.circular(25),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
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

                  // Google Map Display
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

                  // Start/Stop Sharing Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSharing
                            ? Colors.red
                            : AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
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
