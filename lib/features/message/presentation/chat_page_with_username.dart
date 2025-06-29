// lib/features/message/presentation/chat_page_with_username.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyfeed_frontend/features/message/model/message_model.dart';
import 'package:onlyfeed_frontend/features/message/presentation/chat_page.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';

class ChatPageWithUsername extends StatefulWidget {
  final String username;

  const ChatPageWithUsername({
    super.key,
    required this.username,
  });

  @override
  State<ChatPageWithUsername> createState() => _ChatPageWithUsernameState();
}

class _ChatPageWithUsernameState extends State<ChatPageWithUsername> {
  final _dio = DioClient().dio;
  ConversationUser? otherUser;
  String? conversationId;
  bool isLoading = true;
  bool isNewConversation = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndConversation();
  }

  Future<void> _loadUserAndConversation() async {
    try {
      print('🔍 Recherche de l\'utilisateur: ${widget.username}');
      
      // 1. Récupérer les infos de l'utilisateur
      final userResponse = await _dio.get('/api/users/username/${widget.username}');
      if (userResponse.statusCode == 200) {
        final userData = userResponse.data['user'];
        otherUser = ConversationUser(
          id: userData['id'],
          username: userData['username'],
          avatarUrl: userData['avatar_url'] ?? '',
          isCreator: userData['is_creator'] ?? false,
        );
        print('✅ Utilisateur trouvé: ${otherUser!.username}');
      }

      // 2. Chercher si une conversation existe déjà
      print('🔍 Recherche de conversation existante...');
      final conversationsResponse = await _dio.get('/api/messages/conversations');
      if (conversationsResponse.statusCode == 200) {
        final conversations = conversationsResponse.data['conversations'] as List;
        
        // Chercher une conversation avec cet utilisateur
        for (final conv in conversations) {
          final otherUserData = conv['other_user'];
          if (otherUserData['username'] == widget.username) {
            conversationId = conv['id'];
            print('✅ Conversation existante trouvée: $conversationId');
            break;
          }
        }
      }

      // Si pas de conversation trouvée, c'est une nouvelle conversation
      if (conversationId == null) {
        isNewConversation = true;
        print('🆕 Nouvelle conversation avec ${widget.username}');
      }

      setState(() {
        isLoading = false;
      });

    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
      setState(() {
        isLoading = false;
      });
      
      // 🔧 ROUTE CORRIGÉE: Retourner à la liste des conversations
      if (mounted) {
        context.go('/app/messages');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Utilisateur "${widget.username}" non trouvé')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chargement...'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => context.go('/app/messages'), // 🔧 ROUTE CORRIGÉE
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Recherche de ${widget.username}...'),
            ],
          ),
        ),
      );
    }

    if (otherUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Erreur'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => context.go('/app/messages'), // 🔧 ROUTE CORRIGÉE
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Utilisateur non trouvé',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('L\'utilisateur "${widget.username}" n\'existe pas'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/app/messages'), // 🔧 ROUTE CORRIGÉE
                child: Text('Retour aux conversations'),
              ),
            ],
          ),
        ),
      );
    }

    return ChatPage(
      conversationId: conversationId,
      otherUser: otherUser!,
      isNewConversation: isNewConversation,
    );
  }
}