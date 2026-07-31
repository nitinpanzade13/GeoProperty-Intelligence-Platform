import 'app_config.dart';

class Environment {
  static late AppConfig config;

  static void init({AppConfig? customConfig, String? customIp}) {
    config = customConfig ?? AppConfig.development(customIp: customIp);
  }
}
