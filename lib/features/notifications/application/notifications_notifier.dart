import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/api_error_keys.dart';
import '../../../core/services/notification_service.dart';
import '../domain/app_notification.dart';
import 'notifications_state.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationService _service;

  NotificationsNotifier({NotificationService? service})
      : _service = service ?? NotificationService(),
        super(const NotificationsState());

  Future<void> load({bool force = false}) async {
    if (state.isLoading) return;
    if (state.hasLoadedOnce && !force) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final raw = await _service.getNotifications();

      final data = raw['data'];
      final meta = raw['meta'];

      final notifications = <AppNotification>[];

      // Основная логика парсинга data
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            try {
              notifications.add(AppNotification.fromJson(item));
            } catch (e) {
              debugPrint('Error parsing notification item: $e');
            }
          } else if (item is Map) {
            try {
              notifications.add(AppNotification.fromJson(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error parsing notification item (Map): $e');
            }
          }
        }
      }

      // Fallback: если не удалось найти в data, проверяем другие ключи
      if (notifications.isEmpty && raw['success'] == true) {
        final successData = raw['data'];
        if (successData is List) {
          for (final item in successData) {
            if (item is Map<String, dynamic>) {
              try {
                notifications.add(AppNotification.fromJson(item));
              } catch (e) {
                debugPrint('Error parsing notification: $e');
              }
            } else if (item is Map) {
              try {
                notifications.add(AppNotification.fromJson(Map<String, dynamic>.from(item)));
              } catch (e) {
                debugPrint('Error parsing notification: $e');
              }
            }
          }
        }
      }

      int unreadCount = 0;
      if (meta is Map) {
        final rawUnread = meta['unread_count'];
        if (rawUnread is num) unreadCount = rawUnread.toInt();
        if (rawUnread is String) unreadCount = int.tryParse(rawUnread) ?? 0;
      }

      // Fallback: если meta нет — считаем по isRead
      if (unreadCount == 0 && notifications.isNotEmpty) {
        unreadCount = notifications.where((n) => !n.isRead).length;
      }

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
        hasLoadedOnce: true,
      );
    } catch (e) {
      debugPrint('NotificationsNotifier: load error: $e');

      final exception = NotificationsApiException(
        localizationKey: ApiErrorKeys.unexpected,
        parameters: {'error': e.toString()},
        originalMessage: 'Failed to load notifications',
      );

      state = state.copyWith(
        isLoading: false,
        error: exception.localizationKey,
        hasLoadedOnce: true,
      );
    }
  }

  Future<void> refresh() => load(force: true);

  Future<void> markAsRead(int id) async {
    // Optimistic update
    final idx = state.notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;

    final wasUnread = !state.notifications[idx].isRead;
    if (wasUnread) {
      final updated = [...state.notifications];
      updated[idx] = updated[idx].copyWith(
        readAt: DateTime.now(),
        isRead: true,
      );
      state = state.copyWith(
        notifications: updated,
        unreadCount: (state.unreadCount - 1).clamp(0, 1 << 30),
      );
    }

    try {
      await _service.markAsRead(id);
    } catch (e) {
      // rollback if needed
      if (wasUnread) {
        final rollback = [...state.notifications];
        rollback[idx] = rollback[idx].copyWith(
          clearReadAt: true,
          isRead: false,
        );
        state = state.copyWith(
          notifications: rollback,
          unreadCount: state.unreadCount + 1,
        );
      }

      throw NotificationsApiException(
        localizationKey: ApiErrorKeys.generic,
        parameters: {'message': 'Failed to mark notification as read'},
        originalMessage: e.toString(),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final anyUnread = state.notifications.any((n) => !n.isRead);
    if (!anyUnread) {
      state = state.copyWith(unreadCount: 0);
      return;
    }

    // Optimistic update
    final updated = state.notifications
        .map((n) => n.isRead
            ? n
            : n.copyWith(readAt: DateTime.now(), isRead: true))
        .toList(growable: false);
    final previous = state.notifications;
    final previousUnread = state.unreadCount;

    state = state.copyWith(notifications: updated, unreadCount: 0);

    try {
      await _service.markAllAsRead();
    } catch (e) {
      state = state.copyWith(
        notifications: previous,
        unreadCount: previousUnread,
      );

      throw NotificationsApiException(
        localizationKey: ApiErrorKeys.generic,
        parameters: {'message': 'Failed to mark all notifications as read'},
        originalMessage: e.toString(),
      );
    }
  }

  Future<void> delete(int id) async {
    final idx = state.notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;

    final removed = state.notifications[idx];
    final nextList = [...state.notifications]..removeAt(idx);

    state = state.copyWith(
      notifications: nextList,
      unreadCount:
          removed.isRead ? state.unreadCount : (state.unreadCount - 1).clamp(0, 1 << 30),
    );

    try {
      await _service.deleteNotification(id);
    } catch (e) {
      // rollback
      final rollback = [...state.notifications]..insert(idx, removed);
      state = state.copyWith(
        notifications: rollback,
        unreadCount: removed.isRead ? state.unreadCount : state.unreadCount + 1,
      );

      throw NotificationsApiException(
        localizationKey: ApiErrorKeys.generic,
        parameters: {'message': 'Failed to delete notification'},
        originalMessage: e.toString(),
      );
    }
  }

  /// Сброс состояния уведомлений (используется при смене пользователя)
  void reset() {
    state = const NotificationsState();
  }
}


