import 'package:flutter/foundation.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/services/fcm_service.dart';
import '../domain/user.dart';
import 'auth_api.dart';
import '../../profile/infrastructure/profile_api.dart';

class LoginResult {
  final User user;
  final String? message;

  const LoginResult({
    required this.user,
    this.message,
  });
}

class AuthRepository {
  final AuthApi _api;
  final SecureStorage _storage;
  final ProfileApi _profileApi;

  AuthRepository({AuthApi? api, SecureStorage? storage, ProfileApi? profileApi})
    : _api = api ?? AuthApi(),
      _storage = storage ?? SecureStorage(),
      _profileApi = profileApi ?? ProfileApi();

  Future<User> _enrichWithAvatar(User user) async {
    try {
      final avatarUrl = await _profileApi.getCurrentAvatarUrl();
      if (avatarUrl == null || avatarUrl.isEmpty) return user;
      return user.copyWith(avatarUrl: avatarUrl);
    } catch (_) {
      return user;
    }
  }

  Future<LoginResult> login({
    required String email,
    required String password,
    String? locale,
  }) async {
    final response = await _api.login(
      email: email,
      password: password,
      locale: locale,
    );
    await _storage.saveToken(response.token);
    
    // НЕ сохраняем пользователя из ответа логина сразу
    // Сохранение произойдет после проверки профиля в AuthNotifier
    // Это гарантирует, что мы не сохраним устаревшие данные профиля
    
    // Для верифицированных пользователей обогащаем аватаром в фоне
    // Это не блокирует авторизацию
    if (response.user.verified) {
      _enrichWithAvatarInBackground(response.user);
      
      // Инициализируем FCM в фоне (не блокирует авторизацию)
      _initializeFcmInBackground();
    }
    
    // Возвращаем пользователя из ответа
    return LoginResult(
      user: response.user,
      message: response.message,
    );
  }
  
