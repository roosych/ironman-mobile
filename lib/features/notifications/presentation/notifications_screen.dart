import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../../shared/utils/alert_helper.dart';
import '../../../shared/utils/error_handler.dart';
import '../../settings/application/locale_notifier.dart';
import '../application/notifications_notifier.dart';
import '../application/notifications_state.dart';
import '../domain/app_notification.dart';
import 'notification_detail_screen.dart';
import '../../../core/services/notification_permission_service.dart';
import '../../../core/services/fcm_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with WidgetsBindingObserver {
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  final _scrollController = ScrollController();
  String? _openedItemKey;
  final NotificationPermissionService _permissionService =
      NotificationPermissionService();
  bool _isNotificationDenied = false;
  bool _isCheckingPermission = true;
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkNotificationPermission();
      ref.read(notificationsProvider.notifier).load();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
      _recheckFcmPermissions();
    }
  }

  Future<void> _checkNotificationPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    try {
      final isAuthorized = await _permissionService.isAuthorized;

      if (mounted) {
        setState(() {
          _isNotificationDenied = !isAuthorized;
          _isCheckingPermission = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNotificationDenied = false;
          _isCheckingPermission = false;
        });
      }
    }
  }

  Future<void> _recheckFcmPermissions() async {
    try {
      final wasDenied = _isNotificationDenied;
      await _checkNotificationPermission();

      if (wasDenied && !_isNotificationDenied) {
        await FcmService().recheckPermissionsAndRegister();
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  Future<void> _openAppSettings() async {
    final wasDenied = _isNotificationDenied;
    await _permissionService.openAppSettings();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _checkNotificationPermission();
        _recheckFcmPermissions();
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _checkNotificationPermission();
        if (wasDenied && !_isNotificationDenied) {
          FcmService().recheckPermissionsAndRegister();
        }
      }
    });
  }

  Future<void> _refresh() async {
    try {
      await ref.read(notificationsProvider.notifier).refresh();
    } catch (e) {
      // Ошибка уже обработана в провайдере
    }
  }

  void _showErrorSafely(dynamic error, BuildContext context) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.mounted) return;
      ErrorHandler.showError(context, error);
    });
  }

  String _localizeError(BuildContext context, String? errorKey) {
    if (errorKey == null) {
      return AppLocalizations.of(context)!.common_loading_error;
    }

    final localizations = AppLocalizations.of(context)!;

    switch (errorKey) {
      case 'api_error_timeout':
        return localizations.api_error_timeout;
      case 'api_error_unexpected':
        return localizations.api_error_unexpected('Network error');
      case 'api_error_generic':
        return localizations.api_error_generic('Loading failed');
      case 'api_error_network_no_connection':
        return localizations.api_error_network_no_connection;
      default:
        return errorKey.isNotEmpty ? errorKey : localizations.common_loading_error;
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ref.read(notificationsProvider.notifier).markAllAsRead();
    } catch (e) {
      if (!mounted) return;
      AlertHelper.showError(
        context,
        AppLocalizations.of(context)!.notifications_mark_all_read_error,
      );
    }
  }

  Future<void> _openNotification(AppNotification n) async {
    try {
      await ref.read(notificationsProvider.notifier).markAsRead(n.id);
    } catch (_) {
      // Ignore
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(notification: n),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    ref.listen<NotificationsState>(notificationsProvider, (previous, next) {
      if (!mounted) return;
      if (next.hasError &&
          next.error != null &&
          next.notifications.isNotEmpty &&
          previous?.error != next.error &&
          _lastShownError != next.error) {
        _lastShownError = next.error;
        _showErrorSafely(next.error!, context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: theme.colorScheme.onSurface,
            size: 24.r,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.notifications_title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.notifications_mark_all_read_tooltip,
            onPressed: state.notifications.isEmpty ? null : _markAllAsRead,
            icon: const Icon(Icons.mark_email_read_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.isLoading && state.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.hasError && state.notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _localizeError(context, state.error),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      IconButton(
                        onPressed: () =>
                            ref.read(notificationsProvider.notifier).refresh(),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32.r,
                        ),
                        tooltip: AppLocalizations.of(context)!.common_retry,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.isEmpty && !(_isNotificationDenied && !_isCheckingPermission)) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.notifications_no_notifications,
                ),
              );
            }

            final bannerCount = (!_isCheckingPermission && _isNotificationDenied ? 1 : 0);
            final loaderCount = state.isLoadingMore ? 1 : 0;
            final totalItemCount = bannerCount + state.notifications.length + loaderCount;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: totalItemCount,
                itemBuilder: (context, index) {
                  if (!_isCheckingPermission &&
                      _isNotificationDenied &&
                      index == 0) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _buildNotificationPermissionBanner(
                        context,
                        AppLocalizations.of(context)!,
                      ),
                    );
                  }

                  final notificationIndex = (!_isCheckingPermission &&
                          _isNotificationDenied
                      ? index - 1
                      : index);
                  if (notificationIndex >= state.notifications.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  final n = state.notifications[notificationIndex];
                  final itemKey = 'notification_${n.id}_${n.readAt}';
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _NotificationListItem(
                      itemKey: itemKey,
                      isOpen: _openedItemKey == itemKey,
                      onOpenSwipe: (key) {
                        if (_openedItemKey != key) {
                          setState(() {
                            _openedItemKey = key;
                          });
                        }
                      },
                      onCloseSwipe: () {
                        if (_openedItemKey != null) {
                          setState(() {
                            _openedItemKey = null;
                          });
                        }
                      },
                      notification: n,
                      dateFormat: _dateFormat,
                      onOpen: () {
                        setState(() => _openedItemKey = null);
                        _openNotification(n);
                      },
                      onDelete: () async {
                        final currentContext = context;
                        try {
                          await ref
                              .read(notificationsProvider.notifier)
                              .delete(n.id);
                        } catch (e) {
                          if (!mounted || !currentContext.mounted) return;
                          ErrorHandler.showError(currentContext, e);
                        }
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationPermissionBanner(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGradientStart.withValues(alpha: 0.05),
              AppColors.primaryGradientEnd.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification02,
                    color: AppColors.primaryGradientEnd,
                    size: 24.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      localizations.dashboard_notification_card_title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                localizations.dashboard_notification_card_message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppButtonStyles.primaryGradientButton(
                      text: localizations.dashboard_notification_card_enable,
                      onPressed: _openAppSettings,
                      borderRadius: 10.r,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationListItem extends ConsumerStatefulWidget {
  final String itemKey;
  final bool isOpen;
  final void Function(String key) onOpenSwipe;
  final VoidCallback onCloseSwipe;
  final AppNotification notification;
  final DateFormat dateFormat;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _NotificationListItem({
    required this.itemKey,
    required this.isOpen,
    required this.onOpenSwipe,
    required this.onCloseSwipe,
    required this.notification,
    required this.dateFormat,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  ConsumerState<_NotificationListItem> createState() =>
      _NotificationListItemState();
}

class _NotificationListItemState extends ConsumerState<_NotificationListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double get _offset => _controller.value;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 160),
          lowerBound: 0,
          upperBound: 56,
          value: widget.isOpen ? 56 : 0,
        )..addListener(() {
          setState(() {});
        });
  }

  @override
  void didUpdateWidget(covariant _NotificationListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOpen && _controller.value != 0) {
      _controller.animateTo(0, duration: const Duration(milliseconds: 120));
    } else if (widget.isOpen && _controller.value != _controller.upperBound) {
      _controller.animateTo(
        _controller.upperBound,
        duration: const Duration(milliseconds: 120),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _controller.animateTo(target, duration: const Duration(milliseconds: 160));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    _controller.value = (_controller.value - delta).clamp(0, _controller.upperBound);
  }

  void _onDragEnd(DragEndDetails details) {
    final shouldOpen = _controller.value > _controller.upperBound * 0.3;
    if (shouldOpen) {
      _animateTo(_controller.upperBound);
      widget.onOpenSwipe(widget.itemKey);
    } else {
      _animateTo(0);
      widget.onCloseSwipe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final theme = Theme.of(context);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE53E3E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onDelete,
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE53E3E).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: const Color(0xFFE53E3E),
                    size: 22.r,
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-_offset, 0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.onCloseSwipe();
                    _animateTo(0);
                    widget.onOpen();
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final locale = ref.watch(localeProvider);
                                  final localizedTitle = n.getLocalizedTitle(
                                    locale.languageCode,
                                  );
                                  return Text(
                                    localizedTitle.isEmpty
                                        ? AppLocalizations.of(context)!.notifications_fallback_title
                                        : localizedTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: n.isRead
                                          ? FontWeight.w400
                                          : FontWeight.w700,
                                      fontSize: 16.sp,
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (!n.isRead) ...[
                              SizedBox(width: 8.w),
                              Container(
                                width: 8.r,
                                height: 8.r,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Builder(
                          builder: (context) {
                            final locale = ref.watch(localeProvider);
                            final localizedBody = n.getLocalizedBody(
                              locale.languageCode,
                            );
                            if (localizedBody.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8.h),
                                Text(
                                  localizedBody,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (n.createdAt != null) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 14.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                widget.dateFormat.format(n.createdAt!.toLocal()),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
