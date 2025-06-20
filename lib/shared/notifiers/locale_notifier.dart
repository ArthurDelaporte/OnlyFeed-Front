// lib/shared/notifiers/locale_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier with ChangeNotifier {
  Locale _locale = Locale('fr');

  Locale get locale => _locale;

  void initLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final newLocale = await prefs.getString('locale') ?? 'fr';

    setLocale(Locale(newLocale));
  }

  void setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.languageCode);
  }
}
