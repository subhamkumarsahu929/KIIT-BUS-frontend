import 'package:geolocator/geolocator.dart';

class PermissionHelper {
  static Future<LocationPermission> requestPermission() async {
   
    LocationPermission perm = await Geolocator.checkPermission();

       if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

  
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings(); // opens Android Settings UI
    }

    return perm;
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}