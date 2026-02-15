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

    try {
      debugPrint('=== AuthResponse.fromJson: LOGIN RESPONSE DEBUG ===');
      debugPrint('Full login response keys: ${json.keys}');
      debugPrint('Data keys: ${data.keys}');
      debugPrint('User JSON keys: ${userJson.keys}');
      if (userJson['profile'] is Map) {
        final profile = userJson['profile'] as Map<String, dynamic>;
        debugPrint('Profile keys: ${profile.keys}');
        debugPrint('Profile personal_bests: ${profile['personal_bests']}');
        if (profile['stats'] is Map) {
          final stats = profile['stats'] as Map<String, dynamic>;
          debugPrint('Stats keys: ${stats.keys}');
          debugPrint('Stats personal_bests: ${stats['personal_bests']}');
        }
      }
      debugPrint('============================================');
    } catch (e) {
      debugPrint('Debug logging error (safe to ignore): $e');
    }

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
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      debugPrint('Unexpected error during login: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? locale,
    String? countryCode,
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
      if (countryCode != null) {
        data['country_code'] = countryCode;
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
  /// GET /auth/user
  Future<User> getCurrentUser() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/auth/user');
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

  /// Forgot password - send reset email
  /// POST /auth/forgot-password
  /// Returns the localized success message from API
  Future<String> forgotPassword({required String email}) async {
    try {
      debugPrint('AuthApi.forgotPassword: Starting API call');

      final response = await _client.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
      );

      debugPrint('AuthApi.forgotPassword: Response received');
      debugPrint('Response data: ${response.data}');

      final json = response.data!;
      if (json['success'] == true) {
        debugPrint('AuthApi.forgotPassword: Success response');
        // Return localized message from API
        return json['message'] as String? ?? 'Password reset email sent successfully';
      } else {
        debugPrint('AuthApi.forgotPassword: Error in response data');
        throw _parseError(json);
      }
    } on DioException catch (e) {
      debugPrint('AuthApi.forgotPassword: DioException caught');
      debugPrint('Status code: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');

      // Handle specific status codes
      if (e.response?.statusCode == 429) {
        debugPrint('AuthApi.forgotPassword: 429 Too Many Requests');
        // Try to get message from response (already localized)
        final json = e.response?.data as Map<String, dynamic>?;
        final message = json?['message'] as String?;
        if (message != null) {
          debugPrint('AuthApi.forgotPassword: Using message from 429 response: $message');
          throw AuthApiException(message);
        }
        // Fallback to generic message
        throw const AuthApiException('NETWORK_TOO_MANY_REQUESTS');
      }

      debugPrint('AuthApi.forgotPassword: Other DioException, using _handleDioError');
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      debugPrint('AuthApi.forgotPassword: Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Resend email verification
  /// POST /auth/email/resend
  /// Returns the localized success message from API
  Future<String> resendEmailVerification() async {
    try {
      debugPrint('AuthApi.resendEmailVerification: Starting API call');

      final response = await _client.post<Map<String, dynamic>>(
        '/auth/email/resend-verification',
        data: {},
      );

      debugPrint('AuthApi.resendEmailVerification: Response received');
      debugPrint('Response data: ${response.data}');

      final json = response.data!;
      if (json['success'] == true) {
        debugPrint('AuthApi.resendEmailVerification: Success response');
        // Return localized message from API
        return json['message'] as String? ?? 'Verification email sent successfully';
      } else {
        debugPrint('AuthApi.resendEmailVerification: Error in response data');
        throw _parseError(json);
      }
    } on DioException catch (e) {
      debugPrint('AuthApi.resendEmailVerification: DioException caught');
      debugPrint('Status code: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');

      // Handle specific status codes
      if (e.response?.statusCode == 429) {
        debugPrint('AuthApi.resendEmailVerification: 429 Too Many Requests');
        // Try to get message from response (already localized)
        final json = e.response?.data as Map<String, dynamic>?;
        final message = json?['message'] as String?;
        if (message != null) {
          debugPrint('AuthApi.resendEmailVerification: Using message from 429 response: $message');
          throw AuthApiException(message);
        }
        // Fallback to generic message
        throw const AuthApiException('NETWORK_TOO_MANY_REQUESTS');
      }

      debugPrint('AuthApi.resendEmailVerification: Other DioException, using _handleDioError');
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      debugPrint('AuthApi.resendEmailVerification: Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
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
      debugPrint('AuthApi.changePassword: Starting API call');

      final response = await _client.put<Map<String, dynamic>>(
        '/user/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );

      debugPrint('AuthApi.changePassword: Response received');
      debugPrint('Response data: ${response.data}');

      final json = response.data!;
      if (json['success'] == true) {
        debugPrint('AuthApi.changePassword: Success response');
        // Return localized message from API
        return json['message'] as String? ?? 'Password changed successfully';
      } else {
        debugPrint('AuthApi.changePassword: Error in response data');
        throw _parseError(json);
      }
    } on DioException catch (e) {
      debugPrint('AuthApi.changePassword: DioException caught');
      debugPrint('Status code: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');

      // Handle specific status codes
      if (e.response?.statusCode == 403) {
        debugPrint('AuthApi.changePassword: 403 Forbidden - incorrect password');
        // Try to get message from response (already localized)
        final json = e.response?.data as Map<String, dynamic>?;
        final message = json?['message'] as String?;
        if (message != null) {
          debugPrint('AuthApi.changePassword: Using message from 403 response: $message');
          throw AuthApiException(message);
        }
        // Fallback to errors if no message
        debugPrint('AuthApi.changePassword: No message in 403 response, using _handleDioError');
        throw _handleDioError(e);
      }
      if (e.response?.statusCode == 422) {
        debugPrint('AuthApi.changePassword: 422 Validation error');
        // Validation errors - parse field errors (already localized)
        throw _handleDioError(e);
      }
      debugPrint('AuthApi.changePassword: Other DioException, using _handleDioError');
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      debugPrint('AuthApi.changePassword: Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
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
    debugPrint('AuthApi._handleDioError: Processing DioException');
    debugPrint('Exception type: ${e.type}');
    debugPrint('Status code: ${e.response?.statusCode}');
    debugPrint('Response data: ${e.response?.data}');

    // Если есть ответ от сервера, используем локализованные сообщения из API
    if (e.response?.data != null && e.response?.data is Map) {
      debugPrint('AuthApi._handleDioError: Response data is Map');
      final json = e.response!.data as Map<String, dynamic>;

      // Проверяем наличие errors (локализованные ошибки валидации)
      if (json['errors'] != null) {
        debugPrint('AuthApi._handleDioError: Found errors field, parsing');
        return _parseError(json);
      }

      // Проверяем наличие message (локализованное сообщение об ошибке)
      final message = json['message'] as String?;
      if (message != null) {
        debugPrint('AuthApi._handleDioError: Using message from response: $message');
        return AuthApiException(message);
      }
    }

    // Для сетевых ошибок (когда нет ответа от сервера) возвращаем общее сообщение
    // Эти ошибки не локализуются на бэкенде, так как сервер недоступен
    // В этом случае можно использовать локализацию Flutter на клиенте
    debugPrint('AuthApi._handleDioError: Processing network/connection errors');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        debugPrint('AuthApi._handleDioError: Timeout error');
        // Возвращаем сообщение, которое будет локализовано на клиенте через ErrorHandler
        return const AuthApiException('NETWORK_TIMEOUT');
      case DioExceptionType.connectionError:
        debugPrint('AuthApi._handleDioError: Connection error');
        // Возвращаем сообщение, которое будет локализовано на клиенте через ErrorHandler
        return const AuthApiException('NETWORK_CONNECTION_ERROR');
      case DioExceptionType.badResponse:
        debugPrint('AuthApi._handleDioError: Bad response error');
        final statusCode = e.response?.statusCode;

        // Обработка HTTP 429 (Too Many Requests / Throttle)
        // Проверяем, есть ли локализованное сообщение в ответе
        if (statusCode == 429) {
          debugPrint('AuthApi._handleDioError: 429 Too Many Requests');
          final json = e.response?.data as Map<String, dynamic>?;
          final message = json?['message'] as String?;
          if (message != null) {
            return AuthApiException(message);
          }
          // Если нет сообщения от сервера, возвращаем общее сообщение
          return const AuthApiException('NETWORK_TOO_MANY_REQUESTS');
        }

        // Для других ошибок badResponse проверяем, есть ли сообщение от сервера
        debugPrint('AuthApi._handleDioError: Other bad response (status: $statusCode)');
        final json = e.response?.data as Map<String, dynamic>?;
        final message = json?['message'] as String?;
        if (message != null) {
          debugPrint('AuthApi._handleDioError: Using message from bad response: $message');
          return AuthApiException(message);
        }

        // Если нет сообщения от сервера, возвращаем общее сообщение
        debugPrint('AuthApi._handleDioError: No message in bad response, using generic error');
        return AuthApiException('NETWORK_SERVER_ERROR_${statusCode ?? "unknown"}');
      default:
        debugPrint('AuthApi._handleDioError: Default/unknown error type');
        return const AuthApiException('NETWORK_ERROR');
    }
  }
}
