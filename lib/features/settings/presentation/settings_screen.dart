import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../../../shared/utils/alert_helper.dart';
import '../application/locale_notifier.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/infrastructure/auth_repository.dart';
import '../../../core/services/notification_permission_service.dart';
import '../../../core/services/fcm_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isUpdatingLocale = false;
  final NotificationPermissionService _permissionService =
      NotificationPermissionService();
  bool _isNotificationDenied = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationPermission();
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
      final isDenied = await _permissionService.isDenied;
      if (mounted) {
        setState(() {
          _isNotificationDenied = isDenied;
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

  Future<void> _handleLocaleChange(Locale? value) async {
    if (value == null || _isUpdatingLocale) return;

    // Блокируем повторные нажатия
    setState(() {
      _isUpdatingLocale = true;
    });

    // Hide all current SnackBars before language change
    ScaffoldMessenger.of(context).clearSnackBars();

    // Обновляем locale в приложении
    await ref.read(localeProvider.notifier).setLocale(value);

    // Если пользователь авторизован, отправляем locale на бэкенд
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      final localeForApi = ref.read(localeProvider.notifier).getLocaleForApi();
      try {
        final repository = AuthRepository();
        final success = await repository.updateLocale(localeForApi);
        if (success) {
          // Обновляем пользователя в состоянии
          final user = authState.user;
          if (user != null) {
            ref
                .read(authProvider.notifier)
                .updateUser(user.copyWith(locale: localeForApi));
          }
        }
      } catch (e) {
        debugPrint('Error updating locale on backend: $e');
        // Не показываем ошибку пользователю, так как locale уже изменен локально
      }
    }

    // Сбрасываем состояние загрузки
    if (mounted) {
      setState(() {
        _isUpdatingLocale = false;
      });
    }

    // Wait for Flutter to rebuild with new locale
    if (context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          // Get updated localizations after locale change
          final updatedLocalizations = AppLocalizations.of(context);
          if (updatedLocalizations != null) {
            AlertHelper.showInfo(context, updatedLocalizations.settings_language_changed);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.settings_title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.settings_language,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_isUpdatingLocale)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
                RadioGroup<Locale>(
                  groupValue: locale,
                  onChanged: (Locale? value) {
                    if (!_isUpdatingLocale) {
                      _handleLocaleChange(value);
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<Locale>(
                        title: Text(localizations.language_azerbaijani),
                        value: const Locale('az'),
                        enabled: !_isUpdatingLocale,
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      RadioListTile<Locale>(
                        title: Text(localizations.language_english),
                        value: const Locale('en'),
                        enabled: !_isUpdatingLocale,
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      RadioListTile<Locale>(
                        title: Text(localizations.language_russian),
                        value: const Locale('ru'),
                        enabled: !_isUpdatingLocale,
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Notification Permission Banner (if denied)
          if (!_isCheckingPermission && _isNotificationDenied) ...[
            const SizedBox(height: 16),
            _buildNotificationPermissionBanner(context, localizations),
          ],
        ],
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
