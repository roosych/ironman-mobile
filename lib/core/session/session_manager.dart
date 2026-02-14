import 'dart:async';
import 'package:flutter/material.dart';
import '../../shared/utils/alert_helper.dart';
import '../storage/secure_storage.dart';

/// Centralized session manager for handling session expiry (401 Unauthenticated).
///
/// This manager:
/// - Provides a single point for handling session expiry across the app
/// - Prevents infinite logout loops with [isLoggingOut] flag
/// - Clears token and user data from secure storage
/// - Navigates to login screen and shows session expired message
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final SecureStorage _storage = SecureStorage();

  /// Global navigator key for navigation without BuildContext
  GlobalKey<NavigatorState>? navigatorKey;

  /// Callback to clear auth state in the provider
  VoidCallback? onForceLogout;

  /// Flag to prevent multiple simultaneous logout attempts
  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  /// Initialize the session manager with navigator key and logout callback
  void init({
    required GlobalKey<NavigatorState> navigatorKey,
    required VoidCallback onForceLogout,
  }) {
    this.navigatorKey = navigatorKey;
    this.onForceLogout = onForceLogout;
  }

  /// Handle 401 Unauthenticated response.
  ///
  /// This method:
  /// 1. Checks if logout is already in progress (prevents infinite loops)
  /// 2. Clears token and user from secure storage
  /// 3. Clears auth state via callback
  /// 4. Navigates to login screen
  /// 5. Shows session expired snackbar
  Future<void> handleSessionExpired() async {
    // Prevent multiple simultaneous logout attempts
    if (_isLoggingOut) {
      debugPrint('SessionManager: Logout already in progress, ignoring');
      return;
    }

    _isLoggingOut = true;
    debugPrint('SessionManager: Handling session expired (401)');

    try {
      // 1. Clear token and user from storage с таймаутом
      await Future.wait([
        _storage.deleteToken(),
        _storage.deleteUser(),
      ]).timeout(
        const Duration(seconds: 3), // Таймаут для операций очистки
        onTimeout: () {
          debugPrint('⚠️ SessionManager: Storage cleanup TIMEOUT');
          return []; // Продолжаем даже при таймауте
        },
      );
      debugPrint('SessionManager: Token and user cleared from storage');

      // 2. Clear auth state via callback
      try {
        onForceLogout?.call();
        debugPrint('SessionManager: Auth state cleared');
      } catch (e) {
        debugPrint('SessionManager: Error clearing auth state: $e');
      }

      // 3. Navigate to login and show message
      final navigator = navigatorKey?.currentState;
      if (navigator != null) {
        // Navigate to login, clearing the entire navigation stack
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);

        // Show snackbar after navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSessionExpiredMessage();
        });
      }
    } finally {
      // Reset flag after a short delay to ensure all pending 401s are ignored
      Future.delayed(const Duration(milliseconds: 500), () {
        _isLoggingOut = false;
        debugPrint('SessionManager: Logout complete, flag reset');
      });
    }
  }

  void _showSessionExpiredMessage() {
    final context = navigatorKey?.currentContext;
    if (context != null) {
      AlertHelper.showError(
        context,
        'Your session has expired. Please log in again.',
      );
    }
  }
}
