import 'dart:developer' as dev;
import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    dev.log(
      '→ ${options.method} ${options.baseUrl}${options.path}'
      '${options.queryParameters.isNotEmpty ? ' ?${options.queryParameters}' : ''}',
      name: 'API',
    );
    if (options.data != null) dev.log('Body: ${options.data}', name: 'API');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    dev.log(
      '← ${response.statusCode} ${response.requestOptions.path}',
      name: 'API',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    dev.log(
      '✗ ${err.response?.statusCode ?? 'NO_STATUS'} ${err.requestOptions.path} :: ${err.message}',
      name: 'API',
      error: err.error,
    );
    if (err.response?.data != null) dev.log('Error data: ${err.response?.data}', name: 'API');
    super.onError(err, handler);
  }
}
