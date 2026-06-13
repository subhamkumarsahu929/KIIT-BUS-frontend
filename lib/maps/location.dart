import 'package:geolocator/geolocator.dart';

Future<Position> determinePosition() async {

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    
    await Geolocator.openLocationSettings();
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
  }

  
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Open app settings so the user can manually grant permission.
    await Geolocator.openAppSettings();
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.',
    );
  }

  // At this point services are enabled and permission is granted.
  return await Geolocator.getCurrentPosition();
}
