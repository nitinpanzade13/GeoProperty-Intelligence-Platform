import 'package:flutter/foundation.dart';

enum EnvironmentType { dev, staging, prod }

class AppConfig {
  final String apiBaseUrl;
  final EnvironmentType environment;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;

  const AppConfig({
    required this.apiBaseUrl,
    required this.environment,
    this.connectTimeoutMs = 30000,
    this.receiveTimeoutMs = 30000,
  });

  /// Development Configuration
  ///
  /// Platform-Aware Host Selection:
  /// - Flutter Web (Chrome): localhost (Backend running on same computer)
  /// - Mobile (Android/iOS): Local Wi-Fi LAN IP (10.193.171.183)
  /// - customIp: Overrides host if specified
  factory AppConfig.development({String? customIp}) {
    late final String host;

    if (customIp != null && customIp.isNotEmpty) {
      host = customIp;
    } else if (kIsWeb) {
      // Flutter Web in Chrome on same PC MUST use localhost
      host = 'localhost';
    } else {
      // Mobile devices on same Wi-Fi network use PC's LAN IP
      host = '10.193.171.183';
    }

    return AppConfig(
      apiBaseUrl: 'http://$host:8000/api',
      environment: EnvironmentType.dev,
      connectTimeoutMs: 30000,
      receiveTimeoutMs: 30000,
    );
  }

  factory AppConfig.staging() {
    return const AppConfig(
      apiBaseUrl: 'https://staging.example.com/api',
      environment: EnvironmentType.staging,
    );
  }

  factory AppConfig.production() {
    return const AppConfig(
      apiBaseUrl: 'https://api.example.com/api',
      environment: EnvironmentType.prod,
    );
  }
}
