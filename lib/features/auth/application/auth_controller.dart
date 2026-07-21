import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

/// Riverpod [Notifier] that manages auth operations and exposes [AuthState].
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Listen to Firebase auth state stream and keep controller in sync.
    // We only update from the stream when we are NOT in the middle of an
    // operation (loading) so we don't race against explicit state sets.
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      next.when(
        data: (user) {
          // Don't override an error state that was just set by a method.
          if (state.status == AuthStatus.error) return;
          if (user != null) {
            state = AuthState(status: AuthStatus.authenticated, user: user);
          } else if (state.status != AuthStatus.loading) {
            // Only go to unauthenticated if we're not mid-operation
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
        },
        error: (err, stack) {
          debugPrint('[AuthController] stream error: $err');
          state = AuthState(
              status: AuthStatus.error, errorMessage: err.toString());
        },
        loading: () {
          if (state.status == AuthStatus.initial) {
            state = state.copyWith(status: AuthStatus.loading);
          }
        },
      );
    });
    return const AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  // ── Helpers ──────────────────────────────────────────────────
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لم يتم العثور على حساب بهذا البريد الإلكتروني.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      case 'invalid-credential':
        return 'بيانات الاعتماد غير صحيحة. تحقق من البريد وكلمة المرور.';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم بالفعل.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة. يجب أن تكون 6 أحرف على الأقل.';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح.';
      case 'too-many-requests':
        return 'محاولات كثيرة. الرجاء الانتظار ثم المحاولة مجددًا.';
      case 'network-request-failed':
        return 'فشل الاتصال بالشبكة. تحقق من الإنترنت.';
      case 'account-exists-with-different-credential':
        return 'الحساب موجود بطريقة تسجيل دخول مختلفة.';
      default:
        return 'حدث خطأ غير متوقع: ${e.message}';
    }
  }

  // ── Sign In ──────────────────────────────────────────
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      debugPrint('[AuthController] signInWithEmailAndPassword: email=$email');
      final credential = await _repo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[AuthController] sign-in success: uid=${credential.user?.uid}');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: credential.user,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthController] FirebaseAuthException: code=${e.code}, message=${e.message}');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      );
    } catch (e, stack) {
      debugPrint('[AuthController] Unexpected error in signIn: $e\n$stack');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'حدث خطأ غير متوقع.',
      );
    }
  }

  // ── Sign Up ────────────────────────────────────────────────
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final credential = await _repo.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: credential.user,
      );
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'حدث خطأ غير متوقع.',
      );
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final credential = await _repo.signInWithGoogle();
      if (credential == null) {
        // User cancelled
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        user: credential.user,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException in signInWithGoogle: code=${e.code}, message=${e.message}');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      );
    } catch (e, stack) {
      debugPrint('Unexpected error in AuthController.signInWithGoogle: $e\n$stack');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'فشل تسجيل الدخول عبر Google. ($e)',
      );
    }
  }

  // ── Apple Sign-In ──────────────────────────────────────────
  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final credential = await _repo.signInWithApple();
      if (credential == null) {
        // User cancelled
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        user: credential.user,
      );
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'فشل تسجيل الدخول عبر Apple.',
      );
    }
  }

  // ── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _repo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── Password Reset ────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.sendPasswordResetEmail(email);
      state = const AuthState(status: AuthStatus.unauthenticated);
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      );
    }
  }
}

// ── Provider ─────────────────────────────────────────────────
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
