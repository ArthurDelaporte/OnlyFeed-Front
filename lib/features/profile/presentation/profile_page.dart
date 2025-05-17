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
        // Afficher l'URL de l'avatar pour comparaison
        print("Avatar URL: ${_user?['avatar_url']}");
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
      // Récupérer directement la réponse pour inspecter les données
      final response = await _dio.get('/api/posts/me');
      print("Réponse brute de l'API posts: ${response.data}");
      
      if (response.statusCode == 200) {
        final List<dynamic> postsJson = response.data['posts'];
        
        // Examiner chaque post pour vérifier les URLs des médias
        for (var postJson in postsJson) {
          print("Post ID: ${postJson['id']}");
          print("MediaURL: ${postJson['media_url']}");
        }
        
        final posts = postsJson.map((json) => Post.fromJson(json)).toList();
        
        if (mounted) {
          setState(() {
            _userPosts = posts;
            _isLoadingPosts = false;
          });
        }
      } else {
        throw Exception("Erreur: ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur lors de la récupération des posts: $e");
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
                            crossAxisCount: 3, // 3 posts par ligne
                            crossAxisSpacing: 2, // Espacement minimal
                            mainAxisSpacing: 2, // Espacement minimal
                            childAspectRatio: 1, // Format carré
                          ),
                          itemCount: _userPosts.length,
                          itemBuilder: (context, index) {
                            final post = _userPosts[index];
                            return InstagramPostCard(post: post);
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

// Widget pour afficher un post style Instagram
class InstagramPostCard extends StatelessWidget {
  final Post post;

  const InstagramPostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Vous pourriez naviguer vers une page de détail du post
        // Par exemple: context.push('/post/${post.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Post: ${post.title}")),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image du post
          post.mediaURL.isNotEmpty
            ? Image.network(
                post.mediaURL,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, color: Colors.grey[500]),
                  );
                },
              )
            : Container(
                color: Colors.grey[200],
                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
              ),
          
          // Indicateur de contenu payant
          if (post.isPaid)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.lock,
                  color: Colors.amber,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Gardez l'ancienne classe PostCard pour référence ou supprimez-la
// Ne pas utiliser les deux à la fois dans la grille
class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Logging pour déboguer les URLs
    print("Affichage du post avec ID: ${post.id}");
    print("URL du média: ${post.mediaURL}");
    
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Afficher l'URL pour débogage
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("URL: ${post.mediaURL}")),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du post
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Vérifier si l'URL n'est pas vide avant d'afficher l'image
                  post.mediaURL.isNotEmpty
                    ? Image.network(
                        post.mediaURL,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print("Erreur de chargement d'image: $error");
                          print("URL problématique: ${post.mediaURL}");
                          
                          return Container(
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey[500], size: 32),
                                SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    "Erreur de chargement",
                                    style: TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, color: Colors.grey[400], size: 32),
                            SizedBox(height: 4),
                            Text(
                              "Aucune image disponible",
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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