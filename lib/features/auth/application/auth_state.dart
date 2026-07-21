import 'package:firebase_auth/firebase_auth.dart';

/// Represents the possible states of the auth flow in the UI.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

// Sentinel used to differentiate "not provided" from "explicitly null".
const _kClearError = Object();

/// Immutable auth state object.
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasError => status == AuthStatus.error;

  /// Pass [errorMessage] = null to explicitly clear the error.
  /// If [errorMessage] is omitted entirely, the current value is preserved.
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Object? errorMessage = _kClearError,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: identical(errorMessage, _kClearError)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.uid}, error: $errorMessage)';
}
