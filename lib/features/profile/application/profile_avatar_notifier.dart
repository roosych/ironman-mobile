import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/application/auth_notifier.dart';
import '../infrastructure/profile_api.dart';
import 'profile_avatar_state.dart';

final profileAvatarProvider =
    StateNotifierProvider<ProfileAvatarNotifier, ProfileAvatarState>((ref) {
  return ProfileAvatarNotifier(ref);
});

/// Handles avatar upload only.
/// avatarUrl is stored in AuthState.user.avatarUrl (Single Source of Truth)
class ProfileAvatarNotifier extends StateNotifier<ProfileAvatarState> {
  final Ref _ref;
  final ProfileApi _api;
  final ImagePicker _picker;

  ProfileAvatarNotifier(this._ref, {ProfileApi? api, ImagePicker? picker})
      : _api = api ?? ProfileApi(),
        _picker = picker ?? ImagePicker(),
        super(const ProfileAvatarState());

  /// Pick image from gallery and upload as avatar
  Future<void> pickAndUploadAvatar() async {
    try {
      // 1. Open picker
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        return; // User cancelled
      }

      state = state.copyWith(isLoading: true, clearError: true);

      // 2. Upload photo
      final file = File(image.path);
      final uploadedPhoto = await _api.uploadPhoto(file);

      // 3. Set as avatar
      final avatarPhoto = await _api.setAvatar(uploadedPhoto.id);

      // 4. Update avatar in AuthState (Single Source of Truth)
      _ref.read(authProvider.notifier).updateAvatar(avatarPhoto.url);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить фото',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
