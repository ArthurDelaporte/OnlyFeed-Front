// lib/features/message/presentation/chat_page.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onlyfeed_frontend/features/message/model/message_model.dart';
import 'package:onlyfeed_frontend/features/message/services/message_service.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';

// Classe utilitaire pour détecter et extraire les liens de posts
class PostLinkDetector {
  static RegExp _postLinkRegex = RegExp(
    r'(?:https?://)?(?:www\.)?[^/]+/([^/]+)/post/([a-zA-Z0-9-]+)',
    caseSensitive: false,
  );

  static Map<String, String>? extractPostLink(String content) {
    final match = _postLinkRegex.firstMatch(content);
    if (match != null) {
      return {
        'username': match.group(1)!,
        'postId': match.group(2)!,
        'fullUrl': match.group(0)!,
      };
    }
    return null;
  }

  static String getContentWithoutLink(String content) {
    return content.replaceAll(_postLinkRegex, '').trim();
  }
}

// Widget pour afficher un aperçu du post partagé
class SharedPostPreview extends StatelessWidget {
  final String username;
  final String postId;
  final String fullUrl;
  final bool isFromMe;

  const SharedPostPreview({
    Key? key,
    required this.username,
    required this.postId,
    required this.fullUrl,
    required this.isFromMe,
  }) : super(key: key);

  void _openPost(BuildContext context) {
    // Navigation vers le post
    context.go('/$username/post/$postId');
  }

