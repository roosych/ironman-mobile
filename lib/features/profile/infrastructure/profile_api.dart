import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../auth/domain/user.dart';
import '../domain/athlete_profile.dart';
import '../domain/user_photo.dart';

/// Exception for profile API errors
class ProfileApiException implements Exception {
  final String message;
  ProfileApiException(this.message);

  @override
  String toString() => message;
}

class ProfileApi {
  final ApiClient _client;

  ProfileApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Get user profile
  /// GET /user/profile
  Future<User> getProfile() async {
    try {
      final response = await _client.get('/user/profile');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final userData = data['data'] as Map<String, dynamic>;
        return User.fromJson(userData);
      }
      
      // Try to get localized error message from API
      final errorMessage = data['message'] as String?;
      if (errorMessage != null) {
        throw ProfileApiException(errorMessage);
      }
      
      // Check for errors field (localized validation errors)
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw ProfileApiException(firstError.first.toString());
        }
      }
      
      throw ProfileApiException('NETWORK_SERVER_ERROR_unknown');
    } on DioException catch (e) {
      debugPrint('ProfileApi.getProfile DioException: $e');
      
      // For network errors without server response, use client-side localization codes
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ProfileApiException('NETWORK_TIMEOUT');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw ProfileApiException('NETWORK_CONNECTION_ERROR');
      }
      
      // For server errors, try to get localized message from response
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data as Map<String, dynamic>?;
      
      // Check for localized message
      final message = responseData?['message'] as String?;
      if (message != null) {
        throw ProfileApiException(message);
      }
      
      // Check for localized errors
      final errors = responseData?['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw ProfileApiException(firstError.first.toString());
        }
      }
      
      throw ProfileApiException('NETWORK_SERVER_ERROR_${statusCode ?? "unknown"}');
    }
  }

  /// Update user profile
  /// PUT /user/profile
  /// Returns a map with 'data' and 'message' (localized from API)
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String? bio,
    required SocialLinks socialLinks,
  }) async {
    try {
      final response = await _client.put(
        '/user/profile',
        data: {
          'name': name,
          'bio': bio,
          'social_links': socialLinks.toJson(),
        },
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        // Return both data and message (message is already localized from API)
        return {
          'data': data['data'] as Map<String, dynamic>? ?? {},
          'message': data['message'] as String?,
        };
      }
      
      // If success is false, try to get localized error message
      final errorMessage = data['message'] as String?;
      if (errorMessage != null) {
        throw ProfileApiException(errorMessage);
      }
      
      // Check for errors field (localized validation errors)
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw ProfileApiException(firstError.first.toString());
        }
      }
      
      throw ProfileApiException('Failed to update profile');
    } on DioException catch (e) {
      debugPrint('ProfileApi.updateProfile DioException: $e');
      
      // For network errors without server response, use client-side localization
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ProfileApiException('NETWORK_TIMEOUT');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw ProfileApiException('NETWORK_CONNECTION_ERROR');
      }
      
      // For server errors, try to get localized message from response
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data as Map<String, dynamic>?;
      
      // Check for localized message
      final message = responseData?['message'] as String?;
      if (message != null) {
        throw ProfileApiException(message);
      }
      
      // Check for localized errors
      final errors = responseData?['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw ProfileApiException(firstError.first.toString());
        }
      }
      
      throw ProfileApiException('NETWORK_SERVER_ERROR_${statusCode ?? "unknown"}');
    }
  }

  /// Get user's photos
  /// GET /user/photos
  Future<List<UserPhoto>> getUserPhotos() async {
    try {
      final response = await _client.get('/user/photos');
      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final list = data['data'] as List<dynamic>;
        return list
            .whereType<Map<String, dynamic>>()
            .map(UserPhoto.fromJson)
            .toList();
      }
      
      // Try to get localized error message from API
      final errorMessage = data['message'] as String?;
      if (errorMessage != null) {
        throw ProfileApiException(errorMessage);
      }
      
      throw ProfileApiException('Failed to load user photos');
    } on DioException catch (e) {
      debugPrint('ProfileApi.getUserPhotos DioException: $e');
      
      // For network errors without server response, use client-side localization codes
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ProfileApiException('NETWORK_TIMEOUT');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw ProfileApiException('NETWORK_CONNECTION_ERROR');
      }
      
      // For server errors, try to get localized message from response
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data as Map<String, dynamic>?;
      
      // Check for localized message
      final message = responseData?['message'] as String?;
      if (message != null) {
        throw ProfileApiException(message);
      }
      
      throw ProfileApiException('NETWORK_SERVER_ERROR_${statusCode ?? "unknown"}');
    }
  }

  /// Convenience helper to get the current avatar photo url (if any)
  Future<String?> getCurrentAvatarUrl() async {
    final photos = await getUserPhotos();
    for (final p in photos) {
      if (p.isAvatar) return p.url;
    }
    return null;
  }

  /// Upload photo to server
  /// POST /user/photos
  Future<UserPhoto> uploadPhoto(File file) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'photos[]': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final response = await _client.dio.post(
      '/user/photos',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      final photos = data['data']['photos'] as List<dynamic>;
      if (photos.isNotEmpty) {
        return UserPhoto.fromJson(photos.first as Map<String, dynamic>);
      }
    }

    throw Exception('Failed to upload photo');
  }

  /// Set photo as avatar
  /// POST /user/profile/avatar
  Future<UserPhoto> setAvatar(int photoId) async {
    final response = await _client.post(
      '/user/profile/avatar',
      data: {'photo_id': photoId},
    );

    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return UserPhoto.fromJson(data['data']['photo'] as Map<String, dynamic>);
    }

    throw Exception('Failed to set avatar');
  }

  /// Delete photo
  /// DELETE /user/photos/{id}
  Future<void> deletePhoto(int photoId) async {
    final response = await _client.delete('/user/photos/$photoId');

    final data = response.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception('Failed to delete photo');
    }
  }

  /// Link existing profile to user by code
  /// POST /profiles/link
  Future<User> linkProfile(String code) async {
    try {
      // Приводим код к верхнему регистру
      final upperCode = code.toUpperCase();
      
      final response = await _client.post(
        '/profiles/link',
        data: {'code': upperCode},
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        // API возвращает профиль, но нам нужен полный объект User
        // Получаем текущего пользователя, который теперь должен иметь профиль
        return await getProfile();
      }
      throw ProfileApiException(
        data['message'] as String? ?? 'Failed to link profile',
      );
    } on DioException catch (e) {
      // Детальное логирование для отладки
      debugPrint('=== LINK PROFILE ERROR ===');
      debugPrint('Error type: ${e.type}');
      debugPrint('Error message: ${e.message}');
      debugPrint('Request URL: ${e.requestOptions.uri}');
      debugPrint('Request path: ${e.requestOptions.path}');
      debugPrint('Request data: ${e.requestOptions.data}');
      if (e.response != null) {
        debugPrint('Response status: ${e.response!.statusCode}');
        debugPrint('Response data: ${e.response!.data}');
      }
      debugPrint('========================');
      
      // For network errors without server response, use client-side localization codes
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ProfileApiException('NETWORK_TIMEOUT');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw ProfileApiException('NETWORK_CONNECTION_ERROR');
      }
      
      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data as Map<String, dynamic>?;
      
      // Try to get localized message from API response first
      if (errorData != null) {
        final message = errorData['message'] as String?;
        if (message != null) {
          throw ProfileApiException(message); // Already localized from API
        }
        
        // Check for localized errors field
        final errors = errorData['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          // Check for code errors first (most specific)
          final codeErrors = errors['code'] as List<dynamic>?;
          if (codeErrors != null && codeErrors.isNotEmpty) {
            // Get first error message (already localized from API)
            throw ProfileApiException(codeErrors.first.toString());
          }
          
          // Get first error from any field (already localized from API)
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw ProfileApiException(firstError.first.toString());
          }
        }
      }
      
      // Fallback for specific status codes
      if (statusCode == 401) {
        throw ProfileApiException('NETWORK_SERVER_ERROR_401');
      }
      
      throw ProfileApiException('NETWORK_SERVER_ERROR_${statusCode ?? "unknown"}');
    }
  }

  /// Create new profile for user
  /// POST /profiles/create
  Future<User> createProfile({String role = 'athlete'}) async {
    try {
      final response = await _client.post(
        '/profiles/create',
        data: {'role': role},
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        // После создания профиля получаем обновленного пользователя
        return await getProfile();
      }
      // Try to get localized error message from API
      final errorMessage = data['message'] as String?;
      if (errorMessage != null) {
        throw ProfileApiException(errorMessage);
      }
      
      // Check for errors field (localized validation errors)
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw ProfileApiException(firstError.first.toString());
        }
      }
      
      throw ProfileApiException('NETWORK_SERVER_ERROR_unknown');
    } on DioException catch (e) {
      debugPrint('ProfileApi.createProfile DioException: $e');
      
      // For network errors without server response, use client-side localization codes
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ProfileApiException('NETWORK_TIMEOUT');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw ProfileApiException('NETWORK_CONNECTION_ERROR');
      }
      
      // For server errors, try to get localized message from response
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data as Map<String, dynamic>?;
      
      // Check for localized message
      final message = responseData?['message'] as String?;
      if (message != null) {
        throw ProfileApiException(message);
      }
      
      // Check for localized errors
      final errors = responseData?['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw ProfileApiException(firstError.first.toString());
        }
      }
      
      throw ProfileApiException('NETWORK_SERVER_ERROR_${statusCode ?? "unknown"}');
    }
  }
}
