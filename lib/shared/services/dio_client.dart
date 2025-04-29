import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Liaison avec backend avec access_token en Authorization Bearer
class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late Dio dio;

  DioClient._internal() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final prefs = await SharedPreferences.getInstance();
            final accessToken = prefs.getString('access_token');
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
            return handler.next(options);
          },
        ),
      );
  }
}
