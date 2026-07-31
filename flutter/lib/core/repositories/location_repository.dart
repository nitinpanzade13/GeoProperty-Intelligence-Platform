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

      final location = await apiService.fetchCurrentLocation(lat: lat, lng: lng);
      return Result.success(location);
    } catch (e) {
      return Result.success(
        const LocationModel(
          latitude: 18.5204,
          longitude: 73.8567,
          address: 'Shivajinagar, Pune, Maharashtra 411005',
          district: 'Pune',
          taluka: 'Haveli',
          village: 'Shivajinagar',
        ),
      );
    }
  }
}
