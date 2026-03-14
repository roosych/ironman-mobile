import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../../main.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/presentation/notification_detail_screen.dart';
import 'notification_service.dart';
import '../../features/notifications/application/notifications_notifier.dart';
import '../storage/secure_storage.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  // Геттер вместо поля — см. комментарий в notification_permission_service.dart
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final ApiClient _apiClient = ApiClient();
  final SecureStorage _storage = SecureStorage();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? _androidChannel;
  String? _currentToken;
  bool _isInitialized = false;

  /// Принудительная переинициализация FCM (для отладки)
  /// Сбрасывает флаг инициализации и заново инициализирует FCM
  Future<void> forceReinitialize() async {
    debugPrint('FCM: Force reinitializing...');
    _isInitialized = false;
    _currentToken = null;
    await initialize();
  }

  /// Инициализация FCM
  Future<void> initialize() async {
    try {
      // Ленивая инициализация инфраструктуры — выполняем один раз за сессию
      if (!_isInitialized) {
        await _initLocalNotifications();

        // ВАЖНО: Настраиваем обработчики сообщений ВСЕГДА, даже без разрешений
        // Это нужно, чтобы при получении разрешений обработчики уже были готовы
        _setupMessageHandlers();

        // Слушаем обновления токена (регистрация нового)
        _messaging.onTokenRefresh.listen((newToken) async {
          if (await _hasValidAuthSession()) {
            await _registerToken(newToken);
          } else {
            debugPrint('FCM: Skip token refresh register (no auth/unverified)');
          }
        });

        // Проверяем текущий статус разрешений (БЕЗ запроса разрешения)
        // Не вызываем requestPermission(), чтобы не показывать системную модалку
        final settings = await _messaging.getNotificationSettings();

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          // iOS: разрешить показ в foreground
          await _messaging.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('FCM: Initialized infrastructure with permissions');
        } else {
          // Разрешение не предоставлено (denied или notDetermined)
          // Инфраструктура все равно инициализирована, обработчики готовы
          // Пользователь может включить уведомления через настройки
          debugPrint(
            'FCM: Initialized infrastructure without permissions (status: ${settings.authorizationStatus})',
          );
        }

        _isInitialized = true;
      }

      // ВАЖНО: при каждом вызове initialize пытаемся зарегистрировать токен заново
      // (после нового логина или восстановления сессии).
      if (!await _hasValidAuthSession()) {
        debugPrint(
          'FCM: Skip token registration — no auth token or user unverified',
        );
        return;
      }

      // Проверяем статус разрешений перед регистрацией токена
      final currentSettings = await _messaging.getNotificationSettings();
      if (currentSettings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          currentSettings.authorizationStatus ==
              AuthorizationStatus.provisional) {
        await _getAndRegisterToken();
        debugPrint('FCM: Token ensured/registered');
      } else {
        debugPrint('FCM: Skip token registration — permission not granted');
      }
    } catch (e) {
      debugPrint('FCM: Error during initialization: $e');
    }
  }

  /// Повторная проверка разрешений и регистрация токена
  /// Используется после того, как пользователь включил уведомления в настройках
  Future<void> recheckPermissionsAndRegister() async {
    try {
      debugPrint('FCM: Rechecking permissions and registering token...');

      if (!await _hasValidAuthSession()) {
        debugPrint('FCM: Skip recheck — no auth token or user unverified');
        return;
      }

      final settings = await _messaging.getNotificationSettings();
      debugPrint(
        'FCM: Current permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Если разрешение предоставлено, но инфраструктура еще не настроена
        if (!_isInitialized) {
          await _initLocalNotifications();
          _setupMessageHandlers();
          _messaging.onTokenRefresh.listen((newToken) async {
            if (await _hasValidAuthSession()) {
              await _registerToken(newToken);
            } else {
              debugPrint(
                'FCM: Skip token refresh register (no auth/unverified)',
              );
            }
          });
          _isInitialized = true;
          debugPrint(
            'FCM: Infrastructure initialized after permission granted',
          );
        }

        // ВАЖНО: Обновляем настройки для iOS даже если инфраструктура уже инициализирована
        // Это нужно, чтобы уведомления показывались в foreground после включения разрешений
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Регистрируем токен
        await _getAndRegisterToken();
        debugPrint('FCM: ✅ Token registered after permission granted');
      } else {
        debugPrint(
          'FCM: Permission still not granted (status: ${settings.authorizationStatus})',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('FCM: Error during recheck: $e');
      debugPrint('FCM: Stack trace: $stackTrace');
    }
  }

  /// Проверяем, есть ли валидная сессия и пользователь верифицирован
  Future<bool> _hasValidAuthSession() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return false;
    final user = await _storage.getUser();
    if (user is Map<String, dynamic>) {
      final verified = user['verified'];
      if (verified == false) return false;
    }
    return true;
  }

  /// Получить и зарегистрировать токен
  Future<void> _getAndRegisterToken() async {
    try {
      if (!await _hasValidAuthSession()) {
        debugPrint('FCM: Skip get/register — no auth token or user unverified');
        return;
      }

      // Если в памяти нет токена — попробуем достать из локального хранилища,
      // чтобы не потерять его между рестартами приложения.
      _currentToken ??= await _loadTokenLocally();

      String? token = await _messaging.getToken();
      token ??= _currentToken;

      if (token != null) {
        _currentToken = token;
        await _registerToken(token);
      }
    } catch (e) {
      debugPrint('FCM: Error getting token: $e');
    }
  }

  /// Регистрация токена на сервере
  Future<void> _registerToken(String token) async {
    try {
      if (!await _hasValidAuthSession()) {
        debugPrint('FCM: Skip register — no auth token or user unverified');
        return;
      }

      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Unknown Device';
      String deviceType = Platform.isAndroid ? 'android' : 'ios';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} (${iosInfo.model})';
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/user/fcm-token',
        data: {
          'token': token,
          'device_type': deviceType,
          'device_name': deviceName,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('FCM: Token registered successfully');
        await _saveTokenLocally(token);
      } else {
        debugPrint('FCM: Failed to register token: ${response.statusCode}');
        debugPrint('FCM: Response: ${response.data}');
      }
    } catch (e) {
      debugPrint('FCM: Error registering token: $e');
    }
  }

  /// Сохранение токена локально
  Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  /// Получить токен из локального хранилища (если был сохранён ранее)
  Future<String?> _loadTokenLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  /// Удаление токена (при logout)
  Future<void> unregisterToken() async {
    // Если токен в памяти отсутствует, пробуем достать его из SharedPreferences.
    _currentToken ??= await _loadTokenLocally();
    if (_currentToken == null) return;

    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/user/fcm-token',
        data: {'token': _currentToken},
      );

      if (response.statusCode == 200) {
        debugPrint('FCM: Token unregistered successfully');
        _currentToken = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('fcm_token');
      }
    } catch (e) {
      debugPrint('FCM: Error unregistering token: $e');
    }
  }

  /// Настройка обработчиков сообщений
  void _setupMessageHandlers() {
    debugPrint('🎯 FCM: Setting up message handlers');
    // Уведомления когда приложение открыто (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔥 FCM: Foreground message received');
      debugPrint('🔥 FCM: Title: ${message.notification?.title}');
      debugPrint('🔥 FCM: Body: ${message.notification?.body}');
      debugPrint('🔥 FCM: Data: ${message.data}');
      debugPrint('🔥 FCM: Message ID: ${message.messageId}');

      // Показываем локальное уведомление, т.к. стандартно FCM не отображает его в foreground
      _showLocalNotification(message);

      // Здесь можно обновить UI приложения
      _handleNotification(message);
      _refreshNotifications();
    });

    // Уведомления когда приложение в фоне (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM: Background message opened app');
      _handleNotificationTap(message);
    });

    // Проверка, было ли приложение открыто из уведомления
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('FCM: App opened from notification');
        _handleNotificationTap(message);
      }
    });
  }

  /// Обработка уведомления
  void _handleNotification(RemoteMessage message) {
    // Здесь можно обновить состояние приложения
    // Пример: обновить список уведомлений
    // notificationService.refreshNotifications();
  }

  void _refreshNotifications() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    try {
      final container = ProviderScope.containerOf(context);
      container.read(notificationsProvider.notifier).refresh();
    } catch (e) {
      debugPrint('FCM: Unable to refresh notifications: $e');
    }
  }

  /// Обработка тапа по уведомлению
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final notificationIdRaw = data['notification_id'] ?? data['id'];

    // Навигация в зависимости от типа уведомления
    // Используем navigatorKey из main.dart
    // Если navigator еще не готов, ждем немного
    void navigate() {
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        // Если navigator еще не готов, ждем 100мс и пробуем снова
        Future.delayed(const Duration(milliseconds: 100), navigate);
        return;
      }

      switch (type) {
        case 'race':
          final raceId = data['race_id'];
          if (raceId != null) {
            // Navigator.pushNamed(context, '/race/$raceId');
            debugPrint('FCM: Navigate to race: $raceId');
          }
          break;
        case 'profile':
          final profileId = data['profile_id'];
          if (profileId != null) {
            // Navigator.pushNamed(context, '/profile/$profileId');
            debugPrint('FCM: Navigate to profile: $profileId');
          }
          break;
        case 'security':
          // Navigator.pushNamed(context, '/security');
          debugPrint('FCM: Navigate to security');
          break;
        default:
          if (notificationIdRaw != null) {
            final notificationId = int.tryParse(notificationIdRaw.toString());
            if (notificationId != null) {
              // Помечаем прочитанным на сервере и открываем экран с деталями
              NotificationService()
                  .markAsRead(notificationId)
                  .catchError((_) {});

              final notification = AppNotification(
                id: notificationId,
                title:
                    (message.notification?.title ??
                            data['title'] ??
                            data['subject'] ??
                            'Уведомление')
                        .toString(),
                body: (message.notification?.body ?? data['body'] ?? '')
                    .toString(),
                createdAt: DateTime.now(),
                readAt: DateTime.now(),
              );

              navigator.push(
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationDetailScreen(notification: notification),
                ),
              );
              _refreshNotifications();
              return;
            }
          }
          // Navigator.pushNamed(context, '/notifications');
          debugPrint('FCM: Navigate to notifications');
          break;
      }
    }

    navigate();
  }

  /// Получить текущий токен
  String? get currentToken => _currentToken;

  /// Инициализация локальных уведомлений (каналы/иконки)
  Future<void> _initLocalNotifications() async {
    try {
      // Android: канал с высоким приоритетом
      _androidChannel ??= const AndroidNotificationChannel(
        'ironman_high_importance',
        'High Importance Notifications',
        description: 'Shows important notifications while app is in foreground',
        importance: Importance.high,
      );

      const androidInit = AndroidInitializationSettings(
        '@drawable/ic_notification',
      );
      const iosInit = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      final initResult = await _localNotifications.initialize(initSettings);

      if (initResult == true) {
        debugPrint('FCM: Local notifications initialized successfully');
      } else {
        debugPrint('FCM: Local notifications initialization returned false');
      }

      if (Platform.isAndroid && _androidChannel != null) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_androidChannel!);
        debugPrint('FCM: Android notification channel created');
      }
    } catch (e) {
      debugPrint('FCM: Error initializing local notifications: $e');
      // Не пробрасываем ошибку, чтобы не ломать общую инициализацию FCM
    }
  }

  /// Показать локальное уведомление в foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final android = notification?.android;

      debugPrint('📱 FCM: Showing local notification');
      debugPrint(
        '📱 FCM: Title: ${notification?.title ?? message.data['title']}',
      );
      debugPrint('📱 FCM: Body: ${notification?.body ?? message.data['body']}');
      debugPrint(
        '📱 FCM: Channel ID: ${_androidChannel?.id ?? 'ironman_high_importance'}',
      );
      debugPrint('📱 FCM: Local notifications ready: $_isInitialized');

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel?.id ?? 'ironman_high_importance',
          _androidChannel?.name ?? 'High Importance Notifications',
          channelDescription:
              _androidChannel?.description ?? 'Foreground notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@drawable/ic_notification',
          showWhen: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        notification.hashCode,
        notification?.title ?? message.data['title'],
        notification?.body ?? message.data['body'],
        details,
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );

      debugPrint('✅ FCM: Local notification shown successfully');
    } catch (e) {
      debugPrint('FCM: Error showing local notification: $e');
    }
  }
}

/// Top-level функция для обработки фоновых сообщений
/// Должна быть вне класса
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🚀 FCM: Background message received');
  debugPrint('🚀 FCM: Title: ${message.notification?.title}');
  debugPrint('🚀 FCM: Body: ${message.notification?.body}');
  debugPrint('🚀 FCM: Data: ${message.data}');
  debugPrint('🚀 FCM: Message ID: ${message.messageId}');

  // Показываем уведомление в background режиме
  try {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Инициализируем локальные уведомления если еще не инициализированы
    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // Создаем канал для Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'ironman_high_importance',
        'High Importance Notifications',
        description: 'Shows important notifications while app is in background',
        importance: Importance.high,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }

    // Показываем локальное уведомление
    final notification = message.notification;
    if (notification != null) {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'ironman_high_importance',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title ?? message.data['title'],
        notification.body ?? message.data['body'],
        details,
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );

      debugPrint('✅ FCM: Background notification shown');
    }
  } catch (e) {
    debugPrint('FCM: Error showing background notification: $e');
  }
}
