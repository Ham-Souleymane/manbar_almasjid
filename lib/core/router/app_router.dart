import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/firebase_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
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

// ── Router provider ───────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final imamState = ref.watch(currentImamProvider);
  final isAdminAsync = ref.watch(isAdminProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (authState.isLoading || imamState.isLoading || isAdminAsync.isLoading) {
        if (location != AppRoutes.splash) return AppRoutes.splash;
        return null;
      }

      final user = authState.asData?.value;
      final isLoggedIn = user != null;
      final isAdmin = isAdminAsync.asData?.value ?? false;
      final imam = imamState.asData?.value;

      const publicRoutes = {AppRoutes.splash, AppRoutes.login};
      const registrationRoutes = {
        AppRoutes.registerImam,
        AppRoutes.registerMosque,
        AppRoutes.askFeatureSetup,
      };

      // Splash → resolve destination once auth + profile are loaded
      if (location == AppRoutes.splash) {
        if (!isLoggedIn) return AppRoutes.login;
        if (isAdmin) return AppRoutes.home;
        if (imam == null) return AppRoutes.registerImam;
        if (imam.status == ImamStatus.blocked) {
          return AppRoutes.underReview;
        }
        if (imam.status == ImamStatus.rejected) return AppRoutes.registerImam;
        return AppRoutes.home;
      }

      if (!isLoggedIn) {
        if (location == AppRoutes.registerImam) return null;
        if (!publicRoutes.contains(location)) return AppRoutes.login;
        return null;
      }

      // Admin bypasses all registration/under review checks and goes directly to home
      if (isAdmin) {
        if (publicRoutes.contains(location) ||
            registrationRoutes.contains(location) ||
            location == AppRoutes.underReview) {
          return AppRoutes.home;
        }
        return null;
      }

      // Logged in — no imam profile yet → registration flow
      if (imam == null) {
        if (!registrationRoutes.contains(location)) return AppRoutes.registerImam;
        return null;
      }

      // Blocked → under review screen
      if (imam.status == ImamStatus.blocked) {
        if (location != AppRoutes.underReview) return AppRoutes.underReview;
        return null;
      }

      // Verified → home; rejected → allow re-registration
      if (imam.status == ImamStatus.rejected) {
        if (!registrationRoutes.contains(location)) return AppRoutes.registerImam;
        return null;
      }

      // Verified imam — allow mosque/ask-setup routes if they have no mosque
      // (accessing from settings to add mosque later)
      final verifiedMosqueRoutes = {
        AppRoutes.registerMosque,
        AppRoutes.askFeatureSetup,
      };
      if (imam.mosqueId == null &&
          (verifiedMosqueRoutes.contains(location) ||
              location == AppRoutes.registerImam)) {
        return null; // let them through
      }

      if (publicRoutes.contains(location) ||
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
