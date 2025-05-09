// lib/features/auth/presentation/login_page.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/core/widgets/scaffold_with_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _dio = DioClient().dio;

  void _login() async {
    try {
      final hashedPassword = sha256.convert(utf8.encode(_passwordCtrl.text)).toString();

      final response = await _dio.post('/api/auth/login', data: {
        "email": _emailCtrl.text,
        "password": hashedPassword,
      });

      if (response.statusCode == 200) {
        final accessToken = response.data['access_token'];
        final refreshToken = response.data['refresh_token'];

        if (accessToken != null && refreshToken != null) {
          await TokenManager.saveBoth(accessToken, refreshToken);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr("user.log.successful"))));
          context.go('/');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr("core.error"))));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr("user.log.error"))));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${context.tr("core.error")} : $e")));
    }
  }

  void goToSignup() {
    context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    // final currentLocale = context.locale; // OBLIGATOIRE POUR LE CHANGEMENT DE LANGUE

    return ScaffoldWithHeader(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: ListView(
          children: [
            Center(
              child: Text(context.tr("user.log.connection").capitalize(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 16),
            TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: context.tr('user.field.email').capitalize())
            ),
            TextField(
                controller: _passwordCtrl,
                decoration: InputDecoration(labelText: context.tr('user.field.password').capitalize()),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login()
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text(context.tr('user.log.login').capitalize())),
            SizedBox(height: 20),
            ElevatedButton(onPressed: goToSignup, child: Text(context.tr('user.log.no_account'))),
          ],
        ),
      ),
    );
  }
}
