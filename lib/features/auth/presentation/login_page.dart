// lib/features/auth/presentation/login_page.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _dio = DioClient().dio;

  void _login(BuildContext context) async {
    try {
      final hashedPassword = sha256.convert(utf8.encode(_passwordCtrl.text)).toString();

      final response = await _dio.post('/api/auth/login', data: {
        "email": _emailCtrl.text,
        "password": hashedPassword,
      });

      if (response.statusCode == 200) {
        final accessToken = response.data['access_token'];
        final refreshToken = response.data['refresh_token'];
        final user = response.data['user'];

        if (accessToken != null && refreshToken != null && user != null) {
          await TokenManager.saveBoth(accessToken, refreshToken);
          context.read<SessionNotifier>().setUser(user);

          final language = user['language'];
          final theme = user['theme'];
          if (language != null) {
            await context.setLocale(Locale(language));
            context.read<LocaleNotifier>().setLocale(Locale(language));
          }
          if (theme != null) {
            context.read<ThemeNotifier>().setTheme(parseThemeMode(theme));
          }

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("user.log.successful".tr())));
          context.go('/');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("core.error".tr())));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("user.log.error".tr())));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${"core.error".tr()} : $e")));
    }
  }

  void goToSignup() {
    context.go('/account/signup');
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;

    return ScaffoldWithMenubar(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: ListView(
          children: [
            Center(
              child: Text("user.log.connection".tr().capitalize(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 16),
            TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: 'user.field.email'.tr().capitalize())
            ),
            SizedBox(height: 8),
            TextField(
                controller: _passwordCtrl,
                decoration: InputDecoration(labelText: 'user.field.password'.tr().capitalize()),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(context)
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => _login(context),
                child: Text('user.log.login'.tr().capitalize())
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: goToSignup,
                child: Text('user.log.no_account'.tr())
            ),
          ],
        ),
      ),
    );
  }
}
