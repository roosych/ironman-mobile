import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/secure_storage.dart';
import '../session/session_manager.dart';
import '../../main.dart';
import '../config/app_config.dart';
import '../../shared/utils/error_handler.dart';

/// Простой и надежный API клиент без сложных workaround'ов
class SimpleApiClient {
  static final SimpleApiClient _instance = SimpleApiClient._internal();
  factory SimpleApiClient() => _instance;
  SimpleApiClient._internal();

  late final Dio _dio;
  final SecureStorage _storage = SecureStorage();

  bool _initialized = false;

  /// Инициализация клиента (вызывается один раз)
  Future<void> init() async {
    if (_initialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Простой interceptor для добавления токена
    _dio.interceptors.add(_SimpleAuthInterceptor(_storage));

    // Interceptor для обработки 401 ошибок
    _dio.interceptors.add(_SimpleErrorInterceptor());

    if (AppConfig.enableRequestLogging && kDebugMode) {
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

    _initialized = true;
    debugPrint('✅ SimpleApiClient initialized');
  }

  /// Универсальный метод для запросов с автоматической обработкой ошибок
  Future<ApiResponse<T>> request<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool showErrorDialog = true,
  }) async {
    try {
      debugPrint('🌐 API Request: $method $path');

      late Response response;

      switch (method.toLowerCase()) {
        case 'get':
          response = await _dio.get(path, queryParameters: queryParameters);
          break;
        case 'post':
          response = await _dio.post(path, data: data, queryParameters: queryParameters);
          break;
        case 'put':
          response = await _dio.put(path, data: data, queryParameters: queryParameters);
          break;
        case 'delete':
          response = await _dio.delete(path, data: data, queryParameters: queryParameters);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      debugPrint('✅ API Success: ${response.statusCode} $path');

      // Парсим успешный ответ
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final success = responseData['success'] as bool? ?? true;
        final message = responseData['message'] as String?;
        final data = responseData['data'];

        T? parsedData;
        if (fromJson != null && data != null) {
          parsedData = fromJson(data);
        }

        return ApiResponse<T>(
          success: success,
          data: parsedData,
          message: message,
          statusCode: response.statusCode ?? 200,
        );
      }

      return ApiResponse<T>(
        success: true,
        data: fromJson != null ? fromJson(responseData) : null,
        statusCode: response.statusCode ?? 200,
      );

    } on DioException catch (e) {
      debugPrint('❌ API Error: ${e.response?.statusCode} $path - ${e.message}');

      final apiError = _handleDioError(e, showErrorDialog);
      return ApiResponse<T>(
        success: false,
        error: apiError,
        statusCode: e.response?.statusCode ?? 0,
      );
    } catch (e) {
      debugPrint('❌ Unexpected Error: $path - $e');

      const apiError = ApiError(
        message: 'Произошла неожиданная ошибка',
        type: ApiErrorType.unknown,
      );

      if (showErrorDialog) {
        // Показываем ошибку в следующем кадре, чтобы не блокировать UI
        Future.microtask(() => _showError(apiError.message));
      }

      return ApiResponse<T>(
        success: false,
        error: apiError,
        statusCode: 0,
      );
    }
  }

  /// Обработка DioException
  ApiError _handleDioError(DioException e, bool showErrorDialog) {
    String message;
    ApiErrorType type;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Превышено время ожидания. Проверьте подключение к интернету.';
        type = ApiErrorType.timeout;
        break;

      case DioExceptionType.connectionError:
        message = 'Ошибка подключения. Проверьте интернет-соединение.';
        type = ApiErrorType.network;
        break;

      case DioExceptionType.badResponse:
        final response = e.response;
        if (response?.data is Map<String, dynamic>) {
          final responseData = response!.data as Map<String, dynamic>;

          // Обработка ошибок валидации
          if (response.statusCode == 422 && responseData['errors'] != null) {
            final errors = responseData['errors'] as Map<String, dynamic>;
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              message = firstError.first as String;
              type = ApiErrorType.validation;
            } else {
              message = 'Ошибка валидации данных';
              type = ApiErrorType.validation;
            }
          }
          // Обработка других ошибок с сервера
          else {
            message = responseData['message'] as String? ?? 'Ошибка сервера';
            type = _getErrorTypeByStatusCode(response.statusCode);
          }
        } else {
          message = 'Ошибка сервера';
          type = _getErrorTypeByStatusCode(response?.statusCode);
        }
        break;

