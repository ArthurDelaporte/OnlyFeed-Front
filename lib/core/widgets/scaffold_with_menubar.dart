import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/shared/shared.dart';

enum SidebarItem {
  home,
  search,
  create,
  chats,
  profile,
  login,
}

const sizeMinSidebar = 768;
const sizeMinLabelIcon = 1024;

class ScaffoldWithMenubar extends StatefulWidget {
  final Widget body;

  const ScaffoldWithMenubar({super.key, required this.body});

  @override
  State<ScaffoldWithMenubar> createState() => _ScaffoldWithMenubarState();
}

class _ScaffoldWithMenubarState extends State<ScaffoldWithMenubar> {
  final _dio = DioClient().dio;
  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();

  void _onSearchSubmit(String value) {
    final username = value.trim();
    if (username.isNotEmpty) {
      context.go('/$username');
      _searchCtrl.clear();
    }
  }

  Future<void> _toggleTheme() async {
    final themeNotifier = context.read<ThemeNotifier>();
    final current = themeNotifier.themeMode;
    final next = current == ThemeMode.light
        ? ThemeMode.dark
        : current == ThemeMode.dark
        ? ThemeMode.system
        : ThemeMode.light;
    themeNotifier.setTheme(next);
    await _dio.put(
      '/api/me',
      data: FormData.fromMap({'theme': next.name}),
    );
  }

  Future<void> _toggleLocale() async {
    final locale = context.read<LocaleNotifier>();
    final newLocale =
    locale.locale.languageCode == 'fr' ? Locale('en') : Locale('fr');
    await context.setLocale(newLocale);
    locale.setLocale(newLocale);
    await _dio.put(
      '/api/me',
      data: FormData.fromMap({'language': newLocale.languageCode}),
    );
  }

