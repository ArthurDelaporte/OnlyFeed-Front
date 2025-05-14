import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/features/auth/presentation/login_page.dart';
import 'package:onlyfeed_frontend/features/auth/presentation/signup_page.dart';
import 'package:onlyfeed_frontend/features/home/presentation/home_page.dart';
import 'package:onlyfeed_frontend/features/profile/presentation/profile_page.dart';
import 'package:onlyfeed_frontend/features/profile/presentation/edit_profile_page.dart';
import 'package:onlyfeed_frontend/features/profile/presentation/public_profile_page.dart';
import 'package:onlyfeed_frontend/features/post/presentation/create_post_page.dart';
import 'package:onlyfeed_frontend/shared/notifiers/session_notifier.dart';

class OnlyFeedApp {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => HomePage()),
      GoRoute(path: '/account/login', builder: (context, state) => LoginPage()),
      GoRoute(path: '/account/signup', builder: (context, state) => SignupPage()),
      GoRoute(
        path: '/:username',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          final usernameConnected = context.read<SessionNotifier>().user?['username'];
          if (username == usernameConnected) return ProfilePage();
          return PublicProfilePage(username: username);
        },
      ),
      GoRoute(
        path: '/:username/edit',
        builder: (context, state) => EditProfilePage(),
        redirect: (context, state){
          final username = state.pathParameters['username']!;
          final usernameConnected = context.read<SessionNotifier>().user?['username'];
          if (username == usernameConnected) return null;
          return '/account/login';
        }
      ),
      GoRoute(path: '/create-post', builder: (context, state) => CreatePostPage()),
    ],
  );
}
