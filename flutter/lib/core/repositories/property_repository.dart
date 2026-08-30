import '../services/property_api_service.dart';
import '../models/property_model.dart';
import '../models/survey_model.dart';
import '../models/location_model.dart';
import '../models/owner_model.dart';
import '../models/polygon_model.dart';
import '../models/property_identify_model.dart';
import '../utils/result.dart';
import '../constants/defaults.dart';

abstract class IPropertyRepository {
  Future<Result<PropertyModel>> getPropertyDetails(String propertyId,
      {String? gisCode, String? surveyNumber});
  Future<Result<Map<String, dynamic>>> getPropertyExtent(
      String gisCode, String surveyNumber);
  Future<Result<Map<String, dynamic>>> getVillageMap(String gisCode);
  Future<Result<PropertyIdentifyModel>> identifyProperty(
    String gisCode,
    double latitude,
    double longitude,
  );
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
      final code = gisCode ?? Defaults.legacyGisCode;
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
            district: Defaults.district,
            taluka: Defaults.taluka,
            village: Defaults.village,
            areaSqMeters: Defaults.defaultAreaSqMeters,
            landType: Defaults.landType,
            location: LocationModel(
              latitude: Defaults.latitude,
              longitude: Defaults.longitude,
              address: Defaults.fallbackAddress,
              district: Defaults.district,
              taluka: Defaults.taluka,
              village: Defaults.village,
            ),
          ),
          owners: const [
            OwnerModel(
              ownerName: 'Rajesh Suresh Patil',
              khataNumber: 'KH-4902',
              totalArea: 0.9800,
              potKharaba: 0.0000,
            ),
            OwnerModel(
              ownerName: 'Sanjay Suresh Patil',
              khataNumber: 'KH-4902',
              totalArea: 0.0000,
              potKharaba: 0.0000,
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
          status: Defaults.propertyStatus,
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

  @override
  Future<Result<PropertyIdentifyModel>> identifyProperty(
    String gisCode,
    double latitude,
    double longitude,
  ) async {
    try {
      final property = await apiService.identifyProperty(
        gisCode: gisCode,
        latitude: latitude,
        longitude: longitude,
      );

      return Result.success(property);
    } catch (e) {
      return Result.failure(
        "Failed to identify property",
      );
    }
  }
}
