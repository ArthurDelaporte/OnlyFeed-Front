import 'dart:html' as html;

Future<void> syncToWebStorage(String accessToken, String refreshToken) async {
  html.window.localStorage['access_token'] = accessToken;
  html.window.localStorage['refresh_token'] = refreshToken;
}

Future<void> clearWebStorage() async {
  html.window.localStorage.remove('access_token');
  html.window.localStorage.remove('refresh_token');
}