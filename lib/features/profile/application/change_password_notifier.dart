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
    try {
      debugPrint('ChangePasswordNotifier: Starting password change');

      // Clear any previous state
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccessMessage: true,
      );

      // Get localized success message from API
      final message = await _api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );

      debugPrint('ChangePasswordNotifier: Password change successful');

      state = state.copyWith(
        isLoading: false,
        successMessage: message, // Already localized from API
      );
    } on AuthApiException catch (e) {
      debugPrint('ChangePasswordNotifier: AuthApiException: ${e.firstError}');

      state = state.copyWith(
        isLoading: false,
        error: e.firstError, // Already localized from API
      );
    } catch (e, stackTrace) {
      debugPrint('ChangePasswordNotifier: Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        error: 'NETWORK_ERROR', // Will be localized by ErrorHandler
      );
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
}

