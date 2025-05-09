// lib/features/auth/presentation/signup_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http_parser/http_parser.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_header.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';

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
  String _selectedLanguage = 'fr';
  XFile? _profileImage;
  Uint8List? _webImageBytes;

  final _dio = DioClient().dio;

  void _signup() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final username = _usernameCtrl.text.trim();
    final firstname = _firstnameCtrl.text.trim();
    final lastname = _lastnameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();

    // Validation des champs requis
    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr("user.field.invalid"))),
      );
      return;
    }

    if (!Validators.isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Adresse email invalide")),
      );
      return;
    }

    // Vérification de la langue
    if (!['fr', 'en'].contains(_selectedLanguage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr("user.lang.invalid"))),
      );
      return;
    }

    // Vérification de l'extension du fichier de la photo
    if (_profileImage != null) {
      final fileName = _profileImage!.name.toLowerCase();
      final isValidExtension = RegExp(r'\.(jpg|jpeg|png|webp|gif|heic)$').hasMatch(fileName);
      if (!isValidExtension) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr("user.field.profile_picture_invalid"))),
        );
        return;
      }
    }

    try {
      final hashedPassword = sha256.convert(utf8.encode(_passwordCtrl.text)).toString();

      final formData = FormData();

      formData.fields.addAll([
        MapEntry('email', email),
        MapEntry('password', hashedPassword),
        MapEntry('username', username),
        MapEntry('firstname', firstname),
        MapEntry('lastname', lastname),
        MapEntry('bio', bio),
        MapEntry('language', _selectedLanguage),
      ]);

      if (_profileImage != null) {
        MultipartFile profilePicture;

        if (kIsWeb) {
          profilePicture = MultipartFile.fromBytes(
            _webImageBytes!,
            filename: _profileImage!.name,
            contentType: MediaType('image', _profileImage!.name.split('.').last),
          );
        } else {
          profilePicture = await MultipartFile.fromFile(
            _profileImage!.path,
            filename: _profileImage!.name,
          );
        }

        formData.files.add(MapEntry('profile_picture', profilePicture));
      }

      final response = await _dio.post(
        '/api/auth/signup',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr("user.sign.successful"))));
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr("user.sign.error"))));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${context.tr("core.error")} : $e")));
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _profileImage = image;
        });
      } else {
        setState(() {
          _profileImage = image;
        });
      }
    }
  }

  void goToLogin() {
    context.go('/login');
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
              child: Text(context.tr('user.sign.registration').capitalize(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 16),
            TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: context.tr('user.field.email').capitalize())),
            TextField(controller: _passwordCtrl, decoration: InputDecoration(labelText: context.tr('user.field.password').capitalize()), obscureText: true),
            TextField(controller: _usernameCtrl, decoration: InputDecoration(labelText: context.tr('user.field.username').capitalize())),
            TextField(controller: _firstnameCtrl, decoration: InputDecoration(labelText: context.tr('user.field.firstname').capitalize())),
            TextField(controller: _lastnameCtrl, decoration: InputDecoration(labelText: context.tr('user.field.lastname').capitalize())),
            TextField(controller: _bioCtrl, decoration: InputDecoration(labelText: context.tr('user.field.bio').capitalize())),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(labelText: context.tr('user.lang.language').capitalize()),
              items: [
                DropdownMenuItem(value: 'fr', child: Text(context.tr('user.lang.french').capitalize())),
                DropdownMenuItem(value: 'en', child: Text(context.tr('user.lang.english').capitalize())),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                }
              },
            ),
            SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: kIsWeb
                      ? (_webImageBytes != null ? MemoryImage(_webImageBytes!) : null)
                      : (_profileImage != null ? FileImage(File(_profileImage!.path)) : null) as ImageProvider?,
                  child: _profileImage == null
                      ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(context.tr('user.field.profile_picture').capitalize()),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _signup, child: Text(context.tr('user.sign.register').capitalize())),
            SizedBox(height: 20),
            ElevatedButton(onPressed: goToLogin, child: Text(context.tr('user.sign.already_account'))),
          ],
        ),
      ),
    );
  }
}
