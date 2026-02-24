import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user.dart';
import '../infrastructure/auth_api.dart';
import '../infrastructure/auth_repository.dart';
import 'auth_state.dart';
import '../../settings/application/locale_notifier.dart';
import '../../../core/services/fcm_service.dart';
import '../../../main.dart';
import '../../results/application/race_results_notifier.dart';
import '../../rankings/application/rankings_notifier.dart';

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
        if (user != null && user.profile != null) {
          try {
            final profile = user.profile!;
            if (profile.id == null) {
              // Профиль не валиден - устанавливаем null
              finalUser = user.copyWith(clearProfile: true);
            }
          } catch (e) {
            debugPrint('Error processing user profile on session restore: $e');
            // В случае ошибки обработки профиля, устанавливаем null
            finalUser = user.copyWith(clearProfile: true);
          }
        }

        // Для верифицированных пользователей синхронно проверяем профиль через API
        // Это гарантирует актуальность данных (на случай, если профиль был удален вручную)
        if (finalUser?.verified == true) {
          try {
            final refreshedUser = await _repository.refreshUser();

            // Проверяем профиль и обновляем состояние
            final profileData = refreshedUser.profile;
            if (profileData != null && profileData.id == null) {
              finalUser = refreshedUser.copyWith(clearProfile: true);
            } else {
              finalUser = refreshedUser;
            }
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

        // Инициализируем FCM для верифицированных пользователей с защитой от зависания
        if (finalUser?.verified == true) {
          Future.microtask(() async {
            try {
              debugPrint('🔔 FCM (restore): Starting initialization with 3s timeout...');
              await FcmService().initialize().timeout(
                Duration(seconds: 3),
                onTimeout: () {
                  debugPrint('⚠️ FCM (restore): Initialization timed out after 3s - continuing without FCM');
                  return;
                },
              );
              debugPrint('✅ FCM (restore): Successfully initialized');
            } catch (e) {
              debugPrint('❌ FCM: Error initializing on session restore: $e');
            }
          });
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

    debugPrint('=== AuthNotifier: Starting login attempt ===');
    debugPrint('Email: $email');
    debugPrint('Time: ${DateTime.now()}');

    state = state.copyWith(
      isLoading: true,
      loadingStage: AuthLoadingStage.sending,
      clearError: true,
      clearWarning: true,
    );

    try {
      // Получаем locale для API (только ru или en)
      final localeForApi =
          locale ??
          _ref?.read(localeProvider.notifier).getLocaleForApi() ??
          'en';

      debugPrint('=== AuthNotifier: Calling repository.login ===');
      debugPrint('Locale for API: $localeForApi');

      // Update to processing stage
      state = state.copyWith(loadingStage: AuthLoadingStage.processing);

      final result = await _repository.login(
        email: email,
        password: password,
        locale: localeForApi,
      );

      debugPrint('=== AuthNotifier: Login repository call completed ===');
      debugPrint('User verified: ${result.user.verified}');

      // Update to verifying stage
      state = state.copyWith(loadingStage: AuthLoadingStage.verifying);

      // Успешный запрос - сбрасываем время последней ошибки
      _lastNetworkErrorTime = null;

      // ВАЖНО: НЕ используем данные из ответа логина напрямую для финального пользователя
      // Ответ логина может содержать устаревшие данные профиля (кэш на сервере)
      // Всегда проверяем профиль через API для актуальности
      User finalUser = result.user;
      bool hasValidProfile = false;

      // Для верифицированных пользователей ВСЕГДА синхронно проверяем профиль через API
      // Это гарантирует актуальность данных
      if (result.user.verified) {
        try {
          // Синхронно проверяем профиль через API для актуальности
          final refreshedUser = await _repository.refreshUser();

          // Проверяем наличие валидного профиля (должен быть id)
          final profileData = refreshedUser.profile;
          if (profileData != null) {
            final profileId = profileData.id;

            if (profileId != null) {
              // Профиль валиден - используем его
              hasValidProfile = true;
              finalUser = refreshedUser;
            } else {
              // Профиль не валиден (нет id) - устанавливаем null
              hasValidProfile = false;
              // ВАЖНО: Явно устанавливаем profile в null
              finalUser = refreshedUser.copyWith(clearProfile: true);
            }
          } else {
            // Профиль null - нет профиля
            hasValidProfile = false;
            finalUser = refreshedUser;
          }
        } catch (e) {
          // Если не удалось обновить из API, устанавливаем профиль в null
          // НЕ используем данные из ответа логина, так как они могут быть устаревшими
          debugPrint('Failed to refresh user after login: $e');
          hasValidProfile = false;
          // Используем данные из ответа логина, но с profile = null
          // ВАЖНО: Убеждаемся, что profile явно установлен в null
          finalUser = result.user.copyWith(clearProfile: true);
        }
      } else {
        // Для неверифицированных пользователей проверяем профиль из ответа логина
        final profileData = result.user.profile;
        hasValidProfile = profileData?.id != null;
        finalUser = result.user;
      }

      // ВАЖНО: Сохраняем пользователя в локальное хранилище ТОЛЬКО после проверки профиля
      // Это гарантирует, что мы сохраняем актуальные данные и не сохраняем устаревшие
      // Если профиль был удален вручную из базы, мы сохраним пользователя с profile: null
      await _repository.saveUser(finalUser);

      // Дополнительная проверка: убеждаемся, что сохранено правильно
      final savedUser = await _repository.getSavedUser();
      if (savedUser != null && savedUser.profile?.id != finalUser.profile?.id) {
        // Пересохраняем для гарантии
        await _repository.saveUser(finalUser);
      }

      // ВАЖНО: Убеждаемся, что profile явно null, если его нет
      // Это критично для правильной работы роутера
      if (!hasValidProfile && finalUser.profile != null) {
        finalUser = finalUser.copyWith(clearProfile: true);
        await _repository.saveUser(finalUser);
      }

      // ВАЖНО: Обновляем состояние с финальным пользователем
      // Создаем НОВЫЙ объект состояния явно, чтобы гарантировать обновление в Riverpod

      // Создаем новый объект состояния явно для гарантии обновления
      // ВАЖНО: Не сохраняем warning в состоянии, чтобы не показывать snackbar на главном экране
      final newState = AuthState(
        user: finalUser,
        status: AuthStatus.authenticated,
        isLoading: false,
        loadingStage: AuthLoadingStage.none,
        warning: null, // Очищаем warning после успешного логина
      );

      // Обновляем состояние
      // ВАЖНО: Используем прямое присваивание для гарантии обновления в Riverpod
      state = newState;

      // Синхронизируем locale с пользователем из API
      _syncLocaleWithUser(finalUser);

      // ВАЖНО: Принудительно обновляем состояние через несколько способов
      // для гарантии, что роутер увидит изменения

      // 1. Обновление через microtask (немедленно)
      Future.microtask(() {
        // Принудительно создаем новый объект состояния для гарантии обновления
        final forcedState = AuthState(
          user: finalUser,
          status: AuthStatus.authenticated,
          isLoading: false,
          loadingStage: AuthLoadingStage.none,
          warning: null, // Очищаем warning
        );

        // Обновляем состояние принудительно
        state = forcedState;
      });

      // 2. Обновление через PostFrameCallback (после отрисовки кадра)
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Принудительно создаем новый объект состояния для гарантии обновления
        final forcedState = AuthState(
          user: finalUser,
          status: AuthStatus.authenticated,
          isLoading: false,
          loadingStage: AuthLoadingStage.none,
          warning: null, // Очищаем warning
        );

        // Обновляем состояние принудительно
        state = forcedState;
      });
    } on AuthApiException catch (e) {
      await _handleAuthError(e, email, password, locale);
    } catch (e, stackTrace) {
      debugPrint('=== AuthNotifier: Login failed with unexpected error ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Time: ${DateTime.now()}');

      await _handleUnexpectedError(e, email, password, locale);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? locale,
    String? countryCode,
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
        countryCode: countryCode,
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
    debugPrint('=== AUTH: logout() started ===');
    // Prevent double-click
    if (state.isLoading) {
      debugPrint('=== AUTH: logout() blocked - already loading ===');
      return;
    }

    // ВАЖНО: Сразу устанавливаем unauthenticated состояние, чтобы предотвратить
    // API запросы во время logout процесса
    debugPrint('=== AUTH: Setting unauthenticated + loading state ===');
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      isLoading: true,
    );
    debugPrint('=== AUTH: State set to unauthenticated + loading ===');

    try {
      debugPrint('=== AUTH: Calling repository.logout() ===');
      await _repository.logout();
      debugPrint('=== AUTH: repository.logout() completed ===');
    } catch (e) {
      debugPrint('=== AUTH: Error in repository.logout(): $e ===');
    } finally {
      debugPrint('=== AUTH: Setting final logout state ===');
      // ВАЖНО: Полностью сбрасываем состояние при выходе
      // Создаем НОВЫЙ объект состояния явно для гарантии обновления в Riverpod
      // Это гарантирует, что все данные очищены и при следующем входе
      // не будут использоваться старые данные

      // Создаем новый объект состояния для гарантии обновления
      final logoutState = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );

      state = logoutState;
      debugPrint('=== AUTH: Final logout state set - isLoading = false ===');

      // ВАЖНО: Очищаем состояние провайдеров с приватными данными при logout
      debugPrint('=== AUTH: Clearing private provider states ===');
      try {
        if (_ref != null) {
          // Очищаем только приватные данные пользователя (результаты)
          _ref.read(raceResultsProvider.notifier).reset();
          // Очищаем выбор атлетов для сравнения, но оставляем сами рейтинги (публичные данные)
          _ref.read(rankingsProvider.notifier).clearSelection();
          debugPrint('=== AUTH: Private provider states cleared successfully ===');
        }
      } catch (e) {
        debugPrint('=== AUTH: Error clearing provider states: $e ===');
      }

      // ВАЖНО: Очищаем навигационный стек после logout и возвращаем на главный экран.
      // Используем pushNamedAndRemoveUntil вместо popUntil, чтобы гарантировать
      // корректную навигацию независимо от состояния стека (например, если DashboardScreen
      // стал корневым маршрутом после Register -> Login flow).
      Future.microtask(() {
        try {
          debugPrint('=== AUTH: Navigating to root after logout ===');
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        } catch (e) {
          debugPrint('=== AUTH: Error navigating after logout: $e ===');
        }
      });
    }
    debugPrint('=== AUTH: logout() completed ===');
  }

  /// Force logout without calling the API.
  ///
  /// Used when the session has already been invalidated server-side (401).
  /// This method only clears the local state without making API calls.
  void forceLogout() {
    state = const AuthState(status: AuthStatus.unauthenticated);

    // Очищаем состояние провайдеров с приватными данными
    try {
      if (_ref != null) {
        // Очищаем только приватные данные пользователя (результаты)
        _ref.read(raceResultsProvider.notifier).reset();
        // Очищаем выбор атлетов для сравнения, но оставляем сами рейтинги (публичные данные)
        _ref.read(rankingsProvider.notifier).clearSelection();
      }
    } catch (e) {
      debugPrint('Error clearing provider states in forceLogout: $e');
    }
  }

  /// Forgot password without setting global loading state
  /// This prevents AuthRouter from showing loading screen
  Future<String> forgotPassword({required String email}) async {
    // Блокировка после ошибки сети (cooldown период)
    if (_lastNetworkErrorTime != null) {
      final timeSinceError = DateTime.now().difference(_lastNetworkErrorTime!);
      if (timeSinceError < _networkErrorCooldown) {
        final remainingSeconds =
            (_networkErrorCooldown - timeSinceError).inSeconds;
        throw AuthApiException('NETWORK_COOLDOWN_$remainingSeconds');
      }
    }

    // Очищаем только ошибку, НЕ устанавливаем isLoading чтобы избежать AuthRouter loading screen
    state = state.copyWith(clearError: true);

    try {
      final message = await _repository.forgotPassword(email: email);

      // Успешный запрос - сбрасываем время последней ошибки
      _lastNetworkErrorTime = null;

      return message;
    } on AuthApiException catch (e) {
      // Сохраняем время ошибки для блокировки повторных запросов
      final errorMessage = e.firstError.toLowerCase();
      if (errorMessage.contains('подключ') ||
          errorMessage.contains('сеть') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('слишком много') ||
          errorMessage.contains('too many')) {
        _lastNetworkErrorTime = DateTime.now();
      }

      state = state.copyWith(error: e.firstError);
      rethrow;
    } catch (e) {
      _lastNetworkErrorTime = DateTime.now();
      state = state.copyWith(error: 'error_unexpected');
      rethrow;
    }
  }

  /// Resend email verification without setting global loading state
  /// This prevents AuthRouter from showing loading screen
  Future<String> resendEmailVerification() async {
    // Блокировка после ошибки сети (cooldown период)
    if (_lastNetworkErrorTime != null) {
      final timeSinceError = DateTime.now().difference(_lastNetworkErrorTime!);
      if (timeSinceError < _networkErrorCooldown) {
        final remainingSeconds =
            (_networkErrorCooldown - timeSinceError).inSeconds;
        throw AuthApiException('NETWORK_COOLDOWN_$remainingSeconds');
      }
    }

    // Очищаем только ошибку, НЕ устанавливаем isLoading чтобы избежать AuthRouter loading screen
    state = state.copyWith(clearError: true);

    try {
      final message = await _repository.resendEmailVerification();

      // Успешный запрос - сбрасываем время последней ошибки
      _lastNetworkErrorTime = null;

      return message;
    } on AuthApiException catch (e) {
      // Сохраняем время ошибки для блокировки повторных запросов
      final errorMessage = e.firstError.toLowerCase();
      if (errorMessage.contains('подключ') ||
          errorMessage.contains('сеть') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('слишком много') ||
          errorMessage.contains('too many')) {
        _lastNetworkErrorTime = DateTime.now();
      }

      state = state.copyWith(error: e.firstError);
      rethrow;
    } catch (e) {
      _lastNetworkErrorTime = DateTime.now();
      state = state.copyWith(error: 'error_unexpected');
      rethrow;
    }
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

  /// Handle authentication errors with smart retry and background verification
  Future<void> _handleAuthError(
    AuthApiException e,
    String email,
    String password,
    String? locale
  ) async {
    debugPrint('=== AuthNotifier: Login failed with AuthApiException ===');
    debugPrint('Error: ${e.firstError}');
    debugPrint('Time: ${DateTime.now()}');

    final errorMessage = e.firstError.toLowerCase();
    final isNetworkError = errorMessage.contains('подключ') ||
        errorMessage.contains('сеть') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('слишком много');

    if (isNetworkError) {
      debugPrint('=== AuthNotifier: Network error detected, checking retry options ===');

      // Check if we should try background verification for timeout errors
      if (errorMessage.contains('timeout') || errorMessage.contains('не отвечает')) {
        await _handleTimeoutWithBackgroundCheck(email, password, locale);
        return;
      }

      // Set cooldown for other network errors
      _lastNetworkErrorTime = DateTime.now();
    }

    // Show error for non-timeout cases
    state = state.copyWith(
      isLoading: false,
      loadingStage: AuthLoadingStage.none,
      error: e.firstError
    );
  }

  /// Handle unexpected errors with potential retry
  Future<void> _handleUnexpectedError(
    dynamic error,
    String email,
    String password,
    String? locale
  ) async {
    final errorString = error.toString().toLowerCase();

    // Check if this might be a timeout that succeeded on server
    if (errorString.contains('timeout') || errorString.contains('connection')) {
      debugPrint('=== AuthNotifier: Unexpected error might be timeout, checking background ===');
      await _handleTimeoutWithBackgroundCheck(email, password, locale);
      return;
    }

    // Regular error handling
    _lastNetworkErrorTime = DateTime.now();
    state = state.copyWith(
      isLoading: false,
      loadingStage: AuthLoadingStage.none,
      error: 'error_unexpected',
    );
  }

  /// Handle timeout errors with background authentication verification
  Future<void> _handleTimeoutWithBackgroundCheck(
    String email,
    String password,
    String? locale
  ) async {
    debugPrint('=== AuthNotifier: Starting background verification after timeout ===');

    // Update UI to show background check
    state = state.copyWith(loadingStage: AuthLoadingStage.backgroundCheck);

    // Wait a bit for server to potentially complete the request
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Try to get current user to see if auth actually succeeded
      debugPrint('=== AuthNotifier: Checking current user status ===');
      final user = await _repository.refreshUser();

      if (user.id > 0) {
        debugPrint('=== AuthNotifier: Background check SUCCESS - user is authenticated! ===');

        // Auth succeeded! Update state
        await _repository.saveUser(user);

        final successState = AuthState(
          user: user,
          status: AuthStatus.authenticated,
          isLoading: false,
          loadingStage: AuthLoadingStage.none,
        );

        state = successState;
        _syncLocaleWithUser(user);

        // Initialize FCM for verified users with timeout protection
        if (user.verified) {
          Future.microtask(() async {
            try {
              debugPrint('🔔 FCM: Starting initialization with 3s timeout...');
              await FcmService().initialize().timeout(
                Duration(seconds: 3),
                onTimeout: () {
                  debugPrint('⚠️ FCM: Initialization timed out after 3s - continuing without FCM');
                  return;
                },
              );
              debugPrint('✅ FCM: Successfully initialized');
            } catch (e) {
              debugPrint('❌ FCM: Error initializing after background check: $e');
            }
          });
        }

        return;
      }
    } catch (backgroundError) {
      debugPrint('=== AuthNotifier: Background check failed: $backgroundError ===');

      // If background check fails, try one retry
      final backgroundErrorString = backgroundError.toString();
      if (!backgroundErrorString.contains('retry_attempted')) {
        debugPrint('=== AuthNotifier: Attempting one retry after background check failure ===');
        await _attemptRetry(email, password, locale);
        return;
      }
    }

    // If we get here, both background check and retry failed
    debugPrint('=== AuthNotifier: All recovery attempts failed, showing timeout error ===');
    state = state.copyWith(
      isLoading: false,
      loadingStage: AuthLoadingStage.none,
      error: 'Сервер не отвечает. Попробуйте позже.',
    );

    _lastNetworkErrorTime = DateTime.now();
  }

  /// Attempt one retry with exponential backoff
  Future<void> _attemptRetry(String email, String password, String? locale) async {
    debugPrint('=== AuthNotifier: Starting retry attempt ===');

    // Update UI to show retry
    state = state.copyWith(loadingStage: AuthLoadingStage.retrying);

    // Wait a bit before retry (exponential backoff)
    await Future.delayed(const Duration(seconds: 1));

    try {
      debugPrint('=== AuthNotifier: Retry - calling repository.login ===');
      state = state.copyWith(loadingStage: AuthLoadingStage.processing);

      final result = await _repository.login(
        email: email,
        password: password,
        locale: locale ?? 'en',
      );

      debugPrint('=== AuthNotifier: Retry SUCCESS ===');

      // Success on retry! Handle normally
      state = state.copyWith(loadingStage: AuthLoadingStage.verifying);

      User finalUser = result.user;

      // Continue with normal success flow...
      if (result.user.verified) {
        try {
          final refreshedUser = await _repository.refreshUser();
          final profileData = refreshedUser.profile;
          if (profileData?.id != null) {
            finalUser = refreshedUser;
          } else {
            finalUser = refreshedUser.copyWith(clearProfile: true);
          }
        } catch (e) {
          debugPrint('Failed to refresh user after retry: $e');
          finalUser = result.user.copyWith(clearProfile: true);
        }
      }

      await _repository.saveUser(finalUser);

      final successState = AuthState(
        user: finalUser,
        status: AuthStatus.authenticated,
        isLoading: false,
        loadingStage: AuthLoadingStage.none,
      );

      state = successState;
      _syncLocaleWithUser(finalUser);

      if (finalUser.verified) {
        Future.microtask(() async {
          try {
            debugPrint('🔔 FCM (retry): Starting initialization with 3s timeout...');
            await FcmService().initialize().timeout(
              Duration(seconds: 3),
              onTimeout: () {
                debugPrint('⚠️ FCM (retry): Initialization timed out after 3s - continuing without FCM');
                return;
              },
            );
            debugPrint('✅ FCM (retry): Successfully initialized');
          } catch (e) {
            debugPrint('❌ FCM: Error initializing after retry: $e');
          }
        });
      }

    } catch (retryError) {
      debugPrint('=== AuthNotifier: Retry failed: $retryError ===');

      // Mark that retry was attempted to avoid infinite loops
      final errorWithRetryMark = 'retry_attempted: ${retryError.toString()}';

      if (retryError is AuthApiException) {
        await _handleAuthError(
          AuthApiException(errorWithRetryMark),
          email, password, locale
        );
      } else {
        await _handleUnexpectedError(errorWithRetryMark, email, password, locale);
      }
    }
  }
}
