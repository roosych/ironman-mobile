import '../../../core/network/base_api_service.dart';
import '../../../core/network/simple_api_client.dart';
import '../domain/user.dart';

/// Простой и надежный API сервис для аутентификации
class SimpleAuthApi extends BaseApiService {
  /// Логин пользователя
  Future<ApiResponse<AuthResult>> login({
    required String email,
    required String password,
    String? locale,
  }) async {
    await init();

    final data = <String, dynamic>{
      'email': email,
      'password': password,
    };

    if (locale != null) {
      data['locale'] = locale;
    }

    return client.post<AuthResult>(
      '/auth/login',
      data: data,
      fromJson: (json) => AuthResult.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Регистрация пользователя
  Future<ApiResponse<AuthResult>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? locale,
    String? countryCode,
  }) async {
    await init();

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

    return client.post<AuthResult>(
      '/auth/register',
      data: data,
      fromJson: (json) => AuthResult.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Выход из системы
  Future<ApiResponse<void>> logout() async {
    await init();

    return client.post<void>('/auth/logout');
  }

  /// Получение текущего пользователя
  Future<ApiResponse<User>> getCurrentUser() async {
    await init();

    return client.get<User>(
      '/auth/user',
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Обновление языка пользователя
  Future<ApiResponse<LocaleResult>> updateLocale(String locale) async {
    await init();

    return client.put<LocaleResult>(
      '/auth/locale',
      data: {'locale': locale},
      fromJson: (json) => LocaleResult.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Восстановление пароля
  Future<ApiResponse<MessageResult>> forgotPassword({
    required String email,
  }) async {
    await init();

    return client.post<MessageResult>(
      '/auth/forgot-password',
      data: {'email': email},
      fromJson: (json) => MessageResult.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Повторная отправка письма верификации
  Future<ApiResponse<MessageResult>> resendEmailVerification() async {
    await init();

    return client.post<MessageResult>(
      '/auth/email/resend-verification',
      data: {},
      fromJson: (json) => MessageResult.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Смена пароля
  Future<ApiResponse<MessageResult>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await init();

    return client.put<MessageResult>(
      '/user/password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
      fromJson: (json) => MessageResult.fromJson(json as Map<String, dynamic>),
    );
  }
}

/// Результат аутентификации
class AuthResult {
  final User user;
  final String token;
  final String? message;

  const AuthResult({
    required this.user,
    required this.token,
    this.message,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      message: json['message'] as String?,
    );
  }
}

/// Результат изменения языка
class LocaleResult {
  final String locale;

  const LocaleResult({required this.locale});

  factory LocaleResult.fromJson(Map<String, dynamic> json) {
    return LocaleResult(
      locale: json['locale'] as String,
    );
  }
}

/// Результат с сообщением
class MessageResult {
  final String message;

  const MessageResult({required this.message});

  factory MessageResult.fromJson(Map<String, dynamic> json) {
    return MessageResult(
      message: json['message'] as String,
    );
  }
}