  /// Обогащение пользователя аватаром в фоне
  void _enrichWithAvatarInBackground(User user) {
    Future.microtask(() async {
      try {
        final avatarUrl = await _profileApi.getCurrentAvatarUrl();
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          final enrichedUser = user.copyWith(avatarUrl: avatarUrl);
          await _storage.saveUser(enrichedUser.toJson());
          debugPrint('Avatar enriched in background: $avatarUrl');
        }
      } catch (e) {
        debugPrint('Failed to enrich avatar in background: $e');
      }
    });
  }
  
  /// Инициализация FCM в фоне с защитой от зависания
  void _initializeFcmInBackground() {
    Future.microtask(() async {
      try {
        debugPrint('🔔 FCM (bg): Starting initialization with 3s timeout...');
        await FcmService().initialize().timeout(
          Duration(seconds: 3),
          onTimeout: () {
            debugPrint('⚠️ FCM (bg): Initialization timed out after 3s - continuing without FCM');
            return;
          },
        );
        debugPrint('✅ FCM (bg): Successfully initialized');
      } catch (e) {
        debugPrint('❌ FCM: Error initializing in background: $e');
      }
    });
  }

  Future<LoginResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? locale,
  }) async {
    final response = await _api.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      locale: locale,
    );
    await _storage.saveToken(response.token);

    // Сохраняем пользователя сразу из ответа (быстро)
    await _storage.saveUser(response.user.toJson());
    
    // Для верифицированных пользователей обогащаем аватаром в фоне
    if (response.user.verified) {
      _enrichWithAvatarInBackground(response.user);
      
      // Инициализируем FCM в фоне (не блокирует регистрацию)
      _initializeFcmInBackground();
    }
    
    // Возвращаем пользователя из ответа (быстро)
    return LoginResult(
      user: response.user,
      message: response.message,
    );
  }

  Future<void> logout() async {
    try {
      // 1) Удаляем FCM токен на сервере пока access token ещё валиден
      try {
        debugPrint('=== Logout: Unregistering FCM token ===');
        await FcmService().unregisterToken();
        debugPrint('=== Logout: FCM token unregistered ===');
      } catch (e) {
        debugPrint('FCM: Error unregistering token on logout: $e');
        // Продолжаем logout даже если FCM токен не удалось удалить
      }

      // 2) Стандартный logout на бэкенде
      await _api.logout();
    } catch (_) {
      // Ignore API errors during logout
    } finally {
      // 3) ВАЖНО: Полностью чистим все локальные данные пользователя
      // Это гарантирует, что при следующем входе не будут использоваться старые данные
      debugPrint('=== Logout: Clearing all user data ===');
      await _storage.deleteToken();
      await _storage.deleteUser();
      
      // Дополнительная проверка: убеждаемся, что данные действительно удалены
      final tokenAfterDelete = await _storage.getToken();
      final userAfterDelete = await _storage.getUser();
      debugPrint('Token after delete: ${tokenAfterDelete != null ? "EXISTS (ERROR!)" : "null (OK)"}');
      debugPrint('User after delete: ${userAfterDelete != null ? "EXISTS (ERROR!)" : "null (OK)"}');
      debugPrint('=== Logout: All data cleared ===');
    }
  }

  /// Clear session without calling logout API
  /// Used after registration to prevent auto-authentication
  Future<void> clearSession() async {
    await _storage.deleteToken();
    await _storage.deleteUser();
  }

  Future<bool> hasSession() async {
    return await _storage.hasToken();
  }

  Future<User?> getSavedUser() async {
    final userJson = await _storage.getUser();
    if (userJson != null) {
      return User.fromJson(userJson);
    }
    return null;
  }

  Future<String?> getToken() async {
    return await _storage.getToken();
  }

  Future<void> saveUser(User user) async {
    await _storage.saveUser(user.toJson());
  }

  /// Update user locale on backend
  Future<bool> updateLocale(String locale) async {
    try {
      final updatedLocale = await _api.updateLocale(locale);
      // Обновляем locale в сохраненном пользователе
      final user = await getSavedUser();
      if (user != null) {
        final updatedUser = user.copyWith(locale: updatedLocale);
        await saveUser(updatedUser);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating locale: $e');
      return false;
    }
  }

  /// Get user profile from ProfileApi
  /// Used to check if user has a profile after authentication
  Future<User> getProfile() async {
    final user = await _profileApi.getProfile();
    
    debugPrint('=== getProfile: User from ProfileApi ===');
    debugPrint('Profile from API: ${user.profile}');
    debugPrint('Profile type: ${user.profile.runtimeType}');

    // ВАЖНО: Проверяем профиль ДО обогащения аватаром
    // Если профиль null или не имеет 'id', устанавливаем его в null
    final profileData = user.profile;
    final isValidProfile = profileData?.id != null;

    if (!isValidProfile) {
      // Профиль не валиден (нет id) - устанавливаем null
      debugPrint('Profile has no valid id, setting to null');
    } else {
      debugPrint('Profile has valid id: ${profileData!.id}');
    }

    // Обогащаем аватаром только если профиль валиден
    User finalUser;
    if (isValidProfile) {
      finalUser = await _enrichWithAvatar(user);
    } else {
      finalUser = user.copyWith(clearProfile: true);
    }
    
    await _storage.saveUser(finalUser.toJson());
    
    debugPrint('=== getProfile: Final User ===');
    debugPrint('Final profile: ${finalUser.profile}');
    debugPrint('Final profile type: ${finalUser.profile.runtimeType}');
    debugPrint('Has profile id: ${finalUser.profile?.id}');
    
    return finalUser;
  }

  /// Fetch fresh user profile from API and save to storage
  Future<User> refreshUser() async {
    final user = await _api.getCurrentUser();
    
    debugPrint('=== refreshUser: User from API ===');
    debugPrint('Profile from API: ${user.profile}');
    debugPrint('Profile type: ${user.profile.runtimeType}');

    // ВАЖНО: Проверяем профиль ДО обогащения аватаром
    // Если профиль null или не имеет 'id', устанавливаем его в null
    final profileData = user.profile;
    final isValidProfile = profileData?.id != null;

    if (!isValidProfile) {
      // Профиль не валиден (нет id) - устанавливаем null
      debugPrint('Profile has no valid id, setting to null');
    } else {
      debugPrint('Profile has valid id: ${profileData!.id}');
    }

    // Обогащаем аватаром только если профиль валиден
    User finalUser;
    if (isValidProfile) {
      finalUser = await _enrichWithAvatar(user);
    } else {
      finalUser = user.copyWith(clearProfile: true);
    }
    
    await _storage.saveUser(finalUser.toJson());
    
    debugPrint('=== refreshUser: Final User ===');
    debugPrint('Final profile: ${finalUser.profile}');
    debugPrint('Final profile type: ${finalUser.profile.runtimeType}');
    debugPrint('Has profile id: ${finalUser.profile?.id}');
    
    return finalUser;
  }

  /// Forgot password - send reset email
  Future<String> forgotPassword({required String email}) async {
    return await _api.forgotPassword(email: email);
  }

  /// Resend email verification
  Future<String> resendEmailVerification() async {
    return await _api.resendEmailVerification();
  }

}
