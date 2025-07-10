import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';

class PostService {
  final _dio = DioClient().dio;

  // 🔧 CORRECTION: Récupérer tous les posts avec gestion d'erreur améliorée
  Future<List<Post>> getAllPosts({bool includePaywalled = false}) async {
    try {
      print("🔍 Appel API: GET /api/posts avec paywalled=$includePaywalled");
      
      final response = await _dio.get(
        '/api/posts',
        queryParameters: {
          if (includePaywalled) 'paywalled': 'true',
        },
      );

      print("✅ Réponse API: Status ${response.statusCode}");
      print("📄 Data: ${response.data}");

      if (response.statusCode == 200) {
        // Vérifier la structure de la réponse
        if (response.data == null) {
          print("⚠️ Réponse null");
          return [];
        }

        // Gérer différents formats de réponse
        dynamic postsData;
        if (response.data is Map<String, dynamic>) {
          postsData = response.data['posts'];
        } else if (response.data is List) {
          postsData = response.data;
        } else {
          print("⚠️ Format de réponse inattendu: ${response.data.runtimeType}");
          return [];
        }

        if (postsData == null) {
          print("⚠️ Pas de champ 'posts' dans la réponse");
          return [];
        }

        final List<dynamic> postsJson = postsData is List ? postsData : [];
        print("📊 Nombre de posts reçus: ${postsJson.length}");
        
        // Debug pour chaque post
        for (var i = 0; i < postsJson.length && i < 3; i++) {
          print("📄 Post $i avant conversion getAllPosts: ${postsJson[i]}");
        }
        
        final posts = postsJson.map((json) {
          try {
            return Post.fromJson(json);
          } catch (e) {
            print("❌ Erreur conversion post: $e");
            print("📄 JSON problématique: $json");
            return null;
          }
        }).where((post) => post != null).cast<Post>().toList();
        
        // Vérifier les posts après conversion
        for (var i = 0; i < posts.length && i < 3; i++) {
          print("✅ Post $i après conversion getAllPosts - mediaURL: ${posts[i].mediaURL}");
        }
        
        return posts;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur serveur: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print("❌ DioException: ${e.message}");
      print("📄 Response data: ${e.response?.data}");
      print("📊 Status code: ${e.response?.statusCode}");
      
      if (e.response?.statusCode == 500) {
        throw Exception('Erreur serveur interne. Veuillez réessayer plus tard.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Endpoint non trouvé');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Non autorisé');
      } else {
        throw Exception('Erreur réseau: ${e.message}');
      }
    } catch (e) {
      print("❌ Erreur générale: $e");
      throw Exception('Erreur lors de la récupération des posts: $e');
    }
  }

  // 🔧 CORRECTION: Récupérer les posts de l'utilisateur connecté
  Future<List<Post>> getUserPosts() async {
    try {
      print("🔍 Appel API: GET /api/posts/me");
      
      final response = await _dio.get('/api/posts/me');
      
      print("✅ Réponse API: Status ${response.statusCode}");

      if (response.statusCode == 200) {
        if (response.data == null) {
          return [];
        }

        dynamic postsData;
        if (response.data is Map<String, dynamic>) {
          postsData = response.data['posts'];
        } else if (response.data is List) {
          postsData = response.data;
        } else {
          return [];
        }

        final List<dynamic> postsJson = postsData is List ? postsData : [];
        
        final posts = postsJson.map((json) {
          try {
            return Post.fromJson(json);
          } catch (e) {
            print("❌ Erreur conversion post getUserPosts: $e");
            return null;
          }
        }).where((post) => post != null).cast<Post>().toList();
        
        return posts;
      } else {
        throw Exception('Erreur lors de la récupération de vos posts');
      }
    } catch (e) {
      print("❌ Erreur getUserPosts: $e");
      throw Exception('Erreur lors de la récupération de vos posts: $e');
    }
  }

  // 🔧 CORRECTION: Récupérer un post spécifique
  Future<Post> getPostById(String id) async {
    try {
      print("🔍 Appel API: GET /api/posts/$id");
      
      final response = await _dio.get('/api/posts/$id');
      
      print("✅ Réponse API: Status ${response.statusCode}");

      if (response.statusCode == 200) {
        if (response.data == null) {
          throw Exception('Réponse vide du serveur');
        }

        // Gérer différents formats de réponse
        dynamic postData;
        if (response.data is Map<String, dynamic>) {
          postData = response.data['post'] ?? response.data;
        } else {
          postData = response.data;
        }
        
        print("📄 Post avant conversion getPostById: $postData");
        
        final post = Post.fromJson(postData);
        print("✅ Post après conversion getPostById - mediaURL: ${post.mediaURL}");
        
        return post;
      } else {
        throw Exception('Erreur lors de la récupération du post');
      }
    } catch (e) {
      print("❌ Erreur getPostById: $e");
      throw Exception('Erreur lors de la récupération du post: $e');
    }
  }

  Future<List<Post>> getPostsByUsername(String username) async {
    try {
      final response = await DioClient().dio.get('/api/users/username/$username/posts');
      
      if (response.statusCode == 200) {
        final postsData = response.data['posts'] as List? ?? [];
        return postsData.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des posts');
      }
    } catch (e) {
      print("❌ Erreur getPostsByUsername: $e");
      throw Exception('Erreur lors de la récupération des posts: $e');
    }
  }

  // Créer un nouveau post (pour mobile)
  Future<Post> createPost({
    required String title,
    required String description,
    required File mediaFile,
    required bool isPaid,
  }) async {
    try {
      // Créer le FormData pour l'upload
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'is_paid': isPaid.toString(),
        'media': await MultipartFile.fromFile(
          mediaFile.path,
          filename: mediaFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/api/posts',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Réponse de création de post: ${response.data}");
        return Post.fromJson(response.data['post']);
      } else {
        throw Exception('Erreur lors de la création du post');
      }
    } catch (e) {
      print("❌ Erreur createPost: $e");
      throw Exception('Erreur lors de la création du post: $e');
    }
  }

  Future<Post> createPostWeb({
    required String title,
    required String description,
    required Uint8List imageBytes,
    required String fileName,
    required bool isPaid,
  }) async {
    try {
      // Déterminer le type MIME basé sur l'extension du fichier
      String extension = fileName.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg'; // Par défaut
      
      // Mapper les extensions courantes à leurs types MIME
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }
      
      // Créer le FormData pour l'upload
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'is_paid': isPaid.toString(),
        'media': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      });

      final response = await _dio.post(
        '/api/posts',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Réponse de création de post web: ${response.data}");
        return Post.fromJson(response.data['post']);
      } else {
        throw Exception('Erreur lors de la création du post');
      }
    } catch (e) {
      print("❌ Erreur createPostWeb: $e");
      throw Exception('Erreur lors de la création du post: $e');
    }
  }

  // Supprimer un post
  Future<void> deletePost(String id) async {
    try {
      final response = await _dio.delete('/api/posts/$id');

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la suppression du post');
      }
    } catch (e) {
      print("❌ Erreur deletePost: $e");
      throw Exception('Erreur lors de la suppression du post: $e');
    }
  }
}