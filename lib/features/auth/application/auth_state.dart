import '../domain/user.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthState {
  final User? user;
  final String? token;
  final AuthStatus status;
  final bool isLoading;
  final String? error;
  final String? warning;

  const AuthState({
    this.user,
    this.token,
    this.status = AuthStatus.initial,
    this.isLoading = false,
    this.error,
    this.warning,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isInitial => status == AuthStatus.initial;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.user?.id == user?.id &&
        other.status == status &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.warning == warning;
  }

  @override
  int get hashCode {
    return Object.hash(
      user?.id,
      status,
      isLoading,
      error,
      warning,
    );
  }

  AuthState copyWith({
    User? user,
    String? token,
    AuthStatus? status,
    bool? isLoading,
    String? error,
    String? warning,
    bool clearUser = false,
    bool clearError = false,
    bool clearWarning = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearUser ? null : (token ?? this.token),
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      warning: clearWarning ? null : (warning ?? this.warning),
    );
  }
}
