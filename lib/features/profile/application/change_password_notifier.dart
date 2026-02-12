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

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    debugPrint('ChangePasswordNotifier: Starting password change');

    try {
      // Clear any previous state
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccessMessage: true,
      );

      debugPrint('ChangePasswordNotifier: State cleared, calling API...');

      // Safe API call with multiple layers of protection
      final message = await _safeApiCall(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );

      debugPrint('ChangePasswordNotifier: Password change successful, message: $message');

      if (!mounted) {
        debugPrint('ChangePasswordNotifier: Widget unmounted, skipping success state update');
        return;
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: message, // Already localized from API
      );

      debugPrint('ChangePasswordNotifier: Success state updated');
    } on AuthApiException catch (e) {
      debugPrint('ChangePasswordNotifier: AuthApiException caught: ${e.firstError}');

      if (!mounted) {
        debugPrint('ChangePasswordNotifier: Widget unmounted, skipping error state update');
        return;
      }

      state = state.copyWith(
        isLoading: false,
        error: e.firstError, // Already localized from API
      );

      debugPrint('ChangePasswordNotifier: Error state updated');
    } catch (e, stackTrace) {
      debugPrint('ChangePasswordNotifier: Unexpected error caught: $e');
      debugPrint('ChangePasswordNotifier: Error type: ${e.runtimeType}');
      debugPrint('ChangePasswordNotifier: Stack trace: $stackTrace');

      if (!mounted) {
        debugPrint('ChangePasswordNotifier: Widget unmounted, skipping error state update');
        return;
      }

      String errorMessage = 'NETWORK_ERROR';
      if (e.toString().contains('API_TIMEOUT')) {
        errorMessage = 'API call timed out';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      debugPrint('ChangePasswordNotifier: Generic error state updated');
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

  /// Safe API call with crash protection using native HTTP instead of Dio
  Future<String> _safeApiCall({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    debugPrint('ChangePasswordNotifier: _safeApiCall starting with native HTTP');

    try {
      // Create a completer for better control
      final completer = Completer<String>();

      // Start the API call in a separate "zone" with error handling
      runZonedGuarded(() async {
        try {
          debugPrint('ChangePasswordNotifier: Starting native HTTP API call in protected zone');

          final result = await _nativeHttpChangePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            newPasswordConfirmation: newPasswordConfirmation,
          );

          debugPrint('ChangePasswordNotifier: Native HTTP API call completed successfully in zone');
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        } catch (e, stackTrace) {
          debugPrint('ChangePasswordNotifier: Error in protected zone: $e');
          debugPrint('ChangePasswordNotifier: Zone stack trace: $stackTrace');
          if (!completer.isCompleted) {
            completer.completeError(e, stackTrace);
          }
        }
      }, (error, stackTrace) {
        debugPrint('ChangePasswordNotifier: Zone error handler caught: $error');
        debugPrint('ChangePasswordNotifier: Zone error stack trace: $stackTrace');
        if (!completer.isCompleted) {
          completer.completeError(Exception('ZONE_ERROR: $error'), stackTrace);
        }
      });

      // Add timeout
      return await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 15), () {
          debugPrint('ChangePasswordNotifier: API call timeout after 15 seconds');
          throw Exception('API_TIMEOUT');
        }),
      ]);

    } catch (e, stackTrace) {
      debugPrint('ChangePasswordNotifier: _safeApiCall outer catch: $e');
      debugPrint('ChangePasswordNotifier: _safeApiCall stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Native HTTP implementation to bypass Dio
  Future<String> _nativeHttpChangePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    debugPrint('ChangePasswordNotifier: _nativeHttpChangePassword starting');

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
      debugPrint('Headers: $headers');
      debugPrint('Body: $body');

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

        debugPrint('ChangePasswordNotifier: Processing response...');

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          debugPrint('ChangePasswordNotifier: 200 response parsed: $jsonResponse');
          if (jsonResponse['success'] == true) {
            return jsonResponse['message'] ?? 'Password changed successfully';
          } else {
            throw AuthApiException(jsonResponse['message'] ?? 'Unknown error');
          }
        } else if (response.statusCode == 403) {
          final jsonResponse = jsonDecode(response.body);
          debugPrint('ChangePasswordNotifier: 403 response parsed: $jsonResponse');

          // Handle errors field structure
          if (jsonResponse['errors'] != null) {
            final errors = jsonResponse['errors'] as Map<String, dynamic>;
            if (errors['current_password'] != null) {
              final currentPasswordErrors = errors['current_password'] as List;
              final errorMessage = currentPasswordErrors.first ?? 'Current password is incorrect';
              debugPrint('ChangePasswordNotifier: Throwing AuthApiException: $errorMessage');
              throw AuthApiException(errorMessage);
            }
          }

          // Fallback to message field or default
          final errorMessage = jsonResponse['message'] ?? 'Incorrect current password';
          debugPrint('ChangePasswordNotifier: Throwing fallback AuthApiException: $errorMessage');
          throw AuthApiException(errorMessage);
        } else {
          debugPrint('ChangePasswordNotifier: Other HTTP error: ${response.statusCode}');
          throw AuthApiException('HTTP ${response.statusCode}: ${response.body}');
        }
      } finally {
        client.close();
      }

    } catch (e, stackTrace) {
      debugPrint('ChangePasswordNotifier: _nativeHttpChangePassword error: $e');
      debugPrint('ChangePasswordNotifier: Stack trace: $stackTrace');
      rethrow;
    }
  }
}

