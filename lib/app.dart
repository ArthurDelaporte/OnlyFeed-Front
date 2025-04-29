import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:onlyfeed_frontend/features/auth/presentation/login_page.dart';
import 'package:onlyfeed_frontend/features/auth/presentation/signup_page.dart';
import 'package:onlyfeed_frontend/features/home/presentation/home_page.dart';

class OnlyFeedApp extends StatelessWidget {
  OnlyFeedApp({super.key});

  final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => HomePage()),
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => SignupPage()),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      title: 'OnlyFeed',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    );
  }
}
