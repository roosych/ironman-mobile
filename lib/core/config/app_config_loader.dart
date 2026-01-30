import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Загрузчик конфигурации из JSON файла
///
/// Использование:
/// 1. Создайте app_config.json на основе app_config.json.example
/// 2. Заполните реальными значениями
/// 3. Вызовите AppConfigLoader.load() в main.dart перед runApp()
class AppConfigLoader {
  static bool _loaded = false;

  /// Загрузить конфигурацию из JSON файла
  ///
  /// Вызывайте в main() перед runApp():
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await AppConfigLoader.load();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> load() async {
    if (_loaded) return;

    try {
      final String jsonString = await rootBundle.loadString(
        'lib/core/config/app_config.json',
      );
      final Map<String, dynamic> json = jsonDecode(jsonString);

      // Обновляем значения в AppConfig
      _updateConfig(json);
      _loaded = true;
    } catch (e) {
      // Если файл не найден или ошибка парсинга, используем значения по умолчанию
      // из app_config.dart
      debugPrint('⚠️ Не удалось загрузить app_config.json: $e');
      debugPrint('Используются значения по умолчанию из app_config.dart');
    }
  }

  static void _updateConfig(Map<String, dynamic> json) {
    // Примечание: В Dart нельзя изменить const значения во время выполнения
    // Поэтому для JSON варианта нужно использовать другой подход:
    // либо сделать AppConfig не const, либо использовать singleton с загрузкой

    // Этот пример показывает концепцию, но для реального использования
    // нужно переделать AppConfig на не-const класс с методами загрузки
  }
}
