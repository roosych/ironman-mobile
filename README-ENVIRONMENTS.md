# 🚀 Простая система управления окружениями

Простая и безопасная система для работы с тремя окружениями: DEV, STAGING и PROD.

## 🎯 Что получили:

✅ **Максимальная простота** - вручную размещаете файлы в папки
✅ **Безопасность** - продакшн ключи не попадают в git
✅ **Контроль** - всегда знаете какое окружение активно
✅ **Скорость** - переключение одной командой

## 📁 Созданная структура:

```
project-root/
├── firebase-configs/
│   ├── dev/                          # DEV конфиги (коммитятся в git)
│   │   ├── README.md                 # Инструкции
│   │   ├── google-services.json      # ← Добавьте сюда Android конфиг
│   │   └── GoogleService-Info.plist  # ← Добавьте сюда iOS конфиг
│   ├── staging/                      # STAGING конфиги (использует dev)
│   │   ├── README.md                 # Инструкции + объяснение
│   │   ├── google-services.json      # ← Копируется из dev
│   │   └── GoogleService-Info.plist  # ← Копируется из dev
│   └── prod/                         # PROD конфиги (НЕ коммитятся!)
│       ├── README.md                 # Инструкции + предупреждения
│       ├── google-services.json      # ← Добавьте сюда Android конфиг
│       └── GoogleService-Info.plist  # ← Добавьте сюда iOS конфиг
├── .env.development                  # Dev настройки
├── .env.staging                      # Staging настройки (копирует dev)
├── .env.production                   # Production настройки
├── switch-env.sh                     # Переключение окружений
├── check-env.sh                      # Проверка текущего окружения
├── ENVIRONMENTS.md                   # Полная документация
└── .gitignore                        # Обновлен для безопасности
```

## 🏁 Быстрый старт:

### 1. **Создайте Firebase проекты:**
- `ironman-mobile-dev` (для разработки)
- `ironman-mobile-prod` (для продакшна)

### 2. **Скачайте конфиги из Firebase Console:**
Для каждого проекта: Project Settings → General → Your apps:
- Android: `google-services.json`
- iOS: `GoogleService-Info.plist`

### 3. **Вручную разместите файлы:**
```
firebase-configs/dev/google-services.json      (от ironman-mobile-dev)
firebase-configs/dev/GoogleService-Info.plist  (от ironman-mobile-dev)
firebase-configs/prod/google-services.json     (от ironman-mobile-prod)
firebase-configs/prod/GoogleService-Info.plist (от ironman-mobile-prod)
```

### 4. **Переключение между окружениями:**

```bash
./switch-env.sh dev      # Переключить на разработку
./switch-env.sh staging  # Переключить на staging (использует dev конфиги)
./switch-env.sh prod     # Переключить на продакшн

./check-env.sh           # Проверить текущее окружение
```

## 🧪 Особенности STAGING окружения:

**Staging использует DEV Firebase конфиги, но свои .env настройки:**

✅ **Firebase конфиги:** Копируются из dev (один проект для упрощения)
✅ **API сервер:** Отдельный staging сервер (`192.168.50.115:8081`)
✅ **Debug режим:** Отключен (в отличие от dev)
✅ **Логирование:** Включено (для тестирования)

**Зачем это нужно:**
- Тестирование с отдельным staging сервером, но без создания отдельного Firebase проекта
- Отладка в production-like режиме (DEBUG_MODE=false)
- Изолированное тестирование API с staging бекендом
- Быстрое переключение между dev и staging

## 🔒 Безопасность автоматически настроена:

### ❌ НЕ попадает в git:
- Активные конфиги (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`)
- Продакшн ключи (`firebase-configs/prod/*`)
- Логи переключений (`switch-env.log`)

### ✅ Сохраняется в git:
- Dev конфиги (безопасно для разработки)
- Staging конфиги (копируют dev, безопасно)
- Скрипты управления
- Документация

## 📊 Примеры использования:

```bash
# Разработка
./switch-env.sh dev
flutter run --dart-define-from-file=.env.development

# Staging тестирование (использует dev Firebase + staging настройки)
./switch-env.sh staging
flutter run --dart-define-from-file=.env.staging

# Релиз
./switch-env.sh prod
flutter build appbundle --dart-define-from-file=.env.production

# Всегда проверяйте перед билдом
./check-env.sh
```

## 🚨 Первый запуск:

**Если видите ошибку "google-services.json is missing":**

1. Разместите Firebase конфиги в папки `firebase-configs/dev/` и `firebase-configs/prod/`
2. Переключитесь на dev: `./switch-env.sh dev`
3. Запустите приложение: `flutter run`

---

**🎉 Система готова! Просто добавьте файлы и используйте!**