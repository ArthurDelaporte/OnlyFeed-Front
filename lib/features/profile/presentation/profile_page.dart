import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_header.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/features/post/services/post_service.dart';
import 'package:onlyfeed_frontend/features/post/widgets/post_grid.dart';

import 'package:provider/provider.dart';
import 'package:onlyfeed_frontend/features/post/providers/post_provider.dart';

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
    
    // Utiliser le provider pour charger les posts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchUserPosts();
    });
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
    // Observer le provider pour les posts
    final postProvider = context.watch<PostProvider>();
    
    return ScaffoldWithHeader(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-post'),
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add_a_photo, color: Colors.white),
        tooltip: "post.create_post".tr(),
      ),
      body: _user == null
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _fetchUserProfile(),
                  context.read<PostProvider>().fetchUserPosts(),
                ]);
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Section profil
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
                      Text("${'user.lang.language'.tr().capitalize()}: ${('user.lang.${context.locale.languageCode}').tr().capitalize()}", style: TextStyle(fontSize: 14)),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/profile/edit'),
                        icon: Icon(Icons.edit),
                        label: Text("user.edit.edit_profile".tr()),
                      ),
                      
                      // Nouvelle section pour les posts
                      SizedBox(height: 32),
                      Text(
                        "post.my_posts".tr(),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      
                      // Utilisation du widget de grille réutilisable avec le provider
                      PostGrid(
                        posts: postProvider.userPosts,
                        isLoading: postProvider.isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}