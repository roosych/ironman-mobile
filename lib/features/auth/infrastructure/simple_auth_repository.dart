import 'package:flutter/foundation.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/simple_api_client.dart';
import '../domain/user.dart';
import 'simple_auth_api.dart';

/// Простой репозиторий для аутентификации
class SimpleAuthRepository {
  final SimpleAuthApi _api = SimpleAuthApi();
  final SecureStorage _storage = SecureStorage();

  /// Логин
  Future<AuthResult?> login({
    required String email,
    required String password,
    String? locale,
  }) async {
    final response = await _api.login(
      email: email,
      password: password,
      locale: locale,
    );

    if (response.isSuccess && response.data != null) {
      final result = response.data!;

      // Сохраняем токен и пользователя
      await _storage.saveToken(result.token);
      await _storage.saveUser(result.user.toJson());

      return result;
    }

    return null;
  }

  /// Регистрация
  Future<AuthResult?> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? locale,
    String? countryCode,
  }) async {
    final response = await _api.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      locale: locale,
      countryCode: countryCode,
    );

    if (response.isSuccess && response.data != null) {
      final result = response.data!;

      // Сохраняем токен и пользователя
      await _storage.saveToken(result.token);
      await _storage.saveUser(result.user.toJson());

      return result;
    }

    return null;
  }

  /// Выход
  Future<bool> logout() async {
    try {
      // Пытаемся выйти через API (не критично если не получится)
      await _api.logout();
    } catch (e) {
      debugPrint('Logout API error (ignored): $e');
    }

    // Всегда очищаем локальные данные
    await _storage.deleteToken();
    await _storage.deleteUser();

    return true;
  }

  /// Проверка сессии
  Future<bool> hasSession() async {
    return await _storage.hasToken();
  }

  /// Получение сохраненного пользователя
  Future<User?> getSavedUser() async {
    final userJson = await _storage.getUser();
    if (userJson != null) {
      return User.fromJson(userJson);
    }
    return null;
  }

  /// Получение токена
  Future<String?> getToken() async {
    return await _storage.getToken();
  }

  /// Сохранение пользователя
  Future<void> saveUser(User user) async {
    await _storage.saveUser(user.toJson());
  }

  /// Обновление пользователя с сервера
  Future<User?> refreshUser() async {
    final response = await _api.getCurrentUser();

    if (response.isSuccess && response.data != null) {
      final user = response.data!;
      await saveUser(user);
      return user;
    }

    return null;
  }

  /// Обновление языка
  Future<String?> updateLocale(String locale) async {
    final response = await _api.updateLocale(locale);

    if (response.isSuccess && response.data != null) {
      final newLocale = response.data!.locale;

      // Обновляем locale в сохраненном пользователе
      final user = await getSavedUser();
      if (user != null) {
        final updatedUser = user.copyWith(locale: newLocale);
        await saveUser(updatedUser);
      }

      return newLocale;
    }

    return null;
  }

  /// Восстановление пароля
  Future<String?> forgotPassword({required String email}) async {
    final response = await _api.forgotPassword(email: email);

    if (response.isSuccess && response.data != null) {
      return response.data!.message;
    }

    return null;
  }

  /// Повторная отправка письма верификации
  Future<String?> resendEmailVerification() async {
    final response = await _api.resendEmailVerification();

    if (response.isSuccess && response.data != null) {
      return response.data!.message;
    }

    return null;
  }

  /// Смена пароля
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await _api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      newPasswordConfirmation: newPasswordConfirmation,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!.message;
    }

    return null;
  }

  /// Очистка сессии без вызова API
  Future<void> clearSession() async {
    await _storage.deleteToken();
    await _storage.deleteUser();
  }
}