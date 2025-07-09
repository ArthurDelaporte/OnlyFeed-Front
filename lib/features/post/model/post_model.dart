// features/post/model/post_model.dart
class Post {
  final String id;
  final String title;
  final String description;
  final String mediaURL;
  final bool isPaid;
  final DateTime createdAt;
  final String userId;
  final int likeCount;
  final bool isLiked;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaURL,
    required this.isPaid,
    required this.createdAt,
    required this.userId,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? json['ID'] ?? '',
      title: json['title'] ?? json['Title'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      mediaURL: json['media_url'] ?? json['MediaURL'] ?? '',
      isPaid: json['is_paid'] ?? json['IsPaid'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? json['CreatedAt']),
      userId: json['user_id'] ?? json['UserID'] ?? '',
      likeCount: json['like_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'media_url': mediaURL,
      'is_paid': isPaid,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'like_count': likeCount,
      'is_liked': isLiked,
    };
  }

  // Méthode pour créer une copie avec des valeurs mises à jour
  Post copyWith({
    String? id,
    String? title,
    String? description,
    String? mediaURL,
    bool? isPaid,
    DateTime? createdAt,
    String? userId,
    int? likeCount,
    bool? isLiked,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaURL: mediaURL ?? this.mediaURL,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}