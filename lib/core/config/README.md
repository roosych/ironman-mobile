# Конфигурация приложения

## Настройка

1. **Скопируйте файл примера:**
   ```bash
   cp lib/core/config/app_config.example.dart lib/core/config/app_config.dart
   ```

2. **Откройте `app_config.dart` и заполните реальными значениями:**
   - `baseUrl` - URL вашего API сервера
   - `googleMapsApiKey` - если используете Google Maps
   - `firebaseApiKey` - если используете Firebase
   - Другие настройки по необходимости

## Важно

- ✅ Файл `app_config.dart` **НЕ** загружается в GitHub (добавлен в `.gitignore`)
- ✅ Файл `app_config.example.dart` **загружается** в GitHub как шаблон
- ✅ Все настройки проекта берутся из `AppConfig`

## Примеры baseUrl

- **Android эмулятор:** `http://10.0.2.2:8000/api/v1`
- **iOS симулятор:** `http://127.0.0.1:8000/api/v1`
- **Физическое устройство (USB):** `http://127.0.0.1:8000/api/v1` (требуется `adb reverse tcp:8000 tcp:8000`)
- **Физическое устройство (Wi-Fi):** `http://192.168.1.100:8000/api/v1` (IP вашего компьютера)

## Использование в коде

```dart
import 'package:ironman_mobile/core/config/app_config.dart';

// Получить базовый URL
final url = AppConfig.baseUrl;

// Получить API ключ
final apiKey = AppConfig.googleMapsApiKey;
```

