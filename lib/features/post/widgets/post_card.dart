import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';

class OnlyFeedPostCard extends StatelessWidget {
  final Post post;
  final String username; // Ajout du username

  const OnlyFeedPostCard({
    Key? key,
    required this.post,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // 🆕 Navigation vers la nouvelle page au lieu du modal
        context.go('/$username/post/${post.id}');
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