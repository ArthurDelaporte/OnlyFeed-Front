import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:onlyfeed_frontend/shared/services/token_manager.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late Dio dio;

  DioClient._internal() {
    // URL selon la plateforme
    String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://localhost:8080';
    } else {
      baseUrl = 'http://10.0.2.2:8080';  // Émulateur Android
    }

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            print('🚀 Requête vers: ${options.baseUrl}${options.path}'); // Debug
            
            final accessToken = await TokenManager.getAccessToken();
            final refreshToken = await TokenManager.getRefreshToken();

            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
            if (refreshToken != null && refreshToken.isNotEmpty) {
              options.headers['X-Refresh-Token'] = refreshToken;
            }

            return handler.next(options);
          },
          onResponse: (response, handler) async {
            print('✅ Réponse reçue: ${response.statusCode}'); // Debug
            
            final newAccessToken = response.headers['X-New-Access-Token']?.first;
            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await TokenManager.save(newAccessToken);
            }
            return handler.next(response);
          },
          onError: (error, handler) {
            print('❌ Erreur Dio: ${error.message}'); // Debug
            print('❌ URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
            return handler.next(error);
          },
        ),
      );
  }
}