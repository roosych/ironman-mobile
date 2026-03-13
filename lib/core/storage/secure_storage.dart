import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';

  // In-memory cache — eliminates SecureStorage read contention on parallel requests
  static String? _cachedToken;
  static String? _cachedRefreshToken;

  final FlutterSecureStorage _storage;

  SecureStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token).timeout(
        const Duration(seconds: 2),
      );
      debugPrint('=== SecureStorage: Token saved ===');
    } catch (e) {
      debugPrint('❌ SecureStorage.saveToken() ERROR: $e');
    }
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      final token = await _storage.read(key: _tokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      _cachedToken = token;
      debugPrint('=== SecureStorage: Token retrieved ===');
      debugPrint('Token: ${token != null ? "${token.substring(0, 20)}..." : "null"}');
      return token;
    } catch (e) {
      debugPrint('❌ SecureStorage.getToken() ERROR: $e');
      return null;
    }
  }

  Future<void> deleteToken() async {
    _cachedToken = null;
    try {
      await _storage.delete(key: _tokenKey).timeout(
        const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('❌ SecureStorage.deleteToken() ERROR: $e');
    }
  }

  Future<void> saveRefreshToken(String token) async {
    _cachedRefreshToken = token;
    try {
      await _storage.write(key: _refreshTokenKey, value: token).timeout(
        const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('❌ SecureStorage.saveRefreshToken() ERROR: $e');
    }
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    try {
      final token = await _storage.read(key: _refreshTokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      _cachedRefreshToken = token;
      return token;
    } catch (e) {
      debugPrint('❌ SecureStorage.getRefreshToken() ERROR: $e');
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    _cachedRefreshToken = null;
    try {
      await _storage.delete(key: _refreshTokenKey).timeout(
        const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('❌ SecureStorage.deleteRefreshToken() ERROR: $e');
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
