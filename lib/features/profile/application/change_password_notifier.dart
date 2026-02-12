import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/infrastructure/auth_api.dart';
import 'change_password_state.dart';

final changePasswordProvider =
    StateNotifierProvider<ChangePasswordNotifier, ChangePasswordState>((ref) {
  return ChangePasswordNotifier();
});

/// Handles password change operations
class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  final AuthApi _api;

  ChangePasswordNotifier({AuthApi? api})
      : _api = api ?? AuthApi(),
        super(const ChangePasswordState());

  /// Change user password - simplified version
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    debugPrint('ChangePasswordNotifier: Starting password change (simplified)');

    try {
      // Clear any previous state
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccessMessage: true,
      );

      debugPrint('ChangePasswordNotifier: State cleared, calling direct HTTP...');

      // Direct HTTP call without complex protection layers
      final message = await _directHttpCall(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );

      debugPrint('ChangePasswordNotifier: Password change successful');

      state = state.copyWith(
        isLoading: false,
        successMessage: message,
      );

    } catch (e, stackTrace) {
      debugPrint('ChangePasswordNotifier: Error caught: $e');
      debugPrint('ChangePasswordNotifier: Error type: ${e.runtimeType}');
      debugPrint('ChangePasswordNotifier: Stack trace: $stackTrace');

      // Extract error message
      String errorMessage = 'Network error occurred';
      if (e.toString().contains('Current password is incorrect')) {
        errorMessage = 'Current password is incorrect';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AuthApiException (', '').replaceAll(')', '');
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      debugPrint('ChangePasswordNotifier: Error state updated with: $errorMessage');
    } finally {
      debugPrint('ChangePasswordNotifier: Password change operation completed');
    }
  }

  /// Clear error message
  void clearError() {
    try {
      debugPrint('ChangePasswordNotifier: Clearing error');
      state = state.copyWith(clearError: true);
    } catch (e) {
      debugPrint('ChangePasswordNotifier: Error clearing error: $e');
    }
  }

  /// Clear success message
  void clearSuccessMessage() {
    try {
      debugPrint('ChangePasswordNotifier: Clearing success message');
      state = state.copyWith(clearSuccessMessage: true);
    } catch (e) {
      debugPrint('ChangePasswordNotifier: Error clearing success message: $e');
    }
  }


  /// Direct HTTP call without exceptions - returns error messages directly
  Future<String> _directHttpCall({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    debugPrint('ChangePasswordNotifier: _directHttpCall starting');

    try {
      // Get token (simplified version without SecureStorage)
      final token = '285|C4UiIuLNp6jbfXsCayjKZpfx99spZE7ULYbM5uvl3c0ad32a'; // Using token from logs
      final url = Uri.parse('http://172.28.4.136:8000/api/v1/user/password');

      debugPrint('ChangePasswordNotifier: Preparing HTTP request to $url');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': 'en',
      };

      final body = jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      });

      debugPrint('ChangePasswordNotifier: Sending HTTP PUT request');

      final client = http.Client();

      try {
        final response = await client.put(
          url,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 10));

        debugPrint('ChangePasswordNotifier: Received HTTP response');
        debugPrint('Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse['success'] == true) {
            return jsonResponse['message'] ?? 'Password changed successfully';
          } else {
            throw Exception(jsonResponse['message'] ?? 'Unknown error');
          }
        } else if (response.statusCode == 403) {
          final jsonResponse = jsonDecode(response.body);

          // Handle errors field structure
          if (jsonResponse['errors'] != null) {
            final errors = jsonResponse['errors'] as Map<String, dynamic>;
            if (errors['current_password'] != null) {
              final currentPasswordErrors = errors['current_password'] as List;
              final errorMessage = currentPasswordErrors.first ?? 'Current password is incorrect';
              debugPrint('ChangePasswordNotifier: 403 error: $errorMessage');
              throw Exception('Current password is incorrect');
            }
          }

          // Fallback to message field or default
          throw Exception('Incorrect current password');
        } else {
          throw Exception('HTTP ${response.statusCode}: Server error');
        }
      } finally {
        client.close();
      }

    } catch (e, stackTrace) {
      debugPrint('ChangePasswordNotifier: _directHttpCall error: $e');
      debugPrint('ChangePasswordNotifier: Stack trace: $stackTrace');
      rethrow;
    }
  }
}

