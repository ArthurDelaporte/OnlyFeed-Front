// lib/features/message/presentation/share_post_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/features/message/model/message_model.dart';
import 'package:onlyfeed_frontend/features/message/services/message_service.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';

class SharePostDialog extends StatefulWidget {
  final Post post;
  final String username;

  const SharePostDialog({
    Key? key,
    required this.post,
    required this.username,
  }) : super(key: key);

  @override
  _SharePostDialogState createState() => _SharePostDialogState();
}

class _SharePostDialogState extends State<SharePostDialog> {
  final MessageService _messageService = MessageService();
  final _dio = DioClient().dio;
  final _searchController = TextEditingController();
  
  List<ConversationUser> _searchResults = [];
  List<ConversationUser> _recentChats = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Charger les conversations récentes
  Future<void> _loadRecentChats() async {
    try {
      setState(() => _isLoading = true);
      
      final conversations = await _messageService.getConversations();
      setState(() {
        _recentChats = conversations
            .take(6) // Limiter à 6 conversations récentes
            .map((conv) => conv.otherUser)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Rechercher des utilisateurs
  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await _dio.get(
        '/api/users/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = response.data['users'] ?? [];
        setState(() {
          _searchResults = usersJson
            .map((json) => ConversationUser.fromJson(json))
            .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  // Envoyer le post à un utilisateur
  Future<void> _sendPostToUser(ConversationUser user) async {
    try {
      setState(() => _isLoading = true);

      // Créer le message avec le lien du post
      final postUrl = '${Uri.base.origin}/${widget.username}/post/${widget.post.id}';
      final messageContent = '📷 ${widget.post.title}\n\n${postUrl}';

      await _messageService.sendTextMessage(
        receiverId: user.id,
        content: messageContent,
      );

      setState(() => _isLoading = false);

      // Fermer le dialogue et afficher un message de succès
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post partagé avec ${user.username} !'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () {
              context.go('/app/messages/chat/${user.username}');
            },
          ),
        ),
      );

    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Copier le lien dans le presse-papiers
  void _copyLink() {
    final postUrl = '${Uri.base.origin}/${widget.username}/post/${widget.post.id}';
    Clipboard.setData(ClipboardData(text: postUrl));
    
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lien copié dans le presse-papiers !'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildUserTile(ConversationUser user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: user.avatarUrl.isNotEmpty
          ? NetworkImage(user.avatarUrl)
          : null,
        child: user.avatarUrl.isEmpty
          ? Icon(Icons.person, size: 20)
          : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.username,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (user.isCreator)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Créateur',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      trailing: Icon(Icons.send, color: Theme.of(context).primaryColor),
      onTap: _isLoading ? null : () => _sendPostToUser(user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.share, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Partager le post',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Aperçu du post
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      child: widget.post.mediaURL.isNotEmpty
                        ? Image.network(
                            widget.post.mediaURL,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image),
                          ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Par @${widget.username}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (widget.post.isPaid)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.amber[800],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // Option copier le lien
            ListTile(
              leading: Icon(Icons.link, color: Theme.of(context).primaryColor),
              title: Text('Copier le lien'),
              subtitle: Text('Partager le lien ailleurs'),
              onTap: _copyLink,
            ),

            Divider(height: 1),

            // Barre de recherche
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _searchUsers,
              ),
            ),

            // Liste des résultats
            Expanded(
              child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                  ? Center(
                      child: Text(
                        'Erreur: $_error',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : _isSearching
                    ? Center(child: CircularProgressIndicator())
                    : _searchController.text.isNotEmpty
                      ? _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun utilisateur trouvé',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              return _buildUserTile(_searchResults[index]);
                            },
                          )
                      : _recentChats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, 
                                  size: 48, color: Colors.grey[400]),
                                SizedBox(height: 12),
                                Text(
                                  'Recherchez un utilisateur\npour partager ce post',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(
                                  'Conversations récentes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _recentChats.length,
                                  itemBuilder: (context, index) {
                                    return _buildUserTile(_recentChats[index]);
                                  },
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