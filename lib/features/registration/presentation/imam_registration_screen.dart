import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import '../application/registration_controller.dart';
import 'widgets/document_upload_area.dart';
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

  File? _verificationDocument;
  bool _isCreatingAccount = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(firebaseAuthProvider).currentUser;
      final regEmail = ref.read(registrationControllerProvider).email;
      if (user?.email != null) {
        _emailController.text = user!.email!;
      } else if (regEmail.isNotEmpty) {
        _emailController.text = regEmail;
      }
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

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verificationDocument == null) {
      context.showSnackBar('يرجى رفع مستند التحقق', isError: true);
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
          authState.errorMessage ?? 'حدث خطأ',
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
          verificationDocument: _verificationDocument,
        );

    if (mounted) context.go(AppRoutes.registerMosque);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isCreatingAccount;
    final isAlreadyAuthenticated =
        ref.watch(firebaseAuthProvider).currentUser != null;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('تسجيل الإمام'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const RegistrationProgressIndicator(currentStep: 1),
                  const SizedBox(height: 28),
                  Text(
                    'بيانات الإمام',
                    style: GoogleFonts.tajawal(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldDark,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أدخل معلوماتك الشخصية ومستند التحقق',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: AppColors.grey500,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: 'الاسم الكامل',
                    hint: 'محمد أحمد',
                    controller: _fullNameController,
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل الاسم الكامل';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'رقم الهاتف',
                    hint: '+966 5XX XXX XXXX',
                    controller: _phoneController,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل رقم الهاتف';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'البريد الإلكتروني',
                    hint: 'imam@masjid.com',
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: isAlreadyAuthenticated,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                      if (!v.trim().isValidEmail) return 'البريد الإلكتروني غير صالح';
                      return null;
                    },
                  ),
                  if (!isAlreadyAuthenticated) ...[
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'كلمة المرور',
                      hint: '••••••••',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                        if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'تأكيد كلمة المرور',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أكّد كلمة المرور';
                        if (v != _passwordController.text) {
                          return 'كلمتا المرور غير متطابقتين';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  DocumentUploadArea(
                    file: _verificationDocument,
                    onFileSelected: (file) =>
                        setState(() => _verificationDocument = file),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'التالي',
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
