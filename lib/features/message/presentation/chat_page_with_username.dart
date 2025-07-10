import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyfeed_frontend/features/message/model/message_model.dart';
import 'package:onlyfeed_frontend/features/message/presentation/chat_page.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';
import 'package:dio/dio.dart';

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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserAndConversation();
  }

  Future<void> _loadUserAndConversation() async {
    try {
      print('🔍 Recherche de l\'utilisateur: ${widget.username}');
      
      // 1. Récupérer les infos de l'utilisateur
      try {
        final userResponse = await _dio.get('/api/users/username/${widget.username}');
        print('🔍 Réponse complète de l\'utilisateur: ${userResponse.data}');
        
        if (userResponse.statusCode == 200) {
          final userData = userResponse.data['user'];
          
          if (userData == null) {
            throw Exception('Aucune donnée utilisateur trouvée');
          }

          otherUser = ConversationUser(
            id: userData['id'],
            username: userData['username'],
            avatarUrl: userData['avatar_url'] ?? '',
            isCreator: userData['is_creator'] ?? false,
          );
          print('✅ Utilisateur trouvé: ${otherUser!.username}');
        } else {
          throw Exception('Statut de réponse invalide: ${userResponse.statusCode}');
        }
      } on DioException catch (dioError) {
        print('❌ Erreur Dio lors de la récupération de l\'utilisateur: ${dioError.response?.data}');
        throw Exception('Impossible de récupérer l\'utilisateur');
      }

      // 2. Chercher si une conversation existe déjà
      print('🔍 Recherche de conversation existante...');
      final conversationsResponse = await _dio.get('/api/messages/conversations');
      
      if (conversationsResponse.statusCode == 200) {
        final conversations = conversationsResponse.data['conversations'] as List? ?? [];
        print('🔍 Conversations récupérées: ${conversations.length}');
        
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

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
      
      if (mounted) {
        setState(() {
          isLoading = false;
          _errorMessage = e.toString();
        });
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
            onPressed: () => context.go('/app/messages'),
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

    if (_errorMessage != null || otherUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Erreur'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => context.go('/app/messages'),
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
              Text(_errorMessage ?? 'L\'utilisateur "${widget.username}" n\'existe pas'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/app/messages'),
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