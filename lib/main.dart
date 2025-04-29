import 'app.dart';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:easy_localization/easy_localization.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  EasyLocalization.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: Locale('fr'),
      child: OnlyFeedApp(),
    ),
  );
}