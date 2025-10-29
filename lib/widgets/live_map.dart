import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../api_services/api_services.dart';
import '../api_services/models/place_from_coordinates.dart';

class LiveMap extends StatefulWidget {
  final String busNumber; 

  const LiveMap({super.key, required this.busNumber});

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  GoogleMapController? _mapController;
  LatLng? _busLocation;
  DatabaseReference? _busRef;
  String _address = "Fetching address...";

  @override
  void initState() {
    super.initState();

   
    _busRef = FirebaseDatabase.instance.ref("buses/${widget.busNumber}");

    
    _busRef!.onValue.listen((event) async {
      final data = event.snapshot.value as Map?;
      if (data != null && data['latitude'] != null && data['longitude'] != null) {
        final double lat = (data['latitude'] as num).toDouble();
        final double lng = (data['longitude'] as num).toDouble();

        setState(() {
          _busLocation = LatLng(lat, lng);
        });

        
        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(_busLocation!));
        }

        await _updateAddress(lat, lng);
      }
    });
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      PlaceFromCoordinates data = await ApiService().placeFromCoordinates(lat, lng);
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
      body: _busLocation == null
          ? const Center(
              child: Text(
                "Waiting for bus location...",
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
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("bus_marker"),
                        position: _busLocation!,
                        infoWindow: InfoWindow(title: "Bus ${widget.busNumber}"),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                      ),
                    },
                    onMapCreated: (controller) => _mapController = controller,
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
