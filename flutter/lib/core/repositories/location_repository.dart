import 'package:geocoding/geocoding.dart';
import '../services/location_api_service.dart';
import '../services/location_service.dart';
import '../models/location_model.dart';
import '../utils/result.dart';
import '../constants/defaults.dart';

abstract class ILocationRepository {
  Future<Result<LocationModel>> getCurrentLocation();
}

class LocationRepository implements ILocationRepository {
  final LocationApiService apiService;
  final LocationService deviceLocationService;

  LocationRepository({
    required this.apiService,
    required this.deviceLocationService,
  });

  @override
  Future<Result<LocationModel>> getCurrentLocation() async {
    try {
      final pos = await deviceLocationService.getCurrentPosition();
      final double lat = pos?.latitude ?? Defaults.latitude;
      final double lng = pos?.longitude ?? Defaults.longitude;

      String? villageName;
      String? districtName;
      String? stateName = Defaults.state;

      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final subLoc = place.subLocality;
          final loc = place.locality;
          final subAdmin = place.subAdministrativeArea;
          final admin = place.administrativeArea;

          villageName = (subLoc != null && subLoc.isNotEmpty) ? subLoc : loc;
          districtName = (subAdmin != null && subAdmin.isNotEmpty) ? subAdmin : loc;
          stateName = (admin != null && admin.isNotEmpty) ? admin : Defaults.state;
        }
      } catch (_) {}

      final backendLoc = await apiService.fetchCurrentLocation(lat: lat, lng: lng);

      final finalLoc = LocationModel(
        latitude: lat,
        longitude: lng,
        address: backendLoc.address,
        district: districtName ?? backendLoc.district ?? Defaults.district,
        taluka: backendLoc.taluka ?? Defaults.taluka,
        village: villageName ?? backendLoc.village ?? Defaults.village,
        state: stateName ?? backendLoc.state ?? Defaults.state,
        pincode: backendLoc.pincode,
      );

      return Result.success(finalLoc);
    } catch (e) {
      return Result.success(
        const LocationModel(
          latitude: Defaults.latitude,
          longitude: Defaults.longitude,
          address: Defaults.fallbackAddress,
          district: Defaults.district,
          taluka: Defaults.taluka,
          village: Defaults.village,
          state: Defaults.state,
        ),
      );
    }
  }
}
