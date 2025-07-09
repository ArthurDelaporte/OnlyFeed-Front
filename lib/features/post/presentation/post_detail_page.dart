import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // 🆕 Ajout pour SessionNotifier
import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/features/like/like.dart';
import 'package:onlyfeed_frontend/features/message/presentation/share_post_dialog.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';
import 'package:onlyfeed_frontend/shared/notifiers/session_notifier.dart'; // 🆕 Import SessionNotifier

class PostDetailPage extends StatefulWidget {
  final String username;
  final String postId;

  const PostDetailPage({
    Key? key,
    required this.username,
    required this.postId,
  }) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final _dio = DioClient().dio;
  
  Post? post;
  List<Map<String, dynamic>> comments = [];
  bool isLoadingPost = true;
  bool isLoadingComments = true;
  bool isSendingComment = false;
  
  // Variables pour gérer les likes
  int _likeCount = 0;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      isLoadingPost = true;
    });

    try {
      final response = await _dio.get('/api/posts/${widget.postId}');
      
      if (response.statusCode == 200) {
        // 🔧 Debug: Afficher la structure de la réponse
        print('Response data: ${response.data}');
        
        // 🔧 Gérer les deux structures possibles
        final postData = response.data['post'] ?? response.data;
        
        setState(() {
          post = Post(
            id: postData['ID'],
            title: postData['Title'],
            description: postData['Description'] ?? '',
            mediaURL: postData['MediaURL'] ?? '',
            isPaid: postData['IsPaid'] ?? false,
            createdAt: DateTime.parse(postData['CreatedAt']),
            userId: postData['UserID'],
            likeCount: postData['like_count'] ?? 0,
            isLiked: postData['is_liked'] ?? false,
          );
          
          // Initialiser les variables de like
          _likeCount = post!.likeCount;
          _isLiked = post!.isLiked;
          
          isLoadingPost = false;
        });
        
        // Charger les commentaires après avoir chargé le post
        _loadComments();
      } else {
        throw Exception('Post non trouvé');
      }
    } catch (e) {
      setState(() {
        isLoadingPost = false;
      });
      
      // Rediriger vers le profil si le post n'existe pas
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("post.not_found".tr())),
        );
        context.go('/${widget.username}');
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      isLoadingComments = true;
    });

    try {
      final response = await _dio.get('/api/posts/${widget.postId}/comments');

      if (response.statusCode == 200) {
        final List<dynamic> commentsData = response.data['comments'] ?? [];
        
        setState(() {
          comments = commentsData.map((comment) => {
            'id': comment['id'],
            'username': comment['username'] ?? 'Utilisateur',
            'text': comment['text'] ?? comment['content'] ?? '',
            'timestamp': DateTime.parse(comment['created_at']),
          }).toList();
          isLoadingComments = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingComments = false;
      });
      print('Erreur lors du chargement des commentaires: $e');
    }
  }

  Future<void> _sendComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() {
      isSendingComment = true;
    });

    try {
      final response = await _dio.post('/api/comments', data: {
        'post_id': widget.postId,
        'text': _commentController.text,
      });

      if (response.statusCode == 201) {
        final comment = response.data['comment'];
        
        setState(() {
          comments.insert(0, {
            'id': comment['id'],
            'username': comment['username'] ?? 'Vous',
            'text': comment['text'] ?? comment['content'] ?? '',
            'timestamp': DateTime.parse(comment['created_at']),
          });
          _commentController.clear();
          isSendingComment = false;
        });
      }
    } catch (e) {
      setState(() {
        isSendingComment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("post.comment_send_error".tr())),
      );
    }
  }

  // Callback pour gérer les changements de like
  void _onLikeChanged(LikeResponse likeResponse) {
    setState(() {
      _likeCount = likeResponse.likeCount;
      _isLiked = likeResponse.isLiked;
    });
  }

  // 🆕 Fonction pour ouvrir le dialogue de partage
  void _sharePost() {
    if (post != null) {
      showDialog(
        context: context,
        builder: (context) => SharePostDialog(
          post: post!,
          username: widget.username,
        ),
      );
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
      return DateFormat('dd/MM/yy').format(timestamp);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ NOUVELLE LIGNE - Vérifier l'authentification
    final isAuthenticated = context.watch<SessionNotifier>().isAuthenticated;

    if (isLoadingPost) {
      return ScaffoldWithMenubar(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (post == null) {
      return ScaffoldWithMenubar(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text("Post non trouvé"),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/${widget.username}'),
                child: Text("user.back_profile".tr()),
              ),
            ],
          ),
        ),
      );
    }

    // 🔧 Détection mobile/desktop basée sur ScaffoldWithMenubar
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      // 📱 Version mobile avec zone de saisie fixée en bas
      return ScaffoldWithMenubar(
        body: _buildMobileLayout(isAuthenticated), // 🔧 Passer isAuthenticated
      );
    } else {
      // 💻 Version desktop (côte à côte)
      return ScaffoldWithMenubar(
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1200),
              child: _buildDesktopLayout(isAuthenticated), // 🔧 Passer isAuthenticated
            ),
          ),
        ),
      );
    }
  }

  // 💻 Layout Desktop (côte à côte)
  Widget _buildDesktopLayout(bool isAuthenticated) { // 🔧 Ajouter paramètre
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne de gauche - Image du post
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bouton retour
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/${widget.username}'),
                      icon: Icon(Icons.arrow_back),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "user.back_profile".tr(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Image du post
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: post!.mediaURL.isNotEmpty
                      ? Image.network(
                          post!.mediaURL,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 300,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                        )
                      : Container(
                          height: 300,
                          child: Center(
                            child: Icon(Icons.image_not_supported, 
                              color: Colors.grey[400], size: 64),
                          ),
                        ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Informations du post
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post!.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (post!.description.isNotEmpty) ...[
                      Text(
                        post!.description,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                    ],
                    
                    // ✅ Row avec date, bouton like ET bouton partage (modifiée)
                    Row(
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(post!.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 16),
                        // ✅ Bouton Like (desktop)
                        LikeButton(
                          postId: post!.id,
                          initialLikeCount: _likeCount,
                          initialIsLiked: _isLiked,
                          onLikeChanged: _onLikeChanged,
                          style: LikeButtonStyle.standard,
                        ),
                        // 🔧 Bouton Partage (desktop) - SEULEMENT si connecté
                        if (isAuthenticated) ...[
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: _sharePost,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.share,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "post.share".tr(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    if (post!.isPaid) ...[
                      SizedBox(height: 8),
                      Chip(
                        label: Text("profile_page.premium".tr()),
                        avatar: Icon(Icons.lock, size: 16),
                        backgroundColor: Colors.amber.withOpacity(0.2),
                        labelStyle: TextStyle(color: Colors.amber[800]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Colonne de droite - Commentaires
        Expanded(
          flex: 1,
          child: _buildCommentsSection(isAuthenticated), // 🔧 Passer isAuthenticated
        ),
      ],
    );
  }

  // 📱 Layout Mobile (empilé) avec zone de saisie fixée en bas
  Widget _buildMobileLayout(bool isAuthenticated) { // 🔧 Ajouter paramètre
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Partie scrollable (image + infos + commentaires)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En haut - Image du post et infos
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bouton retour
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.go('/${widget.username}'),
                              icon: Icon(Icons.arrow_back),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "user.back_profile".tr(),
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Image du post
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[100],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: post!.mediaURL.isNotEmpty
                              ? Image.network(
                                  post!.mediaURL,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  },
                                )
                              : Container(
                                  height: 200,
                                  child: Center(
                                    child: Icon(Icons.image_not_supported, 
                                      color: Colors.grey[400], size: 64),
                                  ),
                                ),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Informations du post
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post!.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (post!.description.isNotEmpty) ...[
                              Text(
                                post!.description,
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 8),
                            ],
                            
                            // ✅ Row avec date, bouton like ET bouton partage (mobile modifiée)
                            Column(
                              children: [
                                // Première ligne : Date
                                Row(
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(post!.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                // Deuxième ligne : Boutons Like et Partage
                                Row(
                                  children: [
                                    // ✅ Bouton Like (mobile compact)
                                    LikeButton(
                                      postId: post!.id,
                                      initialLikeCount: _likeCount,
                                      initialIsLiked: _isLiked,
                                      onLikeChanged: _onLikeChanged,
                                      style: LikeButtonStyle.compact,
                                    ),
                                    // 🔧 Bouton Partage (mobile compact) - SEULEMENT si connecté
                                    if (isAuthenticated) ...[
                                      SizedBox(width: 12),
                                      InkWell(
                                        onTap: _sharePost,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                            color: Colors.transparent,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.share,
                                                color: Colors.grey[600],
                                                size: 16,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "post.share".tr(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            
                            if (post!.isPaid) ...[
                              SizedBox(height: 8),
                              Chip(
                                label: Text("profile_page.premium".tr()),
                                avatar: Icon(Icons.lock, size: 16),
                                backgroundColor: Colors.amber.withOpacity(0.2),
                                labelStyle: TextStyle(color: Colors.amber[800]),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Section commentaires (sans la zone de saisie)
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre section commentaires
                        Row(
                          children: [
                            Icon(Icons.comment, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "chat.messages".tr(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isLoadingComments) ...[
                              SizedBox(width: 8),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Liste des commentaires
                        isLoadingComments
                          ? Center(child: CircularProgressIndicator())
                          : comments.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(Icons.chat_bubble_outline, 
                                        size: 48, color: Colors.grey[400]),
                                      SizedBox(height: 16),
                                      Text(
                                        "message.no_messages".tr(),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "message.send_first_message".tr(),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[800]
                                        : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              comment['username'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              _formatTimestamp(comment['timestamp']),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          comment['text'],
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        // Padding en bas pour éviter que le dernier commentaire soit caché par la zone de saisie
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Zone de saisie fixée en bas - SEULEMENT si connecté
      bottomNavigationBar: isAuthenticated ? Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 
          MediaQuery.of(context).padding.bottom + 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "message.type_message".tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, 
                    vertical: 12
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.white,
                ),
                maxLines: null,
                maxLength: 500,
                buildCounter: (context, {required currentLength, maxLength, required isFocused}) {
                  return null;
                },
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: isSendingComment ? null : _sendComment,
                icon: isSendingComment 
                    ? SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      )
                    : Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ) : null, // 🔧 Pas de zone de saisie si non connecté
    );
  }

  // 💬 Section commentaires (utilisée pour desktop uniquement maintenant)
  Widget _buildCommentsSection(bool isAuthenticated) { // 🔧 Ajouter paramètre
    return Container(
      height: MediaQuery.of(context).size.height - 100,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section commentaires
          Row(
            children: [
              Icon(Icons.comment, size: 20),
              SizedBox(width: 8),
              Text(
                "chat.messages".tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLoadingComments) ...[
                SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          SizedBox(height: 16),
          
          // Zone de saisie commentaire (desktop uniquement) - SEULEMENT si connecté
          if (isAuthenticated) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "message.type_message".tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 8
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: isSendingComment ? null : _sendComment,
                  icon: isSendingComment 
                      ? SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      : Icon(Icons.send),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
          ],
          
          // Liste des commentaires
          Expanded(
            child: isLoadingComments
              ? Center(child: CircularProgressIndicator())
              : comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, 
                          size: 48, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          "message.no_messages".tr(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "message.send_first_message".tr(),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  comment['username'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(comment['timestamp']),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              comment['text'],
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}