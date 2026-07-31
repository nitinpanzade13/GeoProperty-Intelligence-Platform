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
        connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.i('HTTP Request [${options.method}] => ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.i('HTTP Response [${response.statusCode}] <= ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          AppLogger.e('HTTP Error [${error.response?.statusCode}] <= ${error.requestOptions.uri}', error);
          if (_shouldRetry(error)) {
            try {
              final response = await _retry(error.requestOptions);
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

  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
    AppLogger.i('ApiClient base URL updated to: $newUrl');
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

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

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _unwrapResponse(response);
    } catch (e) {
      throw ExceptionHandler.parse(e);
    }
  }

  dynamic _unwrapResponse(Response response) {
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
