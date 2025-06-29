// lib/features/message/model/message_model.dart

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
}

class ConversationUser {
  final String id;
  final String username;
  final String avatarUrl;
  final bool isCreator;

  ConversationUser({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.isCreator,
  });

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'] ?? '',
      isCreator: json['is_creator'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'is_creator': isCreator,
    };
  }

  @override
  String toString() {
    return 'ConversationUser{id: $id, username: $username, avatarUrl: $avatarUrl, isCreator: $isCreator}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Message {
  final String id;
  final DateTime createdAt;
  final String conversationId;
  final ConversationUser sender;
  final String content;
  final MessageType messageType;
  final String? mediaUrl;
  final bool isRead;
  final DateTime? readAt;
  final bool isDeleted;

  Message({
    required this.id,
    required this.createdAt,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.messageType,
    this.mediaUrl,
    required this.isRead,
    this.readAt,
    required this.isDeleted,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      conversationId: json['conversation_id'],
      sender: ConversationUser.fromJson(json['sender']),
      content: json['content'] ?? '',
      messageType: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['message_type'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: json['media_url'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'conversation_id': conversationId,
      'sender': sender.toJson(),
      'content': content,
      'message_type': messageType.toString().split('.').last,
      'media_url': mediaUrl,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  Message copyWith({
    String? id,
    DateTime? createdAt,
    String? conversationId,
    ConversationUser? sender,
    String? content,
    MessageType? messageType,
    String? mediaUrl,
    bool? isRead,
    DateTime? readAt,
    bool? isDeleted,
  }) {
    return Message(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'Message{id: $id, sender: ${sender.username}, content: $content, type: $messageType}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Classe pour encapsuler le message et l'ID de conversation lors de l'envoi
class MessageWithConversation {
  final Message message;
  final String conversationId;

  MessageWithConversation({
    required this.message,
    required this.conversationId,
  });

  @override
  String toString() {
    return 'MessageWithConversation{message: $message, conversationId: $conversationId}';
  }
}