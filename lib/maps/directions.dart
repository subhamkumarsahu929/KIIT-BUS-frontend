import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../maps/constants.dart';

class DirectionsService {
  // Existing method getRoutePoints remains unchanged.

  // New helper: fetch only the overview polyline (simplified route) for long distances.
  Future<List<LatLng>> getOverviewPoints(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving&overview=full&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = (data['status'] ?? '').toString();
        if (status != 'OK') {
          throw Exception('Directions API error: $status');
        }
        final routes = data['routes'] as List<dynamic>;
        if (routes.isEmpty) return [];
        final String? points =
            routes[0]['overview_polyline']?['points'] as String?;
        if (points == null || points.isEmpty) return [];
        return _decodePolyline(points);
      } else {
        throw Exception(
          'Failed to fetch overview polyline: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error getting overview polyline: $e');
      return [];
    }
  }

  // Use the Directions API key if provided; otherwise fall back to the generic Google API key.
  // Retrieve API key: use Directions key if set, otherwise fallback to Google Maps key.
  // NOTE: For a production app supply the key via environment variables or secure storage.
  // Here we provide a placeholder to guarantee the Directions API call works during development.
  final String apiKey = Constants.apiKey;

  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving&overview=full&key=$apiKey';

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
          return [];
        }

        // Build a highly detailed and precise polyline from every step and waypoint.
        final List<dynamic> legs = routes[0]['legs'] as List<dynamic>? ?? [];
        List<LatLng> fullPath = [];

        for (var leg in legs) {
          final List<dynamic>? steps = leg['steps'] as List<dynamic>?;
          if (steps != null && steps.isNotEmpty) {
            for (int i = 0; i < steps.length; i++) {
              final step = steps[i];

              // Add step start location for precision at intersections
              final startLoc = step['start_location'] as Map<String, dynamic>?;
              if (startLoc != null) {
                final LatLng startPoint = LatLng(
                  (startLoc['lat'] as num).toDouble(),
                  (startLoc['lng'] as num).toDouble(),
                );
                if (fullPath.isEmpty || fullPath.last != startPoint) {
                  fullPath.add(startPoint);
                }
              }

              // Add the step's detailed polyline
              final String? stepPoints = step['polyline']?['points'] as String?;
              if (stepPoints != null && stepPoints.isNotEmpty) {
                final decodedSteps = _decodePolyline(stepPoints);
                for (final point in decodedSteps) {
                  if (fullPath.isEmpty || fullPath.last != point) {
                    fullPath.add(point);
                  }
                }
              }

              // Add step end location to ensure accurate waypoint
              final endLoc = step['end_location'] as Map<String, dynamic>?;
              if (endLoc != null) {
                final LatLng endPoint = LatLng(
                  (endLoc['lat'] as num).toDouble(),
                  (endLoc['lng'] as num).toDouble(),
                );
                if (fullPath.isEmpty || fullPath.last != endPoint) {
                  fullPath.add(endPoint);
                }
              }
            }
          }
        }

        if (fullPath.isNotEmpty) {
          return _removeDuplicatePoints(fullPath);
        }

        // Fallback to the overview polyline (still road-aligned but less detailed).
        final String? points =
            routes[0]['overview_polyline']?['points'] as String?;
        if (points == null || points.isEmpty) {
          return [];
        }

        return _removeDuplicatePoints(_decodePolyline(points));
      } else {
        throw Exception('Failed to fetch route: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Error getting route points: $e');
      return [];
    }
  }

  /// Precision-focused duplicate removal that preserves all route detail.
  /// Only removes exact duplicates and points closer than 2 meters.
  List<LatLng> _removeDuplicatePoints(List<LatLng> points) {
    if (points.isEmpty) return points;

    final List<LatLng> cleaned = [points.first];
    const double minDistanceDegrees = 0.00002; // ~2.2 meters at equator

    for (var point in points.skip(1)) {
      final LatLng last = cleaned.last;

      // Only skip if point is extremely close to the last point
      final double dLat = (point.latitude - last.latitude).abs();
      final double dLng = (point.longitude - last.longitude).abs();

      if (dLat >= minDistanceDegrees || dLng >= minDistanceDegrees) {
        cleaned.add(point);
      }
    }

    return cleaned;
  }

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
