# 🔧 Configuration Guide

Эта документация описывает, как настроить и использовать конфигурацию приложения.

## 📁 Структура конфигурации

```
lib/core/config/
├── environment.dart      # Конфигурации окружений
├── app_config_new.dart   # Главный класс конфигурации
└── app_config.dart       # Старый файл (будет удален)

.env.development.example   # Пример настроек для разработки
.env.staging.example      # Пример настроек для staging
.env.production.example   # Пример настроек для production
```

## 🚀 Быстрый старт

### 1. Настройка для разработки

```bash
# 1. Скопируйте example файл
cp .env.development.example .env.development

# 2. Отредактируйте .env.development под свои нужды
# Измените API_BASE_URL на ваш локальный сервер

# 3. Запустите приложение
flutter run --dart-define-from-file=.env.development
```

### 2. Инициализация в коде

```dart
// main.dart
import 'package:ironman_mobile/core/config/app_config_new.dart';

void main() {
  // Инициализируем конфигурацию ПЕРЕД runApp()
  AppConfig.initialize();

  runApp(MyApp());
}
```

### 3. Использование в коде

```dart
// Везде в приложении
import 'package:ironman_mobile/core/config/app_config_new.dart';

class ApiService {
  static final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: Duration(seconds: AppConfig.connectTimeout),
    receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
  ));
}

class GoogleMapsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      // Используем API ключ из конфига
      apiKey: AppConfig.googleMapsApiKey,
    );
  }
}
```

## 🌍 Окружения

### Development (по умолчанию)
- Локальный сервер разработки
- Включено подробное логирование
- Debug режим включен
- API ключи опциональны

### Staging
- Тестовый сервер
- Логирование включено
- Debug режим выключен
- Тестовые API ключи

### Production
- Продакшн сервер
- Логирование выключено
- Debug режим выключен
- Все API ключи обязательны

## 📝 Способы запуска

### 1. Environment Variables (Рекомендуемый)

```bash
# Development
flutter run --dart-define=ENVIRONMENT=development --dart-define=API_BASE_URL=http://localhost:8000

# Staging
flutter run --dart-define=ENVIRONMENT=staging --dart-define=API_BASE_URL=https://api-staging.com

# Production
flutter run --dart-define=ENVIRONMENT=production --dart-define=API_BASE_URL=https://api.com --dart-define=GOOGLE_MAPS_API_KEY=prod_key
```

### 2. Из .env файлов (Flutter 3.7+)

```bash
# Development
flutter run --dart-define-from-file=.env.development

# Staging
flutter run --dart-define-from-file=.env.staging

# Production
flutter run --dart-define-from-file=.env.production
```

### 3. Build команды

```bash
# Android APK
flutter build apk --dart-define=ENVIRONMENT=production --dart-define-from-file=.env.production

# iOS
flutter build ios --dart-define=ENVIRONMENT=production --dart-define-from-file=.env.production
```

## 🔒 Безопасность

### Что НЕЛЬЗЯ добавлять в git:
```gitignore
# Добавьте в .gitignore
.env.development
.env.staging
.env.production
```

### Что МОЖНО добавлять в git:
- `.env.*.example` файлы
- `environment.dart`
- `app_config_new.dart`

### Для продакшена:
- Все API ключи храните в CI/CD переменных
- Используйте Secrets в GitHub Actions/GitLab CI
- Никогда не хардкодьте production настройки

## 🧪 Тестирование и отладка

### Валидация конфигурации
```dart
void main() {
  AppConfig.initialize();

  // Проверяем корректность настроек
  final errors = AppConfig.validate();
  if (errors.isNotEmpty) {
    print('❌ Ошибки конфигурации:');
    for (final error in errors) {
      print('  - $error');
    }
    exit(1);
  }

  runApp(MyApp());
}
```

### Debug информация
```dart
// Показать все настройки (только в debug режиме)
if (AppConfig.debugMode) {
  print('Current config: ${AppConfig.toMap()}');
}
```

## 🔄 Миграция со старого AppConfig

### 1. Замените импорты
```dart
// Было
import 'package:ironman_mobile/core/config/app_config.dart';

// Стало
import 'package:ironman_mobile/core/config/app_config_new.dart';
```

### 2. Добавьте инициализацию в main()
```dart
void main() {
  AppConfig.initialize(); // Добавить эту строку
  runApp(MyApp());
}
```

### 3. API остается тот же
```dart
// Все эти вызовы работают как раньше
AppConfig.baseUrl
AppConfig.connectTimeout
AppConfig.googleMapsApiKey
AppConfig.debugMode
```

## 📦 CI/CD интеграция

### GitHub Actions
```yaml
name: Build
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2

    - name: Build APK
      run: |
        flutter build apk \
          --dart-define=ENVIRONMENT=production \
          --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }} \
          --dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}
```

### Fastlane
```ruby
# Fastfile
lane :build_production do
  sh("flutter build ios --dart-define=ENVIRONMENT=production --dart-define=API_BASE_URL=#{ENV['API_BASE_URL']}")
end
```

## ❓ Часто задаваемые вопросы

### Как добавить новую настройку?

1. Добавьте в `EnvironmentConfig` абстрактное свойство
2. Реализуйте в каждом конкретном классе окружения
3. Добавьте getter в `AppConfig`
4. Обновите .env.*.example файлы

### Можно ли менять настройки во время выполнения?

Нет, все настройки задаются на этапе compile-time через Environment Variables. Для runtime конфигурации используйте Firebase Remote Config.

### Как тестировать разные конфигурации?

```dart
// В тестах
void main() {
  group('AppConfig tests', () {
    test('development config', () {
      // Тест проверит правильность настроек development
    });
  });
}
```

## 🎯 Best Practices

1. **Всегда инициализируйте** конфигурацию в main()
2. **Не хардкодьте** критичные настройки - используйте Environment Variables
3. **Валидируйте** настройки при старте приложения
4. **Используйте .env файлы** для локальной разработки
5. **Храните секреты** в CI/CD переменных, не в коде
6. **Документируйте** все новые настройки в .example файлах