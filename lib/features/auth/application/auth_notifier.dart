import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user.dart';
import '../infrastructure/auth_api.dart';
import '../infrastructure/auth_repository.dart';
import 'auth_state.dart';
import '../../settings/application/locale_notifier.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref: ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref? _ref;
  DateTime? _lastNetworkErrorTime;
  static const Duration _networkErrorCooldown = Duration(seconds: 3);

  AuthNotifier({AuthRepository? repository, Ref? ref})
    : _repository = repository ?? AuthRepository(),
      _ref = ref,
      super(const AuthState());

  /// Sync locale with user's locale from API
  void _syncLocaleWithUser(User? user) {
    final ref = _ref;
    if (user != null && user.locale != null && ref != null) {
      final localeNotifier = ref.read(localeProvider.notifier);
      localeNotifier.syncWithUserLocale(user.locale);
    }
  }

  Future<void> restoreSession() async {
    try {
      final hasSession = await _repository.hasSession();
      if (hasSession) {
        // Restore from local storage for fast UI
        User? user;
        try {
          user = await _repository.getSavedUser();
        } catch (e) {
          debugPrint('Error getting saved user on session restore: $e');
          // Если не удалось получить пользователя из хранилища, считаем сессию невалидной
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            clearError: true,
          );
          return;
        }

        // ВАЖНО: Проверяем профиль из локального хранилища
        // Если профиль не валиден (нет id), устанавливаем null
        User? finalUser = user;
        if (user != null && user.profile is Map<String, dynamic>) {
          try {
            final profile = user.profile as Map<String, dynamic>;
            final profileId = profile['id'];
            if (profileId == null || profileId is! int) {
              // Профиль не валиден - устанавливаем null
              finalUser = user.copyWith(profile: null);
            }
          } catch (e) {
            debugPrint('Error processing user profile on session restore: $e');
            // В случае ошибки обработки профиля, устанавливаем null
            finalUser = user.copyWith(profile: null);
          }
        }

        // Для верифицированных пользователей синхронно проверяем профиль через API
        // Это гарантирует актуальность данных (на случай, если профиль был удален вручную)
        if (finalUser?.verified == true) {
          try {
            final refreshedUser = await _repository.refreshUser();

            // Проверяем профиль и обновляем состояние
            dynamic finalProfile = refreshedUser.profile;
            if (finalProfile is Map<String, dynamic>) {
              final profileId = finalProfile['id'];
              if (profileId == null || profileId is! int) {
                finalProfile = null;
              }
            }
            finalUser = refreshedUser.copyWith(profile: finalProfile);
          } catch (e) {
            // Игнорируем ошибки при обновлении профиля - используем данные из локального хранилища
            debugPrint('Failed to refresh user profile on session restore: $e');
            // Продолжаем с данными из локального хранилища
          }
        }

        state = state.copyWith(
          user: finalUser,
          status: AuthStatus.authenticated,
          clearError: true,
        );

        // Синхронизируем locale с пользователем
        try {
          _syncLocaleWithUser(finalUser);
        } catch (e) {
          debugPrint('Error syncing locale on session restore: $e');
          // Игнорируем ошибки синхронизации locale
        }
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
        );
      }
    } catch (e, stackTrace) {
      // Критическая ошибка при восстановлении сессии - логируем и устанавливаем неавторизованное состояние
      debugPrint('Critical error during session restore: $e');
      debugPrint('Stack trace: $stackTrace');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? locale,
  }) async {
    // Защита от множественных запросов
    if (state.isLoading) return;

    // Блокировка после ошибки сети (cooldown период)
    if (_lastNetworkErrorTime != null) {
      final timeSinceError = DateTime.now().difference(_lastNetworkErrorTime!);
      if (timeSinceError < _networkErrorCooldown) {
        final remainingSeconds =
            (_networkErrorCooldown - timeSinceError).inSeconds;
        // Используем код для локализации на клиенте (сетевые ошибки)
        state = state.copyWith(error: 'NETWORK_COOLDOWN_$remainingSeconds');
        return;
      }
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearWarning: true,
    );

    try {
      // Получаем locale для API (только ru или en)
      final localeForApi =
          locale ??
          _ref?.read(localeProvider.notifier).getLocaleForApi() ??
          'en';

      final result = await _repository.login(
        email: email,
        password: password,
        locale: localeForApi,
      );

      // Успешный запрос - сбрасываем время последней ошибки
      _lastNetworkErrorTime = null;

      // ВАЖНО: НЕ используем данные из ответа логина напрямую для финального пользователя
      // Ответ логина может содержать устаревшие данные профиля (кэш на сервере)
      // Всегда проверяем профиль через API для актуальности
      User finalUser = result.user;
      bool hasValidProfile = false;

      debugPrint('=== Login: Starting profile check ===');
      debugPrint('User from login response - ID: ${result.user.id}');
      debugPrint(
        'User from login response - verified: ${result.user.verified}',
      );
      debugPrint('User from login response - profile: ${result.user.profile}');

      // Для верифицированных пользователей ВСЕГДА синхронно проверяем профиль через API
      // Это гарантирует актуальность данных
      if (result.user.verified) {
        debugPrint('=== Login: Checking profile for verified user ===');
        debugPrint('Profile from login response: ${result.user.profile}');

        try {
          // Синхронно проверяем профиль через API для актуальности
          debugPrint(
            '=== Login: Calling refreshUser() to get fresh profile data ===',
          );
          final refreshedUser = await _repository.refreshUser();

          debugPrint('=== Login: refreshUser() completed ===');
          debugPrint('Refreshed user ID: ${refreshedUser.id}');
          debugPrint('Refreshed user verified: ${refreshedUser.verified}');
          debugPrint('Profile from refreshUser(): ${refreshedUser.profile}');
          debugPrint('Profile type: ${refreshedUser.profile.runtimeType}');

          // Проверяем наличие валидного профиля (должен быть id)
          if (refreshedUser.profile is Map<String, dynamic>) {
            debugPrint('=== Login: Profile is Map, checking id ===');
            final profile = refreshedUser.profile as Map<String, dynamic>;
            final profileId = profile['id'];
            debugPrint('Profile ID from refreshUser(): $profileId');
            debugPrint('Profile keys: ${profile.keys}');

            if (profileId != null && profileId is int) {
              // Профиль валиден - используем его
              debugPrint('=== Login: Profile ID is valid: $profileId ===');
              hasValidProfile = true;
              finalUser = refreshedUser;
              debugPrint(
                '=== Login: Profile is VALID - will show Dashboard ===',
              );
              debugPrint('FinalUser ID: ${finalUser.id}');
              debugPrint(
                'FinalUser profile ID: ${(finalUser.profile as Map<String, dynamic>)['id']}',
              );
            } else {
              // Профиль не валиден (нет id) - устанавливаем null
              hasValidProfile = false;
              // ВАЖНО: Явно устанавливаем profile в null
              finalUser = refreshedUser.copyWith(profile: null);
              debugPrint(
                'Profile is INVALID (no id) - setting to null, will show ProfileSelection',
              );
              debugPrint(
                'FinalUser profile after setting to null: ${finalUser.profile}',
              );
            }
          } else {
            // Профиль null - нет профиля
            hasValidProfile = false;
            // ВАЖНО: Убеждаемся, что profile явно null
            finalUser = refreshedUser.profile == null
                ? refreshedUser
                : refreshedUser.copyWith(profile: null);
            debugPrint('Profile is NULL - will show ProfileSelection');
            debugPrint('FinalUser profile: ${finalUser.profile}');
          }
        } catch (e) {
          // Если не удалось обновить из API, устанавливаем профиль в null
          // НЕ используем данные из ответа логина, так как они могут быть устаревшими
          debugPrint('=== ERROR: Failed to refresh user after login ===');
          debugPrint('Error: $e');
          debugPrint('Setting profile to null to force profile check');
          hasValidProfile = false;
          // Используем данные из ответа логина, но с profile = null
          // ВАЖНО: Убеждаемся, что profile явно установлен в null
          finalUser = result.user.copyWith(profile: null);
          debugPrint(
            'Will show ProfileSelection (profile set to null due to error)',
          );
          debugPrint('FinalUser profile after error: ${finalUser.profile}');
        }
      } else {
        // Для неверифицированных пользователей проверяем профиль из ответа логина
        if (result.user.profile is Map<String, dynamic>) {
          final profile = result.user.profile as Map<String, dynamic>;
          final profileId = profile['id'];
          hasValidProfile = profileId != null && profileId is int;
        } else {
          hasValidProfile = false;
        }
      }

      // ВАЖНО: Сохраняем пользователя в локальное хранилище ТОЛЬКО после проверки профиля
      // Это гарантирует, что мы сохраняем актуальные данные и не сохраняем устаревшие
      // Если профиль был удален вручную из базы, мы сохраним пользователя с profile: null
      debugPrint('=== Login: Saving user to storage after profile check ===');
      debugPrint('FinalUser ID: ${finalUser.id}');
      debugPrint('FinalUser verified: ${finalUser.verified}');
      debugPrint('hasValidProfile: $hasValidProfile');
      debugPrint('User profile before save: ${finalUser.profile}');
      debugPrint('User profile type: ${finalUser.profile.runtimeType}');
      await _repository.saveUser(finalUser);
      debugPrint('=== Login: User saved to storage ===');

      // Дополнительная проверка: убеждаемся, что сохранено правильно
      final savedUser = await _repository.getSavedUser();
      debugPrint('User profile after save: ${savedUser?.profile}');
      if (savedUser != null && savedUser.profile != finalUser.profile) {
        debugPrint('WARNING: Saved user profile differs from finalUser!');
        // Пересохраняем для гарантии
        await _repository.saveUser(finalUser);
      }

      // ВАЖНО: Убеждаемся, что profile явно null, если его нет
      // Это критично для правильной работы роутера
      if (!hasValidProfile && finalUser.profile != null) {
        debugPrint(
          'WARNING: Profile should be null but is not! Forcing to null...',
        );
        finalUser = finalUser.copyWith(profile: null);
        await _repository.saveUser(finalUser);
      }

      // ВАЖНО: Обновляем состояние с финальным пользователем
      // Создаем НОВЫЙ объект состояния явно, чтобы гарантировать обновление в Riverpod
      debugPrint('=== Updating state after login ===');
      debugPrint('Before update - isAuthenticated: ${state.isAuthenticated}');
      debugPrint('Before update - user: ${state.user?.id}');
      debugPrint('Before update - status: ${state.status}');

      // Создаем новый объект состояния явно для гарантии обновления
      // ВАЖНО: Не сохраняем warning в состоянии, чтобы не показывать snackbar на главном экране
      final newState = AuthState(
        user: finalUser,
        status: AuthStatus.authenticated,
        isLoading: false,
        warning: null, // Очищаем warning после успешного логина
      );

      // Обновляем состояние
      // ВАЖНО: Используем прямое присваивание для гарантии обновления в Riverpod
      state = newState;

      debugPrint('=== State updated (sync) ===');
      debugPrint('New state - isAuthenticated: ${state.isAuthenticated}');
      debugPrint('New state - user: ${state.user?.id}');
      debugPrint('New state - status: ${state.status}');
      debugPrint('New state hashCode: ${state.hashCode}');

      // Синхронизируем locale с пользователем из API
      _syncLocaleWithUser(finalUser);

      debugPrint('=== Final state after login ===');
      debugPrint('User ID: ${finalUser.id}');
      debugPrint('Profile: ${finalUser.profile}');
      debugPrint('Profile type: ${finalUser.profile.runtimeType}');
      debugPrint('Has valid profile: $hasValidProfile');
      debugPrint('After update - isAuthenticated: ${state.isAuthenticated}');
      debugPrint('After update - status: ${state.status}');
      debugPrint('After update - user: ${state.user?.id}');
      debugPrint('After update - user.profile: ${state.user?.profile}');
      debugPrint(
        'Will show: ${hasValidProfile ? "Dashboard" : "ProfileSelection"}',
      );

      // ВАЖНО: Принудительно обновляем состояние через несколько способов
      // для гарантии, что роутер увидит изменения

      // 1. Обновление через microtask (немедленно)
      Future.microtask(() {
        debugPrint('=== Microtask: Forcing state update ===');
        debugPrint('Current state - isAuthenticated: ${state.isAuthenticated}');
        debugPrint('Current state - user: ${state.user?.id}');

        // Принудительно создаем новый объект состояния для гарантии обновления
        final forcedState = AuthState(
          user: finalUser,
          status: AuthStatus.authenticated,
          isLoading: false,
          warning: null, // Очищаем warning
        );

        // Обновляем состояние принудительно
        state = forcedState;

        debugPrint('=== Microtask: State forced update complete ===');
        debugPrint('Forced state - isAuthenticated: ${state.isAuthenticated}');
        debugPrint('Forced state - user: ${state.user?.id}');
        debugPrint('Forced state hashCode: ${state.hashCode}');
      });

      // 2. Обновление через PostFrameCallback (после отрисовки кадра)
      SchedulerBinding.instance.addPostFrameCallback((_) {
        debugPrint('=== PostFrameCallback: Forcing state update ===');
        debugPrint('Current state - isAuthenticated: ${state.isAuthenticated}');
        debugPrint('Current state - user: ${state.user?.id}');

        // Принудительно создаем новый объект состояния для гарантии обновления
        final forcedState = AuthState(
          user: finalUser,
          status: AuthStatus.authenticated,
          isLoading: false,
          warning: null, // Очищаем warning
        );

        // Обновляем состояние принудительно
        state = forcedState;

        debugPrint('=== PostFrameCallback: State forced update complete ===');
        debugPrint('Forced state - isAuthenticated: ${state.isAuthenticated}');
        debugPrint('Forced state - user: ${state.user?.id}');
        debugPrint('Forced state hashCode: ${state.hashCode}');
      });
    } on AuthApiException catch (e) {
      // Сохраняем время ошибки для блокировки повторных запросов
      final errorMessage = e.firstError.toLowerCase();
      if (errorMessage.contains('подключ') ||
          errorMessage.contains('сеть') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('слишком много')) {
        _lastNetworkErrorTime = DateTime.now();
      }

      state = state.copyWith(isLoading: false, error: e.firstError);
    } catch (e) {
      _lastNetworkErrorTime = DateTime.now();
      state = state.copyWith(
        isLoading: false,
        error: 'error_unexpected',
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? locale,
  }) async {
    // Защита от множественных запросов
    if (state.isLoading) return;

    // Блокировка после ошибки сети (cooldown период)
    if (_lastNetworkErrorTime != null) {
      final timeSinceError = DateTime.now().difference(_lastNetworkErrorTime!);
      if (timeSinceError < _networkErrorCooldown) {
        final remainingSeconds =
            (_networkErrorCooldown - timeSinceError).inSeconds;
        // Используем код для локализации на клиенте (сетевые ошибки)
        state = state.copyWith(error: 'NETWORK_COOLDOWN_$remainingSeconds');
        return;
      }
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearWarning: true,
    );

    try {
      // Получаем locale для API (только ru или en)
      final localeForApi =
          locale ??
          _ref?.read(localeProvider.notifier).getLocaleForApi() ??
          'en';

      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        locale: localeForApi,
      );

      // Успешный запрос - сбрасываем время последней ошибки
      _lastNetworkErrorTime = null;

      // После успешной регистрации не аутентифицируем пользователя,
      // чтобы показать экран "Спасибо" без перехода на экран верификации почты
      // Очищаем сохраненные токен и пользователя, чтобы при следующем запуске
      // пользователь не был автоматически аутентифицирован
      await _repository.clearSession();

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        warning: result.message,
        clearUser: true, // Очищаем пользователя из состояния
      );
    } on AuthApiException catch (e) {
      // Сохраняем время ошибки для блокировки повторных запросов
      final errorMessage = e.firstError.toLowerCase();
      if (errorMessage.contains('подключ') ||
          errorMessage.contains('сеть') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('слишком много')) {
        _lastNetworkErrorTime = DateTime.now();
      }

      state = state.copyWith(isLoading: false, error: e.firstError);
    } catch (e) {
      _lastNetworkErrorTime = DateTime.now();
      state = state.copyWith(
        isLoading: false,
        error: 'error_unexpected',
      );
    }
  }

  Future<void> logout() async {
    // Prevent double-click
    if (state.isLoading) return;

    debugPrint('=== AuthNotifier: Starting logout ===');
    debugPrint('Current state - isAuthenticated: ${state.isAuthenticated}');
    debugPrint('Current state - user: ${state.user?.id}');

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.logout();
    } finally {
      // ВАЖНО: Полностью сбрасываем состояние при выходе
      // Создаем НОВЫЙ объект состояния явно для гарантии обновления в Riverpod
      // Это гарантирует, что все данные очищены и при следующем входе
      // не будут использоваться старые данные
      debugPrint('=== AuthNotifier: Resetting state after logout ===');
      debugPrint('Before logout - isAuthenticated: ${state.isAuthenticated}');
      debugPrint('Before logout - user: ${state.user?.id}');

      // Создаем новый объект состояния для гарантии обновления
      final logoutState = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );

      state = logoutState;

      debugPrint('After logout - isAuthenticated: ${state.isAuthenticated}');
      debugPrint('After logout - user: ${state.user}');
      debugPrint('After logout - status: ${state.status}');
      debugPrint('=== AuthNotifier: Logout complete ===');
    }
  }

  /// Force logout without calling the API.
  ///
  /// Used when the session has already been invalidated server-side (401).
  /// This method only clears the local state without making API calls.
  void forceLogout() {
    debugPrint('AuthNotifier: Force logout triggered');
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void setUser(User user) {
    state = state.copyWith(user: user);
  }

  /// Update user and persist to storage
  Future<void> updateUser(User user) async {
    // ВАЖНО: Создаем новый объект состояния явно для гарантии обновления в Riverpod
    // Это гарантирует, что все виджеты, которые отслеживают authState, увидят изменения
    final newState = AuthState(
      user: user,
      status: state.status,
      isLoading: state.isLoading,
      error: state.error,
      warning: state.warning,
    );
    state = newState;
    await _repository.saveUser(user);
  }

  /// Update user's avatar URL (Single Source of Truth)
  /// Also saves updated user to storage for persistence
  /// If avatarUrl is empty string, it will be set to null to show placeholder
  Future<void> updateAvatar(String? avatarUrl) async {
    final currentUser = state.user;
    if (currentUser != null) {
      // Treat empty string as null to show placeholder icon
      final finalAvatarUrl = (avatarUrl == null || avatarUrl.isEmpty) ? null : avatarUrl;
      final updatedUser = currentUser.copyWith(avatarUrl: finalAvatarUrl);
      state = state.copyWith(user: updatedUser);
      // Save updated user to storage
      await _repository.saveUser(updatedUser);
    }
  }

  /// Refresh user profile from server and update state
  /// This ensures we have the latest data from the API
  Future<void> refreshUser() async {
    try {
      final refreshedUser = await _repository.refreshUser();
      await updateUser(refreshedUser);
    } catch (e) {
      debugPrint('Failed to refresh user: $e');
      // Don't throw - keep current state
    }
  }
}
