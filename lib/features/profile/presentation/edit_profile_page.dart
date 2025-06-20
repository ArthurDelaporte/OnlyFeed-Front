import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';
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
  final _subscriptionPriceCtrl = TextEditingController();

  late Map<String, dynamic> _initialValues;
  bool _isLoading = true;
  bool _isCreator = false;

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

      _isCreator = response.data['user']['is_creator'];

      final languageCode = context.read<LocaleNotifier>().locale.languageCode;

      final rawPrice = user['subscription_price'];
      final separator = getDecimalSeparator(languageCode);
      final subscriptionPrice = rawPrice != null
          ? rawPrice.toString().replaceAll('.', separator)
          : (separator == ',' ? '5,0' : '5.0');

      _initialValues = {
        'username': user['username'] ?? '',
        'firstname': user['firstname'] ?? '',
        'lastname': user['lastname'] ?? '',
        'bio': user['bio'] ?? '',
        'avatar': user['avatar_url'] ?? '',
        'language': user['language'] ?? 'fr',
        'is_creator': user['is_creator'] ?? false,
        'subscription_price': subscriptionPrice,
      };

      setState(() {
        _usernameCtrl.text = _initialValues['username'];
        _firstnameCtrl.text = _initialValues['firstname'];
        _lastnameCtrl.text = _initialValues['lastname'];
        _bioCtrl.text = _initialValues['bio'];
        _subscriptionPriceCtrl.text = subscriptionPrice;
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
    final languageCode = context.read<LocaleNotifier>().locale.languageCode;

    final username = _usernameCtrl.text.trim();
    final firstname = _firstnameCtrl.text.trim();
    final lastname = _lastnameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    final rawText = _subscriptionPriceCtrl.text.trim();
    final separator = getDecimalSeparator(languageCode);
    final subscriptionPrice = rawText.replaceAll(separator, '.');

    final Map<String, dynamic> updates = {};

    if (username != _initialValues['username']) updates['username'] = username;
    if (firstname != _initialValues['firstname']) updates['firstname'] = firstname;
    if (lastname != _initialValues['lastname']) updates['lastname'] = lastname;
    if (bio != _initialValues['bio']) updates['bio'] = bio;
    if (subscriptionPrice != _initialValues['subscription_price'] && _initialValues['is_creator']) {
      updates['subscription_price'] = subscriptionPrice;
    }

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
        context.go('/${username}');
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
    final locale = context.watch<LocaleNotifier>().locale;

    if (_isLoading) {
      return ScaffoldWithMenubar(body: Center(child: CircularProgressIndicator()));
    }

    final imageProvider = _newImage != null
        ? (kIsWeb
        ? MemoryImage(_webImageBytes!)
        : FileImage(File(_newImage!.path))) as ImageProvider
        : (_avatarUrl != null && _avatarUrl!.isNotEmpty
        ? NetworkImage(_avatarUrl!)
        : null);

    return ScaffoldWithMenubar(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: ListView(
          children: [
            Text("user.edit.edit_profile".tr(), style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            TextField(controller: _usernameCtrl, decoration: InputDecoration(labelText: 'user.field.username'.tr().capitalize())),
            SizedBox(height: 8),
            TextField(controller: _firstnameCtrl, decoration: InputDecoration(labelText: 'user.field.firstname'.tr().capitalize())),
            SizedBox(height: 8),
            TextField(controller: _lastnameCtrl, decoration: InputDecoration(labelText: 'user.field.lastname'.tr().capitalize())),
            SizedBox(height: 8),
            TextField(controller: _bioCtrl, decoration: InputDecoration(labelText: 'user.field.bio'.tr().capitalize())),
            if (_isCreator) ...[
              SizedBox(height: 8),
              TextField(
                controller: _subscriptionPriceCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(context.locale.languageCode == 'fr' ? r'[0-9,]' : r'[0-9.]'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'user.field.subscription_price'.tr().capitalize(),
                  hintText: context.locale.languageCode == 'fr' ? 'Ex: 9,99' : 'e.g. 9.99',
                ),
              ),
            ],
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
            ElevatedButton(
                onPressed: _saveProfile,
                child: Text("user.edit.register".tr().capitalize())
            ),
          ],
        ),
      ),
    );
  }
}
