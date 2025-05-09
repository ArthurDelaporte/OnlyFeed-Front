// lib/shared/notifiers/locale_notifier.dart
import 'package:flutter/material.dart';

class LocaleNotifier with ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
  }
}
