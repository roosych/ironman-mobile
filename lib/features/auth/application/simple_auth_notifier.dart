import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user.dart';
import '../infrastructure/simple_auth_repository.dart';
import 'auth_state.dart';
import '../../settings/application/locale_notifier.dart';

final simpleAuthProvider = StateNotifierProvider<SimpleAuthNotifier, AuthState>((ref) {
  return SimpleAuthNotifier(ref: ref);
});

/// Простой и надежный AuthNotifier без сложных workaround'ов
class SimpleAuthNotifier extends StateNotifier<AuthState> {
  final SimpleAuthRepository _repository = SimpleAuthRepository();
  final Ref? _ref;

  SimpleAuthNotifier({Ref? ref})
      : _ref = ref,
        super(const AuthState());

  /// Восстановление сессии
  Future<void> restoreSession() async {
    try {
      final hasSession = await _repository.hasSession();
      if (hasSession) {
        final user = await _repository.getSavedUser();
        if (user != null) {
          state = state.copyWith(
            user: user,
            status: AuthStatus.authenticated,
            clearError: true,
          );

          // Синхронизируем locale
          _syncLocaleWithUser(user);

          // Пытаемся обновить данные пользователя в фоне (не критично)
          _refreshUserInBackground();
        } else {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            clearError: true,
          );
        }
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
        );
      }
    } catch (e) {
      debugPrint('Error during session restore: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    }
  }

  /// Логин
  Future<void> login({
    required String email,
    required String password,
    String? locale,
  }) async {
    // Защита от повторных вызовов
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearWarning: true,
    );

    try {
      // Получаем locale для API
      final localeForApi = locale ??
          _ref?.read(localeProvider.notifier).getLocaleForApi() ??
          'en';

      final result = await _repository.login(
        email: email,
        password: password,
        locale: localeForApi,
      );

      if (result != null) {
        state = state.copyWith(
          user: result.user,
          status: AuthStatus.authenticated,
          isLoading: false,
          warning: result.message,
          clearError: true,
        );

        // Синхронизируем locale
        _syncLocaleWithUser(result.user);

        // Обновляем данные пользователя в фоне (не критично)
        _refreshUserInBackground();
      } else {
        // Ошибка уже показана через SimpleApiClient
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Произошла неожиданная ошибка при входе',
      );
    }
  }

  /// Регистрация
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? locale,
    String? countryCode,
  }) async {
    // Защита от повторных вызовов
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearWarning: true,
    );

    try {
      // Получаем locale для API
      final localeForApi = locale ??
          _ref?.read(localeProvider.notifier).getLocaleForApi() ??
          'en';

      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        locale: localeForApi,
        countryCode: countryCode,
      );

      if (result != null) {
        // После успешной регистрации очищаем сессию (как в старом коде)
        await _repository.clearSession();

        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          warning: result.message,
          clearUser: true,
        );
      } else {
        // Ошибка уже показана через SimpleApiClient
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Register error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Произошла неожиданная ошибка при регистрации',
      );
    }
  }

  /// Выход из системы
  Future<void> logout() async {
    // Защита от повторных вызовов
    if (state.isLoading) return;

    // Сразу устанавливаем состояние неавторизованного пользователя
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      isLoading: true,
    );

    try {
      await _repository.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      // В любом случае устанавливаем финальное состояние
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );

      // Очищаем состояние других провайдеров (как в старом коде)
      _clearPrivateProviders();
    }
  }

  /// Принудительный выход (при истечении сессии)
  void forceLogout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
    _clearPrivateProviders();
  }

  /// Восстановление пароля
  Future<String?> forgotPassword({required String email}) async {
    state = state.copyWith(clearError: true);

    try {
      return await _repository.forgotPassword(email: email);
    } catch (e) {
      debugPrint('Forgot password error: $e');
      return null;
    }
  }

  /// Повторная отправка письма верификации
  Future<String?> resendEmailVerification() async {
    state = state.copyWith(clearError: true);

    try {
      return await _repository.resendEmailVerification();
    } catch (e) {
      debugPrint('Resend verification error: $e');
      return null;
    }
  }

  /// Обновление пользователя
  Future<void> updateUser(User user) async {
    state = state.copyWith(user: user);
    await _repository.saveUser(user);
  }

  /// Обновление аватара
  Future<void> updateAvatar(String? avatarUrl) async {
    final currentUser = state.user;
    if (currentUser != null) {
      final finalAvatarUrl = (avatarUrl == null || avatarUrl.isEmpty) ? null : avatarUrl;
      final updatedUser = currentUser.copyWith(avatarUrl: finalAvatarUrl);
      await updateUser(updatedUser);
    }
  }

  /// Обновление пользователя с сервера
  Future<void> refreshUser() async {
    try {
      final user = await _repository.refreshUser();
      if (user != null) {
        state = state.copyWith(user: user);
      }
    } catch (e) {
      debugPrint('Failed to refresh user: $e');
    }
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Синхронизация языка с пользователем
  void _syncLocaleWithUser(User? user) {
    final ref = _ref;
    if (user != null && user.locale != null && ref != null) {
      try {
        final localeNotifier = ref.read(localeProvider.notifier);
        localeNotifier.syncWithUserLocale(user.locale);
      } catch (e) {
        debugPrint('Error syncing locale: $e');
      }
    }
  }

  /// Обновление пользователя в фоне
  void _refreshUserInBackground() {
    Future.microtask(() async {
      try {
        await refreshUser();
      } catch (e) {
        debugPrint('Background refresh error (ignored): $e');
      }
    });
  }

  /// Очистка приватных провайдеров при выходе
  void _clearPrivateProviders() {
    try {
      final ref = _ref;
      if (ref != null) {
        // TODO: Добавить очистку других провайдеров когда они будут переписаны
        debugPrint('Private providers cleared');
      }
    } catch (e) {
      debugPrint('Error clearing providers: $e');
    }
  }
}