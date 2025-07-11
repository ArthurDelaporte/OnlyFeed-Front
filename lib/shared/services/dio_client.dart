import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:onlyfeed_frontend/shared/services/token_manager.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late Dio dio;

  DioClient._internal() {
    final baseUrl = kIsWeb
        ? const String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080')
        : dotenv.env['BASE_URL'] ?? 'http://localhost:8080';

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
            final accessToken = await TokenManager.getAccessToken();
            final refreshToken = await TokenManager.getRefreshToken();

            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
            if (refreshToken != null && refreshToken.isNotEmpty) {
              options.headers['X-Refresh-Token'] = refreshToken;
            }

            options.extra['withCredentials'] = true;

            return handler.next(options);
          },
          onResponse: (response, handler) async {
            final newAccessToken = response.headers['X-New-Access-Token']?.first;
            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await TokenManager.save(newAccessToken);
            }
            return handler.next(response);
          },
          onError: (error, handler) {
            return handler.next(error);
          },
        ),
      );
  }
}
