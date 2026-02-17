import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';

/// Утилита для работы с URL изображений
class ImageUrlHelper {
  /// Конвертирует относительный URL изображения в абсолютный
  ///
  /// Примеры:
  /// - Относительный: "/storage/photos/photo123.jpg"
  /// - Абсолютный: "http://172.16.23.67:8000/storage/photos/photo123.jpg"
  ///
  /// - Уже полный URL: "https://example.com/image.jpg"
  /// - Возвращает как есть: "https://example.com/image.jpg"
  static String getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      debugPrint('🖼️ ImageUrlHelper: URL is null or empty');
      return '';
    }

    // Если URL уже полный (начинается с http или https), возвращаем как есть
    if (url.startsWith('http://') || url.startsWith('https://')) {
      debugPrint('🖼️ ImageUrlHelper: URL already full: $url');
      return url;
    }

    // Если URL начинается с '/', убираем '/api/v1' из baseUrl и добавляем URL
    final baseUrl = AppConfig.baseUrl;
    final serverBaseUrl = baseUrl.replaceAll('/api/v1', '');

    // Убеждаемся, что URL начинается с '/'
    final cleanUrl = url.startsWith('/') ? url : '/$url';

    final fullUrl = '$serverBaseUrl$cleanUrl';
    debugPrint('🖼️ ImageUrlHelper: Converting "$url" to "$fullUrl"');
    return fullUrl;
  }

  /// Проверяет, является ли URL валидным для изображения
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    final fullUrl = getFullImageUrl(url);
    return fullUrl.isNotEmpty;
  }
}