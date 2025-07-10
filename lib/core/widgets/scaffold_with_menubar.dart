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
  adminDashboard,
}

const sizeMinSidebar = 768;
const sizeMinLabelIcon = 1024;

// 🆕 NOUVEAU: Modèle pour les utilisateurs de recherche
class SearchUser {
  final String id;
  final String username;
  final String avatarUrl;
  final bool isCreator;

  SearchUser({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.isCreator,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    return SearchUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      isCreator: json['is_creator'] ?? false,
    );
  }
}

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

  // 🆕 NOUVELLES VARIABLES pour la recherche améliorée
  List<SearchUser> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  
  void _onSearchSubmit(String value) {
    final username = value.trim();
    if (username.isNotEmpty) {
      context.go('/$username');
      _searchCtrl.clear();
      Navigator.of(context).pop(); // Fermer le dialog
    }
  }

  // 🆕 NOUVELLE MÉTHODE: Recherche d'utilisateurs en temps réel
  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final response = await _dio.get(
        '/api/users/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = response.data['users'] ?? [];
        setState(() {
          _searchResults = usersJson
            .map((json) => SearchUser.fromJson(json))
            .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchError = e.toString();
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  // 🆕 NOUVELLE MÉTHODE: Naviguer vers un profil utilisateur
  void _navigateToUser(SearchUser user) {
    Navigator.of(context).pop(); // Fermer le dialog
    context.go('/${user.username}');
    _searchCtrl.clear();
    setState(() {
      _searchResults = [];
      _searchError = null;
    });
  }

  // 🆕 NOUVELLE MÉTHODE: Widget pour afficher un utilisateur dans les résultats
  Widget _buildUserTile(SearchUser user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: user.avatarUrl.isNotEmpty
          ? NetworkImage(user.avatarUrl)
          : null,
        child: user.avatarUrl.isEmpty
          ? Icon(Icons.person, size: 20)
          : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.username,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (user.isCreator)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                context.tr('user.creator'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text('@${user.username}'),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _navigateToUser(user),
    );
  }

  // 🔧 MÉTHODE AMÉLIORÉE: Afficher le dialog de recherche
  void _showImprovedSearchDialog() {
    // Réinitialiser l'état avant d'ouvrir le dialog
    setState(() {
      _searchResults = [];
      _searchError = null;
      _isSearching = false;
    });
    _searchCtrl.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.search),
              SizedBox(width: 8),
              Expanded(
                child: Text("user.search.search_user".tr()),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                  _searchCtrl.clear();
                  setState(() {
                    _searchResults = [];
                    _searchError = null;
                    _isSearching = false;
                  });
                },
              ),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🆕 Barre de recherche améliorée
                TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: "user.search.search_user_hint".tr(),
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setDialogState(() {});
                            setState(() {
                              _searchResults = [];
                              _searchError = null;
                              _isSearching = false;
                            });
                          },
                        )
                      : null,
                  ),
                  onChanged: (value) {
                    setDialogState(() {});
                    _searchUsers(value).then((_) {
                      setDialogState(() {});
                    });
                  },
                  onSubmitted: _onSearchSubmit,
                ),
                SizedBox(height: 16),
                
                // 🆕 Zone des résultats
                Expanded(
                  child: _isSearching
                    ? Center(child: CircularProgressIndicator())
                    : _searchError != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 48, color: Colors.red),
                              SizedBox(height: 8),
                              Text(
                                context.tr('core.error'),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _searchError!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : _searchResults.isEmpty && _searchCtrl.text.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  "user.search.no_users_found".tr(),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "user.search.try_different_search".tr(),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : _searchCtrl.text.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    "user.search.search_to_start".tr(),
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "user.search.search_instructions".tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _searchResults.length,
                              separatorBuilder: (context, index) => Divider(height: 1),
                              itemBuilder: (context, index) {
                                return _buildUserTile(_searchResults[index]);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Focus automatique sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
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
    if (context.read<SessionNotifier>().isAuthenticated) {
      await _dio.put(
        '/api/me',
        data: FormData.fromMap({'theme': next.name}),
      );
    }
  }

  Future<void> _toggleLocale() async {
    final locale = context.read<LocaleNotifier>();
    final newLocale =
    locale.locale.languageCode == 'fr' ? Locale('en') : Locale('fr');
    await context.setLocale(newLocale);
    locale.setLocale(newLocale);
    if (context.read<SessionNotifier>().isAuthenticated) {
      await _dio.put(
        '/api/me',
        data: FormData.fromMap({'language': newLocale.languageCode}),
      );
    }
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
        // 🔧 UTILISATION de la nouvelle méthode de recherche
        _showImprovedSearchDialog();
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
      case SidebarItem.adminDashboard:
        context.go('/admin/dashboard');
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
    final isAdmin = user?['is_admin'];
    final isMobile = width < sizeMinSidebar;

    final items = <SidebarItem>[
      SidebarItem.home,
      SidebarItem.search,
      if (session.isAuthenticated) ...[
        SidebarItem.create,
        SidebarItem.chats,
        SidebarItem.profile,
        if (isAdmin != null && isAdmin != false) SidebarItem.adminDashboard,
      ]
      else SidebarItem.login,
    ];

    PreferredSizeWidget mobileAppBar() {
      return AppBar(
        title: Text("OnlyFeed", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildPopupMenu(),
          ),
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
      case SidebarItem.adminDashboard:
        return const Icon(Icons.admin_panel_settings_rounded);
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
      case SidebarItem.adminDashboard:
        return "admin.dashboard_title".tr();
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}