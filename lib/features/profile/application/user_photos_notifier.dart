import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/network/connectivity_service.dart';
import '../infrastructure/profile_api.dart';
import '../infrastructure/user_photos_storage.dart';
import 'user_photos_state.dart';

final userPhotosProvider =
    StateNotifierProvider<UserPhotosNotifier, UserPhotosState>((ref) {
  return UserPhotosNotifier(ref);
});

class UserPhotosNotifier extends StateNotifier<UserPhotosState> {
  final Ref _ref;
  final ProfileApi _api;
  final ImagePicker _picker;
  final UserPhotosStorage _storage;
  final ConnectivityService _connectivity;

  UserPhotosNotifier(
    this._ref, {
    ProfileApi? api,
    ImagePicker? picker,
    UserPhotosStorage? storage,
    ConnectivityService? connectivity,
  })  : _api = api ?? ProfileApi(),
        _picker = picker ?? ImagePicker(),
        _storage = storage ?? UserPhotosStorage(),
        _connectivity = connectivity ?? ConnectivityService(),
        super(const UserPhotosState()) {
    // Load cached photos on initialization
    _loadCachedPhotos();
  }

  /// Load photos from cache
  Future<void> _loadCachedPhotos() async {
    try {
      await _storage.init();
      final cachedPhotos = _storage.getPhotos();
      if (cachedPhotos.isNotEmpty) {
        state = state.copyWith(photos: cachedPhotos);
      }
    } catch (e) {
      // Ignore cache errors on init
    }
  }

  Future<void> loadPhotos() async {
    if (state.isLoading || state.isRefreshing) return;

    // Show appropriate loading state based on whether we have cached photos
    if (state.photos.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    // Check internet connection
    final hasInternet = await _connectivity.hasInternetConnection();

    if (hasInternet) {
      // If online: fetch from API and update cache
      try {
        final photos = await _api.getUserPhotos();
        
        // Save to cache
        await _storage.savePhotos(photos);
        
        state = state.copyWith(
          photos: photos,
          isLoading: false,
          isRefreshing: false,
        );
      } catch (e) {
        // On error, try to load from cache
        final cachedPhotos = _storage.getPhotos();
        if (cachedPhotos.isNotEmpty) {
          state = state.copyWith(
            photos: cachedPhotos,
            isLoading: false,
            isRefreshing: false,
            error: 'Не удалось загрузить фотографии. Показаны сохраненные.',
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            isRefreshing: false,
            error: 'Не удалось загрузить фотографии',
          );
        }
      }
    } else {
      // If offline: load from cache
      final cachedPhotos = _storage.getPhotos();
      if (cachedPhotos.isNotEmpty) {
        state = state.copyWith(
          photos: cachedPhotos,
          isLoading: false,
          isRefreshing: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: null, // No error, just no photos
        );
      }
    }
  }

  Future<void> refreshPhotos() async {
    if (state.isLoading || state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true, clearError: true);

    // Force refresh: always try to fetch from API
    try {
      final photos = await _api.getUserPhotos();

      // Update cache
      await _storage.savePhotos(photos);

      state = state.copyWith(
        photos: photos,
        isRefreshing: false,
      );
    } catch (e) {
      // On error during refresh, keep current photos (from cache)
      // Don't show error for pull-to-refresh failures
      state = state.copyWith(
        isRefreshing: false,
        error: null,
      );
    }
  }

  /// Set photo as avatar
  Future<bool> setAvatar(int photoId) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final avatarPhoto = await _api.setAvatar(photoId);

      // Update photos list: mark new avatar, unmark old
      final updatedPhotos = state.photos.map((photo) {
        if (photo.id == photoId) {
          return photo.copyWith(isAvatar: true);
        } else if (photo.isAvatar) {
          return photo.copyWith(isAvatar: false);
        }
        return photo;
      }).toList();

      state = state.copyWith(
        photos: updatedPhotos,
        isLoading: false,
        isRefreshing: false,
      );

      // Update cache
      await _storage.savePhotos(updatedPhotos);

      // Update avatar in AuthState (Single Source of Truth)
      _ref.read(authProvider.notifier).updateAvatar(avatarPhoto.url);

      return true;
    } catch (e) {
      final errorMessage = e is ProfileApiException ? e.message : 'photo_avatar_set_error';
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Delete photo
  Future<bool> deletePhoto(int photoId) async {
    if (state.isLoading) return false;

    // Find the photo to check if it's an avatar
    final photoToDelete = state.photos.firstWhere(
      (p) => p.id == photoId,
      orElse: () => throw Exception('Photo not found'),
    );

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.deletePhoto(photoId);

      // Remove photo from list
      final updatedPhotos = state.photos.where((p) => p.id != photoId).toList();

      state = state.copyWith(
        photos: updatedPhotos,
        isLoading: false,
        isRefreshing: false,
      );

      // Update cache
      await _storage.removePhoto(photoId);

      // If deleted photo was avatar, clear avatar in AuthState and refresh user from server
      if (photoToDelete.isAvatar) {
        _ref.read(authProvider.notifier).updateAvatar(null);
        
        // Refresh user profile from server to get updated avatar data
        try {
          await _ref.read(authProvider.notifier).refreshUser();
        } catch (e) {
          // Ignore errors - avatar is already cleared locally
        }
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Не удалось удалить фото',
      );
      return false;
    }
  }

  /// Upload new photo
  Future<bool> uploadPhoto() async {
    if (state.isLoading) return false;

    try {
      // Open image picker
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        return false; // User cancelled
      }

      state = state.copyWith(isLoading: true, clearError: true);

      // Upload photo
      final file = File(image.path);
      final uploadedPhoto = await _api.uploadPhoto(file);

      // Add new photo to the beginning of the list
      final updatedPhotos = [uploadedPhoto, ...state.photos];

      state = state.copyWith(
        photos: updatedPhotos,
        isLoading: false,
        isRefreshing: false,
      );

      // Update cache
      await _storage.addPhoto(uploadedPhoto);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Не удалось загрузить фото',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
