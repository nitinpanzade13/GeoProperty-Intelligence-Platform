import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<bool> checkPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      return LocationPermission.denied;
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        LocationPermission permission = await requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return await Geolocator.getLastKnownPosition();
        }
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (err) {
        return null;
      }
    }
  }

  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
