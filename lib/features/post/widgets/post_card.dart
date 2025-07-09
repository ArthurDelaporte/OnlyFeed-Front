import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // 🆕 Ajout de Provider
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/features/message/presentation/share_post_dialog.dart';
import 'package:onlyfeed_frontend/shared/notifiers/session_notifier.dart'; // 🆕 Import SessionNotifier

class OnlyFeedPostCard extends StatelessWidget {
  final Post post;
  final String username;

  const OnlyFeedPostCard({
    Key? key,
    required this.post,
    required this.username,
  }) : super(key: key);

  void _sharePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SharePostDialog(
        post: post,
        username: username,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Vérifier l'authentification
    final isAuthenticated = context.watch<SessionNotifier>().isAuthenticated;

    return InkWell(
      onTap: () {
        // Navigation vers la page de détail du post
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

          // 🔧 Bouton de partage - SEULEMENT si connecté
          if (isAuthenticated)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 16,
                  ),
                  onPressed: () => _sharePost(context),
                  splashRadius: 16,
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}