import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet.';
        break;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        final data = err.response?.data;
        if (data is Map && data['message'] is String) {
          message = data['message'] as String;
        } else if (status == 401) {
          message = 'Unauthorized. Please login again.';
        } else if (status == 404) {
          message = 'Resource not found.';
        } else if (status != null && status >= 500) {
          message = 'Server error ($status). Try again later.';
        } else {
          message = 'Request failed (${status ?? 'unknown'}).';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection.';
        break;
      default:
        message = err.message ?? 'Unknown network error.';
    }
    // Attach friendly message for UI to read via err.error
    handler.next(err.copyWith(error: message));
  }
}
