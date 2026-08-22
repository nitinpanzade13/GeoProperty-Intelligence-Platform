import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/api_client.dart';
import 'models/admin_dashboard_models.dart';

class AdminApiService {
  final ApiClient apiClient;

  String? _accessToken;

  // ------------------------------------------------------------
  // Admin sync operations can legitimately take several minutes.
  // Do NOT let Dio timeout and automatically retry these POSTs.
  // ------------------------------------------------------------

  static const Duration _syncConnectTimeout = Duration(seconds: 30);

  static const Duration _syncReceiveTimeout = Duration(minutes: 15);

  AdminApiService({
    required this.apiClient,
  });

  // ============================================================
  // AUTHENTICATION
  // ============================================================

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

    debugPrint(
      'ADMIN LOGIN RESPONSE: $response',
    );

    final token = response['access_token'];

    if (token == null || token.toString().isEmpty) {
      throw Exception(
        'Access token missing from login response',
      );
    }

    _accessToken = token.toString();

    debugPrint(
      'ADMIN LOGIN SUCCESS',
    );
  }

  void logout() {
    _accessToken = null;
  }

  // ============================================================
  // DASHBOARD SUMMARY
  // ============================================================

  Future<AdminDashboardSummary> getDashboardSummary() async {
    final response = await get(
      '/admin/dashboard/summary',
    );

    return AdminDashboardSummary.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // DISTRICTS
  // ============================================================

  Future<List<AdminDistrictOverview>> getDistrictOverview() async {
    final response = await get(
      '/admin/dashboard/districts',
    );

    final list = List<dynamic>.from(response);

    return list.map((item) {
      return AdminDistrictOverview.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  // ============================================================
  // DISTRICT → TALUKA
  // ============================================================

  Future<List<AdminTalukaOverview>> getTalukaOverview({
    required String districtCode,
  }) async {
    final response = await get(
      '/admin/dashboard/districts/$districtCode/talukas',
    );

    final list = List<dynamic>.from(response);

    return list
        .map(
          (item) => AdminTalukaOverview.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ============================================================
  // TALUKA → VILLAGES
  // ============================================================

  Future<List<AdminVillageOverview>> getVillageOverview({
    required String districtCode,
    required String talukaCode,
  }) async {
    final response = await get(
      '/admin/dashboard/districts/'
      '$districtCode/talukas/'
      '$talukaCode/villages',
    );

    debugPrint(
      'VILLAGE API RESPONSE: $response',
    );

    final list = List<dynamic>.from(response);

    return list
        .map(
          (item) => AdminVillageOverview.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ============================================================
  // SYNC OPTIONS
  // ============================================================

  Options _syncOptions() {
    return Options(
      connectTimeout: _syncConnectTimeout,
      receiveTimeout: _syncReceiveTimeout,
      extra: {
        'disable_retry': true,
      },
    );
  }

  // ============================================================
  // SYNC DISTRICT
  // ============================================================

  Future<Map<String, dynamic>> syncDistrict({
    required String districtCode,
    bool forceRefresh = false,
  }) async {
    debugPrint(
      'ADMIN: Starting asynchronous district sync: $districtCode',
    );

    final response = await post(
      '/admin/sync/district',
      queryParameters: {
        'district_code': districtCode,
        'force_refresh': forceRefresh,
      },
    );

    return Map<String, dynamic>.from(
      response as Map,
    );
  }

  Future<Map<String, dynamic>> getDistrictSyncStatus({
    required String districtCode,
  }) async {
    final response = await get(
      '/admin/sync/district/status',
      queryParameters: {
        'district_code': districtCode,
      },
    );

    return Map<String, dynamic>.from(
      response as Map,
    );
  }

  // ============================================================
  // RESUME DISTRICT SYNC
  // ============================================================

  Future<dynamic> resumeDistrictSync({
    required String districtCode,
  }) async {
    return syncDistrict(
      districtCode: districtCode,
      forceRefresh: false,
    );
  }

  // ============================================================
  // REFRESH ENTIRE DISTRICT
  // ============================================================

  Future<dynamic> refreshDistrict({
    required String districtCode,
  }) async {
    return syncDistrict(
      districtCode: districtCode,
      forceRefresh: true,
    );
  }

  // ============================================================
  // SYNC TALUKA
  // ============================================================

  Future<dynamic> syncTaluka({
    required String districtCode,
    required String talukaCode,
    bool forceRefresh = false,
  }) async {
    debugPrint(
      'ADMIN: Starting taluka sync: '
      '$districtCode / $talukaCode '
      '(forceRefresh=$forceRefresh)',
    );

    final response = await post(
      '/admin/sync/taluka',
      queryParameters: {
        'district_code': districtCode,
        'taluka_code': talukaCode,
        'force_refresh': forceRefresh,
      },
      options: _syncOptions(),
    );

    debugPrint(
      'ADMIN: Taluka sync completed: '
      '$districtCode / $talukaCode '
      '(forceRefresh=$forceRefresh)',
    );

    return response;
  }

  // ============================================================
  // RESUME TALUKA SYNC
  // ============================================================

  Future<dynamic> resumeTalukaSync({
    required String districtCode,
    required String talukaCode,
  }) async {
    return syncTaluka(
      districtCode: districtCode,
      talukaCode: talukaCode,
      forceRefresh: false,
    );
  }

  // ============================================================
  // REFRESH ENTIRE TALUKA
  // ============================================================

  Future<dynamic> refreshTaluka({
    required String districtCode,
    required String talukaCode,
  }) async {
    return syncTaluka(
      districtCode: districtCode,
      talukaCode: talukaCode,
      forceRefresh: true,
    );
  }

  // ============================================================
  // SYNC VILLAGE
  // ============================================================

  Future<dynamic> syncVillage({
    required String districtCode,
    required String talukaCode,
    required String gisCode,
    bool forceRefresh = false,
  }) async {
    debugPrint(
      'ADMIN: Starting village sync: '
      '$gisCode '
      '(forceRefresh=$forceRefresh)',
    );

    final response = await post(
      '/admin/sync/village',
      queryParameters: {
        'district_code': districtCode,
        'taluka_code': talukaCode,
        'gis_code': gisCode,
        'force_refresh': forceRefresh,
      },
      options: _syncOptions(),
    );

    debugPrint(
      'ADMIN: Village sync completed: '
      '$gisCode '
      '(forceRefresh=$forceRefresh)',
    );

    return response;
  }

  // ============================================================
  // REFRESH VILLAGE
  // ============================================================

  Future<dynamic> refreshVillage({
    required String districtCode,
    required String talukaCode,
    required String gisCode,
  }) async {
    return syncVillage(
      districtCode: districtCode,
      talukaCode: talukaCode,
      gisCode: gisCode,
      forceRefresh: true,
    );
  }

  // ============================================================
  // SYNC VILLAGE MAP
  // ============================================================

  Future<dynamic> syncVillageMap({
    required String gisCode,
    bool forceRefresh = false,
  }) async {
    debugPrint(
      'ADMIN: Starting village map sync: '
      '$gisCode '
      '(forceRefresh=$forceRefresh)',
    );

    final response = await post(
      '/admin/sync/village-map',
      queryParameters: {
        'gis_code': gisCode,
        'force_refresh': forceRefresh,
      },
      options: _syncOptions(),
    );

    debugPrint(
      'ADMIN: Village map sync completed: '
      '$gisCode '
      '(forceRefresh=$forceRefresh)',
    );

    return response;
  }

  // ============================================================
  // REFRESH VILLAGE MAP
  // ============================================================

  Future<dynamic> refreshVillageMap({
    required String gisCode,
  }) async {
    return syncVillageMap(
      gisCode: gisCode,
      forceRefresh: true,
    );
  }

  // ============================================================
  // GENERIC GET
  // ============================================================

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

  // ============================================================
  // GENERIC POST
  // ============================================================

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
  }) async {
    return apiClient.post(
      path,
      queryParameters: queryParameters,
      data: data,
      options: _mergeOptions(
        options,
      ),
    );
  }

  // ============================================================
  // MERGE AUTH + REQUEST OPTIONS
  // ============================================================

  Options? _mergeOptions(Options? options) {
    final auth = _authOptions();

    if (options == null && auth == null) {
      return null;
    }

    if (options == null) {
      return auth;
    }

    if (auth == null) {
      return options;
    }

    return options.copyWith(
      headers: {
        ...?options.headers,
        ...?auth.headers,
      },
    );
  }

  // ============================================================
  // AUTH HEADER
  // ============================================================

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
