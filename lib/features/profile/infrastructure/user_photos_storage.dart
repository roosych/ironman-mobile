import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/user_photo.dart';

/// Storage service for user photos using Hive
/// Stores photos as JSON strings for simplicity
class UserPhotosStorage {
  static const String _boxName = 'user_photos';
  static const String _photosKey = 'photos_list';
  Box? _box;

  /// Initialize the storage box
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
  }

  /// Check if box is initialized
  bool get isInitialized => _box != null && _box!.isOpen;

  /// Get all cached photos
  List<UserPhoto> getPhotos() {
    if (!isInitialized) return [];
    
    try {
      final photosJson = _box!.get(_photosKey) as String?;
      if (photosJson == null) return [];
      
      final List<dynamic> decoded = jsonDecode(photosJson);
      return decoded
          .map((json) => UserPhoto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save photos to cache (replaces all existing)
  Future<void> savePhotos(List<UserPhoto> photos) async {
    if (!isInitialized) await init();
    
    try {
      final photosJson = jsonEncode(
        photos.map((photo) => photo.toJson()).toList(),
      );
      await _box!.put(_photosKey, photosJson);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Add a single photo to cache
  Future<void> addPhoto(UserPhoto photo) async {
    if (!isInitialized) await init();
    
    final currentPhotos = getPhotos();
    currentPhotos.insert(0, photo); // Add to beginning
    await savePhotos(currentPhotos);
  }

  /// Update a photo in cache
  Future<void> updatePhoto(UserPhoto photo) async {
    if (!isInitialized) await init();
    
    final currentPhotos = getPhotos();
    final index = currentPhotos.indexWhere((p) => p.id == photo.id);
    if (index != -1) {
      currentPhotos[index] = photo;
      await savePhotos(currentPhotos);
    }
  }

  /// Remove a photo from cache
  Future<void> removePhoto(int photoId) async {
    if (!isInitialized) return;
    
    final currentPhotos = getPhotos();
    currentPhotos.removeWhere((p) => p.id == photoId);
    await savePhotos(currentPhotos);
  }

  /// Clear all cached photos
  Future<void> clear() async {
    if (!isInitialized) return;
    await _box!.delete(_photosKey);
  }

  /// Close the box
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }
}

