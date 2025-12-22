import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../api_services/api_services.dart';
import '../api_services/models/place_from_coordinates.dart';
import '../maps/directions.dart';
import '../maps/location.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); //
    _initializeLocations();
  }

  Future<void> _loadCustomMarker() async {
  
    _busIcon = await BitmapDescriptor.fromAssetImage(
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
    }
  }

  Future<void> _updatePolyline() async {
    if (_busLocation == null || _studentLocation == null) {
      //
    }

    if (_busLocation == _studentLocation) {
      return;
    }

    try {
      debugPrint(" Getting route from $_studentLocation to $_busLocation");

      final routePoints = await _directionsService.getRoutePoints(
        _studentLocation!,
        _busLocation!,
      );

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blueAccent,
            width: 6,
            points: routePoints,
          ),
        };
      });
    } catch (e) {
      debugPrint("Error updating polyline: $e");
    }
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
      body: _busLocation == null || _studentLocation == null
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
