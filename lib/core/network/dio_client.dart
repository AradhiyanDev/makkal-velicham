import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../storage/token_storage.dart';
import 'api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/header_interceptor.dart';
import 'interceptors/idempotency_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class DioClient {
  late final Dio dio;
  final TokenStorage tokenStorage;

  DioClient({
    Dio? dioInstance,
    TokenStorage? tokenStorage,
    bool enablePrettyLogger = true,
  }) : tokenStorage = tokenStorage ?? TokenStorage() {
    dio = dioInstance ??
        Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            sendTimeout: ApiConstants.sendTimeout,
          ),
        );

    // Order: header -> auth (adds Bearer) -> idempotency -> logging -> error -> pretty
    dio.interceptors.addAll([
      HeaderInterceptor(),
      AuthInterceptor(this.tokenStorage),
      IdempotencyInterceptor(),
      LoggingInterceptor(),
      ErrorInterceptor(),
      if (enablePrettyLogger)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
        ),
    ]);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> postForm<T>(
    String path, {
    required FormData data,
    Options? options,
  }) {
    return dio.post<T>(path, data: data, options: options);
  }
}
