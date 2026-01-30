# 🔧 DEV Environment

## Файлы которые нужно добавить в эту папку:

### 📱 Android:
- `google-services.json` - скачать из Firebase Console проекта **ironman-mobile-dev**

### 🍎 iOS:
- `GoogleService-Info.plist` - скачать из Firebase Console проекта **ironman-mobile-dev**

## 📋 Как получить файлы:

1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Выберите проект **ironman-mobile-dev**
3. Перейдите в **Project Settings** → **General**
4. В секции **Your apps**:
   - Для Android: нажмите на Android иконку → **Download google-services.json**
   - Для iOS: нажмите на iOS иконку → **Download GoogleService-Info.plist**
5. Поместите файлы в эту папку

## ✅ Результат должен быть:
```
firebase-configs/dev/
├── google-services.json      ← Android конфиг
└── GoogleService-Info.plist  ← iOS конфиг
```

## 🔒 Безопасность:
DEV конфиги можно коммитить в git - они не содержат продакшн секретов.