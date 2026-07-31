import 'api_client.dart';
import '../models/location_model.dart';

class LocationApiService {
  final ApiClient apiClient;

  LocationApiService({required this.apiClient});

  Future<LocationModel> fetchCurrentLocation({double lat = 18.5204, double lng = 73.8567}) async {
    final data = await apiClient.get('/location/current', queryParameters: {'lat': lat, 'lng': lng});
    return LocationModel.fromJson(data as Map<String, dynamic>);
  }
}
