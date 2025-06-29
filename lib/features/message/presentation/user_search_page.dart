// lib/features/message/presentation/user_search_page.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';
import 'package:onlyfeed_frontend/features/message/model/message_model.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _dio = DioClient().dio;
  final _searchController = TextEditingController();
  
  List<ConversationUser> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
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
            .map((json) => ConversationUser.fromJson(json))
            .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  // 🔧 ROUTE CORRIGÉE: Navigation par username avec la nouvelle route
  void _navigateToChat(ConversationUser user) {
    print('🔄 Navigation vers /app/messages/chat/${user.username}');
    context.go('/app/messages/chat/${user.username}');
  }

  Widget _buildUserTile(ConversationUser user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: user.avatarUrl.isNotEmpty
          ? NetworkImage(user.avatarUrl)
          : null,
        child: user.avatarUrl.isEmpty
          ? Icon(Icons.person)
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
      trailing: Icon(Icons.chat_bubble_outline),
      onTap: () => _navigateToChat(user), // 🔧 Navigation simplifiée
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('message.search_users')),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/app/messages'), // 🔧 ROUTE CORRIGÉE
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('message.search_users_hint'),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _error = null;
                        });
                      },
                    )
                  : null,
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Résultats de recherche
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          context.tr('core.error'),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(_error!),
                      ],
                    ),
                  )
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            context.tr('message.no_users_found'),
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            context.tr('message.try_different_search'),
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : _searchController.text.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              context.tr('message.search_to_start'),
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              context.tr('message.search_instructions'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
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
    );
  }
}