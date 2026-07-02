import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/router/app_router.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';
import 'widgets/apple_sign_in_button.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/google_sign_in_button.dart';

enum _AuthMode { login, register }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  _AuthMode _mode = _AuthMode.login;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animController.reverse().then((_) {
      setState(() {
        _mode =
            _mode == _AuthMode.login ? _AuthMode.register : _AuthMode.login;
        _formKey.currentState?.reset();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
      _animController.forward();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final controller = ref.read(authControllerProvider.notifier);

    if (_mode == _AuthMode.login) {
      await controller.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      await controller.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      context.showSnackBar(state.errorMessage ?? 'حدث خطأ', isError: true);
    }
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      context.showSnackBar(state.errorMessage ?? 'فشل تسجيل الدخول عبر Google', isError: true);
    }
  }

  Future<void> _signInWithApple() async {
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signInWithApple();
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      context.showSnackBar(state.errorMessage ?? 'فشل تسجيل الدخول عبر Apple', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    // Navigate away once authenticated
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next.isAuthenticated) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      _buildHeader(),
                      const SizedBox(height: 36),
                      _buildCard(isLoading),
                      const SizedBox(height: 24),
                      _buildToggleModeButton(),
                      const Spacer(),
                      _buildFooter(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // Mosque icon in gold circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.emeraldDark, AppColors.emerald],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.mosque_rounded,
            color: AppColors.gold,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'منبر المسجد',
          style: GoogleFonts.tajawal(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.emeraldDark,
            height: 1.2,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        Text(
          _mode == _AuthMode.login
              ? 'أهلاً بعودتك — سجّل دخولك للمتابعة'
              : 'أنشئ حسابك الجديد',
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.grey500,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Card ──────────────────────────────────────────────────
  Widget _buildCard(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldDark.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email
            AuthTextField(
              label: 'البريد الإلكتروني',
              hint: 'imam@masjid.com',
              controller: _emailController,
              focusNode: _emailFocusNode,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                if (!v.trim().isValidEmail) return 'البريد الإلكتروني غير صالح';
                return null;
              },
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocusNode),
            ),
            const SizedBox(height: 16),

            // Password
            AuthTextField(
              label: 'كلمة المرور',
              hint: '••••••••',
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: _mode == _AuthMode.login
                  ? TextInputAction.done
                  : TextInputAction.next,
              autofillHints: const [AutofillHints.password],
              validator: (v) {
                if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
                return null;
              },
              onFieldSubmitted: (_) {
                if (_mode == _AuthMode.login) {
                  _submit();
                } else {
                  FocusScope.of(context).requestFocus(_confirmFocusNode);
                }
              },
            ),

            // Confirm Password (register only)
            if (_mode == _AuthMode.register) ...[
              const SizedBox(height: 16),
              AuthTextField(
                label: 'تأكيد كلمة المرور',
                hint: '••••••••',
                controller: _confirmPasswordController,
                focusNode: _confirmFocusNode,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'أكّد كلمة المرور';
                  if (v != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ],

            // Forgot password
            if (_mode == _AuthMode.login) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : _showForgotPasswordSheet,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Primary CTA
            _PrimaryButton(
              label: _mode == _AuthMode.login ? 'تسجيل الدخول' : 'إنشاء الحساب',
              isLoading: isLoading,
              onPressed: _submit,
            ),

            const SizedBox(height: 16),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'أو',
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

            // Google Sign-In
            GoogleSignInButton(
              onPressed: isLoading ? null : _signInWithGoogle,
              isLoading: isLoading && ref.read(authControllerProvider).isLoading,
            ),

            // Apple Sign-In
            const SizedBox(height: 12),
            AppleSignInButton(
              onPressed: isLoading ? null : _signInWithApple,
              isLoading: isLoading && ref.read(authControllerProvider).isLoading,
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle Mode ───────────────────────────────────────────
  Widget _buildToggleModeButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _mode == _AuthMode.login
              ? 'ليس لديك حساب؟'
              : 'لديك حساب بالفعل؟',
          style: GoogleFonts.tajawal(
            fontSize: 14,
            color: AppColors.grey500,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _toggleMode,
          child: Text(
            _mode == _AuthMode.login ? 'أنشئ حساباً' : 'تسجيل الدخول',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.emerald,
            ),
          ),
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────
  Widget _buildFooter() {
    return Text(
      '© 2025 منبر المسجد – جميع الحقوق محفوظة',
      style: GoogleFonts.tajawal(
        fontSize: 11,
        color: AppColors.grey300,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }

  // ── Forgot Password Sheet ──────────────────────────────────
  void _showForgotPasswordSheet() {
    final emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPasswordSheet(
        emailController: emailController,
        onSend: (email) async {
          Navigator.pop(context);
          await ref
              .read(authControllerProvider.notifier)
              .sendPasswordResetEmail(email);
          if (!mounted) return;
          context.showSnackBar('تم إرسال رابط إعادة تعيين كلمة المرور إلى $email');
        },
      ),
    );
  }
}

// ── Primary Button ─────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [AppColors.emerald, AppColors.emeraldMedium],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            height: 54,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Forgot Password Bottom Sheet ──────────────────────────
class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({
    required this.emailController,
    required this.onSend,
  });

  final TextEditingController emailController;
  final void Function(String email) onSend;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'إعادة تعيين كلمة المرور',
              style: GoogleFonts.tajawal(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.emeraldDark,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: AppColors.grey500,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                if (!v.trim().isValidEmail) return 'البريد الإلكتروني غير صالح';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_key.currentState!.validate()) {
                  widget.onSend(widget.emailController.text.trim());
                }
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}
