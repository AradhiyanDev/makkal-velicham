import 'package:dio/dio.dart';

class HeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    // Add auth token here when available:
    // final token = await SecureStorage.read('token');
    // if (token != null) options.headers['Authorization'] = 'Bearer $token';
    super.onRequest(options, handler);
  }
}
