import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_header.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _dio = DioClient().dio;

  final _usernameCtrl = TextEditingController();
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  late Map<String, dynamic> _initialValues;
  bool _isLoading = true;

  String? _avatarUrl;
  XFile? _newImage;
  Uint8List? _webImageBytes;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _dio.get('/api/me');
      final user = response.data['user'];

      _initialValues = {
        'username': user['Username'] ?? '',
        'firstname': user['Firstname'] ?? '',
        'lastname': user['Lastname'] ?? '',
        'bio': user['Bio'] ?? '',
        'avatar': user['AvatarURL'] ?? '',
      };

      setState(() {
        _usernameCtrl.text = _initialValues['username'];
        _firstnameCtrl.text = _initialValues['firstname'];
        _lastnameCtrl.text = _initialValues['lastname'];
        _bioCtrl.text = _initialValues['bio'];
        _avatarUrl = _initialValues['avatar'];
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("core.error".tr())),
      );
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _newImage = image;
        });
      } else {
        setState(() {
          _newImage = image;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final username = _usernameCtrl.text.trim();
    final firstname = _firstnameCtrl.text.trim();
    final lastname = _lastnameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();

    final Map<String, dynamic> updates = {};

    if (username != _initialValues['username']) updates['username'] = username;
    if (firstname != _initialValues['firstname']) updates['firstname'] = firstname;
    if (lastname != _initialValues['lastname']) updates['lastname'] = lastname;
    if (bio != _initialValues['bio']) updates['bio'] = bio;

    final formData = FormData.fromMap(updates);

    if (_newImage != null) {
      final filename = _newImage!.name;

      final multipart = kIsWeb
          ? MultipartFile.fromBytes(
        _webImageBytes!,
        filename: filename,
        contentType: MediaType('image', filename.split('.').last),
      )
          : await MultipartFile.fromFile(_newImage!.path, filename: filename);

      formData.files.add(MapEntry('profile_picture', multipart));
    }

    if (formData.fields.isEmpty && formData.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("user.edit.no_update".tr().capitalize())),
      );
      return;
    }

    try {
      final response = await _dio.put(
        '/api/me',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("user.edit.updated_success".tr())),
        );
        context.go('/profile');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("user.edit.update_failed".tr())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${"core.error".tr().capitalize()} : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale; // OBLIGATOIRE POUR LE CHANGEMENT DE LANGUE

    if (_isLoading) {
      return ScaffoldWithHeader(body: Center(child: CircularProgressIndicator()));
    }

    final imageProvider = _newImage != null
        ? (kIsWeb
        ? MemoryImage(_webImageBytes!)
        : FileImage(File(_newImage!.path))) as ImageProvider
        : (_avatarUrl != null && _avatarUrl!.isNotEmpty
        ? NetworkImage(_avatarUrl!)
        : null);

    return ScaffoldWithHeader(
      body: Center(
        child: ListView(
          children: [
            Text("user.edit.edit_profile".tr(), style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            TextField(controller: _usernameCtrl, decoration: InputDecoration(labelText: 'user.field.username'.tr().capitalize())),
            TextField(controller: _firstnameCtrl, decoration: InputDecoration(labelText: 'user.field.firstname'.tr().capitalize())),
            TextField(controller: _lastnameCtrl, decoration: InputDecoration(labelText: 'user.field.lastname'.tr().capitalize())),
            TextField(controller: _bioCtrl, decoration: InputDecoration(labelText: 'user.field.bio'.tr().capitalize())),
            SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _saveProfile, child: Text("user.edit.register".tr().capitalize())),
          ],
        ),
      ),
    );
  }
}
