import 'package:get_it/get_it.dart';
import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/location_api_service.dart';
import '../services/village_api_service.dart';
import '../services/survey_api_service.dart';
import '../services/property_api_service.dart';
import '../repositories/location_repository.dart';
import '../repositories/village_repository.dart';
import '../repositories/survey_repository.dart';
import '../repositories/property_repository.dart';
import '../repositories/user_repository.dart';
import '../../features/admin/admin_api_service.dart';
import '../config/environment.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection({String? customIp}) async {
  // Config
  final config = Environment.config;
  if (!getIt.isRegistered<AppConfig>()) {
    getIt.registerSingleton<AppConfig>(config);
  }

  // Storage Service
  if (!getIt.isRegistered<StorageService>()) {
    final storageService = StorageService();
    await storageService.init();
    getIt.registerSingleton<StorageService>(storageService);
  }

  // ApiClient & Device Services
  if (!getIt.isRegistered<ApiClient>()) {
    getIt.registerLazySingleton<ApiClient>(
        () => ApiClient(config: getIt<AppConfig>()));
  }
  if (!getIt.isRegistered<LocationService>()) {
    getIt.registerLazySingleton<LocationService>(() => LocationService());
  }

  // API Services
  if (!getIt.isRegistered<LocationApiService>()) {
    getIt.registerLazySingleton<LocationApiService>(
        () => LocationApiService(apiClient: getIt<ApiClient>()));
  }
  if (!getIt.isRegistered<VillageApiService>()) {
    getIt.registerLazySingleton<VillageApiService>(
        () => VillageApiService(apiClient: getIt<ApiClient>()));
  }
  if (!getIt.isRegistered<SurveyApiService>()) {
    getIt.registerLazySingleton<SurveyApiService>(
        () => SurveyApiService(apiClient: getIt<ApiClient>()));
  }
  if (!getIt.isRegistered<PropertyApiService>()) {
    getIt.registerLazySingleton<PropertyApiService>(
        () => PropertyApiService(apiClient: getIt<ApiClient>()));
  }

  // Repositories
  if (!getIt.isRegistered<ILocationRepository>()) {
    getIt.registerLazySingleton<ILocationRepository>(
      () => LocationRepository(
        apiService: getIt<LocationApiService>(),
        deviceLocationService: getIt<LocationService>(),
      ),
    );
  }

  if (!getIt.isRegistered<IVillageRepository>()) {
    getIt.registerLazySingleton<IVillageRepository>(
      () => VillageRepository(apiService: getIt<VillageApiService>()),
    );
  }

  if (!getIt.isRegistered<ISurveyRepository>()) {
    getIt.registerLazySingleton<ISurveyRepository>(
      () => SurveyRepository(
        apiService: getIt<SurveyApiService>(),
        storageService: getIt<StorageService>(),
      ),
    );
  }

  if (!getIt.isRegistered<IPropertyRepository>()) {
    getIt.registerLazySingleton<IPropertyRepository>(
      () => PropertyRepository(apiService: getIt<PropertyApiService>()),
    );
  }

  if (!getIt.isRegistered<IUserRepository>()) {
    getIt.registerLazySingleton<IUserRepository>(
      () => UserRepository(apiClient: getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<AdminApiService>()) {
    getIt.registerLazySingleton<AdminApiService>(
      () => AdminApiService(
        apiClient: getIt<ApiClient>(),
      ),
    );
  }
}
