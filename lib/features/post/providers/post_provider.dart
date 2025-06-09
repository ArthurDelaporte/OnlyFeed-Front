import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:onlyfeed_frontend/features/post/model/post_model.dart';
import 'package:onlyfeed_frontend/features/post/services/post_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  List<Post> _userPosts = [];
  List<Post> _allPosts = [];
  bool _isLoading = false;

  List<Post> get userPosts => _userPosts;
  List<Post> get allPosts => _allPosts;
  bool get isLoading => _isLoading;

  Future<void> fetchUserPosts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _userPosts = await _postService.getUserPosts();
    } catch (e) {
      print('Error fetching user posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPosts({bool includePaywalled = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allPosts = await _postService.getAllPosts(includePaywalled: includePaywalled);
    } catch (e) {
      print('Error fetching all posts: $e');
    } finally {
      _isLoading = false;
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
    _isLoading = true;
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
      
      // Ajouter le nouveau post à la liste des posts de l'utilisateur
      _userPosts = [newPost, ..._userPosts];
      
      // Mettre à jour aussi la liste de tous les posts si nécessaire
      if (!isPaid || _allPosts.any((post) => post.isPaid)) {
        _allPosts = [newPost, ..._allPosts];
      }
      
      notifyListeners();
      return newPost;
    } catch (e) {
      print('Error creating post: $e');
      rethrow; // Relancer l'exception pour la gérer dans l'UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserPostsByUsername(String username) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userPosts = await _postService.getPostsByUsername(username);
    } catch (e) {
      print('Error fetching posts for user $username: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}