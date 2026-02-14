import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/secure_storage.dart';
import '../session/session_manager.dart';
import '../config/app_config.dart';
import 'interceptors/global_error_interceptor.dart';

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
          // МАКСИМАЛЬНО агрессивные timeouts - должны сработать раньше Timer
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 2),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    // Добавляем глобальный обработчик ошибок ПЕРВЫМ (высший приоритет)
    _dio.interceptors.add(GlobalErrorInterceptor());
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

  /// Простая обертка для безопасных запросов
  Future<Response<T>> _safeRequest<T>(Future<Response<T>> Function() request) async {
    try {
      debugPrint('🌐 SafeRequest: Выполняем запрос...');
      debugPrint('🕒 SafeRequest: Время начала: ${DateTime.now()}');

      // КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Добавляем глобальный timeout поверх всего запроса
      // Это гарантирует, что запрос НИКОГДА не зависнет навсегда, даже если сервер не отвечает
      final response = await Future.any([
        request(),
        Future.delayed(const Duration(seconds: 8), () {
          debugPrint('🔥🔥🔥 SafeRequest: ПРИНУДИТЕЛЬНЫЙ TIMEOUT после 8 секунд! 🔥🔥🔥');
          debugPrint('🕒 SafeRequest: Время timeout: ${DateTime.now()}');
          throw DioException(
            requestOptions: RequestOptions(path: 'forced-timeout'),
            type: DioExceptionType.receiveTimeout,
            message: 'Сервер не отвечает более 8 секунд',
          );
        }),
      ]);

      debugPrint('✅ SafeRequest: Запрос выполнен успешно');
      debugPrint('🕒 SafeRequest: Время завершения: ${DateTime.now()}');
      return response;
    } catch (e, stackTrace) {
      debugPrint('🔴 SafeRequest: Ошибка: ${e.runtimeType} - $e');
      debugPrint('📚 Stack trace: $stackTrace');

      // Конвертируем в безопасную DioException
      final safeError = _createSafeError(e);
      debugPrint('🛡️ Бросаем безопасную ошибку: ${safeError.message}');
      throw safeError;
    }
  }

  /// Создает безопасную DioException из любой ошибки
  DioException _createSafeError(dynamic error) {
    if (error is DioException) {
      // Если это уже DioException, возвращаем как есть
      return error;
    }

    // Для всех остальных ошибок создаем DioException с понятным сообщением
    String userMessage = 'Проблема с подключением к серверу.';
    DioExceptionType errorType = DioExceptionType.unknown;

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      userMessage = 'Сервер не отвечает. Проверьте подключение к интернету.';
      errorType = DioExceptionType.connectionTimeout;
    } else if (errorString.contains('connection') || errorString.contains('network')) {
      userMessage = 'Проблема с подключением к серверу.';
      errorType = DioExceptionType.connectionError;
    } else if (errorString.contains('socket')) {
      userMessage = 'Проблема с сетевым соединением.';
      errorType = DioExceptionType.connectionError;
    }

    return DioException(
      requestOptions: RequestOptions(path: 'safe-error'),
      type: errorType,
      message: userMessage,
      error: error,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    debugPrint('🚀 ApiClient.post: Начинаем POST запрос к $path');
    debugPrint('🕒 POST время начала: ${DateTime.now()}');

    final result = await _safeRequest<T>(() {
      debugPrint('🔄 POST: Вызываем _dio.post для $path');
      return _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    });

    debugPrint('✅ ApiClient.post: POST запрос к $path завершен');
    debugPrint('🕒 POST время завершения: ${DateTime.now()}');
    return result;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest<T>(() => _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    ));
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest<T>(() => _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ));
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest<T>(() => _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ));
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    debugPrint('⚡⚡⚡ AuthInterceptor.onRequest NEW VERSION START ⚡⚡⚡');
    debugPrint('=== AuthInterceptor.onRequest START ===');
    debugPrint('Path: ${options.path}');

    // ФИКС: Выполняем асинхронные операции с таймаутом БЕЗ блокировки очереди
    _addAuthHeadersSafely(options, handler);
  }

  /// ФИКС: Безопасное добавление заголовков с таймаутами
  Future<void> _addAuthHeadersSafely(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      debugPrint('Getting token from SecureStorage with timeout...');

      // ФИКС: Получаем токен с ОЧЕНЬ коротким таймаутом чтобы не блокировать запрос
      final token = await _storage.getToken().timeout(
        const Duration(milliseconds: 500), // Очень короткий таймаут для interceptor
        onTimeout: () {
          debugPrint('⚠️ AuthInterceptor: getToken() TIMEOUT после 500мс');
          return null;
        },
      );

      debugPrint('Token retrieved, length: ${token?.length ?? 0}');

      if (token != null && token.isNotEmpty) {
        debugPrint('Adding Authorization header...');
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        debugPrint('No token found');
      }

      // ФИКС: Добавляем заголовок Accept-Language с таймаутом
      debugPrint('Getting locale from SharedPreferences with timeout...');
      try {
        final prefs = await SharedPreferences.getInstance().timeout(
          const Duration(milliseconds: 300), // Очень короткий таймаут для interceptor
          onTimeout: () {
            debugPrint('⚠️ AuthInterceptor: SharedPreferences TIMEOUT после 300мс');
            throw TimeoutException('SharedPreferences timeout');
          },
        );
        final locale = prefs.getString('app_locale') ?? 'en';
        // Поддерживаем только ru и en для бэкенда
        final backendLocale = (locale == 'ru' || locale == 'en') ? locale : 'en';
        options.headers['Accept-Language'] = backendLocale;
        debugPrint('Set Accept-Language: $backendLocale');
      } catch (e) {
        debugPrint('Error getting locale: $e');
        // Fallback на английский язык при ошибке
        options.headers['Accept-Language'] = 'en';
      }

      debugPrint('Calling handler.next()...');
      handler.next(options);
      debugPrint('=== AuthInterceptor.onRequest END ===');

    } catch (e) {
      debugPrint('❌ AuthInterceptor: Критическая ошибка: $e');
      // ВАЖНО: Даже при ошибке передаем запрос дальше
      options.headers['Accept-Language'] = 'en'; // Fallback
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('=== AuthInterceptor.onError ===');
    debugPrint('Path: ${err.requestOptions.path}');
    debugPrint('Status Code: ${err.response?.statusCode}');
    debugPrint('Error Type: ${err.type}');
    debugPrint('Response Data: ${err.response?.data}');

    // Check for 401 Unauthenticated (skip auth endpoints and session restoration)
    if (_isUnauthenticatedError(err) &&
        !_isAuthEndpoint(err.requestOptions.path) &&
        !_isSessionRestorationRequest(err.requestOptions.path)) {
      debugPrint('Triggering session expiry for: ${err.requestOptions.path}');
      // Trigger session expiry handling (non-blocking)
      SessionManager().handleSessionExpired();
    } else {
      debugPrint('Not triggering session expiry (auth endpoint or 401)');
    }

    debugPrint('Passing error to next handler...');
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
      // Password change (can return 403 for wrong current password)
      '/user/password',       // смена пароля
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
