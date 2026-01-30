import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../domain/user.dart';

class AuthResponse {
  final User user;
  final String token;
  final String? message;

  const AuthResponse({
    required this.user,
    required this.token,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;
    
    return AuthResponse(
      user: User.fromJson(userJson),
      token: data['token'] as String,
      message: json['message'] as String?,
    );
  }
}

class AuthApiException implements Exception {
  final String message;
  final Map<String, List<String>>? fieldErrors;

  const AuthApiException(this.message, {this.fieldErrors});

  String get firstError {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      // Приоритизируем ошибки email и password для логина
      final emailErrors = fieldErrors!['email'];
      if (emailErrors != null && emailErrors.isNotEmpty) {
        return emailErrors.first;
      }
      final passwordErrors = fieldErrors!['password'];
      if (passwordErrors != null && passwordErrors.isNotEmpty) {
        return passwordErrors.first;
      }
      // Если нет ошибок email/password, возвращаем первую ошибку из любого поля
      final firstField = fieldErrors!.values.first;
      if (firstField.isNotEmpty) {
        return firstField.first;
      }
    }
    return message;
  }

  @override
  String toString() => firstError;
}

class AuthApi {
  final ApiClient _client;

  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<AuthResponse> login({
    required String email,
    required String password,
    String? locale,
  }) async {
    try {
      final fullUrl = '${ApiClient.baseUrl}/auth/login';
      debugPrint('=== LOGIN REQUEST ===');
      debugPrint('Full URL: $fullUrl');
      debugPrint('Base URL: ${ApiClient.baseUrl}');
      debugPrint('Email: $email');
      debugPrint('====================');

      final data = <String, dynamic>{
        'email': email,
        'password': password,
      };
      if (locale != null) {
        data['locale'] = locale;
      }
      
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: data,
      );

      debugPrint('=== LOGIN RESPONSE SUCCESS ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Data keys: ${response.data?.keys}');
      debugPrint('=====================');

      final json = response.data!;

      // Некоторые бэкенды для не верифицированного e-mail могут присылать
      // success=false, но при этом отдавать токен и пользователя.
      // В этом случае не падаем, а продолжаем аутентификацию
      // и показываем предупреждение (message).
      final hasAuthPayload =
          json['data'] is Map<String, dynamic> &&
          (json['data'] as Map<String, dynamic>)['user'] != null &&
          (json['data'] as Map<String, dynamic>)['token'] != null;

      if (json['success'] == true || hasAuthPayload) {
        return AuthResponse.fromJson(json);
      }

      throw _parseError(json);
    } on DioException catch (e) {
      // Детальное логирование для отладки
      debugPrint('=== LOGIN ERROR ===');
      debugPrint('Error type: ${e.type}');
      debugPrint('Error message: ${e.message}');
      debugPrint('Request URL: ${e.requestOptions.uri}');
      debugPrint('Request path: ${e.requestOptions.path}');
      debugPrint('Base URL: ${ApiClient.baseUrl}');
      debugPrint('Request headers: ${e.requestOptions.headers}');
      debugPrint('Request data: ${e.requestOptions.data}');
      if (e.error != null) {
        debugPrint('Error details: ${e.error}');
        debugPrint('Error toString: ${e.error.toString()}');
      }
      if (e.response != null) {
        debugPrint('Response status: ${e.response!.statusCode}');
        debugPrint('Response data: ${e.response!.data}');
      }
      debugPrint('===================');
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      debugPrint('=== UNEXPECTED ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('=======================');
      rethrow;
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? locale,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };
      if (locale != null) {
        data['locale'] = locale;
      }
      
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/register',
        data: data,
      );

