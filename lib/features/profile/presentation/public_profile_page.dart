// lib/features/profile/presentation/public_profile_page.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';

class PublicProfilePage extends StatefulWidget {
  final String username;

  const PublicProfilePage({super.key, required this.username});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final _dio = DioClient().dio;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void didUpdateWidget(covariant PublicProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) {
      setState(() {
        _user = null;
        _isLoading = true;
      });
      _fetchUser();
    }
  }

  Future<void> _fetchUser() async {
    try {
      if (widget.username != "OnlyFeed") {
        final response = await _dio.get('/api/users/username/${widget.username}');
        setState(() {
          _user = response.data['user'];
        });
      }
      _isLoading = false;
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("core.error".tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;

    if (_isLoading) {
      return ScaffoldWithMenubar(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return ScaffoldWithMenubar(body: Center(child: Text("user.not_found".tr())));
    }

    return ScaffoldWithMenubar(
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              if (_user!['avatar_url'] != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_user!['avatar_url']),
                ),
              SizedBox(height: 16),
              Text(
                _user!['username'] ?? '',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _user!['bio'] ?? '',
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      ),
    );
  }
}
