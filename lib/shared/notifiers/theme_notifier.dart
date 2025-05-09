import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier{
  Locale locale = Locale('fr', 'FR');

  void onChangeLocale(Locale value){
    locale = value;
    notifyListeners();
  }
}