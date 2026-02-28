import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppException('Connection timeout. Please try again.');
        case DioExceptionType.badResponse:
          return _handleResponseError(error.response);
        case DioExceptionType.cancel:
          return AppException('Request cancelled');
        default:
          return AppException('Network error. Please check your connection.');
      }
    }
    return AppException(error.toString());
  }

  static AppException _handleResponseError(Response? response) {
    if (response == null) {
      return AppException('Unknown error occurred');
    }

    final statusCode = response.statusCode;
    final data = response.data;

    String message = 'An error occurred';
    if (data is Map && data.containsKey('detail')) {
      message = data['detail'].toString();
    }

    switch (statusCode) {
      case 400:
        return AppException('Bad request: $message');
      case 401:
        return AppException('Unauthorized: $message');
      case 403:
        return AppException('Access denied: $message');
      case 404:
        return AppException('Not found: $message');
      case 409:
        return AppException('Conflict: $message');
      case 500:
        return AppException('Server error: $message');
      default:
        return AppException(message);
    }
  }
}
