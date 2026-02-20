/// Базовый класс для API исключений с поддержкой локализации
abstract class ApiException implements Exception {
  /// Ключ для локализации сообщения об ошибке
  final String localizationKey;

  /// Параметры для подстановки в локализованное сообщение
  final Map<String, dynamic>? parameters;

  /// Исходное сообщение об ошибке (fallback)
  final String? originalMessage;

  const ApiException({
    required this.localizationKey,
    this.parameters,
    this.originalMessage,
  });

  @override
  String toString() => originalMessage ?? localizationKey;
}

/// Исключение для ошибок API гонок
class RacesApiException extends ApiException {
  const RacesApiException({
    required super.localizationKey,
    super.parameters,
    super.originalMessage,
  });

  /// Создание исключения с простым сообщением
  factory RacesApiException.message(String message) => RacesApiException(
        localizationKey: 'api_error_generic',
        parameters: {'message': message},
        originalMessage: message,
      );
}

/// Исключение для ошибок API рейтингов
class RankingsApiException extends ApiException {
  const RankingsApiException({
    required super.localizationKey,
    super.parameters,
    super.originalMessage,
  });

  /// Создание исключения с простым сообщением
  factory RankingsApiException.message(String message) => RankingsApiException(
        localizationKey: 'api_error_generic',
        parameters: {'message': message},
        originalMessage: message,
      );
}

/// Исключение для ошибок API атлетов
class AthletesApiException extends ApiException {
  const AthletesApiException({
    required super.localizationKey,
    super.parameters,
    super.originalMessage,
  });

  /// Создание исключения с простым сообщением
  factory AthletesApiException.message(String message) => AthletesApiException(
        localizationKey: 'api_error_generic',
        parameters: {'message': message},
        originalMessage: message,
      );
}

/// Исключение для ошибок API предстоящих гонок
class UpcomingRacesApiException extends ApiException {
  const UpcomingRacesApiException({
    required super.localizationKey,
    super.parameters,
    super.originalMessage,
  });

  /// Создание исключения с простым сообщением
  factory UpcomingRacesApiException.message(String message) => UpcomingRacesApiException(
        localizationKey: 'api_error_generic',
        parameters: {'message': message},
        originalMessage: message,
      );
}

/// Исключение для ошибок API уведомлений
class NotificationsApiException extends ApiException {
  const NotificationsApiException({
    required super.localizationKey,
    super.parameters,
    super.originalMessage,
  });

  /// Создание исключения с простым сообщением
  factory NotificationsApiException.message(String message) => NotificationsApiException(
        localizationKey: 'api_error_generic',
        parameters: {'message': message},
        originalMessage: message,
      );
}

/// Исключение для ошибок Transfer API
class TransferApiException extends ApiException {
  /// Ошибки валидации по полям (если есть)
  final Map<String, List<String>>? fieldErrors;

  const TransferApiException({
    required super.localizationKey,
    super.parameters,
    super.originalMessage,
    this.fieldErrors,
  });

  /// Создание исключения с простым сообщением
  factory TransferApiException.message(String message) => TransferApiException(
        localizationKey: 'api_error_generic',
        parameters: {'message': message},
        originalMessage: message,
      );

  /// Получить первую ошибку поля (для отображения в UI)
  String get firstFieldError {
    if (fieldErrors == null || fieldErrors!.isEmpty) {
      return originalMessage ?? localizationKey;
    }

    // Приоритет полей: source_athlete_id -> первое поле с ошибкой
    if (fieldErrors!.containsKey('source_athlete_id')) {
      return fieldErrors!['source_athlete_id']!.first;
    }

    return fieldErrors!.values.first.first;
  }
}