import 'package:dio/dio.dart';

/// Исключение API для операций переноса результатов
class TransferApiException implements Exception {
  /// Сообщение об ошибке
  final String message;

  /// Ошибки валидации по полям (если есть)
  final Map<String, List<String>>? fieldErrors;

  const TransferApiException(
    this.message, {
    this.fieldErrors,
  });

  /// Создает исключение из DioException
  static TransferApiException fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // Обработка специфичных ошибок переноса
    if (statusCode == 409 && data != null && data['message'] != null) {
      return TransferApiException(data['message']?.toString() ?? 'Конфликт при создании заявки');
    }

    if (statusCode == 422 && data != null) {
      // Ошибки валидации
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map<String, dynamic>;
        final fieldErrors = <String, List<String>>{};

        errors.forEach((field, messages) {
          if (messages is List) {
            fieldErrors[field] = messages.map((m) => m.toString()).toList();
          }
        });

        final message = data['message']?.toString() ?? 'Ошибка валидации данных';
        return TransferApiException(message, fieldErrors: fieldErrors);
      }
    }

    // Обработка типов DioException
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const TransferApiException('Превышено время ожидания');

      case DioExceptionType.connectionError:
        return const TransferApiException('NETWORK_NO_CONNECTION');

      case DioExceptionType.badResponse:
        final message = data?['message']?.toString();
        return TransferApiException(
          message ?? 'Ошибка сервера ($statusCode)',
        );

      default:
        return const TransferApiException('Произошла ошибка при обращении к серверу');
    }
  }

  /// Получить первую ошибку поля (для отображения в UI)
  String get firstFieldError {
    if (fieldErrors == null || fieldErrors!.isEmpty) {
      return message;
    }

    // Приоритет полей: source_athlete_id -> первое поле с ошибкой
    if (fieldErrors!.containsKey('source_athlete_id')) {
      return fieldErrors!['source_athlete_id']!.first;
    }

    return fieldErrors!.values.first.first;
  }

  @override
  String toString() => message;
}