// features/like/service/like_service.dart
import 'package:dio/dio.dart';
import '../../../shared/services/dio_client.dart';
import '../model/like_model.dart';

class LikeService {
  final Dio _dio = DioClient().dio;

  /// Toggle like/unlike pour un post
  Future<LikeResponse> toggleLike(String postId) async {
    try {
      final response = await _dio.post('/api/posts/$postId/like');
      return LikeResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Vous devez être connecté pour liker un post');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Post non trouvé');
      }
      throw Exception('Erreur lors du toggle like: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors du toggle like: $e');
    }
  }

  /// Récupérer le statut des likes pour un post
  /// 🔧 MODIFICATION : Gérer le cas non authentifié
  Future<LikeResponse> getLikeStatus(String postId) async {
    try {
      final response = await _dio.get('/api/posts/$postId/likes');
      return LikeResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Post non trouvé');
      } else if (e.response?.statusCode == 401) {
        // ✅ Si non authentifié, retourner un statut par défaut
        return LikeResponse(
          postId: postId,
          likeCount: 0, // Ou récupérer depuis une autre source si disponible
          isLiked: false,
        );
      }
      throw Exception('Erreur lors de la récupération du statut des likes: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la récupération du statut des likes: $e');
    }
  }

  /// Récupérer les posts avec les informations de likes
  /// 🔧 MODIFICATION : Gérer correctement l'état d'authentification
  Future<List<Map<String, dynamic>>> getPostsWithLikes({bool showPaywalled = false}) async {
    try {
      final response = await _dio.get('/api/posts', queryParameters: {
        if (showPaywalled) 'paywalled': 'true',
      });
      
      final List<dynamic> postsData = response.data['posts'] ?? [];
      
      // 🔧 NOUVELLE LOGIQUE : Nettoyer les données de likes si non authentifié
      return postsData.map<Map<String, dynamic>>((post) {
        final Map<String, dynamic> postMap = Map<String, dynamic>.from(post);
        
        // Si l'utilisateur n'est pas authentifié (vérifiable via l'absence de certains champs),
        // forcer is_liked à false
        if (!_isUserAuthenticated(response)) {
          postMap['is_liked'] = false;
        }
        
        return postMap;
      }).toList();
    } on DioException catch (e) {
      throw Exception('Erreur lors de la récupération des posts avec likes: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des posts avec likes: $e');
    }
  }

  /// 🆕 NOUVELLE MÉTHODE : Vérifier si l'utilisateur est authentifié via la réponse
  bool _isUserAuthenticated(Response response) {
    // Logique pour déterminer si l'utilisateur est authentifié
    // Par exemple, vérifier la présence de certains headers ou la structure de la réponse
    final posts = response.data['posts'] as List?;
    if (posts != null && posts.isNotEmpty) {
      final firstPost = posts.first;
      // Si le champ is_liked existe et n'est pas null, l'utilisateur est probablement authentifié
      return firstPost['is_liked'] != null;
    }
    return false;
  }

  /// Récupérer les posts likés par l'utilisateur connecté
  Future<List<Map<String, dynamic>>> getLikedPosts() async {
    try {
      final response = await _dio.get('/api/me/liked-posts');
      final List<dynamic> postsData = response.data['posts'] ?? [];
      return postsData.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Vous devez être connecté');
      }
      throw Exception('Erreur lors de la récupération des posts likés: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des posts likés: $e');
    }
  }

  /// Récupérer les statistiques de likes pour un utilisateur
  Future<Map<String, dynamic>> getUserLikeStats(String userId) async {
    try {
      final response = await _dio.get('/api/users/$userId/like-stats');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Utilisateur non trouvé');
      }
      throw Exception('Erreur lors de la récupération des statistiques: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}