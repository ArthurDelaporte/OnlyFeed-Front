// lib/features/message/services/message_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:onlyfeed_frontend/features/message/model/message_model.dart';
import 'package:onlyfeed_frontend/features/message/model/conversation_model.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';

class MessageService {
  final Dio _dio = DioClient().dio;

  // Récupérer toutes les conversations de l'utilisateur
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _dio.get('/api/messages/conversations');

      if (response.statusCode == 200) {
        final List<dynamic> conversationsJson = response.data['conversations'] ?? [];
        return conversationsJson.map((json) => Conversation.fromJson(json)).toList();
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des conversations: $e');
    }
  }

  // Récupérer les messages d'une conversation
  Future<List<Message>> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/api/messages/conversations/$conversationId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = response.data['messages'] ?? [];
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des messages: $e');
    }
  }

  // 🆕 NOUVEAU: Supprimer une conversation côté utilisateur
  Future<void> deleteConversation(String conversationId) async {
    try {
      final response = await _dio.delete('/api/messages/conversations/$conversationId');

      if (response.statusCode == 200) {
        print('✅ Conversation $conversationId supprimée avec succès');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression de la conversation: $e');
      throw Exception('Erreur lors de la suppression de la conversation: $e');
    }
  }

  // Envoyer un message texte
  Future<MessageWithConversation> sendTextMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/api/messages/send',
        data: {
          'receiver_id': receiverId,
          'content': content,
          'message_type': 'text',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MessageWithConversation(
          message: Message.fromJson(response.data['message']),
          conversationId: response.data['conversation_id'],
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  // Envoyer un message avec image (mobile)
  Future<MessageWithConversation> sendImageMessage({
    required String receiverId,
    required String content,
    required File imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'receiver_id': receiverId,
        'content': content,
        'message_type': 'image',
        'media': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/messages/send',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MessageWithConversation(
          message: Message.fromJson(response.data['message']),
          conversationId: response.data['conversation_id'],
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'image: $e');
    }
  }

  // Envoyer un message avec image (web)
  Future<MessageWithConversation> sendImageMessageWeb({
    required String receiverId,
    required String content,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Déterminer le type MIME
      String extension = fileName.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }

      final formData = FormData.fromMap({
        'receiver_id': receiverId,
        'content': content,
        'message_type': 'image',
        'media': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      });

      final response = await _dio.post(
        '/api/messages/send',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MessageWithConversation(
          message: Message.fromJson(response.data['message']),
          conversationId: response.data['conversation_id'],
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'image: $e');
    }
  }

  // Envoyer un message vidéo (mobile)
  Future<MessageWithConversation> sendVideoMessage({
    required String receiverId,
    required String content,
    required File videoFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'receiver_id': receiverId,
        'content': content,
        'message_type': 'video',
        'media': await MultipartFile.fromFile(
          videoFile.path,
          filename: videoFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/messages/send',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MessageWithConversation(
          message: Message.fromJson(response.data['message']),
          conversationId: response.data['conversation_id'],
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la vidéo: $e');
    }
  }

  // Envoyer un fichier audio (mobile)
  Future<MessageWithConversation> sendAudioMessage({
    required String receiverId,
    required String content,
    required File audioFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'receiver_id': receiverId,
        'content': content,
        'message_type': 'audio',
        'media': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/messages/send',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MessageWithConversation(
          message: Message.fromJson(response.data['message']),
          conversationId: response.data['conversation_id'],
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'audio: $e');
    }
  }

  // Envoyer un fichier quelconque (mobile)
  Future<MessageWithConversation> sendFileMessage({
    required String receiverId,
    required String content,
    required File file,
  }) async {
    try {
      final formData = FormData.fromMap({
        'receiver_id': receiverId,
        'content': content,
        'message_type': 'file',
        'media': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/messages/send',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MessageWithConversation(
          message: Message.fromJson(response.data['message']),
          conversationId: response.data['conversation_id'],
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du fichier: $e');
    }
  }

  // Marquer un message comme lu
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final response = await _dio.put('/api/messages/$messageId/read');

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors du marquage du message comme lu: $e');
    }
  }

  // Supprimer un message
  Future<void> deleteMessage(String messageId) async {
    try {
      final response = await _dio.delete('/api/messages/$messageId');

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression du message: $e');
    }
  }

  // Rechercher des utilisateurs pour démarrer une conversation
  Future<List<ConversationUser>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/api/users/search', // ✅ CORRIGÉ: était '/api/users/searcah'
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = response.data['users'] ?? [];
        return usersJson.map((json) => ConversationUser.fromJson(json)).toList();
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'utilisateurs: $e');
    }
  }

  // Marquer tous les messages d'une conversation comme lus
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final response = await _dio.put('/api/messages/conversations/$conversationId/read');

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors du marquage de la conversation comme lue: $e');
    }
  }

  // Obtenir le nombre de messages non lus
  Future<int> getUnreadMessagesCount() async {
    try {
      final response = await _dio.get('/api/messages/unread/count');

      if (response.statusCode == 200) {
        return response.data['count'] ?? 0;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération du nombre de messages non lus: $e');
    }
  }
}