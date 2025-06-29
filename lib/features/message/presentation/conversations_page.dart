// lib/features/message/presentation/conversations_page.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';
import 'package:onlyfeed_frontend/features/message/model/conversation_model.dart';
import 'package:onlyfeed_frontend/features/message/model/message_model.dart';
import 'package:onlyfeed_frontend/features/message/services/message_service.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final _messageService = MessageService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  // 🔧 NOUVEAU: Rafraîchir quand on revient sur la page
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Vérifier si on revient d'une autre page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshConversationsIfNeeded();
      }
    });
  }

  Future<void> _refreshConversationsIfNeeded() async {
    // Rafraîchir seulement si la liste est déjà chargée
    if (!_isLoading && mounted) {
      print('🔄 Auto-refresh des conversations');
      await _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final conversations = await _messageService.getConversations();
      
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // 🆕 NOUVEAU: Supprimer une conversation
  Future<void> _deleteConversation(Conversation conversation) async {
    // Afficher la boîte de dialogue de confirmation
    final bool? confirmed = await _showDeleteConfirmation(conversation);
    
    if (confirmed != true) return;

    try {
      // Appeler l'API pour supprimer la conversation
      await _messageService.deleteConversation(conversation.id);
      
      // Retirer la conversation de la liste locale
      setState(() {
        _conversations.removeWhere((conv) => conv.id == conversation.id);
      });
      
      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('message.conversation_deleted')),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('message.delete_error')),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 🆕 NOUVEAU: Dialogue de confirmation de suppression
  Future<bool?> _showDeleteConfirmation(Conversation conversation) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('message.delete_conversation')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('message.delete_conversation_warning', 
                namedArgs: {'username': conversation.otherUser.username}),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      SizedBox(width: 6),
                      Text(
                        context.tr('message.important'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    context.tr('message.delete_explanation'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('core.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(context.tr('core.delete')),
          ),
        ],
      ),
    );
  }

  String _formatLastMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return DateFormat('dd/MM').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return context.tr('message.now');
    }
  }

  // 🔧 MODIFICATION: Navigation vers chat avec username
  void _navigateToChat(Conversation conversation) {
    final username = conversation.otherUser.username;
    print('🔄 Navigation vers /app/messages/chat/$username');
    context.go('/app/messages/chat/$username');
  }

  // 🔧 MODIFICATION: Nouveau design avec menu contextuel
  Widget _buildConversationTile(Conversation conversation) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => _navigateToChat(conversation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundImage: conversation.otherUser.avatarUrl.isNotEmpty
                  ? NetworkImage(conversation.otherUser.avatarUrl)
                  : null,
                child: conversation.otherUser.avatarUrl.isEmpty
                  ? Icon(Icons.person, size: 28)
                  : null,
              ),
              SizedBox(width: 12),
              
              // Contenu principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom d'utilisateur + badge créateur
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherUser.username,
                            style: TextStyle(
                              fontWeight: conversation.unreadCount > 0 
                                ? FontWeight.bold 
                                : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (conversation.otherUser.isCreator)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
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
                    ),
                    SizedBox(height: 4),
                    
                    // Dernier message
                    if (conversation.lastMessage != null)
                      Text(
                        conversation.lastMessage!.messageType == MessageType.text
                          ? conversation.lastMessage!.content
                          : '📷 ${context.tr('message.image')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: conversation.unreadCount > 0 
                            ? FontWeight.w500 
                            : FontWeight.normal,
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      )
                    else
                      Text(
                        context.tr('message.no_messages'),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Côté droit : heure + badge + menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Heure
                      Text(
                        _formatLastMessageTime(conversation.lastMessageAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 4),
                      
                      // 🆕 NOUVEAU: Menu contextuel
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        onSelected: (value) {
                          switch (value) {
                            case 'delete':
                              _deleteConversation(conversation);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red[600],
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  context.tr('message.delete_conversation'),
                                  style: TextStyle(
                                    color: Colors.red[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Badge de messages non lus
                  if (conversation.unreadCount > 0) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        conversation.unreadCount > 99 
                          ? '99+' 
                          : conversation.unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    return ScaffoldWithMenubar(
      body: Column(
        children: [
          // 🆕 Header pour les messages
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('message.conversations'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FloatingActionButton.small(
                  onPressed: () => context.push('/app/messages/search'),
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(Icons.add_comment, color: Colors.white, size: 20),
                  tooltip: context.tr('message.new_conversation'),
                ),
              ],
            ),
          ),
          
          // Corps principal
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          context.tr('core.error'),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(_error!),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadConversations,
                          child: Text(context.tr('core.retry')),
                        ),
                      ],
                    ),
                  )
                : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            context.tr('message.no_conversations'),
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            context.tr('message.start_conversation_hint'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          return _buildConversationTile(_conversations[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}