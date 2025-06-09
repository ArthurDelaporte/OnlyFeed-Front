// lib/shared/notifiers/session_notifier.dart
import 'package:flutter/material.dart';

import 'package:onlyfeed_frontend/shared/services/token_manager.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';

class SessionNotifier with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isInitialized = false;

  Map<String, dynamic>? get user => _user;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;

  void setUser(Map<String, dynamic>? userData) {
    _user = userData;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final isValid = await TokenManager.isValid();
    if (!isValid) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      final dio = DioClient().dio;
      final response = await dio.get('/api/me');
      final user = response.data['user'];

      setUser(user);
    } catch (_) {}
  }

  void clearUser() {
    setUser(null);
  }
}
