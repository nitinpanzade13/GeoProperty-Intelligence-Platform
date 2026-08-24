import 'app_config.dart';

class Environment {
  static late AppConfig config;

  static const String _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  static void init({AppConfig? customConfig, String? customIp}) {
    if (customConfig != null) {
      config = customConfig;
    } else if (_apiBaseUrlFromEnv.isNotEmpty) {
      config = AppConfig(
        apiBaseUrl: _apiBaseUrlFromEnv,
        environment: EnvironmentType.prod,
      );
    } else {
      config = AppConfig.development(customIp: customIp);
    }
  }
}
