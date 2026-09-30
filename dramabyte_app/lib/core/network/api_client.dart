import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/config/app_config.dart';
import 'package:dramabyte_app/core/network/auth_interceptor.dart';

final class ApiClient {
  ApiClient(AuthInterceptor authInterceptor)
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          sendTimeout: AppConfig.sendTimeout,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      )..interceptors.add(authInterceptor);

  final Dio dio;
}
