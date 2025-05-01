// lib/core/widgets/scaffold_with_header.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isValid = await TokenManager.isValid();
    setState(() => _isAuthenticated = isValid);
  }

  void _toggleLocale() {
    final current = context.locale;
    final newLocale = current.languageCode == 'fr' ? Locale('en') : Locale('fr');
    context.setLocale(newLocale);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale; // OBLIGATOIRE POUR LE CHANGEMENT DE LANGUE

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
            child: Text(context.locale.languageCode.toUpperCase(), style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.go('/profile');
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
