import 'package:onlyfeed_frontend/shared/notifiers/theme_notifier.dart';
import 'package:provider/provider.dart';

import 'app.dart';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:easy_localization/easy_localization.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());

  final multiProviders = MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => ThemeNotifier())],
    child: EasyLocalization(
      supportedLocales: [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: Locale('fr'),
      saveLocale: true,
      child: OnlyFeedApp(),
    ),
  );
  runApp(multiProviders);
}
