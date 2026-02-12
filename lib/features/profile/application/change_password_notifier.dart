import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'change_password_state.dart';
import '../infrastructure/profile_api.dart';

final changePasswordProvider =
    StateNotifierProvider<ChangePasswordNotifier, ChangePasswordState>((ref) {
  return ChangePasswordNotifier();
});

/// Handles password change operations
class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  final ProfileApi _profileApi;

  ChangePasswordNotifier({ProfileApi? profileApi})
      : _profileApi = profileApi ?? ProfileApi(),
        super(const ChangePasswordState());

  /// Change user password using ProfileApi
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    debugPrint('🚀🚀🚀 ChangePasswordNotifier: NEW VERSION CALLED 🚀🚀🚀');
    debugPrint('ChangePasswordNotifier: Starting password change');

    // Clear any previous state
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccessMessage: true,
    );

    debugPrint('ChangePasswordNotifier: State cleared, calling ProfileApi...');

    try {
      // Add small delay to let UI update before API call
      await Future.delayed(Duration(milliseconds: 100));

      debugPrint('ChangePasswordNotifier: Adding high-level timeout...');

      // Use ProfileApi with high-level timeout wrapper
      final result = await _profileApi.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      ).timeout(Duration(seconds: 8), onTimeout: () {
        debugPrint('ChangePasswordNotifier: HIGH-LEVEL TIMEOUT after 8 seconds');
        return {'success': false, 'message': 'Request timed out'};
      });

      debugPrint('ChangePasswordNotifier: ProfileApi result: $result');

      if (result['success'] == true) {
        debugPrint('ChangePasswordNotifier: Password change successful');
        state = state.copyWith(
          isLoading: false,
          successMessage: result['message'] as String?,
        );
      } else {
        debugPrint('ChangePasswordNotifier: Password change failed');
        state = state.copyWith(
          isLoading: false,
          error: result['message'] as String?,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('ChangePasswordNotifier: Unexpected error caught: $e');
      debugPrint('ChangePasswordNotifier: Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    } finally {
      // Ensure loading state is always cleared
      if (state.isLoading) {
        debugPrint('ChangePasswordNotifier: Finally block - clearing loading state');
        state = state.copyWith(isLoading: false);
      }
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

