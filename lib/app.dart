import 'package:go_router/go_router.dart';

import 'package:onlyfeed_frontend/features/auth/presentation/login_page.dart';
import 'package:onlyfeed_frontend/features/auth/presentation/signup_page.dart';
import 'package:onlyfeed_frontend/features/home/presentation/home_page.dart';
import 'package:onlyfeed_frontend/features/profile/presentation/profile_page.dart';
import 'package:onlyfeed_frontend/features/profile/presentation/edit_profile_page.dart';
import 'package:onlyfeed_frontend/features/profile/presentation/public_profile_page.dart';
import 'package:onlyfeed_frontend/features/post/presentation/create_post_page.dart';
import 'package:onlyfeed_frontend/shared/notifiers/theme_notifier.dart';
import 'package:provider/provider.dart';


class OnlyFeedApp {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => HomePage()),
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => SignupPage()),
      // GoRoute(path: '/profile', builder: (context, state) => ProfilePage(), redirect: (context, state){
      //   bool isConnected = false;
      //   if(isConnected){
      //     return null;
      //   }
      //
      //   return '/login';
      // }),
      GoRoute(path: '/profile', builder: (context, state) => ProfilePage()),
      GoRoute(path: '/profile/edit', builder: (context, state) => EditProfilePage()),
      GoRoute(path: '/create-post', builder: (context, state) => CreatePostPage()),
      GoRoute(
        path: '/u/:username',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return PublicProfilePage(username: username);
        },
      ),
    ],
  );
}
