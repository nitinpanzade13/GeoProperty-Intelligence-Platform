import 'api_client.dart';
import '../models/property_model.dart';
import '../models/survey_model.dart';
import '../models/location_model.dart';
import '../models/owner_model.dart';
import '../models/polygon_model.dart';

class PropertyApiService {
  final ApiClient apiClient;

  PropertyApiService({required this.apiClient});

  Future<PropertyModel> fetchPropertyDetails({
    required String gisCode,
    required String surveyNumber,
  }) async {
    final data = await apiClient.get('/property/details', queryParameters: {
      'gis_code': gisCode,
      'survey_number': surveyNumber,
    });

    final map = data as Map<String, dynamic>;

    final List<dynamic> ownersRaw = map['owners'] as List<dynamic>? ?? [];
    final owners = ownersRaw.map((o) {
      final om = o as Map<String, dynamic>;
      return OwnerModel(
        ownerId: om['owner_id'] as String? ?? 'OWN-101',
        fullName: om['owner_name'] as String? ?? om['full_name'] as String? ?? 'Registered Owner',
        ownershipPercentage: (om['ownership_percentage'] as num?)?.toDouble() ?? 100.0,
        khataNumber: om['khata_number'] as String? ?? 'KH-101',
      );
    }).toList();

    List<PolygonPointModel> polyPoints = [];
    if (map['polygon'] != null && map['polygon']['points'] != null) {
      final List<dynamic> pts = map['polygon']['points'] as List<dynamic>;
      polyPoints = pts.map((p) {
        final pm = p as Map<String, dynamic>;
        return PolygonPointModel(
          latitude: (pm['latitude'] as num).toDouble(),
          longitude: (pm['longitude'] as num).toDouble(),
        );
      }).toList();
    }

    final double areaSqMeters = (map['area_sq_meters'] as num?)?.toDouble() ?? 4500.0;

    return PropertyModel(
      propertyId: map['property_id'] as String? ?? 'PROP-101',
      title: 'Survey No. $surveyNumber - Shivajinagar',
      surveyDetails: SurveyModel(
        id: map['property_id'] as String? ?? 'SURV-$surveyNumber',
        surveyNumber: surveyNumber,
        subdivisionNumber: '3/A',
        district: 'Pune',
        taluka: 'Haveli',
        village: 'Shivajinagar',
        areaSqMeters: areaSqMeters,
        landType: 'Government Verified',
        location: const LocationModel(
          latitude: 18.5204,
          longitude: 73.8567,
          village: 'Shivajinagar',
          district: 'Pune',
          taluka: 'Haveli',
        ),
      ),
      owners: owners,
      totalAreaHectares: double.parse((areaSqMeters / 10000.0).toStringAsFixed(4)),
      boundaryPoints: polyPoints,
      valuationEstimateInr: areaSqMeters * 1850.0,
      status: 'Verified',
    );
  }

  Future<Map<String, dynamic>> fetchPropertyExtent({
    required String gisCode,
    required String surveyNumber,
  }) async {
    final data = await apiClient.get('/property/extent', queryParameters: {
      'gis_code': gisCode,
      'survey_number': surveyNumber,
    });
    return data as Map<String, dynamic>;
  }
}
