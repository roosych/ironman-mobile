import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
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
    _checkNotificationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Проверяем статус разрешений при возврате приложения в активное состояние
    // (например, после возврата из системных настроек)
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
      _recheckFcmPermissions();
    }
  }

  /// Проверка статуса разрешений уведомлений
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

  /// Повторная проверка разрешений FCM и регистрация токена
  Future<void> _recheckFcmPermissions() async {
    try {
      final wasDenied = _isNotificationDenied;
      await _checkNotificationPermission();
      
      // Если разрешения были запрещены, а теперь разрешены - переинициализируем FCM
      if (wasDenied && !_isNotificationDenied) {
        await FcmService().recheckPermissionsAndRegister();
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Открыть системные настройки приложения
  Future<void> _openAppSettings() async {
    final wasDenied = _isNotificationDenied;
    await _permissionService.openAppSettings();
    
    // Проверяем статус снова после возврата из настроек
    // Используем несколько проверок с задержками, так как система может обновлять статус не сразу
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _checkNotificationPermission();
        _recheckFcmPermissions();
      }
    });
    
    // Дополнительная проверка через 1 секунду на случай, если первая не сработала
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _checkNotificationPermission();
        // Если разрешения были запрещены, а теперь разрешены - переинициализируем FCM
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
      // Ошибка уже обработана в провайдере, алерт покажется через listener
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
      // Ignore — UI still открывается, стейт откатится при ошибке
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

    // Слушаем ошибки при refresh (pull to refresh)
    ref.listen<NotificationsState>(notificationsProvider, (previous, next) {
      if (!mounted) return;
      // Показываем ошибку только если есть данные (не пустой список) и ошибка появилась при refresh
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
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.notifications_title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(
              context,
            )!.notifications_mark_all_read_tooltip,
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.error ??
                            AppLocalizations.of(context)!.common_loading_error,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      IconButton(
                        onPressed: () =>
                            ref.read(notificationsProvider.notifier).refresh(),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
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
            final totalItemCount = bannerCount + state.notifications.length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: totalItemCount,
                itemBuilder: (context, index) {
                  // Показываем баннер в начале списка, если разрешения запрещены
                  if (!_isCheckingPermission &&
                      _isNotificationDenied &&
                      index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildNotificationPermissionBanner(
                        context,
                        AppLocalizations.of(context)!,
                      ),
                    );
                  }
                  
                  // Корректируем индекс для списка уведомлений
                  final notificationIndex = (!_isCheckingPermission &&
                          _isNotificationDenied
                      ? index - 1
                      : index);
                  final n = state.notifications[notificationIndex];
                  final itemKey = 'notification_${n.id}_${n.readAt}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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

  /// Виджет баннера для уведомления о запрещенных уведомлениях
  Widget _buildNotificationPermissionBanner(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification01,
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.notification_permission_disabled_title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              localizations.notification_permission_disabled_message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _openAppSettings,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              child: Text(
                localizations.notification_permission_open_settings,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
  static const double _iconArea = 56;
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
          upperBound: _iconArea,
          value: widget.isOpen ? _iconArea : 0,
        )..addListener(() {
          setState(() {});
        });
  }

  @override
  void didUpdateWidget(covariant _NotificationListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOpen && _controller.value != 0) {
      _controller.animateTo(0, duration: const Duration(milliseconds: 120));
    } else if (widget.isOpen && _controller.value != _iconArea) {
      _controller.animateTo(
        _iconArea,
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
    _controller.value = (_controller.value - delta).clamp(0, _iconArea);
  }

  void _onDragEnd(DragEndDetails details) {
    final shouldOpen = _controller.value > _iconArea * 0.3;
    if (shouldOpen) {
      _animateTo(_iconArea);
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
              color: theme.cardColor,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onDelete,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppColors.ironmanRed,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-_offset, 0),
            child: Card(
              color: theme.cardColor,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  widget.onCloseSwipe();
                  _animateTo(0);
                  widget.onOpen();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                                      ? AppLocalizations.of(
                                          context,
                                        )!.notifications_fallback_title
                                      : localizedTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: n.isRead
                                        ? FontWeight.w400
                                        : FontWeight.w700,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (!n.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
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
                              const SizedBox(height: 8),
                              Text(
                                localizedBody,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (n.createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.dateFormat.format(n.createdAt!.toLocal()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
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
