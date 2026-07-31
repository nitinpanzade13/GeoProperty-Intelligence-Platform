import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException({String message = 'Network connection failure. Please check your internet connection.'})
      : super(message: message, statusCode: 0);
}

class TimeoutException extends ApiException {
  TimeoutException({String message = 'Request timed out. Please try again.'})
      : super(message: message, statusCode: 408);
}

class NotFoundException extends ApiException {
  NotFoundException({String message = 'Requested resource not found.'})
      : super(message: message, statusCode: 404);
}

class ExceptionHandler {
  static ApiException parse(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutException();
        case DioExceptionType.connectionError:
          return NetworkException();
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          final msg = error.response?.data?['message'] ?? 'Server error ($code)';
          if (code == 404) return NotFoundException(message: msg);
          return ApiException(message: msg, statusCode: code, data: error.response?.data);
        default:
          return ApiException(message: error.message ?? 'An unexpected network error occurred');
      }
    }
    if (error is ApiException) return error;
    return ApiException(message: error.toString());
  }
}
