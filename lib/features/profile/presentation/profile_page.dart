import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_header.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _dio = DioClient().dio;

  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _dio.get('/api/me');

      if (response.statusCode == 200) {
        setState(() => _user = response.data['user']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("core.error".tr())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${"core.error".tr()} : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;

    return ScaffoldWithHeader(
      body: _user == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_user?['avatar_url'] != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_user!['avatar_url']),
              )
            else
              CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 40),
              ),
            SizedBox(height: 20),
            Text(_user?['username'] ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(_user?['email'] ?? '', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("${_user?['firstname'] ?? ''} ${_user?['lastname'] ?? ''}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(_user?['bio'] ?? '', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            SizedBox(height: 8),
            Text("${'user.lang.language'.tr().capitalize()}: ${('user.lang.'+context.locale.languageCode).tr().capitalize()}", style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => context.go('/profile/edit'),
              icon: const Icon(Icons.edit),
              label: Text("user.edit.edit_profile".tr()),
            ),
          ],
        ),
      ),
    );
  }
}
