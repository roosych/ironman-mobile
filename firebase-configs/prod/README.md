# 🔧 PRODUCTION Environment

## ⚠️ ВНИМАНИЕ: ПРОДАКШН ОКРУЖЕНИЕ!

Файлы в этой папке содержат продакшн секреты и **НЕ ДОЛЖНЫ** попадать в git!

## Файлы которые нужно добавить в эту папку:

### 📱 Android:
- `google-services.json` - скачать из Firebase Console проекта **ironman-mobile-prod**

### 🍎 iOS:
- `GoogleService-Info.plist` - скачать из Firebase Console проекта **ironman-mobile-prod**

## 📋 Как получить файлы:

1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Выберите проект **ironman-mobile-prod**
3. Перейдите в **Project Settings** → **General**
4. В секции **Your apps**:
   - Для Android: нажмите на Android иконку → **Download google-services.json**
   - Для iOS: нажмите на iOS иконку → **Download GoogleService-Info.plist**
5. Поместите файлы в эту папку

## ✅ Результат должен быть:
```
firebase-configs/prod/
├── google-services.json      ← Android PROD конфиг
└── GoogleService-Info.plist  ← iOS PROD конфиг
```

## 🔒 КРИТИЧЕСКИ ВАЖНО:

1. **НЕ КОММИТИТЬ** эти файлы в git!
2. **ДЕЛАТЬ BACKUP** отдельно от репозитория
3. **ОГРАНИЧИТЬ ДОСТУП** только для ответственных за релизы
4. **ПРОВЕРЯТЬ** `.gitignore` - папка `firebase-configs/prod/*` должна быть исключена

## 💾 Backup продакшн конфигов:
```bash
# Сохраните в безопасное место (не в git!)
cp firebase-configs/prod/* ~/secure-backups/firebase-prod/
```