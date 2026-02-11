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

        // Инициализируем FCM для верифицированных пользователей
        if (finalUser?.verified == true) {
          Future.microtask(() async {
            try {
              await FcmService().initialize();
            } catch (e) {
              debugPrint('FCM: Error initializing on session restore: $e');
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
          warning: null, // Очищаем warning
        );

        // Обновляем состояние принудительно
        state = forcedState;
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

      // ВАЖНО: Очищаем навигационный стек после logout
      Future.microtask(() {
        try {
          if (navigatorKey.currentState?.canPop() == true) {
            debugPrint('=== AUTH: Clearing navigation stack after logout ===');
            navigatorKey.currentState?.popUntil((route) => route.isFirst);
          }
        } catch (e) {
          debugPrint('=== AUTH: Error clearing navigation stack: $e ===');
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
