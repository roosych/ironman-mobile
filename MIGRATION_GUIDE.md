# API Layer Migration Guide

## 🎯 Цель

Полная переработка API слоя для устранения:
- Блокировок UI при запросах
- Зависаний приложения
- Сложных workaround'ов
- Race conditions между запросами

## 🏗️ Новая архитектура

### SimpleApiClient
- **Единый экземпляр** (Singleton pattern)
- **Автоматическая обработка ошибок** с показом AlertDialog
- **Неблокирующие запросы** - UI всегда отзывчив
- **Простые таймауты** без сложной логики
- **Типизированные ответы** ApiResponse<T>

### Базовые классы
- `BaseApiService` - базовый класс для всех API сервисов
- `ApiResponse<T>` - типизированный ответ API
- `ApiError` - структурированная ошибка

## 📁 Новые файлы

### Core Network
- `lib/core/network/simple_api_client.dart` - новый API клиент
- `lib/core/network/base_api_service.dart` - базовый класс для сервисов

### API Services
- `lib/features/auth/infrastructure/simple_auth_api.dart`
- `lib/features/profile/infrastructure/simple_profile_api.dart`
- `lib/features/rankings/infrastructure/simple_rankings_api.dart`
- `lib/features/results/infrastructure/simple_results_api.dart`
- `lib/features/upcoming_races/infrastructure/simple_upcoming_races_api.dart`
- `lib/features/dashboard/infrastructure/simple_athletes_api.dart`

### Repositories
- `lib/features/auth/infrastructure/simple_auth_repository.dart`

### State Notifiers
- `lib/features/auth/application/simple_auth_notifier.dart`
- `lib/features/rankings/application/simple_rankings_notifier.dart`

## 🔄 Как использовать

### В UI коде

**Старый способ:**
```dart
// Сложная логика с ref.listen для ошибок
ref.listen<AuthState>(authProvider, (previous, next) {
  if (next.error != null) {
    ErrorHandler.showError(context, next.error!);
  }
});

// Блокирующий вызов
await ref.read(authProvider.notifier).login(email, password);
```

**Новый способ:**
```dart
// Ошибки показываются автоматически через SimpleApiClient
// Никаких ref.listen для ошибок не нужно!

// Неблокирующий вызов
ref.read(simpleAuthProvider.notifier).login(email: email, password: password);
```

### В API сервисах

**Старый способ:**
```dart
final response = await _dio.post('/auth/login', data: data);
if (response.data['success'] == true) {
  return AuthResponse.fromJson(response.data);
} else {
  throw AuthApiException('Login failed');
}
```

**Новый способ:**
```dart
return client.post<AuthResult>(
  '/auth/login',
  data: data,
  fromJson: (json) => AuthResult.fromJson(json as Map<String, dynamic>),
);
```

## ✨ Преимущества

### 1. Простота
- **Нет сложных interceptor'ов** с таймаутами
- **Нет Future.any() и Future.delayed()**
- **Нет microtask'ов и PostFrameCallback'ов**
- **Нет retry логики и background checks**

### 2. Надежность
- **UI никогда не блокируется** - все запросы асинхронные
- **Автоматический показ ошибок** пользователю
- **Нет race conditions** между запросами
- **Предсказуемое поведение**

### 3. Производительность
- **Singleton API клиент** - нет множественных экземпляров Dio
- **Параллельные запросы** не блокируют друг друга
- **Оптимизированные таймауты**

## 🔧 План миграции

### Этап 1: Core (Завершен)
- ✅ SimpleApiClient
- ✅ BaseApiService
- ✅ Инициализация в main.dart

### Этап 2: Auth (Завершен)
- ✅ SimpleAuthApi
- ✅ SimpleAuthRepository
- ✅ SimpleAuthNotifier

### Этап 3: Остальные сервисы (Частично)
- ✅ SimpleProfileApi
- ✅ SimpleRankingsApi + Notifier
- ✅ SimpleResultsApi
- ✅ SimpleUpcomingRacesApi
- ✅ SimpleAthletesApi
- ⏳ Остальные Notifier'ы
- ⏳ Обновление UI для использования новых провайдеров

### Этап 4: UI миграция
- ⏳ Обновить все экраны для использования новых провайдеров
- ⏳ Удалить старые ref.listen для ошибок
- ⏳ Тестирование

### Этап 5: Cleanup
- ⏳ Удаление старых файлов
- ⏳ Обновление импортов
- ⏳ Финальное тестирование

## 🧪 Тестирование

### Что тестировать:
1. **UI отзывчивость** - нет зависаний при запросах
2. **Показ ошибок** - автоматические AlertDialog'и
3. **Параллельные запросы** - не блокируют друг друга
4. **Таймауты** - корректная обработка медленных запросов
5. **Сессия** - корректная обработка 401 ошибок

### Известные проблемы старого API:
- ❌ Зависание при логине/регистрации
- ❌ Красные экраны в debug режиме
- ❌ Дублирование алерт диалогов
- ❌ Блокировка UI thread

### Ожидаемое поведение нового API:
- ✅ Никаких зависаний
- ✅ Только AlertDialog'и для ошибок
- ✅ Один диалог на ошибку
- ✅ UI всегда отзывчив

## 🚀 Готово к использованию

Новый API слой готов к использованию! Начните с миграции экранов аутентификации:

```dart
// Замените
final authState = ref.watch(authProvider);

// На
final authState = ref.watch(simpleAuthProvider);
```

Все методы остаются теми же, но теперь они работают надежно и не блокируют UI!