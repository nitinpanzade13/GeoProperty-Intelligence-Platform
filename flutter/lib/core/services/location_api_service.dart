import 'api_client.dart';
import '../models/location_model.dart';
import '../constants/defaults.dart';

class LocationApiService {
  final ApiClient apiClient;

  LocationApiService({required this.apiClient});

  Future<LocationModel> fetchCurrentLocation({double lat = Defaults.latitude, double lng = Defaults.longitude}) async {
    final data = await apiClient.get('/location/current', queryParameters: {'lat': lat, 'lng': lng});
    return LocationModel.fromJson(data as Map<String, dynamic>);
  }
}
