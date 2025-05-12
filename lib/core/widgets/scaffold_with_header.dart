// lib/core/widgets/scaffold_with_header.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/shared/shared.dart';

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

class _ScaffoldWithHeaderState extends State<ScaffoldWithHeader> with WidgetsBindingObserver{
  bool _hasCheckedSession = false;
  bool _showSearchBar = false;
  final _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SessionNotifier>().refreshUser();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedSession) {
      _hasCheckedSession = true;
      _loadSessionUser();
    }
  }

  Future<void> _loadSessionUser() async {
    final session = context.read<SessionNotifier>();
    if (!session.isAuthenticated) {
      final isValid = await TokenManager.isValid();
      if (isValid) {
        try {
          final dio = DioClient().dio;
          final response = await dio.get('/api/me');
          final user = response.data['user'];
          session.setUser(user);

          final language = user['language'];
          final locale = context.read<LocaleNotifier>();
          if (language != null && locale.locale.languageCode != language) {
            locale.setLocale(Locale(language));
          }

          final themePref = user['theme'];
          if (themePref != null) {
            final themeNotifier = context.read<ThemeNotifier>();
            themeNotifier.setTheme(parseThemeMode(themePref));
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _toggleLocale() async {
    final session = context.read<SessionNotifier>();
    final locale = context.read<LocaleNotifier>();
    final newLocale = locale.locale.languageCode == 'fr' ? const Locale('en') : const Locale('fr');

    await context.setLocale(newLocale);
    locale.setLocale(newLocale);

    if (session.isAuthenticated) {
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

  void _toggleTheme() async {
    final themeNotifier = context.read<ThemeNotifier>();
    final session = context.read<SessionNotifier>();

    final isDark = themeNotifier.themeMode == ThemeMode.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;

    themeNotifier.setTheme(newMode);

    if (session.isAuthenticated) {
      try {
        final dio = DioClient().dio;
        await dio.put(
          '/api/me',
          data: FormData.fromMap({'theme': newMode.name}),
          options: Options(contentType: 'multipart/form-data'),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("core.error".tr())),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.post('/api/auth/logout');

      if (response.data['message'] != null) {
        await TokenManager.clear();
        context.read<SessionNotifier>().clearUser();
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

  void _onSearchSubmit(String value) {
    final username = value.trim();
    if (username.isNotEmpty) {
      context.go('/u/$username');
      setState(() => _showSearchBar = false);
      _searchCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;
    final session = context.watch<SessionNotifier>();
    final isAuthenticated = session.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Text(
            widget.title ?? "app.title".tr(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
              onPressed: () {
                setState(() => _showSearchBar = !_showSearchBar);
                if (!_showSearchBar) return;

                // Attendre la fin du build avant de donner le focus
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _searchFocusNode.requestFocus();
                });
              }
          ),
          IconButton(
            icon: Icon(
              context.watch<ThemeNotifier>().themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: _toggleTheme,
            tooltip: "user.theme.change_theme".tr(),
          ),
          TextButton(
            onPressed: _toggleLocale,
            child: Text(
                locale.languageCode.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold)),
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
            itemBuilder: (context) => isAuthenticated
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
        bottom: _showSearchBar
            ? PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: "${"user.search.search_user".tr()}...",
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: _onSearchSubmit,
              textInputAction: TextInputAction.search,
            ),
          ),
        )
            : null,
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
