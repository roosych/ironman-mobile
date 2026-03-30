import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:async';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../../../shared/utils/alert_helper.dart';
import '../application/locale_notifier.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/infrastructure/auth_repository.dart';
import '../../../core/services/notification_permission_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../policies/presentation/policy_screen.dart';

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

      // Выполняем обновление локали на сервере в фоновом режиме
      // Не блокируем UI и не показываем ошибки, так как локаль уже обновлена локально
      unawaited((() async {
        try {
          final repository = AuthRepository();
          final success = await repository.updateLocale(localeForApi);
          if (success && mounted) {
            // Обновляем пользователя в состоянии только если виджет все еще mounted
            final user = authState.user;
            if (user != null) {
              ref
                  .read(authProvider.notifier)
                  .updateUser(user.copyWith(locale: localeForApi));
            }
          }
        } catch (e) {
          debugPrint('Error updating locale on backend: $e');
          // Полностью игнорируем все ошибки - локаль уже обновлена локально
        }
      })());
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24.r,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.settings_title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide.none,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
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
                              Padding(
                                padding: EdgeInsets.only(left: 8.w),
                                child: SizedBox(
                                  width: 16.r,
                                  height: 16.r,
                                  child: const CircularProgressIndicator(strokeWidth: 2),
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
                  SizedBox(height: 16.h),
                  _buildNotificationPermissionBanner(context, localizations),
                ],

                // Policies Section
                SizedBox(height: 16.h),
                _buildPoliciesCard(context, localizations),
              ],
            ),
          ),
          // Version info fixed at bottom
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16.h,
              top: 8.h,
            ),
            child: Text(
              'v 1.0.0',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12.sp,
              ),
            ),
          ),
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
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification01,
                  color: theme.colorScheme.error,
                  size: 24.r,
                ),
                SizedBox(width: 12.w),
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
            SizedBox(height: 8.h),
            Text(
              localizations.notification_permission_disabled_message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: AppButtonStyles.primaryGradientButton(
                text: localizations.notification_permission_open_settings,
                onPressed: _openAppSettings,
                borderRadius: 12,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                textStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Виджет карточки политик
  Widget _buildPoliciesCard(BuildContext context, AppLocalizations localizations) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PolicyScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLicenseDraft,
                color: theme.colorScheme.onSurface,
                size: 24.r,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  localizations.settings_policies_and_terms,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
