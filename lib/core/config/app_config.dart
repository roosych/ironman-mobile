import 'package:flutter/foundation.dart';
import 'environment.dart';

/// Главный класс конфигурации приложения
///
/// Использует Environment Variables с fallback значениями.
///
/// Примеры запуска:
/// ```bash
/// # Development (по умолчанию)
/// flutter run --dart-define-from-file=.env.development
///
/// # Production
/// flutter run --dart-define=ENVIRONMENT=production --dart-define=API_BASE_URL=https://prod-api.com --dart-define=GOOGLE_MAPS_API_KEY=your_key
/// ```
class AppConfig {
  static late EnvironmentConfig _config;
  static bool _initialized = false;

  /// Инициализация конфигурации
  /// Должна вызываться в main() перед runApp()
  static void initialize() {
    if (_initialized) return;

    final environmentName = const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

    switch (environmentName.toLowerCase()) {
      case 'production':
      case 'prod':
        _config = ProductionConfig();
        break;
      case 'development':
      case 'dev':
      default:
        _config = DevelopmentConfig();
        break;
    }

    _initialized = true;
    _printConfiguration();
  }

  /// Текущее окружение
  static AppEnvironment get environment {
    _checkInitialized();
    return _config.environment;
  }

  /// Название окружения
  static String get environmentName {
    _checkInitialized();
    return _config.name;
  }

  // ============================================
  // НАСТРОЙКИ СЕРВЕРА
  // ============================================

  /// Базовый URL API сервера
  static String get baseUrl {
    _checkInitialized();
    return _config.baseUrl;
  }

  /// Таймаут подключения к серверу (в секундах)
  static int get connectTimeout {
    _checkInitialized();
    return _config.connectTimeout;
  }

  /// Таймаут получения ответа от сервера (в секундах)
  static int get receiveTimeout {
    _checkInitialized();
    return _config.receiveTimeout;
  }

  // ============================================
  // КЛЮЧИ ОТ СТОРОННИХ ИНТЕГРАЦИЙ
  // ============================================

  /// API ключ для Google Maps
  static String get googleMapsApiKey {
    _checkInitialized();
    return _config.googleMapsApiKey;
  }

  /// API ключ для Firebase
  static String get firebaseApiKey {
    _checkInitialized();
    return _config.firebaseApiKey;
  }

  /// API ключ для других сервисов
  static String get otherApiKey {
    _checkInitialized();
    return _config.otherApiKey;
  }

  // ============================================
  // ДРУГИЕ НАСТРОЙКИ
  // ============================================

  /// Включить/выключить логирование запросов
  static bool get enableRequestLogging {
    _checkInitialized();
    return _config.enableRequestLogging;
  }

  /// Режим отладки
  static bool get debugMode {
    _checkInitialized();
    return _config.debugMode;
  }

  // ============================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ============================================

  /// Проверка, что конфигурация инициализирована
  static void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'AppConfig не инициализирован. Вызовите AppConfig.initialize() в main() перед runApp().'
      );
    }
  }

  /// Вывод текущей конфигурации в дебаг консоль
  static void _printConfiguration() {
    if (_config.debugMode) {
      debugPrint('🚀 AppConfig инициализирован');
      debugPrint('📱 Environment: ${_config.name}');
      debugPrint('🌐 Base URL: ${_config.baseUrl}');
      debugPrint('⏱️ Timeouts: ${_config.connectTimeout}s / ${_config.receiveTimeout}s');
      debugPrint('📝 Request Logging: ${_config.enableRequestLogging}');
      debugPrint('🐛 Debug Mode: ${_config.debugMode}');

      // Не показываем API ключи в логах по безопасности
      debugPrint('🔑 Google Maps API: ${_config.googleMapsApiKey.isNotEmpty ? "✅ Configured" : "❌ Missing"}');
      debugPrint('🔑 Firebase API: ${_config.firebaseApiKey.isNotEmpty ? "✅ Configured" : "❌ Missing"}');
    }
  }

  /// Получить все настройки как Map (для debug/testing)
  static Map<String, dynamic> toMap() {
    _checkInitialized();
    return {
      'environment': _config.environment.name,
      'environmentName': _config.name,
      'baseUrl': _config.baseUrl,
      'connectTimeout': _config.connectTimeout,
      'receiveTimeout': _config.receiveTimeout,
      'enableRequestLogging': _config.enableRequestLogging,
      'debugMode': _config.debugMode,
      'hasGoogleMapsKey': _config.googleMapsApiKey.isNotEmpty,
      'hasFirebaseKey': _config.firebaseApiKey.isNotEmpty,
      'hasOtherKey': _config.otherApiKey.isNotEmpty,
    };
  }

  /// Проверить, что все критичные настройки заполнены
  static List<String> validate() {
    _checkInitialized();
    final errors = <String>[];

    if (_config.baseUrl.isEmpty) {
      errors.add('API_BASE_URL не задан');
    }

    if (_config.environment == AppEnvironment.production) {
      // В продакшене некоторые ключи обязательны
      if (_config.googleMapsApiKey.isEmpty) {
        errors.add('GOOGLE_MAPS_API_KEY обязателен в production');
      }
      if (_config.firebaseApiKey.isEmpty) {
        errors.add('FIREBASE_API_KEY обязателен в production');
      }
    }

    return errors;
  }
}