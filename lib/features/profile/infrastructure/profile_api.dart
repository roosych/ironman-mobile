import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/config/app_config.dart';
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
    String? countryIso,
    int? ironmanNumber,
    required String? bio,
    required SocialLinks socialLinks,
  }) async {
    debugPrint('🌐 ProfileApi.updateProfile: СТАРТ');
    final requestData = {
      'name': name,
      'country_iso': countryIso,
      'ironman_number': ironmanNumber,
      'bio': bio,
      'social_links': socialLinks.toJson(),
    };
    debugPrint('📤 Данные запроса: $requestData');

    try {
      debugPrint('🚀 Отправляем PUT запрос через ApiClient...');

      final response = await _client.put('/user/profile', data: requestData);

      debugPrint('📥 Ответ получен: ${response.statusCode}');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return {
          'data': data['data'] as Map<String, dynamic>? ?? {},
          'message': data['message'] as String?,
        };
      }

      final errorMessage = data['message'] as String?;
      if (errorMessage != null) {
        throw ProfileApiException(errorMessage);
      }

      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw ProfileApiException(firstError.first.toString());
        }
      }

      throw ProfileApiException('Failed to update profile');
    } catch (e) {
      debugPrint('🔴 ProfileApi.updateProfile error: ${e.runtimeType} - $e');

      if (e is DioException && e.message != null) {
        throw ProfileApiException(e.message!);
      }

      if (e is ProfileApiException) {
        rethrow;
      }

      throw ProfileApiException('Произошла ошибка при обновлении профиля');
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
      'photos': await MultipartFile.fromFile(
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
      final photos = data['data'] as List<dynamic>;
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
      final photoData = data['data'];
      // Support both formats: direct object or wrapped {"photo": {...}}
      if (photoData is Map<String, dynamic>) {
        final inner = photoData['photo'];
        if (inner is Map<String, dynamic>) {
          return UserPhoto.fromJson(inner);
        }
        return UserPhoto.fromJson(photoData);
      }
    }

    final message = data['message'] as String?;
    throw ProfileApiException(message ?? 'photo_avatar_set_error');
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

  /// Change user password using plain HTTP client (bypass Dio issues)
  /// PUT /user/password
  /// Returns structured response with success status and message
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    debugPrint('🔥🔥🔥 ProfileApi.changePassword: PLAIN HTTP VERSION 🔥🔥🔥');
    debugPrint('ProfileApi.changePassword: STARTING');

    try {
      // Get token from secure storage
      final storage = SecureStorage();
      final token = await storage.getToken();
      debugPrint('ProfileApi.changePassword: Token retrieved');

      // Prepare request
      final url = Uri.parse('${AppConfig.baseUrl}/auth/password/change');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': 'en',
        'Connection': 'close',
      };

      final body = jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      });

      debugPrint('ProfileApi.changePassword: Sending plain HTTP PUT...');
      debugPrint('ProfileApi.changePassword: URL: $url');

      // Send request with timeout
      final client = http.Client();
      try {
        final response = await client.put(
          url,
          headers: headers,
          body: body,
        ).timeout(Duration(seconds: 10));

        debugPrint('ProfileApi.changePassword: Response received!');
        debugPrint('ProfileApi.changePassword: Status code: ${response.statusCode}');
        debugPrint('ProfileApi.changePassword: Response body: ${response.body}');

        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 200 && data['success'] == true) {
          debugPrint('ProfileApi.changePassword: Success!');
          return {
            'success': true,
            'message': data['message'] ?? 'Password successfully changed.'
          };
        } else if (response.statusCode == 403 || response.statusCode == 422) {
          debugPrint('ProfileApi.changePassword: Validation error');

          final errors = data['errors'] as Map<String, dynamic>?;
          String errorMessage = 'Validation error';

          if (errors != null && errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final firstErrorList = errors[firstKey] as List<dynamic>?;
            if (firstErrorList != null && firstErrorList.isNotEmpty) {
              errorMessage = firstErrorList.first.toString();
            }
          } else if (data['message'] != null) {
            errorMessage = data['message'].toString();
          }

          return {'success': false, 'message': errorMessage};
        } else {
          return {'success': false, 'message': 'Server error: ${response.statusCode}'};
        }
      } finally {
        client.close();
      }

    } catch (e) {
      debugPrint('ProfileApi.changePassword: Plain HTTP error: $e');
      if (e.toString().contains('timeout')) {
        return {'success': false, 'message': 'Request timed out'};
      }
      return {'success': false, 'message': 'Network error: $e'};
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
