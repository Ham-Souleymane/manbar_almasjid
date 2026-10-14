import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import '../../auth/presentation/widgets/google_sign_in_button.dart';
import '../../auth/presentation/widgets/apple_sign_in_button.dart';
import '../application/registration_controller.dart';
import '../data/registration_repository.dart';
import 'widgets/registration_progress_indicator.dart';

class ImamRegistrationScreen extends ConsumerStatefulWidget {
  const ImamRegistrationScreen({super.key});

  @override
  ConsumerState<ImamRegistrationScreen> createState() =>
      _ImamRegistrationScreenState();
}

class _ImamRegistrationScreenState extends ConsumerState<ImamRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCreatingAccount = false;

  /// null = not answered yet, true = has mosque, false = no mosque
  bool? _hasMosque;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(firebaseAuthProvider).currentUser;
      final regEmail = ref.read(registrationControllerProvider).email;
      if (user != null) {
        if (user.email != null) {
          _emailController.text = user.email!;
        }
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          _fullNameController.text = user.displayName!;
        }
      } else if (regEmail.isNotEmpty) {
        _emailController.text = regEmail;
      }
      // Restore previous mosque choice from state (in case user navigated back)
      final prevHasMosque = ref.read(registrationControllerProvider).hasMosque;
      if (prevHasMosque != null) setState(() => _hasMosque = prevHasMosque);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSocialSignInSuccess(User user) async {
    final imam = await ref.read(registrationRepositoryProvider).getImam(user.uid);
    if (!mounted) return;

    // If imam is already fully registered WITH a mosque, go directly to home
    if (imam != null && imam.mosqueId != null) {
      context.go(AppRoutes.home);
      return;
    }

    final imamName = (imam != null && imam.fullName.isNotEmpty)
        ? imam.fullName
        : (_fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : (user.displayName ?? ''));
    final imamPhone = (imam != null && imam.phone.isNotEmpty)
        ? imam.phone
        : _phoneController.text.trim();
    final imamEmail = (imam != null && imam.email.isNotEmpty)
        ? imam.email
        : (user.email ?? '');

    ref.read(registrationControllerProvider.notifier).setImamStep(
          fullName: imamName,
          phone: imamPhone,
          email: imamEmail,
        );

    // Check effective mosque choice: screen state takes precedence, fallback to provider state
    final effectiveHasMosque =
        _hasMosque ?? ref.read(registrationControllerProvider).hasMosque;

    if (effectiveHasMosque == true) {
      ref.read(registrationControllerProvider.notifier).setHasMosque(true);
      context.go(AppRoutes.registerMosque);
    } else if (effectiveHasMosque == false) {
      ref.read(registrationControllerProvider.notifier).setHasMosque(false);
      context.go(AppRoutes.askFeatureSetup);
    } else {
      // User hasn't chosen yet: prefill form and prompt user
      _fullNameController.text = imamName;
      _emailController.text = imamEmail;
      if (imamPhone.isNotEmpty) _phoneController.text = imamPhone;
      context.showSnackBar(
        context.l10n.hasMosqueQuestion,
        isError: true,
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      context.showSnackBar(state.errorMessage ?? context.l10n.failedGoogleLogin, isError: true);
      return;
    }

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      await _handleSocialSignInSuccess(user);
    }
  }

  Future<void> _signInWithApple() async {
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signInWithApple();
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      context.showSnackBar(state.errorMessage ?? context.l10n.failedAppleLogin, isError: true);
      return;
    }

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      await _handleSocialSignInSuccess(user);
    }
  }

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasMosque == null) {
      context.showSnackBar(
        context.l10n.hasMosqueQuestion,
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final isAuthenticated = ref.read(firebaseAuthProvider).currentUser != null;

    if (!isAuthenticated) {
      setState(() => _isCreatingAccount = true);
      await ref.read(authControllerProvider.notifier).createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;

      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        setState(() => _isCreatingAccount = false);
        context.showSnackBar(
          authState.errorMessage ?? context.l10n.anErrorOccurred,
          isError: true,
        );
        return;
      }
      setState(() => _isCreatingAccount = false);
    }

    ref.read(registrationControllerProvider.notifier).setImamStep(
          fullName: _fullNameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
        );

    ref.read(registrationControllerProvider.notifier).setHasMosque(_hasMosque!);

    if (!mounted) return;

    if (_hasMosque == true) {
      // Has mosque → proceed to mosque registration step
      context.go(AppRoutes.registerMosque);
    } else {
      // No mosque → skip mosque step, go directly to ask-feature setup
      context.go(AppRoutes.askFeatureSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authState = ref.watch(authControllerProvider);
    final authStateChanges = ref.watch(authStateChangesProvider);

    final isAlreadyAuthenticated = authStateChanges.asData?.value != null;
    final isLoading = _isCreatingAccount || authState.isLoading;

    // Show 2 steps if no mosque (imam data → ask setup), 3 if yes (imam data → mosque → ask setup)
    final totalSteps = _hasMosque == false ? 2 : 3;

    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      final user = next.asData?.value;
      if (user != null) {
        if (user.email != null) {
          _emailController.text = user.email!;
        }
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          _fullNameController.text = user.displayName!;
        }
      }
    });

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: Text(l10n.registerImam),
          centerTitle: true,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RegistrationProgressIndicator(
                    currentStep: 1,
                    totalSteps: totalSteps,
                    stepTitle: l10n.imamData,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.imamData,
                    style: GoogleFonts.tajawal(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.imamDataSubtitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: l10n.fullName,
                    hint: l10n.fullNameHint,
                    controller: _fullNameController,
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.enterFullName;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: l10n.contactPhone,
                    hint: l10n.phoneHint,
                    controller: _phoneController,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.enterPhone;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: l10n.email,
                    hint: l10n.emailHint,
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: isAlreadyAuthenticated,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.enterEmail;
                      if (!v.trim().isValidEmail) return l10n.invalidEmail;
                      return null;
                    },
                  ),
                  if (!isAlreadyAuthenticated) ...[
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: l10n.password,
                      hint: l10n.passwordHint,
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.enterPassword;
                        if (v.length < 6) return l10n.passwordMinLength;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: l10n.confirmPassword,
                      hint: l10n.passwordHint,
                      controller: _confirmPasswordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.enterConfirmPassword;
                        if (v != _passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.orDivider,
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              color: AppColors.grey500,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.divider)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GoogleSignInButton(
                      label: l10n.continueWithGoogle,
                      onPressed: isLoading ? null : _signInWithGoogle,
                      isLoading: isLoading && authState.isLoading,
                    ),
                    const SizedBox(height: 12),
                    AppleSignInButton(
                      label: l10n.continueWithApple,
                      onPressed: isLoading ? null : _signInWithApple,
                      isLoading: isLoading && authState.isLoading,
                    ),
                  ],

                  // ── Mosque question ─────────────────────────────
                  const SizedBox(height: 28),
                  Text(
                    context.l10n.hasMosqueQuestion,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.hasMosqueSubtitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _MosqueChoiceCard(
                            label: context.l10n.hasMosqueYes,
                            icon: Icons.check_circle_outline_rounded,
                            selected: _hasMosque == true,
                            selectedColor: AppColors.emerald,
                            onTap: () => setState(() => _hasMosque = true),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MosqueChoiceCard(
                            label: context.l10n.hasMosqueNo,
                            icon: Icons.cancel_outlined,
                            selected: _hasMosque == false,
                            selectedColor: Color(0xFFD97706),
                            onTap: () => setState(() => _hasMosque = false),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  AppButton(
                    label: l10n.next,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _onNext,
                  ),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mosque choice card ──────────────────────────────────────────────────────
class _MosqueChoiceCard extends StatelessWidget {
  const _MosqueChoiceCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade300,
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? selectedColor.withValues(alpha: 0.15)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: selected ? selectedColor : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? selectedColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
