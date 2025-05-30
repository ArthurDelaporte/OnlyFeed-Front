import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';

class PostDetailView extends StatefulWidget {
  final Post post;

  const PostDetailView({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  _PostDetailViewState createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  // Contrôleur pour le champ de commentaire
  final TextEditingController _commentController = TextEditingController();
  final _dio = DioClient().dio; // Utilise ton DioClient existant
  
  // Liste des commentaires depuis l'API
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  bool isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  // Charger les commentaires depuis l'API
  Future<void> _loadComments() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _dio.get('/api/posts/${widget.post.id}/comments');

      print('Réponse API commentaires: ${response.statusCode}');
      print('Corps de la réponse: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> commentsData = response.data['comments'] ?? [];
        
        setState(() {
          comments = commentsData.map((comment) => {
            'id': comment['id'],
            'username': comment['username'] ?? 'Utilisateur',
            'text': comment['text'] ?? comment['content'] ?? '', // Gère les deux noms de champ
            'timestamp': DateTime.parse(comment['created_at']),
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erreur lors du chargement des commentaires: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des commentaires: $e")),
      );
    }
  }

  // Envoyer un commentaire à l'API
  Future<void> _sendComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() {
      isSendingComment = true;
    });

    try {
      final response = await _dio.post('/api/comments', data: {
        'post_id': widget.post.id,
        'text': _commentController.text,
      });

      print('Réponse création commentaire: ${response.statusCode}');
      print('Corps de la réponse: ${response.data}');

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
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isSendingComment = false;
      });
      print('Erreur lors de l\'envoi du commentaire: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'envoi du commentaire: $e")),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.post.title),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Row(
          children: [
            // Partie gauche - Image
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.black,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.height * 0.6,
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: widget.post.mediaURL.isNotEmpty
                        ? Image.network(
                            widget.post.mediaURL,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          )
                        : Center(
                            child: Icon(Icons.image_not_supported, color: Colors.white54, size: 64),
                          ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Partie droite - Infos et commentaires
            Expanded(
              flex: 2,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    // Informations sur le post
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (widget.post.description.isNotEmpty)
                            Text(widget.post.description),
                          SizedBox(height: 8),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(widget.post.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          if (widget.post.isPaid)
                            Chip(
                              label: Text("post.premium_content".tr()),
                              avatar: Icon(Icons.lock, size: 16),
                              backgroundColor: Colors.amber.withOpacity(0.2),
                              labelStyle: TextStyle(color: Colors.amber[800]),
                            ),
                        ],
                      ),
                    ),
                    
                    Divider(),
                    
                    // Section commentaires
                    Expanded(
                      child: Column(
                        children: [
                          // Titre de la section avec indicateur de chargement
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.comment, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  "post.comments".tr(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isLoading) 
                                  Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Liste des commentaires
                          Expanded(
                            child: isLoading
                              ? Center(child: CircularProgressIndicator())
                              : comments.isEmpty
                                ? Center(
                                    child: Text("post.no_comments".tr()),
                                  )
                                : ListView.builder(
                                    itemCount: comments.length,
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    itemBuilder: (context, index) {
                                      final comment = comments[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  comment['username'],
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Spacer(),
                                                Text(
                                                  _formatTimestamp(comment['timestamp']),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 2),
                                            Text(comment['text']),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          
                          // Champ de saisie de commentaire
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: "post.add_comment".tr(),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: isSendingComment 
                                      ? SizedBox(
                                          width: 24, 
                                          height: 24, 
                                          child: CircularProgressIndicator(strokeWidth: 2)
                                        )
                                      : Icon(Icons.send),
                                  onPressed: isSendingComment ? null : _sendComment,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formater la date du commentaire
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return "post.just_now".tr();
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
}