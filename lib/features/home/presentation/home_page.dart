// lib/features/home/presentation/home_page.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/features/post/providers/post_provider.dart';
import 'package:onlyfeed_frontend/features/home/widgets/feed_post_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _debugMode = false; // 🔧 Désactivé par défaut

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Initialiser le feed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("🚀 Initialisation du feed...");
      context.read<PostProvider>().initializeFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final postProvider = context.read<PostProvider>();
      if (postProvider.hasMoreFeedPosts && !postProvider.isLoadingFeed) {
        print("📜 Chargement de plus de posts...");
        postProvider.loadMoreFeedPosts();
      }
    }
  }

  Future<void> _onRefresh() async {
    print("🔄 Rafraîchissement du feed...");
    await context.read<PostProvider>().refreshFeed();
  }

  Widget _buildDebugInfo(PostProvider postProvider) {
    if (!_debugMode) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🔧 Debug Info", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("📊 Posts dans le feed: ${postProvider.feedPosts.length}"),
          Text("⏳ En cours de chargement: ${postProvider.isLoadingFeed}"),
          Text("📖 Plus de posts: ${postProvider.hasMoreFeedPosts}"),
          Text("❌ Erreur: ${postProvider.feedError ?? 'Aucune'}"),
          SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => context.read<PostProvider>().initializeFeed(),
                child: Text("Recharger"),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => setState(() => _debugMode = false),
                child: Text("Masquer debug"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              "Aucun post à afficher",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Il n'y a pas encore de contenu dans votre fil d'actualité.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<PostProvider>().initializeFeed(),
              icon: Icon(Icons.refresh),
              label: Text("Réessayer"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              "Erreur",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<PostProvider>().initializeFeed(),
              icon: Icon(Icons.refresh),
              label: Text("Réessayer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return ScaffoldWithMenubar(
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          return Column(
            children: [
              // Debug info (masqué par défaut)
              if (_debugMode) _buildDebugInfo(postProvider),
              
              // Contenu principal
              Expanded(
                child: _buildMainContent(postProvider, isMobile),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(PostProvider postProvider, bool isMobile) {
    // État de chargement initial
    if (postProvider.isLoadingFeed && postProvider.feedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Chargement du fil d'actualité...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // État d'erreur
    if (postProvider.feedError != null && postProvider.feedPosts.isEmpty) {
      return _buildErrorState(postProvider.feedError!);
    }

    // État vide
    if (postProvider.feedPosts.isEmpty) {
      return _buildEmptyState();
    }

    // Feed avec posts
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header du feed
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 8 : 16, 
                16, 
                isMobile ? 8 : 16, 
                8
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Fil d'actualité",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _onRefresh,
                    icon: Icon(Icons.refresh),
                    tooltip: "Actualiser",
                  ),
                  // 🔧 Bouton debug caché (pour développement)
                  if (!_debugMode)
                    IconButton(
                      onPressed: () => setState(() => _debugMode = true),
                      icon: Icon(Icons.bug_report, size: 16),
                      tooltip: "Debug",
                    ),
                ],
              ),
            ),
          ),

          // Liste des posts
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = postProvider.feedPosts[index];
                
                // ✅ Plus besoin de FutureBuilder - utiliser directement FeedPostCard
                return FeedPostCard(post: post);
              },
              childCount: postProvider.feedPosts.length,
            ),
          ),

          // Indicateur de chargement ou fin de liste
          SliverToBoxAdapter(
            child: postProvider.isLoadingFeed
                ? Container(
                    padding: EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Chargement...",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : !postProvider.hasMoreFeedPosts
                    ? Container(
                        padding: EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green[400],
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Vous avez tout vu ! 🎉",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(height: 16),
          ),

          // Espace en bas
          SliverToBoxAdapter(
            child: SizedBox(height: isMobile ? 80 : 24),
          ),
        ],
      ),
    );
  }
}