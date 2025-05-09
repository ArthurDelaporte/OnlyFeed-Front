// lib/core/widgets/scaffold_with_header.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/shared/shared.dart';

class ScaffoldWithHeader extends StatefulWidget {
  final Widget body;

  const ScaffoldWithHeader({
    super.key,
    required this.body,
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
        final language = response.data['user']['language'];
        final currentLocale = context.locale;

        if (language != null && currentLocale.languageCode != language) {
          final newLocale = Locale(language);
          await context.setLocale(newLocale);
          context.read<LocaleNotifier>().setLocale(newLocale);
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isAuthenticated = isValid);
    }
  }

  Future<void> _toggleLocale() async {
    final current = context.read<LocaleNotifier>().locale;
    final newLocale = current.languageCode == 'fr' ? const Locale('en') : const Locale('fr');

    await context.setLocale(newLocale);
    context.read<LocaleNotifier>().setLocale(newLocale);

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
          SnackBar(content: Text("core.error".tr())),
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
          SnackBar(content: Text("user.log.logout_failed".tr())),
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
            "app.title".tr(),
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
            child: Text(
                locale.languageCode.toUpperCase(),
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
                  child: Text('user.profile'.tr().capitalize())
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('user.log.logout'.tr().capitalize()),
              ),
            ] : [
              PopupMenuItem(
                  value: 'login',
                  child: Text('user.log.login'.tr().capitalize())
              ),
              PopupMenuItem(
                  value: 'signup',
                  child: Text('user.sign.signup'.tr().capitalize())
              ),
            ],
          ),
        ],
      ),
      body: widget.body,
    );
  }
}
