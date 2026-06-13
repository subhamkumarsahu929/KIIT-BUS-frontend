import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../api_services/api_services.dart';
import '../api_services/models/place_from_coordinates.dart';
import '../maps/directions.dart';
import '../maps/location.dart';
import '../maps/constants.dart';
import 'dart:math' as math;

class LiveMap extends StatefulWidget {
  final String busNumber;

  const LiveMap({super.key, required this.busNumber});

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  GoogleMapController? _mapController;
  LatLng? _busLocation;
  LatLng? _studentLocation;
  DatabaseReference? _busRef;
  String _address = "Fetching address...";
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _busIcon;
  final DirectionsService _directionsService = DirectionsService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); //
    _initializeLocations();
  }

  Future<void> _loadCustomMarker() async {
    _busIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(54, 54)),
      'assets/icons/bus.png',
    );
    setState(() {});
  }

  Future<void> _initializeLocations() async {
    try {
      final pos = await determinePosition();
      _studentLocation = LatLng(pos.latitude, pos.longitude);

      _busRef = FirebaseDatabase.instance.ref("buses/${widget.busNumber}");
      _busRef!.onValue.listen((event) async {
        final data = event.snapshot.value as Map?;
        if (data != null &&
            data['latitude'] != null &&
            data['longitude'] != null) {
          final double lat = (data['latitude'] as num).toDouble();
          final double lng = (data['longitude'] as num).toDouble();

          setState(() {
            _busLocation = LatLng(lat, lng);
          });

          if (_mapController != null && _studentLocation != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    _studentLocation!.latitude < lat
                        ? _studentLocation!.latitude
                        : lat,
                    _studentLocation!.longitude < lng
                        ? _studentLocation!.longitude
                        : lng,
                  ),
                  northeast: LatLng(
                    _studentLocation!.latitude > lat
                        ? _studentLocation!.latitude
                        : lat,
                    _studentLocation!.longitude > lng
                        ? _studentLocation!.longitude
                        : lng,
                  ),
                ),
                100,
              ),
            );
          }

          await _updateAddress(lat, lng);
          await _updatePolyline();
        }
      });
    } catch (e) {
      debugPrint("Error initializing locations: $e");
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _updatePolyline() async {
    if (_busLocation == null || _studentLocation == null) {
      debugPrint("Locations not ready, skipping polyline update.");
      return;
    }

    if (_areLocationsClose(_busLocation!, _studentLocation!)) {
      debugPrint(
        "Bus and student location are effectively identical, no route to draw.",
      );
      return;
    }

    try {
      if (Constants.apiKey.isEmpty) {
        debugPrint('Directions API key missing – cannot fetch route.');
        setState(() {
          _errorMessage = 'Missing Directions API key.';
        });
        return;
      }

      debugPrint(
        "Fetching detailed route from $_studentLocation to $_busLocation",
      );

      List<LatLng> pointsToDraw = await _directionsService.getRoutePoints(
        _studentLocation!,
        _busLocation!,
      );

      if (pointsToDraw.isEmpty) {
        debugPrint(
          "Detailed route returned no points – falling back to straight line.",
        );
        pointsToDraw = [_studentLocation!, _busLocation!];
      } else if (pointsToDraw.length > 500) {
        debugPrint(
          "Large point count (${pointsToDraw.length}) – simplifying route to preserve shape.",
        );
        pointsToDraw = _simplifyPolyline(
          pointsToDraw,
          tolerance: 0.00001,
          maxPoints: 500,
        );
      }

      debugPrint('=== ROUTE DEBUG ===');
      debugPrint('Total points: ${pointsToDraw.length}');
      if (pointsToDraw.isNotEmpty) {
        debugPrint(
          'First point : ${pointsToDraw.first.latitude}, ${pointsToDraw.first.longitude}',
        );
        final middle = pointsToDraw[pointsToDraw.length ~/ 2];
        debugPrint('Middle point: ${middle.latitude}, ${middle.longitude}');
        debugPrint(
          'Last point  : ${pointsToDraw.last.latitude}, ${pointsToDraw.last.longitude}',
        );
      }
      debugPrint('=== END ROUTE DEBUG ===');

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blueAccent,
            width: 8,
            points: pointsToDraw,
            geodesic: false,
          ),
        };
      });

      if (_mapController != null && pointsToDraw.isNotEmpty) {
        final bounds = _boundsFromPoints(pointsToDraw);
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    } catch (e) {
      debugPrint("Error updating polyline: $e");
      setState(() {
        _errorMessage = "Failed to load route: $e";
      });
    }
  }

  List<LatLng> _samplePolylinePoints(
    List<LatLng> points, {
    int maxPoints = 300,
  }) {
    if (points.length <= maxPoints) return points;

    final int step = (points.length / (maxPoints - 1)).ceil();
    final List<LatLng> sampled = <LatLng>[points.first];

    for (int index = step; index < points.length - 1; index += step) {
      sampled.add(points[index]);
    }

    sampled.add(points.last);
    return sampled;
  }

  List<LatLng> _simplifyPolyline(
    List<LatLng> points, {
    double tolerance = 0.00005,
    int maxPoints = 300,
  }) {
    if (points.length <= maxPoints) return points;

    final simplified = _ramerDouglasPeucker(points, tolerance);
    if (simplified.length <= maxPoints) return simplified;

    return _samplePolylinePoints(simplified, maxPoints: maxPoints);
  }

  List<LatLng> _ramerDouglasPeucker(List<LatLng> points, double tolerance) {
    if (points.length < 3) return List<LatLng>.from(points);

    int index = -1;
    double maxDistance = 0.0;

    for (int i = 1; i < points.length - 1; i++) {
      final dist = _perpendicularDistance(points[i], points.first, points.last);
      if (dist > maxDistance) {
        index = i;
        maxDistance = dist;
      }
    }

    if (maxDistance > tolerance) {
      final List<LatLng> left = _ramerDouglasPeucker(
        points.sublist(0, index + 1),
        tolerance,
      );
      final List<LatLng> right = _ramerDouglasPeucker(
        points.sublist(index, points.length),
        tolerance,
      );

      return [...left.sublist(0, left.length - 1), ...right];
    }

    return [points.first, points.last];
  }

  double _perpendicularDistance(LatLng point, LatLng start, LatLng end) {
    final double dx = end.longitude - start.longitude;
    final double dy = end.latitude - start.latitude;
    if (dx == 0 && dy == 0) {
      return math.sqrt(
        math.pow(point.latitude - start.latitude, 2) +
            math.pow(point.longitude - start.longitude, 2),
      );
    }

    return (dx * (start.latitude - point.latitude) -
                (start.longitude - point.longitude) * dy)
            .abs() /
        math.sqrt(dx * dx + dy * dy);
  }

  // Determine if two locations are effectively the same (within a few meters).
  bool _areLocationsClose(LatLng a, LatLng b, {double thresholdMeters = 10}) {
    const earthRadius = 6371000; // meters
    double dLat = _deg2rad(b.latitude - a.latitude);
    double dLng = _deg2rad(b.longitude - a.longitude);
    double lat1 = _deg2rad(a.latitude);
    double lat2 = _deg2rad(b.latitude);
    double sinDLat = math.sin(dLat / 2);
    double sinDLng = math.sin(dLng / 2);
    double aVal =
        sinDLat * sinDLat + sinDLng * sinDLng * math.cos(lat1) * math.cos(lat2);
    double c = 2 * math.atan2(math.sqrt(aVal), math.sqrt(1 - aVal));
    double distance = earthRadius * c;
    return distance <= thresholdMeters;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  // Determine if the route is long (default >200 km).
  bool _isLongDistance(LatLng a, LatLng b, {double thresholdMeters = 200000}) {
    const earthRadius = 6371000; // meters
    double dLat = _deg2rad(b.latitude - a.latitude);
    double dLng = _deg2rad(b.longitude - a.longitude);
    double lat1 = _deg2rad(a.latitude);
    double lat2 = _deg2rad(b.latitude);
    double sinDLat = math.sin(dLat / 2);
    double sinDLng = math.sin(dLng / 2);
    double aVal =
        sinDLat * sinDLat + sinDLng * sinDLng * math.cos(lat1) * math.cos(lat2);
    double c = 2 * math.atan2(math.sqrt(aVal), math.sqrt(1 - aVal));
    double distance = earthRadius * c;
    return distance >= thresholdMeters;
  }

  // Build a LatLngBounds that encloses all points in the list.
  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      PlaceFromCoordinates data = await ApiService().placeFromCoordinates(
        lat,
        lng,
      );
      if (data.results.isNotEmpty) {
        setState(() {
          _address = data.results[0].formattedAddress;
        });
      } else {
        setState(() {
          _address = "Address not found";
        });
      }
    } catch (e) {
      setState(() {
        _address = "Failed to fetch address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bus ${widget.busNumber} Live Tracking"),
        backgroundColor: Colors.green.shade700,
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                        _initializeLocations();
                      },
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            )
          : _busLocation == null || _studentLocation == null
          ? const Center(
              child: Text(
                "Fetching locations...",
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _busLocation!,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("bus_marker"),
                        position: _busLocation!,
                        infoWindow: InfoWindow(
                          title: "Bus ${widget.busNumber}",
                        ),
                        icon:
                            _busIcon ??
                            BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueAzure,
                            ),
                      ),
                      Marker(
                        markerId: const MarkerId("student_marker"),
                        position: _studentLocation!,
                        infoWindow: const InfoWindow(title: "Your Location"),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
                    polylines: _polylines,
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _address,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
