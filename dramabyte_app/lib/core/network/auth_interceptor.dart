import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/network/token_refresher.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._refresher);

  final TokenRefresher _refresher;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) return handler.next(options);
    final token = await _refresher.validAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final retryable =
        err.response?.statusCode == 401 &&
        request.extra['skipAuth'] != true &&
        request.extra['retried'] != true;
    if (!retryable) return handler.next(err);
    final token = await _refresher.refresh();
    if (token == null) return handler.next(err);
    request
      ..headers['Authorization'] = 'Bearer $token'
      ..extra['retried'] = true;
    try {
      handler.resolve(
        await Dio(
          BaseOptions(baseUrl: request.baseUrl),
        ).fetch<dynamic>(request),
      );
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
