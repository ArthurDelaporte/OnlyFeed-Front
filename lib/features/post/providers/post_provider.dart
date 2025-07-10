import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/features/post/services/post_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  
  // Posts utilisateur
  List<Post> _userPosts = [];
  List<Post> _allPosts = [];
  
  // 🆕 NOUVEAU: Feed avec pagination
  List<Post> _feedPosts = [];
  bool _isLoadingFeed = false;
  bool _hasMoreFeedPosts = true;
  int _feedPage = 1;
  static const int _feedPostsPerPage = 10;
  String? _feedError;

  // Getters existants
  List<Post> get userPosts => _userPosts;
  List<Post> get allPosts => _allPosts;
  bool get isLoading => _isLoadingFeed;

  // 🆕 NOUVEAUX getters pour le feed
  List<Post> get feedPosts => _feedPosts;
  bool get isLoadingFeed => _isLoadingFeed;
  bool get hasMoreFeedPosts => _hasMoreFeedPosts;
  String? get feedError => _feedError;

  // Méthodes existantes
  Future<void> fetchUserPosts() async {
    _isLoadingFeed = true;
    notifyListeners();

    try {
      _userPosts = await _postService.getUserPosts();
    } catch (e) {
      print('Error fetching user posts: $e');
    } finally {
      _isLoadingFeed = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPosts({bool includePaywalled = false}) async {
    _isLoadingFeed = true;
    notifyListeners();

    try {
      _allPosts = await _postService.getAllPosts(includePaywalled: includePaywalled);
    } catch (e) {
      print('Error fetching all posts: $e');
    } finally {
      _isLoadingFeed = false;
      notifyListeners();
    }
  }

  Future<Post?> createPost({
    required String title, 
    required String description, 
    required bool isPaid,
    File? mediaFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    _isLoadingFeed = true;
    notifyListeners();

    try {
      Post newPost;
      
      if (kIsWeb && imageBytes != null) {
        newPost = await _postService.createPostWeb(
          title: title,
          description: description,
          imageBytes: imageBytes,
          fileName: fileName ?? 'image.jpg',
          isPaid: isPaid,
        );
      } else if (mediaFile != null) {
        newPost = await _postService.createPost(
          title: title,
          description: description,
          mediaFile: mediaFile,
          isPaid: isPaid,
        );
      } else {
        throw Exception('No media provided');
      }
      
      // Ajouter le nouveau post aux listes appropriées
      _userPosts = [newPost, ..._userPosts];
      
      if (!isPaid || _allPosts.any((post) => post.isPaid)) {
        _allPosts = [newPost, ..._allPosts];
      }

      // 🆕 Ajouter au feed aussi si c'est public
      if (!isPaid) {
        _feedPosts = [newPost, ..._feedPosts];
      }
      
      notifyListeners();
      return newPost;
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    } finally {
      _isLoadingFeed = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserPostsByUsername(String username) async {
    _isLoadingFeed = true;
    notifyListeners();

    try {
      _userPosts = await _postService.getPostsByUsername(username);
    } catch (e) {
      print('Error fetching posts for user $username: $e');
    } finally {
      _isLoadingFeed = false;
      notifyListeners();
    }
  }

  // 🆕 NOUVELLES méthodes pour le feed

  /// Initialise le feed (première charge)
  Future<void> initializeFeed() async {
    _feedPage = 1;
    _hasMoreFeedPosts = true;
    _feedPosts = [];
    _feedError = null;
    
    await _loadFeedPosts(isInitial: true);
  }

  /// Charge plus de posts pour le feed (pagination)
  Future<void> loadMoreFeedPosts() async {
    if (_isLoadingFeed || !_hasMoreFeedPosts) return;
    
    _feedPage++;
    await _loadFeedPosts(isInitial: false);
  }

  /// Rafraîchit le feed (pull-to-refresh)
  Future<void> refreshFeed() async {
    _feedPage = 1;
    _hasMoreFeedPosts = true;
    _feedError = null;
    
    await _loadFeedPosts(isInitial: true, isRefresh: true);
  }

  /// Méthode privée pour charger les posts
  Future<void> _loadFeedPosts({
    bool isInitial = false, 
    bool isRefresh = false
  }) async {
    if (isInitial) {
      _isLoadingFeed = true;
    }
    
    notifyListeners();

    try {
      print("🔄 Chargement du feed - Page: $_feedPage, Initial: $isInitial, Refresh: $isRefresh");
      
      // ✅ CORRECTION: Appel direct à l'API pour tous les posts
      final allPosts = await _postService.getAllPosts(includePaywalled: false);
      
      print("📊 Posts récupérés: ${allPosts.length}");
      
      // Pagination côté client
      final startIndex = (_feedPage - 1) * _feedPostsPerPage;
      final endIndex = startIndex + _feedPostsPerPage;
      
      print("📄 Pagination: startIndex=$startIndex, endIndex=$endIndex");
      
      if (startIndex >= allPosts.length) {
        _hasMoreFeedPosts = false;
        print("🔚 Plus de posts à charger");
        return;
      }
      
      final newPosts = allPosts.sublist(
        startIndex, 
        endIndex > allPosts.length ? allPosts.length : endIndex
      );
      
      print("📦 Nouveaux posts à ajouter: ${newPosts.length}");
      
      if (isInitial || isRefresh) {
        _feedPosts = newPosts;
        print("🔄 Remplacement des posts du feed");
      } else {
        _feedPosts.addAll(newPosts);
        print("➕ Ajout de posts au feed existant");
      }
      
      _hasMoreFeedPosts = endIndex < allPosts.length;
      _feedError = null;
      
      print("✅ Feed mis à jour - Total posts: ${_feedPosts.length}, Plus de posts: $_hasMoreFeedPosts");
      
    } catch (e) {
      print('❌ Error loading feed posts: $e');
      
      // Extraire un message d'erreur plus convivial
      String userFriendlyError = "Une erreur est survenue";
      if (e.toString().contains("Erreur serveur interne")) {
        userFriendlyError = "Le serveur rencontre des difficultés. Veuillez réessayer.";
      } else if (e.toString().contains("Erreur réseau")) {
        userFriendlyError = "Problème de connexion. Vérifiez votre internet.";
      } else if (e.toString().contains("Non autorisé")) {
        userFriendlyError = "Vous devez être connecté pour voir le contenu.";
      }
      
      _feedError = userFriendlyError;
      
      if (isInitial || isRefresh) {
        _feedPosts = [];
      }
    } finally {
      _isLoadingFeed = false;
      notifyListeners();
    }
  }

  /// Met à jour un post dans le feed (utile pour les likes)
  void updatePostInFeed(Post updatedPost) {
    final index = _feedPosts.indexWhere((post) => post.id == updatedPost.id);
    if (index != -1) {
      _feedPosts[index] = updatedPost;
      notifyListeners();
    }
  }

  /// Supprime un post du feed
  void removePostFromFeed(String postId) {
    _feedPosts.removeWhere((post) => post.id == postId);
    notifyListeners();
  }
}