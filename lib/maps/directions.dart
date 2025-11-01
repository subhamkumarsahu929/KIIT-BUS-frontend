import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../maps/constants.dart';

class DirectionsService {
  final String apiKey = Constants.directionsKey;

  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final status = (data['status'] ?? '').toString();
      if (status != 'OK') {
        final err = data['error_message'] ?? 'no error_message';

        throw Exception('Directions API error: $status - $err');
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        // No routes found for these coordinates

        return [];
      }

      final points = routes[0]['overview_polyline']?['points'] as String?;
      if (points == null || points.isEmpty) {
        return [];
      }

      return _decodePolyline(points);
    } else {
      throw Exception('Failed to fetch route: HTTP ${response.statusCode}');
    }
  }

  /// Decode the polyline from encoded Google response
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }
}
