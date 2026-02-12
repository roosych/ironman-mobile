import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Safe API call with crash protection
  Future<String> _safeApiCall({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    debugPrint('ChangePasswordNotifier: _safeApiCall starting');

    try {
      // Create a completer for better control
      final completer = Completer<String>();

      // Start the API call in a separate "zone" with error handling
      runZonedGuarded(() async {
        try {
          debugPrint('ChangePasswordNotifier: Starting API call in protected zone');

          final result = await _api.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            newPasswordConfirmation: newPasswordConfirmation,
          );

          debugPrint('ChangePasswordNotifier: API call completed successfully in zone');
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
}

