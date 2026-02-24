/// Типы окружений приложения
enum AppEnvironment { development, production }

/// Базовый класс для конфигурации окружения
abstract class EnvironmentConfig {
  AppEnvironment get environment;
  String get name;
  String get baseUrl;
  int get connectTimeout;
  int get receiveTimeout;
  bool get enableRequestLogging;
  bool get debugMode;

  // API Keys
  String get googleMapsApiKey;
  String get firebaseApiKey;
  String get otherApiKey;
}

/// Конфигурация для разработки
class DevelopmentConfig extends EnvironmentConfig {
  @override
  AppEnvironment get environment => AppEnvironment.development;

  @override
  String get name => 'Development';

  @override
  String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.16.23.67:8000/api/v1',
  );

  @override
  int get connectTimeout => const int.fromEnvironment('CONNECT_TIMEOUT', defaultValue: 30);

  @override
  int get receiveTimeout => const int.fromEnvironment('RECEIVE_TIMEOUT', defaultValue: 30);

  @override
  bool get enableRequestLogging => const bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);

  @override
  bool get debugMode => true;

  @override
  String get googleMapsApiKey => const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  @override
  String get firebaseApiKey => const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');

  @override
  String get otherApiKey => const String.fromEnvironment('OTHER_API_KEY', defaultValue: '');
}


/// Конфигурация для продакшена
class ProductionConfig extends EnvironmentConfig {
  @override
  AppEnvironment get environment => AppEnvironment.production;

  @override
  String get name => 'Production';

  @override
  String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ironman.az/api/v1',
  );

  @override
  int get connectTimeout => const int.fromEnvironment('CONNECT_TIMEOUT', defaultValue: 30);

  @override
  int get receiveTimeout => const int.fromEnvironment('RECEIVE_TIMEOUT', defaultValue: 30);

  @override
  bool get enableRequestLogging => const bool.fromEnvironment('ENABLE_LOGGING', defaultValue: false);

  @override
  bool get debugMode => false; // Всегда false в продакшене

  @override
  String get googleMapsApiKey => const String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '', // В проде не должно быть fallback для критичных ключей
  );

  @override
  String get firebaseApiKey => const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');

  @override
  String get otherApiKey => const String.fromEnvironment('OTHER_API_KEY', defaultValue: '');
}