import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/title_bar.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with WidgetsBindingObserver {
  final TextEditingController _busNumberController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? busLocation;
  StreamSubscription<DatabaseEvent>? _busLocationSubscription;
  bool _disposed = false;
  Timer? _mapUpdateDebouncer;

  final dbRef = FirebaseDatabase.instance.ref("buses");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _mapController?.dispose();
      _mapController = null;
    }
  }

  void _trackBus(String busNumber) {
    if (_disposed) return;

    _busLocationSubscription?.cancel();
    _mapUpdateDebouncer?.cancel();
    final normalizedBusNo = busNumber.toUpperCase();

    try {
      _busLocationSubscription = dbRef
          .child(normalizedBusNo)
          .onValue
          .listen(
            (event) {
              if (_disposed || !mounted) return;

              final data = event.snapshot.value;
              if (data == null) {
                setState(() => busLocation = null);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Bus $normalizedBusNo not found or stopped sharing",
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
                return;
              }

              try {
                final map = Map<String, dynamic>.from(data as Map);
                final lat = double.parse(map['latitude'].toString());
                final lng = double.parse(map['longitude'].toString());

                if (mounted) {
                  setState(() {
                    busLocation = LatLng(lat, lng);
                  });

                  // Debounce map updates to prevent too frequent camera movements
                  _mapUpdateDebouncer?.cancel();
                  _mapUpdateDebouncer = Timer(
                    const Duration(milliseconds: 500),
                    () {
                      if (mounted && _mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLng(busLocation!),
                        );
                      }
                    },
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error reading location data: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            onError: (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error tracking bus: $error"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to start bus tracking: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _busLocationSubscription?.cancel();
    _mapUpdateDebouncer?.cancel();
    _mapController?.dispose();
    _busNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: const TitleBar(title: 'Student Dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Welcome to Student Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 25),

            // Input Field
            TextField(
              controller: _busNumberController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Enter Bus Number (e.g. BUS-12)',
                prefixIcon: Icon(Icons.directions_bus),
              ),
            ),

            const SizedBox(height: 20),

            // Button
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text(
                    "View Live Location",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    final busNumber = _busNumberController.text.trim();
                    if (busNumber.isNotEmpty) _trackBus(busNumber);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Map or Info Text
            Expanded(
              child: busLocation == null
                  ? const Center(
                      child: Text(
                        "Enter a bus number to see its live location...",
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: GoogleMap(
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        initialCameraPosition: CameraPosition(
                          target: busLocation!,
                          zoom: 16,
                        ),
                        markers: {
                          if (busLocation != null && !_disposed && mounted)
                            Marker(
                              markerId: const MarkerId('bus'),
                              position: busLocation!,
                              infoWindow: InfoWindow(
                                title: "Bus Current Location",
                                snippet: _busNumberController.text.isNotEmpty
                                    ? "Bus: ${_busNumberController.text.toUpperCase()}"
                                    : null,
                                onTap: mounted
                                    ? () {
                                        if (!_disposed && mounted) {
                                          final now = DateTime.now().toLocal();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Last updated: ${now.hour}:${now.minute}:${now.second}',
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
                                BitmapDescriptor.hueAzure,
                              ),
                            ),
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
