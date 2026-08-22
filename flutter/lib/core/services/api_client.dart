import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'api_exceptions.dart';

class ApiClient {
  late final Dio _dio;
  final AppConfig config;

  ApiClient({required this.config}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: Duration(
          milliseconds: config.connectTimeoutMs,
        ),
        receiveTimeout: Duration(
          milliseconds: config.receiveTimeoutMs,
        ),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.i(
            'HTTP Request [${options.method}] => ${options.uri}',
          );

          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.i(
            'HTTP Response [${response.statusCode}] '
            '<= ${response.requestOptions.uri}',
          );

          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          AppLogger.e(
            'HTTP Error [${error.response?.statusCode}] '
            '<= ${error.requestOptions.uri}',
            error,
          );

          // ------------------------------------------------------
          // Check whether this request explicitly disables retry.
          //
          // This is important for long-running operations such as:
          //
          // POST /admin/sync/district
          // POST /admin/sync/taluka
          // POST /admin/sync/village
          //
          // If the frontend times out, the backend operation may
          // still be running. Retrying the POST could start another
          // request while the original operation is still active.
          // ------------------------------------------------------

          final bool disableRetry =
              error.requestOptions.extra['disable_retry'] == true;

          if (disableRetry) {
            AppLogger.w(
              'Automatic retry disabled for: '
              '${error.requestOptions.method} '
              '${error.requestOptions.uri}',
            );

            return handler.next(error);
          }

          // ------------------------------------------------------
          // Existing retry counter
          // ------------------------------------------------------

          final int retryCount =
              error.requestOptions.extra['retry_count'] as int? ?? 0;

          // ------------------------------------------------------
          // Retry only when allowed
          // ------------------------------------------------------

          if (_shouldRetry(error, retryCount)) {
            error.requestOptions.extra['retry_count'] = retryCount + 1;

            try {
              AppLogger.i(
                'Retrying request: '
                '${error.requestOptions.method} '
                '${error.requestOptions.uri} '
                '(retry ${retryCount + 1}/1)',
              );

              final response = await _retry(
                error.requestOptions,
              );

              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // ============================================================
  // UPDATE BASE URL
  // ============================================================

  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;

    AppLogger.i(
      'ApiClient base URL updated to: $newUrl',
    );
  }

  // ============================================================
  // RETRY DECISION
  // ============================================================

  bool _shouldRetry(
    DioException error,
    int retryCount,
  ) {
    final disableRetry = error.requestOptions.extra['disable_retry'] == true;

    if (disableRetry) {
      return false;
    }

    // ----------------------------------------------------------
    // Maximum 1 automatic retry.
    // ----------------------------------------------------------

    if (retryCount >= 1) {
      return false;
    }

    // ----------------------------------------------------------
    // Web
    //
    // Avoid blind retries for Web CORS / XMLHttpRequest errors.
    // ----------------------------------------------------------

    if (kIsWeb) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout;
    }

    // ----------------------------------------------------------
    // Mobile / Desktop
    // ----------------------------------------------------------

    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  // ============================================================
  // RETRY REQUEST
  // ============================================================

  Future<Response> _retry(
    RequestOptions requestOptions,
  ) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      extra: requestOptions.extra,
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // ============================================================
  // GET
  // ============================================================

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _unwrapResponse(response);
    } catch (e) {
      throw ExceptionHandler.parse(e);
    }
  }

  // ============================================================
  // POST
  // ============================================================

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      // --------------------------------------------------------
      // Preserve existing options and add JSON content type.
      // --------------------------------------------------------

      final postOptions = (options ?? Options()).copyWith(
        headers: {
          'Content-Type': 'application/json',
          ...?options?.headers,
        },
      );

      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: postOptions,
        cancelToken: cancelToken,
      );

      return _unwrapResponse(response);
    } catch (e) {
      throw ExceptionHandler.parse(e);
    }
  }

  // ============================================================
  // RESPONSE UNWRAPPER
  // ============================================================

  dynamic _unwrapResponse(
    Response response,
  ) {
    final data = response.data;

    if (data is Map<String, dynamic> && data.containsKey('data')) {
      if (data['success'] == false) {
        throw ApiException(
          message: data['message'] ?? 'API Operation Failed',
          data: data['errors'],
        );
      }

      return data['data'];
    }

    return data;
  }
}
