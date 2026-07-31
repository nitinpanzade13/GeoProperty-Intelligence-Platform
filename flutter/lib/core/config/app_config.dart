enum EnvironmentType { dev, staging, prod }

class AppConfig {
  final String apiBaseUrl;
  final EnvironmentType environment;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;

  const AppConfig({
    required this.apiBaseUrl,
    required this.environment,
    this.connectTimeoutMs = 15000,
    this.receiveTimeoutMs = 15000,
  });

  /// Factory for development.
  /// Set default to local Wi-Fi LAN IP (http://10.193.171.183:8000/api)
  /// so physical mobile devices (e.g. Motorola Edge 50 Fusion) can connect seamlessly over Wi-Fi.
  factory AppConfig.development({String? customIp}) {
    final String targetIp = customIp ?? '10.193.171.183';
    final baseUrl = 'http://$targetIp:8000/api';

    return AppConfig(
      apiBaseUrl: baseUrl,
      environment: EnvironmentType.dev,
    );
  }
}
