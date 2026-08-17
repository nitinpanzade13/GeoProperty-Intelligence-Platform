import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/api_client.dart';
import 'models/admin_dashboard_models.dart';

class AdminApiService {
  final ApiClient apiClient;

  String? _accessToken;

  AdminApiService({
    required this.apiClient,
  });

  bool get isAuthenticated => _accessToken != null;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/admin/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    debugPrint('ADMIN LOGIN RESPONSE: $response');

    final token = response['access_token'];

    if (token == null || token.toString().isEmpty) {
      throw Exception('Access token missing from login response');
    }

    _accessToken = token.toString();

    debugPrint('ADMIN LOGIN SUCCESS');
    debugPrint('Token received: ${_accessToken != null}');
  }

  void logout() {
    _accessToken = null;
  }

  Future<AdminDashboardSummary> getDashboardSummary() async {
    final response = await get('/admin/dashboard/summary');

    return AdminDashboardSummary.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<List<AdminDistrictOverview>> getDistrictOverview() async {
    final response = await get('/admin/dashboard/districts');

    final list = response as List;

    return list
        .map(
          (item) => AdminDistrictOverview.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return apiClient.get(
      path,
      queryParameters: queryParameters,
      options: _authOptions(),
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
  }) async {
    return apiClient.post(
      path,
      queryParameters: queryParameters,
      data: data,
      options: _authOptions(),
    );
  }

  Options? _authOptions() {
    if (_accessToken == null) {
      return null;
    }

    return Options(
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );
  }
}
