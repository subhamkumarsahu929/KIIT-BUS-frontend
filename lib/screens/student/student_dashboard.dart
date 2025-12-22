import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/title_bar.dart';
import '../../maps/location.dart';
import '../../maps/directions.dart';
import '../../api_services/notification_service.dart';
import 'dart:ui';

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
  int? etaMinutes;
  String busStatus = "On Route";
  DateTime? lastUpdated;

  String? lastNotifiedStatus;

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
    if (mounted) setState(() {});
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
    final pos = await determinePosition();
    if (!_disposed && mounted) {
      studentLocation = LatLng(pos.latitude, pos.longitude);
      setState(() {});
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((newPos) {
      if (!_disposed && mounted) {
        studentLocation = LatLng(newPos.latitude, newPos.longitude);
        _updateRouteAndDistance();
      }
    });
  }

  void _trackBus(String busNumber) {
    _busLocationSubscription?.cancel();

    final busNo = busNumber.toUpperCase();

    _busLocationSubscription = dbRef.child(busNo).onValue.listen((event) {
      if (!mounted || _disposed) return;

      final data = event.snapshot.value;
      if (data == null) {
        setState(() {
          busLocation = null;
          polylineCoordinates.clear();
          distanceKm = null;
          etaMinutes = null;
        });
        return;
      }

      final map = Map<String, dynamic>.from(data as Map);
      busLocation = LatLng(
        double.parse(map['latitude'].toString()),
        double.parse(map['longitude'].toString()),
      );

      _updateRouteAndDistance();

      _mapUpdateDebouncer?.cancel();
      _mapUpdateDebouncer = Timer(const Duration(milliseconds: 400), () {
        if (_mapController != null && busLocation != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(busLocation!));
        }
      });
    });
  }

  Future<void> _updateRouteAndDistance() async {
    if (studentLocation == null || busLocation == null) return;

    final points = await _directionsService.getRoutePoints(
      studentLocation!,
      busLocation!,
    );

    final dist = _calculateDistance(studentLocation!, busLocation!);

    String newStatus;
    if (dist < 0.2) {
      newStatus = "Reached";
    } else if (dist < 1) {
      newStatus = "Near You";
    } else {
      newStatus = "On Route";
    }

    setState(() {
      polylineCoordinates = points;
      distanceKm = dist;
      etaMinutes = ((dist / 45) * 60).ceil();
      busStatus = newStatus;
      lastUpdated = DateTime.now();
    });

    if (lastNotifiedStatus != newStatus) {
      _sendStatusNotification(newStatus);
      lastNotifiedStatus = newStatus;
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const R = 6371;
    final dLat = (end.latitude - start.latitude) * (pi / 180);
    final dLon = (end.longitude - start.longitude) * (pi / 180);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * (pi / 180)) *
            cos(end.latitude * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void _sendStatusNotification(String status) {
    switch (status) {
      case "On Route":
        NotificationService.showNotification(
          title: " Bus On Route",
          body: "Your bus is on the way",
        );
        break;

      case "Near You":
        NotificationService.showNotification(
          title: " Bus Near You",
          body: "Your bus is less than 1 km away",
        );
        break;

      case "Reached":
        NotificationService.showNotification(
          title: " Bus Reached",
          body: "Your bus has reached your location",
        );
        break;
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
    return Scaffold(
      appBar: const TitleBar(title: 'Student Dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _busNumberController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_bus),
                hintText: "Enter Bus Number",
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: GoogleMap(
                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: studentLocation ?? const LatLng(0, 0),
                        zoom: 14,
                      ),
                      markers: {
                        if (busLocation != null)
                          Marker(
                            markerId: const MarkerId("bus"),
                            position: busLocation!,
                            icon: _busIcon ?? BitmapDescriptor.defaultMarker,
                          ),
                        if (studentLocation != null)
                          Marker(
                            markerId: const MarkerId("student"),
                            position: studentLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                          ),
                      },
                      polylines: {
                        if (polylineCoordinates.isNotEmpty)
                          Polyline(
                            polylineId: const PolylineId("route"),
                            points: polylineCoordinates,
                            color: Colors.blue,
                            width: 5,
                          ),
                      },
                      myLocationEnabled: true,
                    ),
                  ),

                  if (busLocation != null)
                    Positioned(
                      top: 16,
                      left: 12,
                      right: 16,
                      child: busStatusCard(
                        busNumber: _busNumberController.text.toUpperCase(),
                        status: busStatus,
                        distance: distanceKm,
                        etaMinutes: etaMinutes,
                        lastUpdated: lastUpdated,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_busNumberController.text.isNotEmpty) {
                    _trackBus(_busNumberController.text.trim());
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text("View Live Location"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget busStatusCard({
    required String busNumber,
    required String status,
    required double? distance,
    required int? etaMinutes,
    required DateTime? lastUpdated,
  }) {
    Color statusColor = status == "Reached"
        ? Colors.green
        : status == "Near You"
        ? Colors.orange
        : Colors.blue;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busNumber,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Status: $status",
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (distance != null)
                          Text(
                            "Distance: ${distance.toStringAsFixed(2)} km",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (etaMinutes != null)
                          Text(
                            "ETA: $etaMinutes min",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 4),
                        if (lastUpdated != null)
                          Text(
                            "Updated: ${lastUpdated.hour}:${lastUpdated.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
