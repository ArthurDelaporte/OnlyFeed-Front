import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_header.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/features/post/services/post_service.dart';

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
    final locale = context.watch<LocaleNotifier>().locale;

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
                      
                      // Affichage des posts
                      if (_isLoadingPosts)
                        Center(child: CircularProgressIndicator())
                      else if (_userPosts.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                Icon(Icons.photo_album_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  "post.no_posts_yet".tr(),
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _userPosts.length,
                          itemBuilder: (context, index) {
                            final post = _userPosts[index];
                            return PostCard(post: post);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// Widget séparé pour afficher un post
class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Vous pourriez ajouter une navigation vers une page de détails du post ici
          // context.push('/post/${post.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du post
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    post.mediaURL,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.broken_image, color: Colors.grey[500]),
                      );
                    },
                  ),
                  if (post.isPaid)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Titre et date
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(post.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}