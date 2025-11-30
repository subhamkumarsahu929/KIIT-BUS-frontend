import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/title_bar.dart';
import '../../maps/location.dart';
import '../../maps/directions.dart';

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
  LatLng? studentLocation;

  StreamSubscription<DatabaseEvent>? _busLocationSubscription;
  Timer? _mapUpdateDebouncer;
  bool _disposed = false;

  final dbRef = FirebaseDatabase.instance.ref("buses");
  final DirectionsService _directionsService = DirectionsService();

  BitmapDescriptor? _busIcon;

  List<LatLng> polylineCoordinates = [];
  double? distanceKm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCustomMarker();
    _getStudentLocation();
  }

  Future<void> _loadCustomMarker() async {
    _busIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(54, 54)),
      'assets/icons/bus.png',
    );
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _mapController?.dispose();
      _mapController = null;
    }
  }

  Future<void> _getStudentLocation() async {
    try {
      final pos = await determinePosition();
      if (mounted && !_disposed) {
        studentLocation = LatLng(pos.latitude, pos.longitude);
        setState(() {});
      }

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position newPos) {
        if (mounted && !_disposed) {
          studentLocation = LatLng(newPos.latitude, newPos.longitude);
          _updateRouteAndDistance();
          setState(() {});
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to get location: $e")));
      }
    }
  }

  void _trackBus(String busNumber) {
    if (_disposed) return;

    _busLocationSubscription?.cancel();
    _mapUpdateDebouncer?.cancel();

    final normalizedBusNo = busNumber.toUpperCase();

    _busLocationSubscription = dbRef
        .child(normalizedBusNo)
        .onValue
        .listen(
          (event) {
            if (_disposed || !mounted) return;

            final data = event.snapshot.value;
            if (data == null) {
              setState(() {
                busLocation = null;
                polylineCoordinates.clear();
                distanceKm = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "$normalizedBusNo not found or stopped sharing",
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }

            try {
              final map = Map<String, dynamic>.from(data as Map);
              final lat = double.parse(map['latitude'].toString());
              final lng = double.parse(map['longitude'].toString());
              busLocation = LatLng(lat, lng);
              _updateRouteAndDistance();

              _mapUpdateDebouncer?.cancel();
              _mapUpdateDebouncer = Timer(
                const Duration(milliseconds: 400),
                () {
                  if (mounted &&
                      _mapController != null &&
                      busLocation != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(busLocation!),
                    );
                  }
                },
              );
              setState(() {});
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error reading bus location: $e")),
              );
            }
          },
          onError: (error) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Firebase error: $error")));
          },
        );
  }

  Future<void> _updateRouteAndDistance() async {
    if (studentLocation == null || busLocation == null) return;

    try {
      final routePoints = await _directionsService.getRoutePoints(
        studentLocation!,
        busLocation!,
      );

      if (routePoints.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No route found — check your Google Directions API key, billing, or coordinate validity.',
              ),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }

      setState(() {
        polylineCoordinates = routePoints;
        distanceKm = _calculateDistance(studentLocation!, busLocation!);
      });
    } catch (e) {
      debugPrint("Route fetch error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route fetch error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double R = 6371;
    final dLat = (end.latitude - start.latitude) * (pi / 180);
    final dLon = (end.longitude - start.longitude) * (pi / 180);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * (pi / 180)) *
            cos(end.latitude * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
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
            Text(
              'Welcome to Student Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 25),

            TextField(
              controller: _busNumberController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Enter Bus Number (e.g. number only)',
                prefixIcon: Icon(Icons.directions_bus),
              ),
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 15),

            if (distanceKm != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "Distance to bus: ${distanceKm!.toStringAsFixed(2)} km",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),

            Expanded(
              child: (busLocation == null && studentLocation == null)
                  ? const Center(
                      child: Text(
                        "Enter a bus number to see live location...",
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: GoogleMap(
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        initialCameraPosition: CameraPosition(
                          target: studentLocation ?? const LatLng(0, 0),
                          zoom: 14,
                        ),
                        markers: {
                          if (busLocation != null)
                            Marker(
                              markerId: const MarkerId('bus'),
                              position: busLocation!,
                              infoWindow: InfoWindow(
                                title: "Bus Location",
                                snippet: _busNumberController.text
                                    .toUpperCase(),
                              ),
                              icon:
                                  _busIcon ??
                                  BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueAzure,
                                  ),
                            ),
                          if (studentLocation != null)
                            Marker(
                              markerId: const MarkerId('student'),
                              position: studentLocation!,
                              infoWindow: const InfoWindow(
                                title: "Your Location",
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                        },
                        polylines: {
                          if (polylineCoordinates.isNotEmpty)
                            Polyline(
                              polylineId: const PolylineId("route"),
                              color: Colors.blue,
                              width: 5,
                              points: polylineCoordinates,
                            ),
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
