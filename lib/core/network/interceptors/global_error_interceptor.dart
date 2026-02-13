import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Глобальный interceptor для обработки всех ошибок API
/// Предотвращает крашы приложения и конвертирует ошибки в понятные сообщения
class GlobalErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('🚨🚨🚨 GlobalErrorInterceptor ВЫЗВАН! 🚨🚨🚨');
    debugPrint('Тип ошибки: ${err.type}');
    debugPrint('Сообщение: ${err.message}');
    debugPrint('URL: ${err.requestOptions.uri}');
    debugPrint('Статус код: ${err.response?.statusCode}');

    debugPrint('🚨 GlobalErrorInterceptor: ${err.type} - ${err.message}');

    // Конвертируем все типы ошибок в понятные сообщения для пользователя
    final userFriendlyError = _convertToUserFriendlyError(err);
    debugPrint('📱 Конвертированное сообщение: $userFriendlyError');

    // Создаем новую ошибку с понятным сообщением, но сохраняем оригинальную структуру
    final newError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: userFriendlyError,
      message: userFriendlyError,
    );

    debugPrint('✅ GlobalErrorInterceptor: передаем ошибку дальше');
    // Передаем обработанную ошибку дальше
    handler.next(newError);
  }

  /// Конвертирует DioException в понятное для пользователя сообщение
  String _convertToUserFriendlyError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Не удается подключиться к серверу. Проверьте подключение к интернету.';

      case DioExceptionType.sendTimeout:
        return 'Не удается отправить данные на сервер. Проверьте подключение к интернету.';

      case DioExceptionType.receiveTimeout:
        return 'Сервер слишком долго отвечает. Попробуйте позже.';

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return 'Запрос был отменен.';

      case DioExceptionType.connectionError:
        return _handleConnectionError(error);

      case DioExceptionType.badCertificate:
        return 'Проблема с сертификатом безопасности сервера.';

      case DioExceptionType.unknown:
        return _handleUnknownError(error);
    }
  }

  /// Обрабатывает ошибки плохого ответа от сервера (4xx, 5xx)
  String _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // Попытаемся извлечь сообщение от API
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return message; // Используем сообщение от API (уже локализованное)
      }

      // Попытаемся извлечь ошибки валидации
      final errors = responseData['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }

    // Стандартные сообщения для HTTP кодов
    switch (statusCode) {
      case 400:
        return 'Некорректные данные запроса.';
      case 401:
        return 'Необходима авторизация. Войдите в аккаунт заново.';
      case 403:
        return 'Доступ запрещен.';
      case 404:
        return 'Запрашиваемый ресурс не найден.';
      case 422:
        return 'Ошибка валидации данных.';
      case 429:
        return 'Слишком много запросов. Попробуйте позже.';
      case 500:
        return 'Внутренняя ошибка сервера. Попробуйте позже.';
      case 502:
      case 503:
      case 504:
        return 'Сервер временно недоступен. Попробуйте позже.';
      default:
        return 'Ошибка сервера ($statusCode). Попробуйте позже.';
    }
  }

  /// Обрабатывает ошибки подключения
  String _handleConnectionError(DioException error) {
    final message = error.message?.toLowerCase() ?? '';

    if (message.contains('network is unreachable') ||
        message.contains('no route to host')) {
      return 'Нет подключения к интернету. Проверьте настройки сети.';
    }

    if (message.contains('connection refused') ||
        message.contains('failed to connect')) {
      return 'Сервер недоступен. Проверьте подключение к интернету или попробуйте позже.';
    }

    if (message.contains('host lookup failed') ||
        message.contains('socket')) {
      return 'Не удается найти сервер. Проверьте подключение к интернету.';
    }

    return 'Проблема с подключением к серверу. Проверьте интернет-соединение.';
  }

  /// Обрабатывает неизвестные ошибки
  String _handleUnknownError(DioException error) {
    final message = error.message?.toLowerCase() ?? '';

    if (message.contains('timeout')) {
      return 'Время ожидания истекло. Проверьте подключение к интернету.';
    }

    if (message.contains('socket') || message.contains('connection')) {
      return 'Проблема с подключением к серверу.';
    }

    return 'Произошла неожиданная ошибка. Попробуйте позже.';
  }
}