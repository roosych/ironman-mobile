import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../domain/app_notification.dart';
import 'notifications_state.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationService _service;
  static const Duration _requestTimeout = Duration(seconds: 20);

  NotificationsNotifier({NotificationService? service})
      : _service = service ?? NotificationService(),
        super(const NotificationsState());

  Future<void> load({bool force = false}) async {
    if (state.isLoading) return;
    if (state.hasLoadedOnce && !force) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final raw = await _service.getNotifications().timeout(_requestTimeout);

      debugPrint('=== DEBUG: NotificationsNotifier.load ===');
      debugPrint('Raw response keys: ${raw.keys.toList()}');
      debugPrint('Raw response type: ${raw.runtimeType}');

      final data = raw['data'];
      final meta = raw['meta'];

      debugPrint('Data type: ${data.runtimeType}');
      debugPrint('Meta type: ${meta.runtimeType}');
      if (data is List) {
        debugPrint('Data is List with ${data.length} items');
      } else if (data != null) {
        debugPrint('Data is not List: $data');
      }

      final notifications = <AppNotification>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            try {
              notifications.add(AppNotification.fromJson(item));
            } catch (e) {
              debugPrint('Error parsing notification item: $e');
              debugPrint('Item: $item');
            }
          } else if (item is Map) {
            try {
              notifications
                  .add(AppNotification.fromJson(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error parsing notification item (Map): $e');
              debugPrint('Item: $item');
            }
          } else {
            debugPrint('Item is not Map: ${item.runtimeType}');
          }
        }
      } else if (data != null) {
        // Если data не List, возможно это другой формат ответа
        debugPrint('Data is not a List, trying to handle as single object or different structure');
        debugPrint('Data: $data');
      }

      debugPrint('Parsed ${notifications.length} notifications');

      // Если data не List, проверяем другие возможные форматы ответа
      if (notifications.isEmpty) {
        // Проверяем, может ли быть другая структура ответа
        if (raw['success'] == true && raw['data'] != null) {
          final successData = raw['data'];
          debugPrint('Found success=true, checking data structure');
          if (successData is List) {
            debugPrint('Data is List in success response with ${successData.length} items');
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
        
        // Проверяем, может ли быть, что данные находятся непосредственно в корне ответа
        if (notifications.isEmpty) {
          // Проверяем, может ли быть, что список уведомлений находится в корне
          for (final key in raw.keys) {
            if (raw[key] is List) {
              debugPrint('Found List in key: $key');
              final listData = raw[key] as List;
              for (final item in listData) {
                if (item is Map<String, dynamic>) {
                  try {
                    notifications.add(AppNotification.fromJson(item));
                  } catch (e) {
                    debugPrint('Error parsing notification from $key: $e');
                  }
                } else if (item is Map) {
                  try {
                    notifications.add(AppNotification.fromJson(Map<String, dynamic>.from(item)));
                  } catch (e) {
                    debugPrint('Error parsing notification from $key: $e');
                  }
                }
              }
              if (notifications.isNotEmpty) {
                debugPrint('Successfully parsed ${notifications.length} notifications from key: $key');
                break;
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

      debugPrint('Final notifications count: ${notifications.length}');
      debugPrint('Unread count: $unreadCount');

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
        hasLoadedOnce: true,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error:
            'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
        hasLoadedOnce: true,
      );
    } catch (e) {
      debugPrint('NotificationsNotifier: load error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Произошла ошибка',
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
      await _service.markAsRead(id).timeout(_requestTimeout);
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
      rethrow;
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
      await _service.markAllAsRead().timeout(_requestTimeout);
    } catch (e) {
      state = state.copyWith(
        notifications: previous,
        unreadCount: previousUnread,
      );
      rethrow;
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
      await _service.deleteNotification(id).timeout(_requestTimeout);
    } catch (e) {
      // rollback
      final rollback = [...state.notifications]..insert(idx, removed);
      state = state.copyWith(
        notifications: rollback,
        unreadCount: removed.isRead ? state.unreadCount : state.unreadCount + 1,
      );
      rethrow;
    }
  }

  /// Сброс состояния уведомлений (используется при смене пользователя)
  void reset() {
    state = const NotificationsState();
  }
}


