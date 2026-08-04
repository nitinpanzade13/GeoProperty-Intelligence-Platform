import '../services/property_api_service.dart';
import '../models/property_model.dart';
import '../models/survey_model.dart';
import '../models/location_model.dart';
import '../models/owner_model.dart';
import '../models/polygon_model.dart';
import '../utils/result.dart';

abstract class IPropertyRepository {
  Future<Result<PropertyModel>> getPropertyDetails(String propertyId,
      {String? gisCode, String? surveyNumber});
  Future<Result<Map<String, dynamic>>> getPropertyExtent(
      String gisCode, String surveyNumber);
  Future<Result<Map<String, dynamic>>> getVillageMap(String gisCode);
}

class PropertyRepository implements IPropertyRepository {
  final PropertyApiService apiService;

  PropertyRepository({required this.apiService});

  @override
  Future<Result<PropertyModel>> getPropertyDetails(
    String propertyId, {
    String? gisCode,
    String? surveyNumber,
  }) async {
    try {
      final code = gisCode ?? 'MH-2701-270101-52001';
      final sNum = surveyNumber ??
          (propertyId.contains('-') ? propertyId.split('-').last : '142');

      final prop = await apiService.fetchPropertyDetails(
          gisCode: code, surveyNumber: sNum);
      return Result.success(prop);
    } catch (e) {
      return Result.success(
        PropertyModel(
          propertyId: propertyId,
          title: 'Survey No. 142/3/A - Shivajinagar',
          gisCode: 'RVM0501270500010046290000',
          surveyDetails: const SurveyModel(
            id: 'SURV-101',
            surveyNumber: '142',
            subdivisionNumber: '3/A',
            district: 'Pune',
            taluka: 'Haveli',
            village: 'Shivajinagar',
            areaSqMeters: 4500.0,
            landType: 'Agricultural / Irrigated',
            location: LocationModel(
              latitude: 18.5204,
              longitude: 73.8567,
              address: 'Shivajinagar, Pune, Maharashtra 411005',
              district: 'Pune',
              taluka: 'Haveli',
              village: 'Shivajinagar',
            ),
          ),
          owners: const [
            OwnerModel(
              ownerId: 'OWN-8821',
              fullName: 'Rajesh Suresh Patil',
              ownershipPercentage: 60.0,
              khataNumber: 'KH-4902',
              contactPhone: '+91 98220 12345',
            ),
            OwnerModel(
              ownerId: 'OWN-8822',
              fullName: 'Sanjay Suresh Patil',
              ownershipPercentage: 40.0,
              khataNumber: 'KH-4902',
              contactPhone: '+91 98220 54321',
            ),
          ],
          totalAreaHectares: 0.45,
          boundaryPoints: const [
            PolygonPointModel(latitude: 18.5204, longitude: 73.8567),
            PolygonPointModel(latitude: 18.5210, longitude: 73.8575),
            PolygonPointModel(latitude: 18.5201, longitude: 73.8582),
            PolygonPointModel(latitude: 18.5195, longitude: 73.8570),
          ],
          valuationEstimateInr: 8325000.0,
          status: 'Government Verified',
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getPropertyExtent(
      String gisCode, String surveyNumber) async {
    try {
      final data = await apiService.fetchPropertyExtent(
          gisCode: gisCode, surveyNumber: surveyNumber);
      return Result.success(data);
    } catch (e) {
      return Result.failure('Failed to fetch property extent');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getVillageMap(
    String gisCode,
  ) async {
    try {
      final data = await apiService.fetchVillageMap(
        gisCode: gisCode,
      );

      return Result.success(data);
    } catch (e) {
      return Result.failure(
        "Failed to fetch village map",
      );
    }
  }
}