      final json = response.data!;
      if (json['success'] == true) {
        return AuthResponse.fromJson(json);
      } else {
        throw _parseError(json);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.post<Map<String, dynamic>>('/auth/logout');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get current user profile
  /// GET /user/profile
  Future<User> getCurrentUser() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/user/profile');
      final json = response.data!;
      if (json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        throw const AuthApiException('Failed to get user profile');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update user locale
  /// PUT /auth/locale
  Future<String> updateLocale(String locale) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/auth/locale',
        data: {'locale': locale},
      );

      final json = response.data!;
      if (json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>?;
        return data?['locale'] as String? ?? locale;
      } else {
        throw _parseError(json);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Change user password
  /// PUT /user/password
  /// Returns the localized success message from API
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/user/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );

      final json = response.data!;
      if (json['success'] == true) {
        // Return localized message from API
        return json['message'] as String? ?? 'Password changed successfully';
      } else {
        throw _parseError(json);
      }
    } on DioException catch (e) {
      // Handle specific status codes
      if (e.response?.statusCode == 403) {
        // Try to get message from response (already localized)
        final json = e.response?.data as Map<String, dynamic>?;
        final message = json?['message'] as String?;
        if (message != null) {
          throw AuthApiException(message);
        }
        // Fallback to errors if no message
        throw _handleDioError(e);
      }
      if (e.response?.statusCode == 422) {
        // Validation errors - parse field errors (already localized)
        throw _handleDioError(e);
      }
      throw _handleDioError(e);
    }
  }

  AuthApiException _parseError(Map<String, dynamic> json) {
    final errors = json['errors'] as Map<String, dynamic>?;
    if (errors != null) {
      final fieldErrors = <String, List<String>>{};
      errors.forEach((key, value) {
        if (value is List) {
          fieldErrors[key] = value.cast<String>();
        }
      });
      return AuthApiException('Validation error', fieldErrors: fieldErrors);
    }
    return const AuthApiException('Unknown error occurred');
  }

  AuthApiException _handleDioError(DioException e) {
    // Если есть ответ от сервера, используем локализованные сообщения из API
    if (e.response?.data != null && e.response?.data is Map) {
      final json = e.response!.data as Map<String, dynamic>;
      
      // Проверяем наличие errors (локализованные ошибки валидации)
      if (json['errors'] != null) {
        return _parseError(json);
      }
      
      // Проверяем наличие message (локализованное сообщение об ошибке)
      final message = json['message'] as String?;
      if (message != null) {
        return AuthApiException(message);
      }
    }

    // Для сетевых ошибок (когда нет ответа от сервера) возвращаем общее сообщение
    // Эти ошибки не локализуются на бэкенде, так как сервер недоступен
    // В этом случае можно использовать локализацию Flutter на клиенте
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // Возвращаем сообщение, которое будет локализовано на клиенте через ErrorHandler
        return const AuthApiException('NETWORK_TIMEOUT');
      case DioExceptionType.connectionError:
        // Возвращаем сообщение, которое будет локализовано на клиенте через ErrorHandler
        return const AuthApiException('NETWORK_CONNECTION_ERROR');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        
        // Обработка HTTP 429 (Too Many Requests / Throttle)
        // Проверяем, есть ли локализованное сообщение в ответе
        if (statusCode == 429) {
          final json = e.response?.data as Map<String, dynamic>?;
          final message = json?['message'] as String?;
          if (message != null) {
            return AuthApiException(message);
          }
          // Если нет сообщения от сервера, возвращаем общее сообщение
          return const AuthApiException('NETWORK_TOO_MANY_REQUESTS');
        }
        
        // Для других ошибок badResponse проверяем, есть ли сообщение от сервера
        final json = e.response?.data as Map<String, dynamic>?;
        final message = json?['message'] as String?;
        if (message != null) {
          return AuthApiException(message);
        }
        
        // Если нет сообщения от сервера, возвращаем общее сообщение
        return AuthApiException('NETWORK_SERVER_ERROR_${statusCode ?? "unknown"}');
      default:
        return const AuthApiException('NETWORK_ERROR');
    }
  }
}
