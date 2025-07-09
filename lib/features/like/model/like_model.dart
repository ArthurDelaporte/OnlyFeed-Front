// features/like/model/like_model.dart
class Like {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      postId: json['post_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class LikeResponse {
  final String postId;
  final int likeCount;
  final bool isLiked;

  LikeResponse({
    required this.postId,
    required this.likeCount,
    required this.isLiked,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      postId: json['post_id'] ?? '',
      likeCount: json['like_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'like_count': likeCount,
      'is_liked': isLiked,
    };
  }
}