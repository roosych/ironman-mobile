import '../domain/app_notification.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int unreadCount;
  final bool hasLoadedOnce;
  final int currentPage;
  final int lastPage;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.unreadCount = 0,
    this.hasLoadedOnce = false,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  bool get hasError => error != null;
  bool get hasData => notifications.isNotEmpty;
  bool get isEmpty =>
      notifications.isEmpty && !isLoading && error == null && hasLoadedOnce;
  bool get hasMorePages => currentPage < lastPage;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? unreadCount,
    bool? hasLoadedOnce,
    int? currentPage,
    int? lastPage,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}


