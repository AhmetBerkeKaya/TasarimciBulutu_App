// lib/core/services/dio_client.dart

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'auth_service.dart';

class DioClient {
  // Singleton pattern: Uygulama boyunca tek bir Dio nesnesi kullanılmasını sağlar.
  DioClient._();
  static final instance = DioClient._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://10.0.2.2:8000", // Temel URL'yi buraya taşıdık
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      responseType: ResponseType.json,
    ),
  )..interceptors.addAll([
    AuthInterceptor(),
    LoggingInterceptor(),
  ]);

  Dio get dio => _dio;
}

// --- INTERCEPTOR'LAR ---

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {

    // --- MANTIK HATASI BURADA DÜZELTİLDİ ---
    // Sadece login ve signup endpoint'leri herkese açık olmalı.
    final isPublicPath = options.path == '/token' ||
        (options.path == '/users/' && options.method == 'POST');

    // Eğer istek herkese açık bir yola DEĞİLSE, token eklemeyi dene.
    if (!isPublicPath) {
      final String? token = await AuthService().getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        print('>>> AuthInterceptor: Token eklendi -> ${options.path}');
      } else {
        print('>>> AuthInterceptor: Token bulunamadı -> ${options.path}');
      }
    }
    // --- DÜZELTME SONU ---

    // İsteğin devam etmesine izin ver
    super.onRequest(options, handler);
  }
}


class LoggingInterceptor extends Interceptor {
  final logger = PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
    compact: true,
    maxWidth: 90,
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.onError(err, handler);
  }
}