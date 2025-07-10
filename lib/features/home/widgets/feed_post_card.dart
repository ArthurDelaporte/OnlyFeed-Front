// lib/features/home/widgets/feed_post_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/features/like/like.dart';
import 'package:onlyfeed_frontend/features/message/presentation/share_post_dialog.dart';
import 'package:onlyfeed_frontend/shared/notifiers/session_notifier.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';

class FeedPostCard extends StatefulWidget {
  final Post post;
  final String username;

  const FeedPostCard({
    Key? key,
    required this.post,
    required this.username,
  }) : super(key: key);

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  final _dio = DioClient().dio;
  late int _likeCount;
  late bool _isLiked;
  Map<String, dynamic>? _userInfo;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _isLiked = widget.post.isLiked;
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final response = await _dio.get('/api/users/${widget.post.userId}');
      if (response.statusCode == 200) {
        setState(() {
          _userInfo = response.data['user'];
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des infos utilisateur: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  void _onLikeChanged(LikeResponse likeResponse) {
    setState(() {
      _likeCount = likeResponse.likeCount;
      _isLiked = likeResponse.isLiked;
    });
  }

  void _sharePost() {
    showDialog(
      context: context,
      builder: (context) => SharePostDialog(
        post: widget.post,
        username: widget.username,
      ),
    );
  }

  void _navigateToPost() {
    context.go('/${widget.username}/post/${widget.post.id}');
  }

  void _navigateToUserProfile() {
    if (_userInfo != null) {
      context.go('/${_userInfo!['username']}');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return "message.now".tr();
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes} min";
    } else if (difference.inDays < 1) {
      return "${difference.inHours}h";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}j";
    } else {
      return DateFormat('dd/MM').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<SessionNotifier>().isAuthenticated;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: 8,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec infos utilisateur
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar utilisateur
                GestureDetector(
                  onTap: _navigateToUserProfile,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: _userInfo?['avatar_url'] != null && 
                                   _userInfo!['avatar_url'].isNotEmpty
                      ? NetworkImage(_userInfo!['avatar_url'])
                      : null,
                    child: _userInfo?['avatar_url'] == null || 
                           _userInfo!['avatar_url'].isEmpty
                      ? Icon(Icons.person, size: 20)
                      : null,
                  ),
                ),
                SizedBox(width: 12),
                
                // Nom d'utilisateur et timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _navigateToUserProfile,
                        child: Row(
                          children: [
                            Text(
                              _isLoadingUser 
                                ? 'Chargement...' 
                                : (_userInfo?['username'] ?? 'Utilisateur'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (_userInfo?['is_creator'] == true) ...[
                              SizedBox(width: 6),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
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
                          ],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _formatTimestamp(widget.post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menu contextuel
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    switch (value) {
                      case 'share':
                        if (isAuthenticated) _sharePost();
                        break;
                      case 'report':
                        // TODO: Implémenter le signalement
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (isAuthenticated)
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 20),
                            SizedBox(width: 12),
                            Text('Partager'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, size: 20, color: Colors.red[600]),
                          SizedBox(width: 12),
                          Text('Signaler', style: TextStyle(color: Colors.red[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Titre du post
          if (widget.post.title.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                widget.post.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          // Description du post
          if (widget.post.description.isNotEmpty) ...[
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                widget.post.description,
                style: TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          // Image du post
          if (widget.post.mediaURL.isNotEmpty) ...[
            SizedBox(height: 12),
            GestureDetector(
              onTap: _navigateToPost,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: isMobile ? 300 : 400,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.post.mediaURL,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, 
                                color: Colors.grey[500], size: 48),
                              SizedBox(height: 8),
                              Text('Erreur de chargement', 
                                style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          
          // Badge contenu payant
          if (widget.post.isPaid) ...[
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 16, color: Colors.amber[800]),
                    SizedBox(width: 4),
                    Text(
                      'Contenu Premium',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Actions (like, commentaire, partage)
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Bouton like
                LikeButton(
                  postId: widget.post.id,
                  initialLikeCount: _likeCount,
                  initialIsLiked: _isLiked,
                  onLikeChanged: _onLikeChanged,
                  style: LikeButtonStyle.standard,
                ),
                
                SizedBox(width: 16),
                
                // Bouton commentaire
                InkWell(
                  onTap: _navigateToPost,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.comment_outlined, 
                          color: Colors.grey[600], size: 20),
                        SizedBox(width: 4),
                        Text(
                          'Commenter',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Spacer(),
                
                // Bouton partage (seulement si connecté)
                if (isAuthenticated)
                  InkWell(
                    onTap: _sharePost,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(Icons.share_outlined, 
                        color: Colors.grey[600], size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}