import '../domain/app_notification.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;
  final bool hasLoadedOnce;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
    this.hasLoadedOnce = false,
  });

  bool get hasError => error != null;
  bool get hasData => notifications.isNotEmpty;
  bool get isEmpty =>
      notifications.isEmpty && !isLoading && error == null && hasLoadedOnce;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
    bool? hasLoadedOnce,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}


