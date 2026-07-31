import 'api_client.dart';
import '../models/survey_model.dart';
import '../models/location_model.dart';

class SurveyApiService {
  final ApiClient apiClient;

  SurveyApiService({required this.apiClient});

  Future<List<SurveyModel>> fetchSurveys({required String gisCode}) async {
    final data = await apiClient.get('/survey/list', queryParameters: {'gis_code': gisCode});

    final Map<String, dynamic> body = data as Map<String, dynamic>;
    final List<dynamic> surveysList = body['surveys'] as List<dynamic>? ?? [];

    return surveysList.map((json) {
      final map = json as Map<String, dynamic>;
      return SurveyModel(
        id: map['survey_id'] as String? ?? 'SURV-${map['survey_number']}',
        surveyNumber: map['survey_number'] as String? ?? '',
        subdivisionNumber: map['subdivision_number'] as String?,
        district: 'Pune',
        taluka: 'Haveli',
        village: 'Shivajinagar',
        areaSqMeters: (map['area_sq_meters'] as num?)?.toDouble() ?? 4500.0,
        landType: 'Agricultural / Irrigated',
        location: const LocationModel(
          latitude: 18.5204,
          longitude: 73.8567,
          village: 'Shivajinagar',
          district: 'Pune',
          taluka: 'Haveli',
        ),
      );
    }).toList();
  }
}
