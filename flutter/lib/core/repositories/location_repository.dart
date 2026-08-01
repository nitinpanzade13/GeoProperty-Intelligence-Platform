import 'package:geocoding/geocoding.dart';
import '../services/location_api_service.dart';
import '../services/location_service.dart';
import '../models/location_model.dart';
import '../utils/result.dart';

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
      final double lat = pos?.latitude ?? 18.5204;
      final double lng = pos?.longitude ?? 73.8567;

      String? villageName;
      String? districtName;
      String? stateName = 'Maharashtra';

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
          stateName = (admin != null && admin.isNotEmpty) ? admin : 'Maharashtra';
        }
      } catch (_) {}

      final backendLoc = await apiService.fetchCurrentLocation(lat: lat, lng: lng);

      final finalLoc = LocationModel(
        latitude: lat,
        longitude: lng,
        address: backendLoc.address,
        district: districtName ?? backendLoc.district ?? 'Pune',
        taluka: backendLoc.taluka ?? 'Haveli',
        village: villageName ?? backendLoc.village ?? 'Shivajinagar',
        state: stateName ?? backendLoc.state ?? 'Maharashtra',
        pincode: backendLoc.pincode,
      );

      return Result.success(finalLoc);
    } catch (e) {
      return Result.success(
        const LocationModel(
          latitude: 18.5204,
          longitude: 73.8567,
          address: 'Shivajinagar, Pune, Maharashtra 411005',
          district: 'Pune',
          taluka: 'Haveli',
          village: 'Shivajinagar',
          state: 'Maharashtra',
        ),
      );
    }
  }
}
