import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class IdempotencyInterceptor extends Interceptor {
  final Uuid _uuid = const Uuid();

  static const _idempotentMethods = {'POST', 'PUT', 'PATCH'};
  static const _idempotentPaths = {
    '/api/v1/mobile/posts/', // like, view, viewed, comments
    '/api/v1/mobile/events/batch',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final path = options.path;
    final isIdempotent = _idempotentMethods.contains(method) &&
        _idempotentPaths.any((p) => path.contains(p));

    if (isIdempotent && !options.headers.containsKey('Idempotency-Key')) {
      options.headers['Idempotency-Key'] = _uuid.v4();
    }
    handler.next(options);
  }
}
