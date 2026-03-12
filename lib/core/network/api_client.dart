import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/secure_storage.dart';
import '../session/session_manager.dart';
import '../config/app_config.dart';
import 'interceptors/global_error_interceptor.dart';

class _TokenRefreshLock {
  static bool _isRefreshing = false;
  static final List<Completer<bool>> _waiters = [];

  static Future<bool> run(Future<bool> Function() refreshFn) async {
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _waiters.add(completer);
      return completer.future;
    }
    _isRefreshing = true;
    try {
      final result = await refreshFn();
      for (final w in _waiters) {
        w.complete(result);
      }
      _waiters.clear();
      return result;
    } catch (_) {
      for (final w in _waiters) {
        w.complete(false);
      }
      _waiters.clear();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}

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
          // Оптимизированные таймауты для мобильных сетей
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 12),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    // Добавляем глобальный обработчик ошибок ПЕРВЫМ (высший приоритет)
    _dio.interceptors.add(GlobalErrorInterceptor());
    _dio.interceptors.add(_AuthInterceptor(_storage, _dio));
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

  /// Простая обертка для безопасных запросов с обработкой ошибок
  Future<Response<T>> _safeRequest<T>(Future<Response<T>> Function() request) async {
    try {
      debugPrint('🌐 SafeRequest: Выполняем запрос...');
      debugPrint('🕒 SafeRequest: Время начала: ${DateTime.now()}');

      // Выполняем запрос напрямую - таймауты обрабатываются на уровне Dio
      final response = await request();

      debugPrint('✅ SafeRequest: Запрос завершен успешно');
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
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

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

      // Получаем токен с разумным таймаутом (из кэша — мгновенно, из хранилища — до 1.5с)
      final token = await _storage.getToken().timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () {
          debugPrint('⚠️ AuthInterceptor: getToken() TIMEOUT после 1500мс');
          return null;
        },
      );

      debugPrint('🔍 Token retrieved: ${token?.isNotEmpty == true ? "[FOUND] length=${token!.length}" : "[NULL/EMPTY]"}');

      if (token != null && token.isNotEmpty) {
        debugPrint('✅ Adding Authorization header: Bearer ${token.substring(0, 10)}...');
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('📋 Final headers: ${options.headers}');
      } else {
        debugPrint('❌ No token found - запрос будет без авторизации!');
        debugPrint('🔍 Проверьте авторизацию пользователя');
      }

      // ФИКС: Добавляем заголовок Accept-Language с таймаутом
      debugPrint('Getting locale from SharedPreferences with timeout...');
      try {
        final prefs = await SharedPreferences.getInstance().timeout(
          const Duration(milliseconds: 800),
          onTimeout: () {
            debugPrint('⚠️ AuthInterceptor: SharedPreferences TIMEOUT после 800мс');
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
    _handleError(err, handler);
  }

  Future<void> _handleError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;

    // Только обрабатываем 401, остальное пропускаем
    if (!_isUnauthenticatedError(err)) {
      handler.next(err);
      return;
    }

    // Auth-эндпоинты (login, register и т.д.) — 401 ожидаемый, не обрабатываем
    if (_isAuthOnlyEndpoint(path)) {
      handler.next(err);
      return;
    }

    // Уже пробовали retry — сдаёмся
    if (err.requestOptions.extra['_retried'] == true) {
      if (!_isSessionRestorationRequest(path) && !_isSilentEndpoint(path)) {
        SessionManager().handleSessionExpired();
      }
      handler.next(err);
      return;
    }

    // Пробуем обновить токен
    final refreshed = await _TokenRefreshLock.run(() => _doRefresh());
    if (refreshed) {
      try {
        final token = await _storage.getToken();
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $token';
        opts.extra['_retried'] = true;
        final response = await _dio.fetch(opts);
        handler.resolve(response);
        return;
      } catch (_) {
        // retry тоже упал — выходим
      }
    }

    // Silent-эндпоинты и session restoration — не роняем сессию при неудаче
    if (!_isSessionRestorationRequest(path) && !_isSilentEndpoint(path)) {
      SessionManager().handleSessionExpired();
    }
    handler.next(err);
  }

  Future<bool> _doRefresh() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ));

      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      final newAccessToken = data?['access_token'] as String?;
      final newRefreshToken = data?['refresh_token'] as String?;

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        await _storage.saveToken(newAccessToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _storage.saveRefreshToken(newRefreshToken);
        }
        debugPrint('✅ Token refreshed successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      return false;
    }
  }

  /// Auth-эндпоинты, где 401 — ожидаемый ответ (неверные credentials).
  /// Для них НЕ делаем refresh токена и НЕ триггерим logout.
  bool _isAuthOnlyEndpoint(String path) {
    const authOnlyPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/password/forgot',
      '/auth/password/reset',
      '/auth/logout',
      '/auth/locale',
      '/auth/password/change',
    ];
    return authOnlyPaths.any((p) => path.contains(p));
  }

  /// Эндпоинты, где при неудаче refresh токена НЕ нужно вызывать logout.
  /// Делаем попытку refresh, но при провале — тихо передаём ошибку.
  bool _isSilentEndpoint(String path) {
    const silentPaths = [
      '/user/photos',         // аватарка
      '/user/fcm-token',      // FCM токен
      '/races',               // список гонок (гость)
      '/notifications',       // уведомления
      '/transfers/current',   // статус заявки на перенос
      '/transfers/eligible-athletes', // список атлетов
      '/transfers',           // создание заявки
    ];
    return silentPaths.any((p) => path.contains(p));
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
