import 'message_model.dart';

class Conversation {
  final String id;
  final ConversationUser otherUser;
  final Message? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      otherUser: ConversationUser.fromJson(json['other_user'] ?? {}),
      lastMessage: json['last_message'] != null 
        ? Message.fromJson(json['last_message']) 
        : null,
      lastMessageAt: json['last_message_at'] != null 
        ? DateTime.parse(json['last_message_at']) 
        : null,
      unreadCount: json['unread_count'] ?? 0,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'other_user': otherUser.toJson(),
      'last_message': lastMessage?.toJson(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}