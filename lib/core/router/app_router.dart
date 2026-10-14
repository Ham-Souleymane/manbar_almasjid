import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/firebase_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/registration/application/registration_controller.dart';
import '../../features/registration/data/registration_repository.dart';
import '../../features/registration/domain/imam_status.dart';
import '../../features/registration/presentation/ask_feature_setup_screen.dart';
import '../../features/registration/presentation/imam_registration_screen.dart';
import '../../features/registration/presentation/mosque_registration_screen.dart';
import '../../features/registration/presentation/under_review_screen.dart';
import '../../features/mosque/presentation/home_dashboard_screen.dart';
import '../../features/prayer_times/presentation/prayer_times_screen.dart';
import '../../features/forum/presentation/discover_groups_screen.dart';
import '../../features/forum/presentation/imam_group_chat_screen.dart';

// ── Route names ───────────────────────────────────────────────
abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const registerImam = '/register/imam';
  static const registerMosque = '/register/mosque';
  static const askFeatureSetup = '/register/ask-setup';
  static const underReview = '/under-review';
  static const home = '/home';
  static const prayerTimes = '/prayer-times';
  static const imamForum = '/imam-forum';
  static const imamGroupChat = '/imam-forum/chat';
}

/// Notifier that triggers GoRouter redirect re-evaluation without
/// disposing and recreating the GoRouter instance.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    ref.listen(currentImamProvider, (_, __) => notifyListeners());
    ref.listen(isAdminProvider, (_, __) => notifyListeners());
    ref.listen(registrationControllerProvider, (_, __) => notifyListeners());
  }
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

// ── Router provider ───────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.matchedLocation;

      const registrationRoutes = {
        AppRoutes.registerImam,
        AppRoutes.registerMosque,
        AppRoutes.askFeatureSetup,
      };

      final authState = ref.read(authStateChangesProvider);
      final imamState = ref.read(currentImamProvider);
      final isAdminAsync = ref.read(isAdminProvider);
      final regState = ref.read(registrationControllerProvider);

      // ── While auth is still initializing, stay on splash ──
      if (authState.isLoading) {
        if (location != AppRoutes.splash) return AppRoutes.splash;
        return null;
      }

      final user = authState.asData?.value;
      final isLoggedIn = user != null;

      // ── Not logged in ──
      if (!isLoggedIn) {
        // Splash → login
        if (location == AppRoutes.splash) return AppRoutes.login;
        // Allow login page and all registration pages (email signup creates account mid-flow)
        if (location == AppRoutes.login) return null;
        if (registrationRoutes.contains(location)) return null;
        // Anything else → login
        return AppRoutes.login;
      }

      // ── Logged in: wait for imam profile + admin status ──
      if (imamState.isLoading || isAdminAsync.isLoading) {
        // Stay on splash or current registration screen while loading
        if (location == AppRoutes.splash || registrationRoutes.contains(location)) {
          return null;
        }
        return AppRoutes.splash;
      }

      final isAdmin = isAdminAsync.asData?.value ?? false;
      final imam = imamState.asData?.value;

      // ── Admin: always go home ──
      if (isAdmin) {
        if (location == AppRoutes.home) return null;
        if (registrationRoutes.contains(location) ||
            location == AppRoutes.login ||
            location == AppRoutes.splash ||
            location == AppRoutes.underReview) {
          return AppRoutes.home;
        }
        return null;
      }

      // ── No imam profile yet (brand new user) ──
      if (imam == null) {
        if (registrationRoutes.contains(location)) return null;
        if (location == AppRoutes.login) return null;
        return AppRoutes.registerImam;
      }

      // ── Blocked imam ──
      if (imam.status == ImamStatus.blocked) {
        if (location == AppRoutes.underReview) return null;
        return AppRoutes.underReview;
      }

      // ── Rejected imam → re-register ──
      if (imam.status == ImamStatus.rejected) {
        if (registrationRoutes.contains(location)) return null;
        return AppRoutes.registerImam;
      }

      // ── Verified imam without mosque ──
      if (imam.mosqueId == null) {
        if (registrationRoutes.contains(location)) return null;
        if (location == AppRoutes.login) return null;
        // Splash → home (or mosque if mid-flow)
        if (location == AppRoutes.splash) {
          return regState.hasMosque == true ? AppRoutes.registerMosque : AppRoutes.home;
        }
        // Let them stay on home with the banner to register mosque
        return null;
      }

      // ── Fully registered imam with mosque ──
      // Kick them off any auth/registration screen back to home
      if (location == AppRoutes.splash ||
          location == AppRoutes.login ||
          registrationRoutes.contains(location) ||
          location == AppRoutes.underReview) {
        return AppRoutes.home;
      }

      return null;
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
        path: AppRoutes.registerImam,
        name: 'registerImam',
        builder: (context, state) => const ImamRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerMosque,
        name: 'registerMosque',
        builder: (context, state) => const MosqueRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.askFeatureSetup,
        name: 'askFeatureSetup',
        builder: (context, state) => const AskFeatureSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.underReview,
        name: 'underReview',
        builder: (context, state) => const UnderReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.prayerTimes,
        name: 'prayerTimes',
        builder: (context, state) {
          final mosqueId = state.extra as String? ?? '';
          return PrayerTimesScreen(mosqueId: mosqueId);
        },
      ),
      GoRoute(
        path: AppRoutes.imamForum,
        name: 'imamForum',
        builder: (context, state) => const DiscoverGroupsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.imamGroupChat}/:groupId',
        name: 'imamGroupChat',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId'] ?? '';
          return ImamGroupChatScreen(groupId: groupId);
        },
      ),
    ],
  );
});
