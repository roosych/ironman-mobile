TASK: Handle 401 Unauthenticated (force logout)
Контекст

Backend использует Laravel Sanctum

Токены могут быть инвалидированы сервером (например, при смене пароля)

Mobile app хранит токен локально

🎯 Цель

При получении 401 Unauthenticated:

разлогинить пользователя

удалить токен

сбросить состояние

перенаправить на экран Login

✅ Требования
1. Centralized API layer

Все HTTP-запросы должны идти через один API client

Использовать:

Dio или

http + interceptor

2. Interceptor на ответы API

При любом ответе:

401 Unauthorized


или body:

{
  "message": "Unauthenticated."
}

3. Поведение при 401

Выполнить один раз (не зациклиться):

Удалить токен из local storage

SharedPreferences / SecureStorage

Очистить user state

Provider / Riverpod / Bloc

Перейти на Login screen

Показать snackbar / dialog:

"Your session has expired. Please log in again."

4. Защита от бесконечного редиректа

Добавить флаг isLoggingOut

Если logout уже выполняется — игнорировать новые 401

5. UX сценарий

📌 Пример:

пользователь открыт экран Athlete Info

backend уже удалил токен

следующий API-запрос → 401

приложение:

выходит

возвращает на Login

пользователь понимает почему