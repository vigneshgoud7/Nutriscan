import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/onboarding/health_profile_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/compare/compare_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/history/conversation_detail_screen.dart';
import '../screens/settings/settings_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final location = state.uri.path;

      if (isLoading) return '/splash';

      final authRoutes = ['/signin', '/signup'];
      final isAuthRoute = authRoutes.contains(location);
      final isSplash = location == '/splash';

      if (!isAuthenticated) {
        if (!isAuthRoute) return '/signin';
        return null;
      }

      if (authState.isNewUser) {
        if (location != '/onboarding/profile') {
          return '/onboarding/profile';
        }
        return null;
      } else {
        if (isAuthRoute || isSplash) {
          return '/home';
        }
        return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/signin', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/onboarding/profile', builder: (_, __) => const HealthProfileScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const ChatScreen()),
          GoRoute(path: '/compare', builder: (_, __) => const CompareScreen()),
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/conversation/:id',
        builder: (_, state) => ConversationDetailScreen(sessionId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
