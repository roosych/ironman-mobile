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
      state = state.copyWith(isLoading: true, clearError: true);

      // Get localized success message from API
      final message = await _api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: message, // Already localized from API
      );
    } on AuthApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.firstError, // Already localized from API
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'NETWORK_ERROR', // Will be localized by ErrorHandler
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(clearSuccessMessage: true);
  }
}

