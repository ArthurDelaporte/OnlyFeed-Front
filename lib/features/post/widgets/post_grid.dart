import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/features/post/widgets/post_card.dart';

class PostGrid extends StatelessWidget {
  final List<Post> posts;
  final bool isLoading;
  final String username; // 🆕 Ajout du paramètre username

  const PostGrid({
    Key? key,
    required this.posts,
    required this.username, // 🆕 Paramètre requis
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (posts.isEmpty) {
      return Center(
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
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 posts par ligne
          crossAxisSpacing: 2, // Espacement minimal
          mainAxisSpacing: 2, // Espacement minimal
          childAspectRatio: 1, // Format carré
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return OnlyFeedPostCard(post: post, username: username); // ✅ Maintenant ça marche !
        },
      );
    }
  }
}