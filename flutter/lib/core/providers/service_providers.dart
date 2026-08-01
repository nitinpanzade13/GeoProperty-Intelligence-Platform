import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dependency_injection.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../repositories/location_repository.dart';
import '../repositories/village_repository.dart';
import '../repositories/survey_repository.dart';
import '../repositories/property_repository.dart';
import '../repositories/user_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return getIt<ApiClient>();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return getIt<StorageService>();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return getIt<LocationService>();
});

final locationRepositoryProvider = Provider<ILocationRepository>((ref) {
  return getIt<ILocationRepository>();
});

final villageRepositoryProvider = Provider<IVillageRepository>((ref) {
  return getIt<IVillageRepository>();
});

final surveyRepositoryProvider = Provider<ISurveyRepository>((ref) {
  return getIt<ISurveyRepository>();
});

final propertyRepositoryProvider = Provider<IPropertyRepository>((ref) {
  return getIt<IPropertyRepository>();
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return getIt<IUserRepository>();
});
