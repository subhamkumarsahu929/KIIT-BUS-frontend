import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../api_services/api_services.dart';
import '../api_services/models/place_from_coordinates.dart';

class LiveMap extends StatefulWidget {
  final double latitude;
  final double longitude;

  const LiveMap({super.key, required this.latitude, required this.longitude});

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  late double lat;
  late double lng;
  String address = "Loading...";

  @override
  void initState() {
    super.initState();
    lat = widget.latitude;
    lng = widget.longitude;
    _fetchAddress(lat, lng);
  }

  Future<void> _fetchAddress(double lat, double lng) async {
    try {
      final data = await ApiService().placeFromCoordinates(lat, lng);
      setState(() {
        address = data.results.isNotEmpty
            ? data.results[0].formattedAddress
            : "No address found";
      });
    } catch (e) {
      setState(() {
        address = "Failed to fetch address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 16,
                ),
                onCameraMove: (position) {
                  setState(() {
                    lat = position.target.latitude;
                    lng = position.target.longitude;
                  });
                },
                onCameraIdle: () => _fetchAddress(lat, lng),
                markers: {
                  Marker(
                    markerId: const MarkerId("live_location"),
                    position: LatLng(lat, lng),
                  ),
                },
              ),
              const Center(
                child: Icon(Icons.location_pin, size: 50, color: Colors.red),
              ),
            ],
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
                  address,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
