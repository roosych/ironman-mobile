import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';

/// Состояние разрешения на уведомления
enum NotificationPermissionState {
  /// Разрешение предоставлено
  authorized,
  
  /// Разрешение отклонено
  denied,
  
  /// Разрешение еще не запрашивалось
  notDetermined,
  
  /// Временное разрешение (только iOS)
  provisional,
}

/// Сервис для работы с разрешениями push-уведомлений
class NotificationPermissionService {
  static final NotificationPermissionService _instance =
      NotificationPermissionService._internal();
  factory NotificationPermissionService() => _instance;
  NotificationPermissionService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Получить текущий статус разрешений уведомлений
  Future<NotificationPermissionState> getPermissionStatus() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          return NotificationPermissionState.authorized;
        case AuthorizationStatus.denied:
          return NotificationPermissionState.denied;
        case AuthorizationStatus.notDetermined:
          return NotificationPermissionState.notDetermined;
        case AuthorizationStatus.provisional:
          return NotificationPermissionState.provisional;
      }
    } catch (e) {
      // В случае ошибки возвращаем notDetermined
      return NotificationPermissionState.notDetermined;
    }
  }

  /// Проверка, разрешены ли уведомления
  Future<bool> get isAuthorized async {
    final status = await getPermissionStatus();
    return status == NotificationPermissionState.authorized ||
        status == NotificationPermissionState.provisional;
  }

  /// Проверка, запрещены ли уведомления
  Future<bool> get isDenied async {
    final status = await getPermissionStatus();
    return status == NotificationPermissionState.denied;
  }

  /// Проверка, не определено ли разрешение
  Future<bool> get isNotDetermined async {
    final status = await getPermissionStatus();
    return status == NotificationPermissionState.notDetermined;
  }

  /// Проверка, является ли разрешение временным (provisional)
  Future<bool> get isProvisional async {
    final status = await getPermissionStatus();
    return status == NotificationPermissionState.provisional;
  }

  /// Открыть системные настройки приложения
  /// Пользователь сможет включить уведомления вручную
  Future<void> openAppSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      // Игнорируем ошибки открытия настроек
    }
  }
}

