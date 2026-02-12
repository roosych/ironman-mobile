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

      // Timeout wrapper around API call
      final message = await Future.any([
        _api.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
          newPasswordConfirmation: newPasswordConfirmation,
        ),
        Future.delayed(const Duration(seconds: 15), () {
          debugPrint('ChangePasswordNotifier: API call timeout after 15 seconds');
          throw Exception('API_TIMEOUT');
        }),
      ]);

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
}

