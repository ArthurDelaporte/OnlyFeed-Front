import 'dart:html' as html;

void setupWebStorageListener(Function onTokenChange) {
  html.window.onStorage.listen((event) {
    if (event.key == 'access_token' || event.key == 'refresh_token') {
      onTokenChange();
    }
  });
}