  Future<void> _logout() async {
    try {
      await _dio.post('/api/auth/logout');
      await TokenManager.clear();
      context.read<SessionNotifier>().clearUser();
      if (mounted) context.go('/');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("core.error".tr())),
      );
    }
  }

  void _handleTap(SidebarItem selected, String? username) {
    switch (selected) {
      case SidebarItem.home:
        context.go('/');
        break;
      case SidebarItem.search:
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("user.search.search_user".tr()),
            content: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(hintText: "Username"),
              onSubmitted: (_) {
                Navigator.of(context).pop();
                _onSearchSubmit(_searchCtrl.text);
              },
            ),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
        break;
      case SidebarItem.create:
        context.go('/$username/create');
        break;
      case SidebarItem.chats:
      context.go('/app/messages');
        break;
      case SidebarItem.profile:
        context.go('/$username');
        break;
      case SidebarItem.login:
        context.go('/account/login');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final session = context.watch<SessionNotifier>();
    final themeMode = context.watch<ThemeNotifier>().themeMode;
    final locale = context.watch<LocaleNotifier>().locale;
    final languageCode = locale.languageCode;
    final user = session.user;
    final username = user?['username'];
    final isMobile = width < sizeMinSidebar;

    final items = <SidebarItem>[
      SidebarItem.home,
      SidebarItem.search,
      if (session.isAuthenticated) ...[
        SidebarItem.create,
        SidebarItem.chats,
        SidebarItem.profile
      ]
      else SidebarItem.login,
    ];

    PreferredSizeWidget mobileAppBar() {
      return AppBar(
        title: Text("OnlyFeed", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actionsPadding: EdgeInsets.only(right: 16),
        actions: [
          _buildPopupMenu()
        ],
      );
    }

    List<NavigationDestination> bottomDestinations = items.map((item) {
      return NavigationDestination(
        icon: _buildIcon(item, themeMode, languageCode),
        label: '',
      );
    }).toList();

    List<NavigationRailDestination> railDestinations = items.map((item) {
      return NavigationRailDestination(
        padding: EdgeInsets.fromLTRB(12, 24, 12, 0),
        icon: _buildIcon(item, themeMode, languageCode),
        label: width >= sizeMinLabelIcon
          ? Center(
            child: Text(
              _buildLabel(item, locale),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurface),
            )
          )
          : const SizedBox.shrink(),
      );
    }).toList();

    Widget nav = isMobile
      ? SizedBox(
        height: 80,
        child: Container(
          color: Theme.of(context).appBarTheme.backgroundColor,
          padding: EdgeInsets.only(top: 12),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 80,
                labelTextStyle: WidgetStateProperty.all(TextStyle(fontSize: 0)),
                iconTheme: WidgetStateProperty.all(IconThemeData(size: 32)),
              ),
              child: NavigationBar(
                destinations: bottomDestinations,
                onDestinationSelected: (i) => _handleTap(items[i], username),
                selectedIndex: 0,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                indicatorColor: Colors.transparent,
              ),
            ),
          ),
        )
      )
      : SizedBox(
        width: 120,
        child: FocusScope(
          canRequestFocus: false,
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Column(
              children: [
                Expanded(
                  child: NavigationRail(
                    labelType: width >= sizeMinLabelIcon
                        ? NavigationRailLabelType.all
                        : NavigationRailLabelType.none,
                    selectedIndex: null,
                    useIndicator: false,
                    destinations: railDestinations,
                    onDestinationSelected: (i) => _handleTap(items[i], username),
                    backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                    groupAlignment: -1.0,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      _buildPopupMenu(),
                      if (MediaQuery.of(context).size.width >= sizeMinLabelIcon)
                        Text(
                          "core.more".tr().capitalize(),
                          style: TextStyle(fontSize: 12, fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurface),
                        ),
                    ],
                  )
                )
              ],
            ),
          )
        ),
      );

    return Scaffold(
      appBar: isMobile ? mobileAppBar() : null,
      body: isMobile
        ? Column(
          children: [
            Expanded(child: widget.body),
            nav,
          ]
        )
        : Row(
          children: [
            nav,
            VerticalDivider(width: 1, color: Theme.of(context).appBarTheme.titleTextStyle?.color),
            Expanded(child: widget.body),
          ]
        )
    );
  }

  Widget _buildIcon(SidebarItem item, ThemeMode themeMode, String languageCode) {
    switch (item) {
      case SidebarItem.home:
        return const Icon(Icons.home_filled);
      case SidebarItem.search:
        return const Icon(Icons.search_rounded);
      case SidebarItem.create:
        return Icon(Icons.add_box_outlined);
      case SidebarItem.chats:
        return const Icon(Icons.send_rounded);
      case SidebarItem.profile:
        return const Icon(Icons.person_rounded);
      case SidebarItem.login:
        return const Icon(Icons.login_rounded);
    }
  }

  String _buildLabel(SidebarItem item, Locale locale) {
    switch (item) {
      case SidebarItem.home:
        return "app.title".tr();
      case SidebarItem.search:
        return "user.search.search".tr().capitalize();
      case SidebarItem.create:
        return "post.create".tr().capitalize();
      case SidebarItem.chats:
        return "chat.messages".tr().capitalize();
      case SidebarItem.profile:
        return "user.profile".tr().capitalize();
      case SidebarItem.login:
        return "user.log.login".tr().capitalize();
    }
  }

  Widget _buildPopupMenu() {
    final themeMode = context.watch<ThemeNotifier>().themeMode;
    final locale = context.watch<LocaleNotifier>().locale;
    final session = context.watch<SessionNotifier>();
    final languageCode = locale.languageCode;

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'lang') _toggleLocale();
        if (value == 'theme') _toggleTheme();
        if (value == 'logout') _logout();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'lang',
          child: Row(
            children: [
              Image.asset(
                'assets/img/flags/$languageCode.jpg',
                width: 32,
                height: 32,
              ),
              SizedBox(width: 8),
              Text(languageCode.toUpperCase()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'theme',
          child: Row(
            children: [
              Icon(
                themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : themeMode == ThemeMode.light
                  ? Icons.light_mode
                  : Icons.computer,
              ),
              SizedBox(width: 8),
              Text('user.theme.${themeMode.name}'.tr().capitalize()),
            ],
          ),
        ),
        if (session.isAuthenticated)
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text('user.log.logout'.tr().capitalize()),
              ],
            ),
          ),
      ],
      icon: Icon(Icons.dehaze_rounded),
      iconSize: 32,
      iconColor: Theme.of(context).colorScheme.onSurface,
      tooltip: "core.more".tr().capitalize(),
    );
  }
}
