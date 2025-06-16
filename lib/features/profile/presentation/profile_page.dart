import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';
import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/features/post/widgets/post_grid.dart';
import 'package:onlyfeed_frontend/features/post/providers/post_provider.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _dio = DioClient().dio;
  Map<String, dynamic>? _user;
  bool? _isFollowing;
  bool _isOwnProfile = false;
  bool _isLoading = true;
  bool _shouldRefresh = false;
  bool _showFullBio = false;
  bool _isAuthenticated = false;
  int followersCount = 0;
  int subscribersCount = 0;
  int postsCount = 0;
  int paidPostsCount = 0;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (args?['refresh'] == true & !_shouldRefresh) {
      _shouldRefresh = true;
      _initProfile();
    }
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) {
      setState(() {
        _isLoading = true;
        _user = null;
      });
      _initProfile();
    }
  }

  Future<void> _initProfile() async {
    try {
      final response = await _dio.get('/api/users/username/${widget.username}');
      _user = response.data['user'];
      final stats = response.data['stats'];
      followersCount = stats["followers_count"] is int
          ? stats["followers_count"]
          : int.tryParse(stats["followers_count"] ?? "0") ?? 0;
      subscribersCount = stats["subscribers_count"] is int
          ? stats["subscribers_count"]
          : int.tryParse(stats["subscribers_count"] ?? "0") ?? 0;
      postsCount = stats["posts_count"] is int
          ? stats["posts_count"]
          : int.tryParse(stats["posts_count"] ?? "0") ?? 0;
      paidPostsCount = stats["paid_posts_count"] is int
          ? stats["paid_posts_count"]
          : int.tryParse(stats["paid_posts_count"] ?? "0") ?? 0;
      _isFollowing = response.data['is_following'];
    } catch (e) {
      _user = null;
    }
    final session = context.read<SessionNotifier>();
    final currentUser = session.user;
    _isAuthenticated = session.isAuthenticated;

    if (_user != null && currentUser != null && _user?["id"] == currentUser['id']) {
      _isOwnProfile = true;
      session.setUser(_user);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PostProvider>().fetchUserPosts();
      });
    } else {
      _isOwnProfile = false;
      await context.read<PostProvider>().fetchUserPostsByUsername(widget.username);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleFollow() async {
    if (_user == null || _user!['id'] == null) return;

    try {
      if (_isFollowing == true) {
        await _dio.delete('/api/follow/${_user!['id']}');
        setState(() {
          _isFollowing = false;
          followersCount--;
        });
      } else {
        await _dio.post('/api/follow/${_user!['id']}');
        setState(() {
          _isFollowing = true;
          followersCount++;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("core.error".tr())),
      );
    }
  }

  bool _shouldShowReadMore(String text) {
    return text.trim().length > 100;
  }

  Widget _buildHeader() {
    final bio = _user?['bio'] ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: SizedBox(
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _user!['avatar_url'] != null
                      ? NetworkImage(_user!['avatar_url'])
                      : null,
                  child: _user!['avatar_url'] == null
                      ? Icon(Icons.person, size: 40)
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?['username'] ?? '',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatLine(followersCount, 'profile_page.followers'.tr(), Theme.of(context).colorScheme.secondary),
                          SizedBox(width: 8),
                          _buildStatLine(subscribersCount, 'profile_page.subscribers'.tr(), Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (bio.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bio,
                    maxLines: _showFullBio ? null : 2,
                    overflow: _showFullBio ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14),
                  ),
                  if (_shouldShowReadMore(bio))
                    TextButton(
                      onPressed: () => setState(() => _showFullBio = !_showFullBio),
                      child: Text(_showFullBio ? "core.less".tr() : "core.more".tr(), style: TextStyle(color: Colors.grey[600])),
                    ),
                ],
              ),

            if (_isAuthenticated) SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isOwnProfile) ...[
                  ElevatedButton.icon(
                    onPressed: () => context.go('/${_user?['username']}/edit'),
                    icon: Icon(Icons.edit),
                    label: Text("user.edit.edit_profile".tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ] else if (_isAuthenticated) ...[
                  ElevatedButton.icon(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    label: Text(_isFollowing == true
                      ? "profile_page.following".tr().capitalize()
                      : "profile_page.follow".tr().capitalize()
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {}, // TODO: abonnement
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    label: Text("profile_page.subscribe".tr().capitalize()),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatLine(int value, String label, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: MediaQuery.of(context).size.width < 768
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatNumber(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: color),
            ),
          ],
        )
        : Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatNumber(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: color),
            ),
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;
    final posts = context.watch<PostProvider>().userPosts;
    final isLoadingPosts = context.watch<PostProvider>().isLoading;

    if (_isLoading) {
      return ScaffoldWithMenubar(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return ScaffoldWithMenubar(body: Center(child: Text("user.not_found".tr())));
    }

    return ScaffoldWithMenubar(
      body: RefreshIndicator(
        onRefresh: () async => await _initProfile(),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                Text("post.my_posts".tr(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          formatNumber(postsCount),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        SizedBox(width: 4),
                        Text("profile_page.posts".tr(), style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                      ],
                    ),
                    SizedBox(width: 16),
                    Row(
                      children: [
                        Text("core.including".tr(), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        SizedBox(width: 4),
                        Text(
                          formatNumber(paidPostsCount),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        SizedBox(width: 4),
                        Text("profile_page.premium".tr(), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                PostGrid(posts: posts, isLoading: isLoadingPosts),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

