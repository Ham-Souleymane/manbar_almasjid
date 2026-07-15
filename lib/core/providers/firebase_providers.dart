import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Firebase Auth ─────────────────────────────────────────────
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Stream of the current [User] (null when signed out).
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Convenience provider: true when a user is currently signed in.
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

// ── Cloud Firestore ───────────────────────────────────────────
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ── Firebase Storage ──────────────────────────────────────────
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// ── Firebase Messaging ────────────────────────────────────────
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

// ── Admin Role (custom claim) ─────────────────────────────────
/// Streams `true` when the currently signed-in user has the `admin: true`
/// custom claim set on their Firebase Auth token.
///
/// The claim must be set externally via the Firebase Admin SDK/CLI:
///   admin.auth().setCustomUserClaims(uid, { admin: true })
///
/// We force-refresh the token (`forceRefresh: true`) so freshly-granted claims
/// are picked up without requiring the user to sign out and back in.
final isAdminProvider = StreamProvider<bool>((ref) async* {
  final auth = ref.watch(firebaseAuthProvider);
  await for (final user in auth.authStateChanges()) {
    if (user == null) {
      yield false;
    } else {
      try {
        final tokenResult = await user.getIdTokenResult(true);
        yield tokenResult.claims?['admin'] == true;
      } catch (_) {
        yield false;
      }
    }
  }
});
