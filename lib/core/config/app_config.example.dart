/// Пример конфигурации приложения
/// 
/// ИНСТРУКЦИЯ:
/// 1. Скопируйте этот файл в app_config.dart
/// 2. Заполните реальными значениями
/// 3. app_config.dart уже добавлен в .gitignore и не будет загружен в GitHub
class AppConfig {
  // ============================================
  // НАСТРОЙКИ СЕРВЕРА
  // ============================================
  
  /// Базовый URL API сервера
  /// 
  /// Примеры:
  /// - Для Android эмулятора: 'http://10.0.2.2:8000/api/v1'
  /// - Для iOS симулятора: 'http://127.0.0.1:8000/api/v1'
  /// - Для физического устройства через USB (ADB port forwarding): 'http://127.0.0.1:8000/api/v1'
  /// - Для физического устройства через Wi-Fi: 'http://192.168.1.100:8000/api/v1'
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  
  /// Таймаут подключения к серверу (в секундах)
  static const int connectTimeout = 30;
  
  /// Таймаут получения ответа от сервера (в секундах)
  static const int receiveTimeout = 30;

  // ============================================
  // КЛЮЧИ ОТ СТОРОННИХ ИНТЕГРАЦИЙ
  // ============================================
  
  /// API ключ для Google Maps (если используется)
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  
  /// API ключ для Firebase (если используется)
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY_HERE';
  
  /// API ключ для других сервисов
  static const String otherApiKey = 'YOUR_OTHER_API_KEY_HERE';

  // ============================================
  // ДРУГИЕ НАСТРОЙКИ
  // ============================================
  
  /// Включить/выключить логирование запросов
  static const bool enableRequestLogging = true;
  
  /// Режим отладки
  static const bool debugMode = true;
}

