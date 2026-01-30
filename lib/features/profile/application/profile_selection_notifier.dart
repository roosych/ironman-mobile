import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/user.dart';
import '../../auth/infrastructure/auth_repository.dart';
import '../infrastructure/profile_api.dart';
import 'profile_selection_state.dart';

final profileSelectionProvider = StateNotifierProvider<ProfileSelectionNotifier, ProfileSelectionState>((ref) {
  return ProfileSelectionNotifier();
});

class ProfileSelectionNotifier extends StateNotifier<ProfileSelectionState> {
  final ProfileApi _api;
  final AuthRepository _authRepository;

  ProfileSelectionNotifier({
    ProfileApi? api,
    AuthRepository? authRepository,
  })  : _api = api ?? ProfileApi(),
        _authRepository = authRepository ?? AuthRepository(),
        super(const ProfileSelectionState());

  /// Link existing profile to user by code
  Future<User?> linkProfile(String code) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final updatedUser = await _api.linkProfile(code);
      
      // Save updated user to storage
      await _authRepository.saveUser(updatedUser);
      
      state = state.copyWith(isProcessing: false);
      return updatedUser;
    } catch (e) {
      String errorMessage = 'error_unexpected';
      if (e is ProfileApiException) {
        errorMessage = e.message;
      } else if (e.toString().contains('Connection') || e.toString().contains('network')) {
        errorMessage = 'NETWORK_CONNECTION_ERROR';
      }
      state = state.copyWith(
        isProcessing: false,
        error: errorMessage,
      );
      return null;
    }
  }

  /// Create new profile for user
  Future<User?> createProfile({String role = 'athlete'}) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final updatedUser = await _api.createProfile(role: role);
      
      // Save updated user to storage
      await _authRepository.saveUser(updatedUser);
      
      state = state.copyWith(isProcessing: false);
      return updatedUser;
    } catch (e) {
      String errorMessage = 'error_unexpected';
      if (e is ProfileApiException) {
        errorMessage = e.message;
      } else if (e.toString().contains('Connection') || e.toString().contains('network')) {
        errorMessage = 'NETWORK_CONNECTION_ERROR';
      }
      state = state.copyWith(
        isProcessing: false,
        error: errorMessage,
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

