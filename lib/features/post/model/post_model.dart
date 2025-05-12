class Post {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String mediaURL;
  final bool isPaid;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.mediaURL,
    required this.isPaid,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      mediaURL: json['media_url'] ?? '',
      isPaid: json['is_paid'] ?? false,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'media_url': mediaURL,
      'is_paid': isPaid,
      'created_at': createdAt.toIso8601String(),
    };
  }
}