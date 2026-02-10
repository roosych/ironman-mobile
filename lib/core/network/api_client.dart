import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/secure_storage.dart';
import '../session/session_manager.dart';
import '../config/app_config.dart';

class ApiClient {
  /// Базовый URL API сервера
  /// Настройки берутся из AppConfig (lib/core/config/app_config.dart)
  static String get baseUrl => AppConfig.baseUrl;

  final Dio _dio;
  final SecureStorage _storage;

  ApiClient({SecureStorage? storage})
    : _storage = storage ?? SecureStorage(),
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(seconds: AppConfig.connectTimeout),
          receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(_AuthInterceptor(_storage));
    if (AppConfig.enableRequestLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
        ),
      );
    }
  }

  Dio get dio => _dio;

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

class _AuthInterceptor extends QueuedInterceptorsWrapper {
  final SecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // Добавляем заголовок Accept-Language
    try {
      final prefs = await SharedPreferences.getInstance();
      final locale = prefs.getString('app_locale') ?? 'en';
      // Поддерживаем только ru и en для бэкенда
      final backendLocale = (locale == 'ru' || locale == 'en') ? locale : 'en';
      options.headers['Accept-Language'] = backendLocale;
    } catch (_) {
      // Fallback на английский язык при ошибке
      options.headers['Accept-Language'] = 'en';
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Check for 401 Unauthenticated (skip auth endpoints and session restoration)
    if (_isUnauthenticatedError(err) &&
        !_isAuthEndpoint(err.requestOptions.path) &&
        !_isSessionRestorationRequest(err.requestOptions.path)) {
      // Trigger session expiry handling (non-blocking)
      SessionManager().handleSessionExpired();
    }
    handler.next(err);
  }

  /// Check if the request is to an auth endpoint.
  /// These endpoints are expected to return 401 for invalid credentials,
  /// so we should NOT trigger session expiry for them.
  bool _isAuthEndpoint(String path) {
    const ignorePaths = [
      // Auth flows
      '/auth/login',
      '/auth/register',
      '/auth/forgot-password',
      '/auth/reset-password',
      // Non-critical GETs where 401 не должен ронять сессию
      '/user/photos',         // аватарка
      '/user/fcm-token',      // регистрация/удаление FCM токена
      '/upcoming-races',      // список гонок (гость/неверифицированный)
      '/notifications',       // список уведомлений
    ];
    return ignorePaths.any((ignorePath) => path.contains(ignorePath));
  }

  /// Check if the request is part of session restoration.
  /// During session restoration, 401 errors should not trigger automatic logout
  /// because we're checking if the current token is still valid.
  bool _isSessionRestorationRequest(String path) {
    const sessionRestorationPaths = [
      '/user',              // getCurrentUser() called during restoreSession()
      '/profile',           // getProfile() called during restoreSession()
    ];
    return sessionRestorationPaths.any((restorationPath) => path.contains(restorationPath));
  }

  /// Check if the error is a 401 Unauthenticated response.
  ///
  /// Matches:
  /// - HTTP 401 status code
  /// - Response body with {"message": "Unauthenticated."}
  bool _isUnauthenticatedError(DioException err) {
    final response = err.response;
    if (response == null) return false;

    // Check HTTP status code
    if (response.statusCode == 401) {
      return true;
    }

    // Check for "Unauthenticated." message in body (Laravel Sanctum format)
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message == 'Unauthenticated.') {
        return true;
      }
    }

    return false;
  }
}
