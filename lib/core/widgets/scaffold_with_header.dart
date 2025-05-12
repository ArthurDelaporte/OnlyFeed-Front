// lib/core/widgets/scaffold_with_header.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:onlyfeed_frontend/shared/notifiers/theme_notifier.dart';

import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:provider/provider.dart';

class ScaffoldWithHeader extends StatefulWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final String? title;


  const ScaffoldWithHeader({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.title,
  });

  @override
  State<ScaffoldWithHeader> createState() => _ScaffoldWithHeaderState();
}

class _ScaffoldWithHeaderState extends State<ScaffoldWithHeader>{
  bool _isAuthenticated = false;
  bool _hasCheckedAuth = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedAuth) {
      _hasCheckedAuth = true;
      _checkAuthentication();
    }
  }

  Future<void> _checkAuthentication() async {
    final isValid = await TokenManager.isValid();
    if (isValid) {
      final dio = DioClient().dio;
      try {
        final response = await dio.get('/api/me');
        final language = response.data['user']['Language'];
        if (language != null && context.locale.languageCode != language) {
          await context.setLocale(Locale(language));
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isAuthenticated = isValid);
    }
  }

  Future<void> _toggleLocale() async {
    final newLocale = context.locale.languageCode == 'fr' ? const Locale('en') : const Locale('fr');

    context.setLocale(newLocale);

    if (_isAuthenticated) {
      try {
        final dio = DioClient().dio;
        await dio.put(
          '/api/me',
          data: FormData.fromMap({
            'language': newLocale.languageCode,
          }),
          options: Options(contentType: 'multipart/form-data'),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr("core.error"))),
        );
      }
    }

    setState(() {});
  }

  Future<void> _logout() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.post('/api/auth/logout');

      if (response.data['message'] != null) {
        await TokenManager.clear();
        if (mounted) context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr("user.log.logout_failed"))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${context.tr("core.error")} : $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedAuth) {
      _hasCheckedAuth = true;
      _checkAuthentication();
    }


    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Text(
            widget.title ?? context.tr("app.title"),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _toggleLocale,
            child: Text(context.locale.languageCode.toUpperCase(), style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  context.go('/profile');
                  break;
                case 'logout':
                  await _logout();
                  break;
                case 'login':
                  context.go('/login');
                  break;
                case 'signup':
                  context.go('/signup');
                  break;
              }
            },
            itemBuilder: (context) => _isAuthenticated
            ? [
              PopupMenuItem(
                  value: 'profile',
                  child: Text(context.tr('user.profile').capitalize())
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text(context.tr('user.log.logout').capitalize()),
              ),
            ] : [
              PopupMenuItem(
                  value: 'login',
                  child: Text(context.tr('user.log.login').capitalize())
              ),
              PopupMenuItem(
                  value: 'signup',
                  child: Text(context.tr('user.sign.signup').capitalize())
              ),
            ],
          ),
        ],
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
