import 'dart:io';
import 'dart:typed_data';  // Ajoutez cet import
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';  // Ajoutez cet import
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';

class PostService {
  final _dio = DioClient().dio;

  // Récupérer tous les posts (publics ou selon l'authentification)
  Future<List<Post>> getAllPosts({bool includePaywalled = false}) async {
    final response = await _dio.get(
      '/api/posts',
      queryParameters: {
        'paywalled': includePaywalled.toString(),
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> postsJson = response.data['posts'];
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des posts');
    }
  }

  // Récupérer les posts de l'utilisateur connecté
  Future<List<Post>> getUserPosts() async {
    final response = await _dio.get('/api/posts/me');

    if (response.statusCode == 200) {
      final List<dynamic> postsJson = response.data['posts'];
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération de vos posts');
    }
  }

  // Récupérer un post spécifique
  Future<Post> getPostById(String id) async {
    final response = await _dio.get('/api/posts/$id');

    if (response.statusCode == 200) {
      return Post.fromJson(response.data['post']);
    } else {
      throw Exception('Erreur lors de la récupération du post');
    }
  }

  // Créer un nouveau post (pour mobile)
  Future<Post> createPost({
    required String title,
    required String description,
    required File mediaFile,
    required bool isPaid,
  }) async {
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
      return Post.fromJson(response.data['post']);
    } else {
      throw Exception('Erreur lors de la création du post');
    }
  }

  // Ajoutez cette nouvelle méthode pour le web
  Future<Post> createPostWeb({
    required String title,
    required String description,
    required Uint8List imageBytes,
    required String fileName,
    required bool isPaid,
  }) async {
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
      return Post.fromJson(response.data['post']);
    } else {
      throw Exception('Erreur lors de la création du post');
    }
  }

  // Supprimer un post
  Future<void> deletePost(String id) async {
    final response = await _dio.delete('/api/posts/$id');

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du post');
    }
  }
}