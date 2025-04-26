// lib/features/auth/presentation/login_page.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';
import '../../../core/widgets/scaffold_with_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));

  void _login() async {
    try {
      final hashedPassword = sha256.convert(utf8.encode(_passwordCtrl.text)).toString();

      final response = await _dio.post('/api/auth/login', data: {
        "email": _emailCtrl.text,
        "password": hashedPassword,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("user.log.successful".tr())));
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("user.log.error".tr())));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${"core.error".tr()} : $e")));
    }
  }

  void goToSignup() {
    context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale; // OBLIGATOIRE POUR LE CHANGEMENT DE LANGUE

    return ScaffoldWithHeader(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: ListView(
          children: [
            Center(
              child: Text("user.log.connection".tr().capitalize(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 16),
            TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'user.field.email'.tr().capitalize())),
            TextField(controller: _passwordCtrl, decoration: InputDecoration(labelText: 'user.field.password'.tr().capitalize()), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('user.log.login'.tr().capitalize())),
            SizedBox(height: 20),
            ElevatedButton(onPressed: goToSignup, child: Text('user.log.no_account'.tr())),
          ],
        ),
      ),
    );
  }
}
