import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/app.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());

  runApp(
    EasyLocalization(
      startLocale: Locale('fr'),
      supportedLocales: [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: Locale('fr'),
      useOnlyLangCode: true,
      saveLocale: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleNotifier()),
        ],
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;

    return MaterialApp.router(
      locale: locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      debugShowCheckedModeBanner: false,
      routerConfig: OnlyFeedApp.router,
      title: 'OnlyFeed',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    );
  }
}
