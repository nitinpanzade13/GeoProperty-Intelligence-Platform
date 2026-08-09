import 'api_client.dart';

import '../models/property_model.dart';
import '../models/property_identify_model.dart';
import '../models/survey_model.dart';
import '../models/location_model.dart';
import '../models/owner_model.dart';
import '../models/polygon_model.dart';

import '../constants/defaults.dart';

class PropertyApiService {
  final ApiClient apiClient;

  PropertyApiService({
    required this.apiClient,
  });

  Future<PropertyModel> fetchPropertyDetails({
    required String gisCode,
    required String surveyNumber,
  }) async {
    final data = await apiClient.get(
      '/property/details',
      queryParameters: {
        'gis_code': gisCode,
        'survey_number': surveyNumber,
      },
    );

    final map = data as Map<String, dynamic>;

    final List<dynamic> ownersRaw = map['owners'] as List<dynamic>? ?? [];

    final owners = ownersRaw.map((o) {
      final om = o as Map<String, dynamic>;

      return OwnerModel(
        ownerId: om['owner_id'] as String? ?? 'OWN-101',
        fullName: om['owner_name'] as String? ??
            om['full_name'] as String? ??
            'Registered Owner',
        ownershipPercentage: (om['ownership_percentage'] as num?)?.toDouble() ??
            Defaults.fullOwnership,
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

    final areaSqMeters = (map['area_sq_meters'] as num?)?.toDouble() ??
        Defaults.defaultAreaSqMeters;

    return PropertyModel(
      propertyId: map['property_id'] as String? ?? 'PROP-101',
      gisCode: map['gis_code'] as String? ?? gisCode,
      title: 'Survey No. $surveyNumber',
      surveyDetails: SurveyModel(
        id: map['property_id'] as String? ?? 'SURV-$surveyNumber',
        surveyNumber: surveyNumber,
        subdivisionNumber: '3/A',
        district: Defaults.district,
        taluka: Defaults.taluka,
        village: Defaults.village,
        areaSqMeters: areaSqMeters,
        landType: 'Government Verified',
        location: const LocationModel(
          latitude: Defaults.latitude,
          longitude: Defaults.longitude,
          village: Defaults.village,
          district: Defaults.district,
          taluka: Defaults.taluka,
        ),
      ),
      owners: owners,
      totalAreaHectares: areaSqMeters / 10000,
      boundaryPoints: polyPoints,
      valuationEstimateInr: areaSqMeters * 1850,
      status: Defaults.propertyStatus,
    );
  }

  Future<Map<String, dynamic>> fetchPropertyExtent({
    required String gisCode,
    required String surveyNumber,
  }) async {
    final data = await apiClient.get(
      '/property/extent',
      queryParameters: {
        'gis_code': gisCode,
        'survey_number': surveyNumber,
      },
    );

    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchVillageMap({
    required String gisCode,
  }) async {
    final data = await apiClient.get(
      '/village/full-map',
      queryParameters: {
        'gis_code': gisCode,
      },
    );

    return data as Map<String, dynamic>;
  }

  Future<PropertyIdentifyModel> identifyProperty({
    required String gisCode,
    required double latitude,
    required double longitude,
  }) async {
    final response = await apiClient.get(
      '/village/identify',
      queryParameters: {
        'gis_code': gisCode,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return PropertyIdentifyModel.fromJson(
      response as Map<String, dynamic>,
    );
  }
}