  void _openExternalLink() async {
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isFromMe ? Colors.white.withOpacity(0.3) : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isFromMe 
          ? Colors.white.withOpacity(0.1)
          : Colors.grey[50],
      ),
      child: InkWell(
        onTap: () => _openPost(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Icône de post
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isFromMe 
                    ? Colors.white.withOpacity(0.2)
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_camera,
                  color: isFromMe 
                    ? Colors.white
                    : Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              
              // Informations du post
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_album,
                          size: 14,
                          color: isFromMe ? Colors.white70 : Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Post partagé',
                          style: TextStyle(
                            fontSize: 12,
                            color: isFromMe ? Colors.white70 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isFromMe 
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bouton d'ouverture
              Icon(
                Icons.open_in_new,
                size: 16,
                color: isFromMe ? Colors.white70 : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String? conversationId;
  final ConversationUser otherUser;
  final bool isNewConversation;

  const ChatPage({
    super.key,
    this.conversationId,
    required this.otherUser,
    this.isNewConversation = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageService = MessageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _dio = DioClient().dio;
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  ConversationUser? _currentUser;
  String? _actualConversationId;

  @override
  void initState() {
    super.initState();
    _actualConversationId = widget.conversationId;
    _loadCurrentUser();
    
    // 🔧 CORRECTION: Ne charger les messages que si ce n'est PAS une nouvelle conversation
    // ET qu'on a un ID de conversation valide (et différent de "new")
    if (!widget.isNewConversation && 
        widget.conversationId != null && 
        widget.conversationId != "new") {
      _loadMessages();
    } else {
      // Pour les nouvelles conversations, mettre conversationId à null
      if (widget.conversationId == "new") {
        _actualConversationId = null;
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await _dio.get('/api/me');
      if (response.statusCode == 200) {
        final userData = response.data['user'];
        setState(() {
          _currentUserId = userData['id'];
          _currentUser = ConversationUser(
            id: userData['id'],
            username: userData['username'],
            avatarUrl: userData['avatar_url'] ?? '',
            isCreator: userData['is_creator'] ?? false,
          );
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  Future<void> _loadMessages() async {
    // 🔧 DOUBLE VÉRIFICATION: S'assurer qu'on a un ID de conversation valide
    if (_actualConversationId == null || 
        _actualConversationId!.isEmpty || 
        _actualConversationId == "new") {
      print('⚠️ Pas d\'ID de conversation valide ($_actualConversationId), skip du chargement des messages');
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      setState(() => _isLoading = true);
      
      print('📥 Chargement des messages pour conversation: $_actualConversationId');
      final messages = await _messageService.getConversationMessages(_actualConversationId!);
      
      setState(() {
        _messages = messages.reversed.toList();
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('❌ Erreur lors du chargement des messages: $e');
      setState(() => _isLoading = false);
      
      // 🔧 Ne pas afficher d'erreur pour les nouvelles conversations
      if (!widget.isNewConversation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr("core.error")}: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending || _currentUser == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Créer un message temporaire avec les bonnes infos pour l'affichage immédiat
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      conversationId: _actualConversationId ?? '',
      sender: _currentUser!,
      content: content,
      messageType: MessageType.text,
      isRead: false,
      isDeleted: false,
    );

    // Ajouter immédiatement le message à l'interface
    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      final result = await _messageService.sendTextMessage(
        receiverId: widget.otherUser.id,
        content: content,
      );

      // Si c'était une nouvelle conversation, récupérer l'ID de conversation
      if (widget.isNewConversation && _actualConversationId == null) {
        _actualConversationId = result.conversationId;
      }

      // 🔧 CORRECTION: Créer un nouveau message avec les bonnes infos au lieu d'utiliser la réponse serveur
      final finalMessage = Message(
        id: result.message.id,
        createdAt: result.message.createdAt,
        conversationId: result.conversationId,
        sender: _currentUser!, // 🎯 GARDER nos infos utilisateur locales
        content: content,
        messageType: MessageType.text,
        isRead: false,
        isDeleted: false,
      );

      // Remplacer le message temporaire par le message final avec les bonnes infos
      setState(() {
        final tempIndex = _messages.indexWhere((msg) => msg.id == tempMessage.id);
        if (tempIndex != -1) {
          _messages[tempIndex] = finalMessage;
        }
        _isSending = false;
      });

    } catch (e) {
      // En cas d'erreur, supprimer le message temporaire
      setState(() {
        _messages.removeWhere((msg) => msg.id == tempMessage.id);
        _isSending = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr("message.send_error")}: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 🆕 VERSION AMÉLIORÉE: Support du partage de posts
  Widget _buildMessageBubble(Message message) {
    // 🔧 DÉTECTION ROBUSTE: plusieurs critères pour identifier nos messages
    final isMe = message.sender.id == _currentUserId || 
                 message.sender.username == _currentUser?.username ||
                 message.id.startsWith('temp_');
                 
    final isTemporary = message.id.startsWith('temp_');
    
    // 🆕 Détecter si le message contient un lien de post
    final postLinkData = PostLinkDetector.extractPostLink(message.content);
    final contentWithoutLink = postLinkData != null 
      ? PostLinkDetector.getContentWithoutLink(message.content)
      : message.content;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: isTemporary ? 0.7 : 1.0,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isMe 
              ? Theme.of(context).primaryColor 
              : Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type de média (image, vidéo, etc.)
              if (message.messageType == MessageType.image && message.mediaUrl != null)
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.mediaUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          child: Icon(Icons.error),
                        );
                      },
                    ),
                  ),
                ),
              
              // 🆕 Contenu textuel (sans le lien s'il y en a un)
              if (contentWithoutLink.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: postLinkData != null ? 0 : 8
                  ),
                  child: Text(
                    contentWithoutLink,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
              
              // 🆕 Aperçu du post partagé
              if (postLinkData != null)
                SharedPostPreview(
                  username: postLinkData['username']!,
                  postId: postLinkData['postId']!,
                  fullUrl: postLinkData['fullUrl']!,
                  isFromMe: isMe,
                ),
              
              // Informations de timestamp et statut
              SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 6),
                    if (isTemporary)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      )
                    else
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead ? Colors.blue[300] : Colors.white70,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/app/messages'), // 🔧 ROUTE CORRIGÉE
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.otherUser.avatarUrl.isNotEmpty
                ? NetworkImage(widget.otherUser.avatarUrl)
                : null,
              child: widget.otherUser.avatarUrl.isEmpty
                ? Icon(Icons.person, size: 20)
                : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.username,
                    style: TextStyle(fontSize: 16),
                  ),
                  if (widget.otherUser.isCreator)
                    Text(
                      context.tr('user.creator'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 🔧 CORRECTION: Afficher le bouton refresh seulement si on a une conversation existante
          if (!widget.isNewConversation && _actualConversationId != null)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadMessages,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          widget.isNewConversation 
                            ? context.tr('message.new_conversation_with')
                            : context.tr('message.no_messages'),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.isNewConversation
                            ? '${widget.otherUser.username}'
                            : context.tr('message.send_first_message'),
                          style: TextStyle(
                            color: widget.isNewConversation ? Theme.of(context).primaryColor : Colors.grey[500],
                            fontWeight: widget.isNewConversation ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (widget.isNewConversation) ...[
                          SizedBox(height: 16),
                          Text(
                            context.tr('message.send_first_message'),
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo_camera),
                  onPressed: () {
                    // TODO: Implémenter l'envoi d'images
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('message.image_coming_soon'))),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: widget.isNewConversation
                        ? context.tr('message.type_first_message')
                        : context.tr('message.type_message'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
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