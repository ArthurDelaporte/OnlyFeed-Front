import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_header.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/features/post/services/post_service.dart';
import 'package:onlyfeed_frontend/features/post/widgets/post_grid.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _dio = DioClient().dio;
  final _postService = PostService();

  Map<String, dynamic>? _user;
  List<Post> _userPosts = [];
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserPosts();
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

  Future<void> _fetchUserPosts() async {
    if (mounted) {
      setState(() {
        _isLoadingPosts = true;
      });
    }
    
    try {
      final posts = await _postService.getUserPosts();
      
      if (mounted) {
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  _fetchUserPosts(),
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
                      
                      // Utilisation du widget de grille réutilisable
                      PostGrid(
                        posts: _userPosts,
                        isLoading: _isLoadingPosts,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}