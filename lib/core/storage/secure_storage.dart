import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  SecureStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveToken(String token) async {
    try {
      // ФИКС: Таймаут для записи токена
      await _storage.write(key: _tokenKey, value: token).timeout(
        const Duration(seconds: 2),
      );
      debugPrint('=== SecureStorage: Token saved ===');

      // Проверяем сохранение с таймаутом
      final verify = await _storage.read(key: _tokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      debugPrint('Token verification: ${verify != null ? "${verify.substring(0, 20)}..." : "null"}');
    } catch (e) {
      debugPrint('❌ SecureStorage.saveToken() ERROR: $e');
      // Не выбрасываем ошибку, чтобы не ломать процесс авторизации
    }
  }

  Future<String?> getToken() async {
    try {
      // ФИКС: Таймаут 2 секунды для flutter_secure_storage
      final token = await _storage.read(key: _tokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⚠️ SecureStorage.getToken() TIMEOUT после 2 секунд');
          return null; // Возвращаем null при таймауте
        },
      );
      debugPrint('=== SecureStorage: Token retrieved ===');
      debugPrint('Token: ${token != null ? "${token.substring(0, 20)}..." : "null"}');
      return token;
    } catch (e) {
      debugPrint('❌ SecureStorage.getToken() ERROR: $e');
      return null; // Возвращаем null при любой ошибке
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey).timeout(
        const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('❌ SecureStorage.deleteToken() ERROR: $e');
    }
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUser(Map<String, dynamic> userJson) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(userJson)).timeout(
        const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('❌ SecureStorage.saveUser() ERROR: $e');
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final userStr = await _storage.read(key: _userKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (userStr != null && userStr.isNotEmpty) {
        return jsonDecode(userStr) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ SecureStorage.getUser() ERROR: $e');
      return null;
    }
  }

  Future<void> deleteUser() async {
    try {
      await _storage.delete(key: _userKey).timeout(
        const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('❌ SecureStorage.deleteUser() ERROR: $e');
    }
  }
}
