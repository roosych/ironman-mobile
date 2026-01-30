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
    await _storage.write(key: _tokenKey, value: token);
    debugPrint('=== SecureStorage: Token saved ===');
    final verify = await _storage.read(key: _tokenKey);
    debugPrint('Token verification: ${verify != null ? "${verify.substring(0, 20)}..." : "null"}');
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    debugPrint('=== SecureStorage: Token retrieved ===');
    debugPrint('Token: ${token != null ? "${token.substring(0, 20)}..." : "null"}');
    return token;
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUser(Map<String, dynamic> userJson) async {
    await _storage.write(key: _userKey, value: jsonEncode(userJson));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userStr = await _storage.read(key: _userKey);
    if (userStr != null && userStr.isNotEmpty) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
  }
}
