# 🔥 Управление окружениями Firebase

Простая система для переключения между разными Firebase проектами.

## 📁 Структура папок

```
firebase-configs/
├── dev/
│   ├── google-services.json      # Android конфиг для DEV
│   └── GoogleService-Info.plist  # iOS конфиг для DEV
└── prod/
    ├── google-services.json      # Android конфиг для PROD
    └── GoogleService-Info.plist  # iOS конфиг для PROD
```

## 🚀 Как использовать

### 1. Подготовка конфигураций

1. **Скачайте конфиги из Firebase Console** для каждого проекта:
   - `ironman-mobile-dev`
   - `ironman-mobile-prod`

2. **Поместите файлы в соответствующие папки**:
   ```bash
   firebase-configs/dev/google-services.json
   firebase-configs/dev/GoogleService-Info.plist
   firebase-configs/prod/google-services.json
   firebase-configs/prod/GoogleService-Info.plist
   ```

### 2. Переключение окружений

#### Windows (Command Prompt):
```cmd
switch-env.bat dev      # Переключить на DEV
switch-env.bat prod     # Переключить на PROD
```

#### Linux/Mac/Git Bash:
```bash
./switch-env.sh dev      # Переключить на DEV
./switch-env.sh prod     # Переключить на PROD
```

### 3. Проверка текущего окружения

```bash
# Просмотреть активный проект
grep "project_id" android/app/google-services.json

# История переключений
cat switch-env.log
```

## 🔒 Безопасность

### Что НЕ коммитится в Git:
- `android/app/google-services.json` (активный конфиг)
- `ios/Runner/GoogleService-Info.plist` (активный конфиг)
- `firebase-configs/prod/*` (продакшн ключи)
- `switch-env.log` (логи переключений)

### Что коммитится в Git:
- `firebase-configs/dev/*` (dev ключи - безопасно)
- Скрипты переключения
- Эта документация

## ⚠️ Важные заметки

1. **Всегда проверяйте** текущее окружение перед сборкой
2. **Переключайте бекенд** на то же окружение
3. **Не коммитьте продакшн ключи** в репозиторий
4. **Делайте backup** продакшн конфигов отдельно

## 🐛 Устранение проблем

### Ошибка "файл не найден":
```bash
# Проверьте структуру папок
ls -la firebase-configs/
ls -la firebase-configs/dev/
```

### Ошибка сборки после переключения:
```bash
# Очистите кеш Flutter
flutter clean
flutter pub get
```

### Неправильный Firebase проект:
```bash
# Проверьте активный конфиг
grep "project_id" android/app/google-services.json
```

## 📱 Примеры использования

### Разработка:
```bash
./switch-env.sh dev
flutter run --dart-define=ENV=dev
```

### Релиз:
```bash
./switch-env.sh prod
flutter build appbundle --dart-define=ENV=prod
```