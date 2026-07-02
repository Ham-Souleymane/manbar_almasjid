import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/firebase_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';

// ── Route names ───────────────────────────────────────────────
abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home'; // placeholder – will be built later
}

// ── Router provider ───────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // While auth state is loading, stay on splash
      if (authState.isLoading) return AppRoutes.splash;

      final user = authState.asData?.value;
      final isLoggedIn = user != null;
      final isGoingToLogin = state.matchedLocation == AppRoutes.login;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      // Not logged in → send to login
      if (!isLoggedIn && !isGoingToLogin && !isOnSplash) {
        return AppRoutes.login;
      }

      // Logged in but still on login/splash → send to home
      if (isLoggedIn && (isGoingToLogin || isOnSplash)) {
        return AppRoutes.home;
      }

      return null; // no redirect
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        // Placeholder home – replace with real home screen later
        builder: (context, state) => const _PlaceholderHomeScreen(),
      ),
    ],
  );
});

// ── Temporary home placeholder ────────────────────────────────
class _PlaceholderHomeScreen extends StatelessWidget {
  const _PlaceholderHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرئيسية')),
      body: const Center(
        child: Text(
          'مرحباً بك في منبر المسجد',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
