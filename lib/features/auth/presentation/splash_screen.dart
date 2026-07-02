import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

/// Splash screen that checks authentication state and auto-routes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for the animation to finish and a short delay to display the brand identity
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final authState = ref.read(authStateChangesProvider);

    authState.when(
      data: (user) {
        if (user != null) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.login);
        }
      },
      error: (_, __) {
        // Fallback to login in case of error
        context.go(AppRoutes.login);
      },
      loading: () {
        // If still loading, wait for redirect logic in GoRouter to handle it
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emeraldDark,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Symbol
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.mosque_rounded,
                    color: AppColors.gold,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // App Title
              Text(
                'منبر المسجد',
                style: GoogleFonts.tajawal(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'تطبيق الإمام والمؤذن للمسجد',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.goldPale.withValues(alpha: 0.7),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 48),
              // Simple elegant loading indicator
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
