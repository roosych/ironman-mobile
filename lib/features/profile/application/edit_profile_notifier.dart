import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_notifier.dart';
import '../domain/athlete_profile.dart';
import '../infrastructure/profile_api.dart';
import 'edit_profile_state.dart';

final editProfileProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>((ref) {
  return EditProfileNotifier(ref);
});

/// Handles edit profile operations
class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final Ref _ref;
  final ProfileApi _api;

  EditProfileNotifier(this._ref, {ProfileApi? api})
      : _api = api ?? ProfileApi(),
        super(const EditProfileState()) {
    _loadInitialDataFromLocal();
  }

  /// Load initial data from local auth state (fast, no network)
  void _loadInitialDataFromLocal() {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    AthleteProfile athleteProfile = const AthleteProfile();
    if (user.profile != null) {
      athleteProfile = AthleteProfile.fromJson(user.profile!.toJson());
    }

    state = state.copyWith(
      name: user.name,
      athleteProfile: athleteProfile,
    );
  }

  /// Load profile data from API
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _api.getProfile();

      AthleteProfile athleteProfile = const AthleteProfile();
      if (user.profile != null) {
        athleteProfile = AthleteProfile.fromJson(user.profile!.toJson());
      }

      state = state.copyWith(
        isLoading: false,
        name: user.name,
        athleteProfile: athleteProfile,
      );

      // Update auth state with fresh data
      _ref.read(authProvider.notifier).setUser(user);
    } on ProfileApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile',
      );
    }
  }

  /// Update name field
  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  /// Update bio field
  void updateBio(String bio) {
    state = state.copyWith(
      athleteProfile: state.athleteProfile.copyWith(bio: bio),
    );
  }

  /// Update strava link
  void updateStrava(String strava) {
    state = state.copyWith(
      athleteProfile: state.athleteProfile.copyWith(
        socialLinks: state.athleteProfile.socialLinks.copyWith(strava: strava),
      ),
    );
  }

  /// Update instagram link
  void updateInstagram(String instagram) {
    state = state.copyWith(
      athleteProfile: state.athleteProfile.copyWith(
        socialLinks:
            state.athleteProfile.socialLinks.copyWith(instagram: instagram),
      ),
    );
  }

  /// Update facebook link
  void updateFacebook(String facebook) {
    state = state.copyWith(
      athleteProfile: state.athleteProfile.copyWith(
        socialLinks:
            state.athleteProfile.socialLinks.copyWith(facebook: facebook),
      ),
    );
  }

  /// Save profile changes
  Future<void> saveProfile() async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      // Update profile and get localized success message from API
      final updateResult = await _api.updateProfile(
        name: state.name,
        bio: state.athleteProfile.bio,
        socialLinks: state.athleteProfile.socialLinks,
      );

      // After successful save, load fresh profile data from API
      // This ensures we have the latest data including name and profile
      final user = await _api.getProfile();

      AthleteProfile athleteProfile = const AthleteProfile();
      if (user.profile != null) {
        athleteProfile = AthleteProfile.fromJson(user.profile!.toJson());
      }

      // Use message from API if available (already localized), otherwise use default
      final successMessage = updateResult['message'] as String? ?? 'Profile saved successfully';

      state = state.copyWith(
        isSaving: false,
        name: user.name,
        athleteProfile: athleteProfile,
        successMessage: successMessage, // Already localized from API
      );

      // Update auth state with fresh data from server (persists to storage)
      // This ensures all screens that read from authProvider will see updated data
      await _ref.read(authProvider.notifier).updateUser(user);
    } on ProfileApiException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.message, // Already localized from API
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
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