      default:
        message = 'Произошла сетевая ошибка';
        type = ApiErrorType.network;
    }

    if (showErrorDialog) {
      // Показываем ошибку в следующем кадре, чтобы не блокировать UI
      Future.microtask(() => _showError(message));
    }

    return ApiError(message: message, type: type, statusCode: e.response?.statusCode);
  }

  /// Определение типа ошибки по статус коду
  ApiErrorType _getErrorTypeByStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return ApiErrorType.badRequest;
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      case 404:
        return ApiErrorType.notFound;
      case 429:
        return ApiErrorType.tooManyRequests;
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiErrorType.server;
      default:
        return ApiErrorType.unknown;
    }
  }

  /// Показ ошибки пользователю
  Future<void> _showError(String message) async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        ErrorHandler.showError(context, message);
      }
    } catch (e) {
      debugPrint('Error showing error dialog: $e');
    }
  }

  // Удобные методы для разных типов запросов
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool showErrorDialog = true,
  }) => request<T>('GET', path,
      queryParameters: queryParameters, fromJson: fromJson, showErrorDialog: showErrorDialog);

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool showErrorDialog = true,
  }) => request<T>('POST', path,
      data: data, queryParameters: queryParameters, fromJson: fromJson, showErrorDialog: showErrorDialog);

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool showErrorDialog = true,
  }) => request<T>('PUT', path,
      data: data, queryParameters: queryParameters, fromJson: fromJson, showErrorDialog: showErrorDialog);

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool showErrorDialog = true,
  }) => request<T>('DELETE', path,
      data: data, queryParameters: queryParameters, fromJson: fromJson, showErrorDialog: showErrorDialog);
}

/// Простой interceptor для добавления токена авторизации
class _SimpleAuthInterceptor extends Interceptor {
  final SecureStorage _storage;

  _SimpleAuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Добавляем токен авторизации
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      // Добавляем язык
      final prefs = await SharedPreferences.getInstance();
      final locale = prefs.getString('app_locale') ?? 'en';
      final backendLocale = (locale == 'ru' || locale == 'en') ? locale : 'en';
      options.headers['Accept-Language'] = backendLocale;

    } catch (e) {
      debugPrint('Auth interceptor error: $e');
      // Продолжаем запрос даже при ошибке
    }

    handler.next(options);
  }
}

/// Простой interceptor для обработки ошибок сессии
class _SimpleErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Обработка 401 ошибок (истекшая сессия)
    if (err.response?.statusCode == 401 && !_isAuthEndpoint(err.requestOptions.path)) {
      // Запускаем обработку истечения сессии в фоне через navigatorKey
      Future.microtask(() {
        final sessionManager = SessionManager();
        if (sessionManager.navigatorKey == null) {
          sessionManager.init(
            navigatorKey: navigatorKey,
            onForceLogout: () {
              // Этот callback будет установлен в main.dart
            },
          );
        }
        sessionManager.handleSessionExpired();
      });
    }

    handler.next(err);
  }

  /// Проверка, является ли эндпоинт авторизационным
  bool _isAuthEndpoint(String path) {
    const authEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/forgot-password',
      '/auth/reset-password',
    ];
    return authEndpoints.any((endpoint) => path.contains(endpoint));
  }
}

/// Ответ API
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final ApiError? error;
  final int statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    required this.statusCode,
  });

  /// Успешный ли ответ
  bool get isSuccess => success && error == null;

  /// Есть ли ошибка
  bool get hasError => !success || error != null;
}

/// Ошибка API
class ApiError {
  final String message;
  final ApiErrorType type;
  final int? statusCode;

  const ApiError({
    required this.message,
    required this.type,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Типы ошибок API
enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  badRequest,
  tooManyRequests,
  server,
  unknown,
}