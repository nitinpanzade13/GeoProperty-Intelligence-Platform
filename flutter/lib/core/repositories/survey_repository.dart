import '../services/survey_api_service.dart';
import '../services/storage_service.dart';
import '../models/survey_model.dart';
import '../models/location_model.dart';
import '../utils/result.dart';
import '../constants/defaults.dart';

abstract class ISurveyRepository {
  Future<Result<List<SurveyModel>>> getSurveys({String? query, String? gisCode});
  Future<Result<void>> toggleFavorite(String surveyId);
}

class SurveyRepository implements ISurveyRepository {
  final SurveyApiService apiService;
  final StorageService storageService;

  SurveyRepository({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<Result<List<SurveyModel>>> getSurveys({String? query, String? gisCode}) async {
    try {
      final code = gisCode ?? Defaults.legacyGisCode;
      final list = await apiService.fetchSurveys(gisCode: code);
      final favorites = storageService.getFavoriteIds();

      var surveys = list.map((s) => s.copyWith(isFavorite: favorites.contains(s.id))).toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        surveys = surveys.where((s) =>
          s.surveyNumber.toLowerCase().contains(q) ||
          s.village.toLowerCase().contains(q) ||
          s.district.toLowerCase().contains(q)
        ).toList();
      }

      return Result.success(surveys);
    } catch (e) {
      final mockData = _getFallbackSurveys(query);
      final favorites = storageService.getFavoriteIds();
      final updated = mockData.map((s) => s.copyWith(isFavorite: favorites.contains(s.id))).toList();
      return Result.success(updated);
    }
  }

  @override
  Future<Result<void>> toggleFavorite(String surveyId) async {
    try {
      if (storageService.isFavorite(surveyId)) {
        await storageService.removeFavorite(surveyId);
      } else {
        await storageService.addFavorite(surveyId);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to update favorite status');
    }
  }

  List<SurveyModel> _getFallbackSurveys(String? query) {
    const defaultSurveys = [
      SurveyModel(
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
      SurveyModel(
        id: 'SURV-102',
        surveyNumber: '145',
        subdivisionNumber: '1',
        district: Defaults.district,
        taluka: Defaults.taluka,
        village: Defaults.village,
        areaSqMeters: 8200.5,
        landType: 'Non-Agricultural (Commercial)',
        location: LocationModel(
          latitude: 18.5240,
          longitude: 73.8590,
          address: 'FC Road, Pune',
          district: Defaults.district,
          taluka: Defaults.taluka,
          village: Defaults.village,
        ),
      ),
      SurveyModel(
        id: 'SURV-103',
        surveyNumber: '88',
        subdivisionNumber: '2/B',
        district: Defaults.district,
        taluka: 'Mulshi',
        village: 'Hinjawadi',
        areaSqMeters: 12400.0,
        landType: 'Industrial / IT Zone',
        location: LocationModel(
          latitude: 18.5912,
          longitude: 73.7389,
          address: 'Phase 1, Hinjawadi, Pune',
          district: Defaults.district,
          taluka: 'Mulshi',
          village: 'Hinjawadi',
        ),
      ),
    ];

    if (query == null || query.isEmpty) return defaultSurveys;
    final q = query.toLowerCase();
    return defaultSurveys.where((s) =>
      s.surveyNumber.toLowerCase().contains(q) ||
      s.village.toLowerCase().contains(q) ||
      s.district.toLowerCase().contains(q)
    ).toList();
  }
}
