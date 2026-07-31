import 'api_client.dart';

class VillageApiService {
  final ApiClient apiClient;

  VillageApiService({required this.apiClient});

  Future<List<dynamic>> fetchDistricts() async {
    final data = await apiClient.get('/village/districts');
    return data as List<dynamic>;
  }

  Future<List<dynamic>> fetchTalukas(String districtCode) async {
    final data = await apiClient.get('/village/talukas', queryParameters: {'district_code': districtCode});
    return data as List<dynamic>;
  }

  Future<List<dynamic>> fetchVillages(String districtCode, String talukaCode) async {
    final data = await apiClient.get('/village/list', queryParameters: {
      'district_code': districtCode,
      'taluka_code': talukaCode,
    });
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> resolveGisCode(
      String districtCode, String talukaCode, String villageCode) async {
    final data = await apiClient.post('/village/giscode', data: {
      'district_code': districtCode,
      'taluka_code': talukaCode,
      'village_code': villageCode,
    });
    return data as Map<String, dynamic>;
  }
}
