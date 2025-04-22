// lib/features/auth/presentation/signup_page.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));

  void _signup() async {
    try {
      final hashedPassword = sha256.convert(utf8.encode(_passwordCtrl.text)).toString();

      final response = await _dio.post('/api/auth/signup', data: {
        "email": _emailCtrl.text,
        "password": hashedPassword,
        "username": _usernameCtrl.text,
        "firstname": _firstnameCtrl.text,
        "lastname": _lastnameCtrl.text,
        "bio": _bioCtrl.text,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Inscription réussie !")));
        print('SignUp ${_emailCtrl.text}');
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'inscription")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("S'inscrire")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            TextField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Nom d\'utilisateur')),
            TextField(controller: _firstnameCtrl, decoration: const InputDecoration(labelText: 'Prénom')),
            TextField(controller: _lastnameCtrl, decoration: const InputDecoration(labelText: 'Nom')),
            TextField(controller: _bioCtrl, decoration: const InputDecoration(labelText: 'Bio')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _signup, child: const Text("Créer un compte")),
          ],
        ),
      ),
    );
  }
}
