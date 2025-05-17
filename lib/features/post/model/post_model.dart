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
    // Debug pour voir les clés disponibles dans le JSON
    print("Clés disponibles dans le JSON du post: ${json.keys.toList()}");
    
    // Extraire les valeurs avec gestion de la casse
    String mediaUrl = json['media_url'] ?? json['MediaURL'] ?? '';
    print("URL extraite du post: $mediaUrl");
    
    return Post(
      id: json['id'] ?? json['ID'] ?? '',
      userId: json['user_id'] ?? json['UserID'] ?? '',
      title: json['title'] ?? json['Title'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      mediaURL: mediaUrl,
      isPaid: json['is_paid'] ?? json['IsPaid'] ?? false,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'])
        : json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
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