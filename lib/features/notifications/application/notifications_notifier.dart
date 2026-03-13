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
      final raw = await _service.getNotifications(page: 1);
      final (notifications, unreadCount, currentPage, lastPage) = _parseResponse(raw);

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        currentPage: currentPage,
        lastPage: lastPage,
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

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading) return;
    if (!state.hasMorePages) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final raw = await _service.getNotifications(page: nextPage);
      final (newItems, _, currentPage, lastPage) = _parseResponse(raw);

      state = state.copyWith(
        notifications: [...state.notifications, ...newItems],
        currentPage: currentPage,
        lastPage: lastPage,
        isLoadingMore: false,
      );
    } catch (e) {
      debugPrint('NotificationsNotifier: loadMore error: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true, currentPage: 1, lastPage: 1);

    try {
      final raw = await _service.getNotifications(page: 1);
      final (notifications, unreadCount, currentPage, lastPage) = _parseResponse(raw);

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        currentPage: currentPage,
        lastPage: lastPage,
        isLoading: false,
        hasLoadedOnce: true,
      );
    } catch (e) {
      debugPrint('NotificationsNotifier: refresh error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  (List<AppNotification>, int, int, int) _parseResponse(Map<String, dynamic> raw) {
    final data = raw['data'];
    final meta = raw['meta'];

    final notifications = <AppNotification>[];
    if (data is List) {
      for (final item in data) {
        try {
          if (item is Map<String, dynamic>) {
            notifications.add(AppNotification.fromJson(item));
          } else if (item is Map) {
            notifications.add(AppNotification.fromJson(Map<String, dynamic>.from(item)));
          }
        } catch (e) {
          debugPrint('Error parsing notification item: $e');
        }
      }
    }

    int unreadCount = 0;
    int currentPage = 1;
    int lastPage = 1;
    if (meta is Map) {
      final rawUnread = meta['unread_count'];
      if (rawUnread is num) unreadCount = rawUnread.toInt();
      if (rawUnread is String) unreadCount = int.tryParse(rawUnread) ?? 0;
      currentPage = (meta['current_page'] as num?)?.toInt() ?? 1;
      lastPage = (meta['last_page'] as num?)?.toInt() ?? 1;
    }

    if (unreadCount == 0 && notifications.isNotEmpty) {
      unreadCount = notifications.where((n) => !n.isRead).length;
    }

    return (notifications, unreadCount, currentPage, lastPage);
  }

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


