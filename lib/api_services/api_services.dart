import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants.dart';

import 'models/place_from_coordinates.dart';

class ApiService {
  Future<PlaceFromCoordinates> placeFromCoordinates(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${Constants.gcpKey}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return PlaceFromCoordinates.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('API ERROR: placeFromCoordinates');
    }
  }
}
