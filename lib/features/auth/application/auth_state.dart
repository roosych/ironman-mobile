import '../domain/user.dart';
import '../../../l10n/app_localizations.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

enum AuthLoadingStage {
  none,
  sending,        // "Отправка данных..."
  processing,     // "Обработка на сервере..."
  verifying,      // "Проверяем результат..."
  retrying,       // "Повторная попытка..."
  backgroundCheck // "Проверяем статус авторизации..."
}

class AuthState {
  final User? user;
  final String? token;
  final AuthStatus status;
  final bool isLoading;
  final AuthLoadingStage loadingStage;
  final String? error;
  final String? warning;

  const AuthState({
    this.user,
    this.token,
    this.status = AuthStatus.initial,
    this.isLoading = false,
    this.loadingStage = AuthLoadingStage.none,
    this.error,
    this.warning,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isInitial => status == AuthStatus.initial;

  /// Get localized loading message based on current stage
  String getLoadingMessage(AppLocalizations localizations) {
    switch (loadingStage) {
      case AuthLoadingStage.sending:
        return 'Отправка данных...'; // Add to localizations
      case AuthLoadingStage.processing:
        return 'Обработка на сервере...'; // Add to localizations
      case AuthLoadingStage.verifying:
        return 'Проверяем результат...'; // Add to localizations
      case AuthLoadingStage.retrying:
        return 'Повторная попытка...'; //  Add to localizations
      case AuthLoadingStage.backgroundCheck:
        return 'Проверяем статус авторизации...'; //  Add to localizations
      case AuthLoadingStage.none:
        return localizations.login_loading;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.user?.id == user?.id &&
        other.status == status &&
        other.isLoading == isLoading &&
        other.loadingStage == loadingStage &&
        other.error == error &&
        other.warning == warning;
  }

  @override
  int get hashCode {
    return Object.hash(
      user?.id,
      status,
      isLoading,
      loadingStage,
      error,
      warning,
    );
  }

  AuthState copyWith({
    User? user,
    String? token,
    AuthStatus? status,
    bool? isLoading,
    AuthLoadingStage? loadingStage,
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
      loadingStage: loadingStage ?? this.loadingStage,
      error: clearError ? null : (error ?? this.error),
      warning: clearWarning ? null : (warning ?? this.warning),
    );
  }
}
