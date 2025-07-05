import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:onlyfeed_frontend/features/auth/presentation/login_page.dart';
import 'package:onlyfeed_frontend/features/auth/presentation/signup_page.dart';
import 'package:onlyfeed_frontend/features/home/presentation/home_page.dart';
import 'package:onlyfeed_frontend/features/profile/presentation/profile_page.dart';
import 'package:onlyfeed_frontend/features/profile/presentation/edit_profile_page.dart';
import 'package:onlyfeed_frontend/features/post/presentation/create_post_page.dart';
import 'package:onlyfeed_frontend/features/post/presentation/post_detail_page.dart';
import 'package:onlyfeed_frontend/features/admin/presentation/admin_dashboard_page.dart';
import 'package:onlyfeed_frontend/core/pages/not_found_page.dart';
import 'package:onlyfeed_frontend/shared/notifiers/session_notifier.dart';

// Imports pour la messagerie
import 'package:onlyfeed_frontend/features/message/presentation/conversations_page.dart';
import 'package:onlyfeed_frontend/features/message/presentation/chat_page.dart';
import 'package:onlyfeed_frontend/features/message/presentation/chat_page_with_username.dart';
import 'package:onlyfeed_frontend/features/message/model/message_model.dart';
import 'package:onlyfeed_frontend/features/message/presentation/user_search_page.dart';

class OnlyFeedApp {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => HomePage()),

      // Routes d'authentification
      GoRoute(
        path: '/account/login',
        builder: (context, state) => LoginPage(),
        redirect: (context, state){
          final userConnected = context.read<SessionNotifier>().user;
          final username = userConnected?["username"];
          if (userConnected != null) return '/$username';
          return null;
        }
      ),
      GoRoute(path: '/account/signup', builder: (context, state) => SignupPage()),

      // Routes de messagerie (avec préfixe /app/ pour éviter les conflits)
      GoRoute(
        path: '/app/messages',
        name: 'conversations',
        builder: (context, state) => ConversationsPage(),
      ),
      GoRoute(
        path: '/app/messages/search',
        name: 'search_users',
        builder: (context, state) => UserSearchPage(),
      ),
      GoRoute(
        path: '/app/messages/chat/:username',
        name: 'chat_with_user',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return ChatPageWithUsername(username: username);
        },
      ),

      // Routes legacy pour compatibilité (optionnel - à supprimer plus tard si non utilisées)
      GoRoute(
        path: '/app/messages/chat/id/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null || extra['otherUser'] == null) {
            return ConversationsPage();
          }

          return ChatPage(
            conversationId: conversationId,
            otherUser: extra['otherUser'] as ConversationUser,
          );
        },
      ),
      GoRoute(
        path: '/app/messages/new',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ChatPage(
            otherUser: extra['otherUser'] as ConversationUser,
            isNewConversation: true,
          );
        },
      ),

      // Routes de profil (structure GitHub maintenue)
      GoRoute(
        path: '/:username',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return ProfilePage(username: username);
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => EditProfilePage(),
            redirect: (context, state){
              final username = state.pathParameters['username']!;
              final usernameConnected = context.read<SessionNotifier>().user?['username'];
              if (username == usernameConnected) return null;
              return '/account/login';
            }
          ),
          GoRoute(
            path: 'create',
            builder: (context, state) {
              final username = state.pathParameters['username']!;
              return CreatePostPage(username: username);
            },
            redirect: (context, state){
              final username = state.pathParameters['username']!;
              final usernameConnected = context.read<SessionNotifier>().user?['username'];
              if (username == usernameConnected) return null;
              return '/account/login';
            }
          ),
          // 🆕 NOUVELLE ROUTE POUR LES POSTS
          GoRoute(
            path: 'post/:postId',
            name: 'post_detail',
            builder: (context, state) {
              final username = state.pathParameters['username']!;
              final postId = state.pathParameters['postId']!;
              return PostDetailPage(
                username: username,
                postId: postId,
              );
            },
          ),
        ]
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) {
          final isAdmin = context.read<SessionNotifier>().user?['is_admin'];
          if (isAdmin == null || isAdmin == false) return NotFoundPage();
          return AdminDashboardPage();
        },
      )
    ],
    errorBuilder: (context, state) => NotFoundPage(),
  );
}