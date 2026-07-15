import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/providers/firebase_providers.dart';

/// Abstract interface for authentication operations.
abstract class IAuthRepository {
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserCredential?> signInWithGoogle();

  Future<UserCredential?> signInWithApple();

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);
}

// ── Implementation ───────────────────────────────────────────
class AuthRepository implements IAuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  // google_sign_in v7: use the singleton, not a constructor
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  // Web Client ID (client_type: 3) from google-services.json.
  // Required on Android for Google Sign-In to work.
  static const _webClientId =
      '934105443254-o2sdu3n2avnn6ciqjpoadmiq2rmdidfd.apps.googleusercontent.com';

  /// Initializes google_sign_in exactly once.
  Future<void> _ensureGoogleInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize(
      serverClientId: _webClientId,
    );
    _googleSignInInitialized = true;
  }

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email / Password ─────────────────────────────────────────
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── Google Sign-In ───────────────────────────────────────────
  @override
  Future<UserCredential?> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      // v7 API: authenticate() replaces the old signIn()
      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      // v7 API: authentication is a synchronous getter, not a Future
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // v7 API: accessToken is no longer on GoogleSignInAuthentication;
      // Firebase only requires idToken for sign-in.
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException caught: code=${e.code}, description=${e.description}');
      // User tapped "Cancel" — treat as a silent no-op.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    } catch (e, stack) {
      debugPrint('Unexpected error in signInWithGoogle: $e\n$stack');
      rethrow;
    }
  }

  // ── Apple Sign-In ────────────────────────────────────────────
  @override
  Future<UserCredential?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final shaNonce = _sha256ofString(rawNonce);

    WebAuthenticationOptions? webOptions;
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
      webOptions = WebAuthenticationOptions(
        clientId: 'com.manbar.manbarAlmasjid.service',
        redirectUri: Uri.parse(
            'https://dinapp-3eadd.firebaseapp.com/__/auth/handler'),
      );
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: shaNonce,
      webAuthenticationOptions: webOptions,
    );

    final credential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    return _auth.signInWithCredential(credential);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.-_';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ── Sign Out ──────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    await _ensureGoogleInitialized();
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── Password Reset ────────────────────────────────────────────
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}

// ── Riverpod Provider ─────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});
