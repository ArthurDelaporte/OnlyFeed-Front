import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:onlyfeed_frontend/app.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/features/post/providers/post_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // await dotenv.load();

  setUrlStrategy(PathUrlStrategy());

  final sessionNotifier = SessionNotifier();
  await sessionNotifier.refreshUser();

  final localeNotifier = LocaleNotifier();
  localeNotifier.initLocale();

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
          ChangeNotifierProvider(create: (_) => localeNotifier),
          ChangeNotifierProvider(create: (_) => sessionNotifier),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => PostProvider()),
        ],
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: context.watch<LocaleNotifier>().locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      debugShowCheckedModeBanner: false,
      routerConfig: OnlyFeedApp.router,
      title: 'OnlyFeed',
      theme: AppTheme.lightTheme,
      darkTheme: AppDarkTheme.darkTheme,
      themeMode: context.watch<ThemeNotifier>().themeMode,
    );
  }
}