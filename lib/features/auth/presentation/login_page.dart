// lib/features/auth/presentation/login_page.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connexion réussie")));
        print('Login ${_emailCtrl.text}');
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de connexion")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text("Se connecter")),
          ],
        ),
      ),
    );
  }
}
