import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/auth/application/auth_notifier.dart';
import 'package:ironman_mobile/features/results/application/race_results_notifier.dart';
import 'package:ironman_mobile/features/results/application/race_results_state.dart';
import 'package:ironman_mobile/features/results/domain/race_result.dart';
import 'package:ironman_mobile/shared/widgets/result_detail_screen.dart';
import 'package:ironman_mobile/shared/widgets/result_card.dart';
import 'package:ironman_mobile/shared/widgets/user_avatar_widget.dart';
import 'package:ironman_mobile/features/dashboard/presentation/profile_screen.dart'
    as profile;
import 'package:ironman_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_notifier.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_state.dart';
import 'package:ironman_mobile/features/upcoming_races/presentation/upcoming_races_screen.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/widgets/grouped_upcoming_race_card.dart';
import 'package:ironman_mobile/features/upcoming_races/domain/upcoming_race.dart';
// import 'package:ironman_mobile/features/race_selection/presentation/widgets/race_selection_bottom_sheet.dart';
import 'package:ironman_mobile/core/theme/app_button_styles.dart';
import '../../notifications/application/notifications_notifier.dart';
import '../../../core/services/notification_permission_service.dart';
import '../application/records_notifier.dart';
import '../../../features/settings/application/theme_notifier.dart';

/// Helper function to safely cast personal bests data
Map<String, dynamic>? _safeGetPersonalBestsData(dynamic data) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) return data;
  if (data is List<dynamic> && data.isNotEmpty && data[0] is Map<String, dynamic>) {
    return data[0] as Map<String, dynamic>;
  }
  return null;
}

// Вспомогательные функции для расчёта темпа
Map<String, double> _getDistances(String raceType) {
  final type = raceType.toLowerCase().replaceAll(' ', '').replaceAll('_', '');

  if (type.contains('70.3') || type.contains('703')) {
    return {'swim': 1.9, 'bike': 90.0, 'run': 21.1};
  } else if (type.contains('5150')) {
    return {'swim': 1.5, 'bike': 40.0, 'run': 10.0};
  } else {
    return {'swim': 3.8, 'bike': 180.0, 'run': 42.2};
  }
}

Duration? _parseTime(String time) {
  try {
    final parts = time.split(':');
    if (parts.length != 3) return null;

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);

    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  } catch (_) {
    return null;
  }
}

String _calculateSwimPace(String timeStr, double distance) {
  final duration = _parseTime(timeStr);
  if (duration == null || distance <= 0) return '';

  final totalSeconds = duration.inSeconds;
  final pacePerHundredMetersSeconds = (totalSeconds / distance) * 0.1; // 100 meters

  final minutes = (pacePerHundredMetersSeconds / 60).floor();
  final seconds = (pacePerHundredMetersSeconds % 60).round();

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String _calculateBikePace(String timeStr, double distance) {
  final duration = _parseTime(timeStr);
  if (duration == null || distance <= 0) return '';

  final hours = duration.inSeconds / 3600;
  final speed = distance / hours;

  return speed.toStringAsFixed(1);
}

String _calculateRunPace(String timeStr, double distance) {
  final duration = _parseTime(timeStr);
  if (duration == null || distance <= 0) return '';

  final totalSeconds = duration.inSeconds;
  final pacePerKmSeconds = totalSeconds / distance;

  final minutes = (pacePerKmSeconds / 60).floor();
  final seconds = (pacePerKmSeconds % 60).round();

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  @override
  void initState() {
    super.initState();
    // Загружаем уведомления один раз при монтировании.
    // НЕ делаем это в build() или build()-методах дочерних виджетов —
    // вызов провайдера из build() создаёт цикл: rebuild → load → rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        ref.read(notificationsProvider.notifier).load();
      }
    });
  }

  // Загрузка результатов не нужна на главном экране - данные из profile.stats
  // void _loadResults() {
  //   final userId = ref.read(authProvider).user?.id;
  //   if (userId != null) {
  //     ref.read(raceResultsProvider.notifier).loadResults(userId);
  //   }
  // }

  // Future<void> _refreshResults() async {
  //   final userId = ref.read(authProvider).user?.id;
  //   if (userId != null) {
  //     await ref.read(raceResultsProvider.notifier).refreshResults(userId);
  //   }
  // }

  // ВАЖНО: эти методы принимают уже прочитанные значения из build() — они НЕ
  // вызывают ref.watch сами по себе. Повторный вызов ref.watch для одного
  // провайдера в одном build()-цикле регистрирует лишние Riverpod-подписки и
  // вызывает дублирующий markNeedsBuild() на iOS → _InactiveElements assertion.

  int? _getTotalRaces(dynamic user, RaceResultsState resultsState) {
    final profile = user?.profile;
    final stats = profile?.stats;
    final totalRaces = stats?.summary?.totalRaces;

    // Fallback 1: из подтверждённых результатов в state
    final approvedResultsCount = resultsState.results.where((r) => r.isApproved).length;

    // Fallback 2: из race_results в профиле
    final profileRaceResults = profile?.raceResults?.length ?? 0;

    // Fallback 3: ironman_races_count из профиля
    final ironmanRacesCount = profile?.ironmanRacesCount ?? 0;

    if (totalRaces != null) return totalRaces;
    if (profileRaceResults > 0) return profileRaceResults;
    if (ironmanRacesCount > 0) return ironmanRacesCount;
    if (approvedResultsCount > 0) return approvedResultsCount;
    return null;
  }

  int? _getProfileId(dynamic user) => user?.profile?.id as int?;

  Future<void> _refreshAllData() async {
    try {
      debugPrint('HomeTab: Pull-to-refresh triggered');

      // Обновляем данные параллельно для лучшей производительности
      final futures = <Future<void>>[
        // Обновить профиль пользователя и статистику
        ref.read(authProvider.notifier).refreshUser(),

        // Обновить upcoming races для dashboard
        _refreshUpcomingRaces(),

        // Обновить уведомления
        _refreshNotifications(),
      ];

      // Добавляем обновление результатов и рекордов, если есть profileId
      final profileId = ref.read(authProvider).user?.profile?.id;
      if (profileId != null) {
        futures.add(_refreshResults(profileId));
        futures.add(ref.read(recordsProvider(profileId).notifier).loadRecords());
      }

      await Future.wait(futures);
      debugPrint('HomeTab: Pull-to-refresh completed successfully');
    } catch (e) {
      debugPrint('HomeTab: Pull-to-refresh error: $e');
      // Ошибки уже обработаны в соответствующих провайдерах
    }
  }

  Future<void> _refreshResults(int profileId) async {
    try {
      await ref.read(raceResultsProvider.notifier).refreshResults(profileId);
    } catch (e) {
      debugPrint('HomeTab: Error refreshing results: $e');
    }
  }

  Future<void> _refreshUpcomingRaces() async {
    try {
      final profileId = ref.read(authProvider).user?.profile?.id;
      await Future.wait([
        ref.read(dashboardUpcomingRacesProvider.notifier).refreshUpcomingRaces(
          onlyFuture: true,
        ),
        if (profileId != null)
          ref.read(myDashboardUpcomingRacesProvider.notifier).refreshUpcomingRaces(
            userProfileId: profileId,
            onlyFuture: true,
          ),
      ]);
    } catch (e) {
      debugPrint('HomeTab: Error refreshing upcoming races: $e');
    }
  }

  Future<void> _refreshNotifications() async {
    try {
      ref.read(notificationsProvider.notifier).load();
    } catch (e) {
      debugPrint('HomeTab: Error refreshing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final resultsState = ref.watch(raceResultsProvider);
    final totalRaces = _getTotalRaces(user, resultsState);
    final profileId = _getProfileId(user);

    // Данные о количестве гонок берутся из profile.stats, которые приходят при авторизации
    // resultsState используется только для отображения списка результатов в карточке

    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // Background image with gradient overlay
          Container(
            height: 0.5.sh,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scaffoldBg.withValues(alpha: 0.2),
                    scaffoldBg.withValues(alpha: 0.6),
                    scaffoldBg,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Main content with pull-to-refresh
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.ironmanRed,
              displacement: 80.0, // Центрирование индикатора
              onRefresh: _refreshAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // Top section with avatar and notifications
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const profile.ProfileScreen()),
                        );
                      },
                      child: UserAvatarWidget(
                        url: user?.avatarUrl,
                        radius: 32.r,
                      ),
                    ),
                    // User Profile and Notifications
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // User Profile Menu
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const profile.ProfileScreen()),
                            );
                          },
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedUser,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 28.r,
                          ),
                        ),
                        // Theme toggle
                        IconButton(
                          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                          icon: HugeIcon(
                            icon: ref.watch(themeModeProvider) == ThemeMode.dark
                                ? HugeIcons.strokeRoundedSun03
                                : HugeIcons.strokeRoundedMoon02,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 28.r,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Notifications
                        _NotificationButton(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Greeting section
              if (user != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.home_greeting_welcome,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 16.sp,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                    ],
                  ),
                ),

              // My Results expandable section
              Padding(
                key: const ValueKey('my_results'),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _MyResultsExpandableCard(
                  totalRaces: totalRaces,
                  resultsState: resultsState,
                  profileId: profileId,
                ),
              ),

              SizedBox(key: const ValueKey('spacer1'), height: 12.h),

              // Personal Bests Expandable Section
              Padding(
                key: const ValueKey('personal_bests'),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _PersonalBestsExpandableCard(
                  profileId: profileId,
                  results: profileId != null
                      ? resultsState.results.where((r) => r.isApproved).toList()
                      : const [],
                ),
              ),

              SizedBox(key: const ValueKey('spacer2'), height: 12.h),

              // My Upcoming Races Expandable Section
              if (profileId != null)
                _MyUpcomingRacesExpandableSection(profileId: profileId),

              // Pace Calculator card
              Padding(
                key: const ValueKey('pace_calc'),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _PaceCalculatorCard(),
              ),

              SizedBox(height: 12.h),

              // Upcoming Races Section
              Padding(
                key: const ValueKey('upcoming_races'),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _UpcomingRacesSection(),
              ),

              SizedBox(height: 12.h),
              // _NotificationPermissionCard убрана — требует Firebase,
              // который не инициализирован, и вызывает assertion на iOS.
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPermissionCard extends ConsumerStatefulWidget {
  const _NotificationPermissionCard({super.key});

  @override
  ConsumerState<_NotificationPermissionCard> createState() =>
      _NotificationPermissionCardState();
}

class _NotificationPermissionCardState
    extends ConsumerState<_NotificationPermissionCard> with WidgetsBindingObserver {
  final NotificationPermissionService _permissionService =
      NotificationPermissionService();
  bool _isNotificationDenied = false;
  bool _isCheckingPermission = true;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ПРАВИЛО: нельзя вызывать функцию, которая делает setState, напрямую из initState.
    // _checkNotificationPermission синхронно вызывает setState(...) ДО первого await —
    // это setState до первого кадра, когда элемент ещё не вставлен в дерево →
    // "Tried to build dirty widget in the wrong build scope" на iOS.
    // addPostFrameCallback гарантирует, что setState вызывается только после
    // того, как элемент полностью вставлен и первый build завершён.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkNotificationPermission();
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
    // Проверяем разрешения при возврате в приложение из настроек
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    // Не вызываем setState здесь — _isCheckingPermission уже true по умолчанию.
    // Синхронный setState в начале async-метода, вызванного из initState (даже через
    // addPostFrameCallback), может попасть в середину build-прохода дочерних виджетов
    // в IndexedStack → _elements.contains(element) assertion на iOS.
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

  void _enableNotifications() async {
    await _permissionService.openAppSettings();
    // Проверка разрешений произойдет автоматически в didChangeAppLifecycleState
  }

  void _dismissCard() {
    setState(() {
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Не показываем карточку если уведомления разрешены, проверка не завершена или карточка скрыта
    if (!_isNotificationDenied || _isCheckingPermission || !_isVisible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      child: Card(
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
              AppColors.primaryGradientStart.withValues(alpha: 0.1),
              AppColors.primaryGradientEnd.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
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
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppButtonStyles.primaryGradientButton(
                      text: localizations.dashboard_notification_card_enable,
                      onPressed: _enableNotifications,
                      borderRadius: 10.r,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _dismissCard,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(
                          color: AppColors.primaryGradientEnd.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        localizations.dashboard_notification_card_later,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryGradientEnd,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _MyResultsExpandableCard extends ConsumerStatefulWidget {
  final int? totalRaces;
  final RaceResultsState resultsState;
  final int? profileId;

  const _MyResultsExpandableCard({
    required this.totalRaces,
    required this.resultsState,
    required this.profileId,
  });

  @override
  ConsumerState<_MyResultsExpandableCard> createState() =>
      _MyResultsExpandableCardState();
}

class _MyResultsExpandableCardState
    extends ConsumerState<_MyResultsExpandableCard> {
  bool _isExpanded = false;
  bool _hasLoaded = false;
  int? _lastProfileId;

  @override
  void initState() {
    super.initState();
    _lastProfileId = widget.profileId;
    // Загружаем данные при первом отображении виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoaded) {
        _loadResultsIfNeeded();
      }
    });
  }

  @override
  void didUpdateWidget(_MyResultsExpandableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если сменился profileId, сбрасываем флаг загрузки
    if (oldWidget.profileId != widget.profileId) {
      _hasLoaded = false;
      _lastProfileId = widget.profileId;
      // Загружаем данные для нового пользователя
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadResultsIfNeeded();
        }
      });
    }
  }

  void _loadResultsIfNeeded() {
    final profileId = widget.profileId;
    final resultsState = ref.read(raceResultsProvider);

    // Загружаем данные, если они еще не загружены или если сменился пользователь
    if (profileId != null &&
        profileId == _lastProfileId &&
        resultsState.results.isEmpty &&
        !resultsState.isLoading &&
        !_hasLoaded) {
      _hasLoaded = true;
      ref.read(raceResultsProvider.notifier).loadResults(profileId);
    }
  }

  Future<void> _refreshResults() async {
    final profileId = widget.profileId;
    if (profileId != null) {
      try {
        await ref.read(raceResultsProvider.notifier).refreshResults(profileId);
      } catch (e) {
        // Ошибка уже обработана в провайдере
      }
    }
  }

  void _loadNextPage() {
    final profileId = widget.profileId;
    if (profileId != null) {
      ref.read(raceResultsProvider.notifier).loadNextPage(profileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Используем resultsState переданный от родителя — не делаем ref.watch здесь,
    // так как родительский виджет уже подписан на raceResultsProvider.
    // Дублирование ref.watch вызывает лишние markNeedsBuild() → iOS assertion.
    final resultsState = widget.resultsState;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header - всегда видимый
          InkWell(
            onTap: () {
              final wasExpanded = _isExpanded;
              setState(() {
                _isExpanded = !_isExpanded;
              });
              // Загружаем данные при разворачивании, если они еще не загружены
              if (!wasExpanded && _isExpanded) {
                _loadResultsIfNeeded();
              }
            },
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  // Icon - PNG картинка флага
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark ? 'assets/images/flag_light.png' : 'assets/images/flag_dark.png',
                    width: 32.w,
                    height: 32.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 16.w),
                  // Count and title - по горизонтали, выровнено по нижней линии
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (widget.totalRaces != null)
                          Text(
                            widget.totalRaces!.toString(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          )
                        else
                          SizedBox(
                            width: 22.w,
                            height: 22.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.home_finishes,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 18.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand/Collapse icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurface,
                      size: 24.r,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content - список результатов
          if (_isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  const Divider(height: 1),
                  if (resultsState.isLoading && resultsState.results.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(24.r),
                      child: const CircularProgressIndicator(),
                    )
                  else if (resultsState.hasError &&
                      resultsState.results.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        children: [
                          Text(
                            resultsState.error ??
                                AppLocalizations.of(
                                  context,
                                )!.common_loading_error,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          AppButtonStyles.gradientElevatedButton(
                            text: AppLocalizations.of(context)!.common_retry,
                            onPressed: () {
                              final profileId = widget.profileId;
                              if (profileId != null) {
                                ref
                                    .read(raceResultsProvider.notifier)
                                    .loadResults(profileId);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  else if (resultsState.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Text(
                        AppLocalizations.of(context)!.results_no_results,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  else
                    NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        // Загружаем следующую страницу, когда пользователь прокрутил до 80% списка
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent * 0.8) {
                          if (resultsState.hasMorePages &&
                              !resultsState.isLoadingMore &&
                              !resultsState.isLoading) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _loadNextPage();
                              }
                            });
                          }
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        color: Theme.of(context).colorScheme.onSurface,
                        onRefresh: _refreshResults,
                        child: Builder(
                          builder: (context) {
                            // Фильтруем только подтвержденные результаты
                            final approvedResults = resultsState.results
                                .where((r) => r.isApproved)
                                .toList();

                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 0.6.sh,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  16.w,
                                  16.h,
                                  16.w,
                                  48.h,
                                ),
                                itemCount:
                                    approvedResults.length +
                                    (resultsState.isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // Показываем индикатор загрузки в конце списка
                                  if (index == approvedResults.length) {
                                    return Padding(
                                      padding: EdgeInsets.all(16.r),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 16.h,
                                    ),
                                    child: ResultCard(
                                      result: approvedResults[index],
                                      isMyResults: true,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Блок в стиле баннера: сплошной фон, текст, кнопка. Ширина как у других карточек (Card).
class _PaceCalculatorCard extends StatelessWidget {
  const _PaceCalculatorCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/pace-calculator');
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.home_pace_calculator_title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17.sp,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      loc.home_pace_calculator_subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              // Кнопка справа — градиентный стиль
              AppButtonStyles.primaryGradientButton(
                text: loc.home_pace_calculator_button,
                onPressed: () {
                  Navigator.of(context).pushNamed('/pace-calculator');
                },
                borderRadius: 10.r,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _UpcomingRacesSection extends ConsumerStatefulWidget {
  const _UpcomingRacesSection();

  @override
  ConsumerState<_UpcomingRacesSection> createState() =>
      _UpcomingRacesSectionState();
}

class _UpcomingRacesSectionState extends ConsumerState<_UpcomingRacesSection> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  double _pageWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_pageWidth > 0) {
        final page = (_scrollController.offset / _pageWidth).round();
        if (page != _currentPage) {
          setState(() => _currentPage = page);
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllRaces();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadAllRaces() {
    // Используем отдельный провайдер для Dashboard - только первая страница (15 записей)
    ref
        .read(dashboardUpcomingRacesProvider.notifier)
        .loadUpcomingRacesFirstPage(
          onlyFuture: true, // Только будущие гонки всех атлетов
        );
  }

  void _navigateToUpcomingRacesScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UpcomingRacesScreen()));
  }

  // void _addUpcomingRace(BuildContext context) {
  //   showRaceSelectionBottomSheet(context);
  // }

  List<dynamic> _getActiveRaces(List<dynamic> races) {
    final now = DateTime.now();
    return races.where((race) {
      try {
        final raceDate = DateTime.parse(race.raceDate);
        return raceDate.isAfter(now) || _isSameDay(raceDate, now);
      } catch (e) {
        return false;
      }
    }).toList();
  }


  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Группирует гонки по уникальному ключу (тип + локация + дата),
  /// возвращает список групп (каждая группа — одна уникальная гонка с атлетами).
  List<List<UpcomingRace>> _groupRaces(List<dynamic> races) {
    final Map<String, List<UpcomingRace>> grouped = {};
    for (final race in races) {
      final r = race as UpcomingRace;
      final key = '${r.raceType}|${r.location}|${r.raceDate}';
      grouped.putIfAbsent(key, () => []).add(r);
    }
    return grouped.values.toList();
  }

  Widget _buildActiveRacesTab(BuildContext context, UpcomingRacesState state, AppLocalizations localizations) {
    final theme = Theme.of(context);

    if (state.isLoading && state.races.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeRaces = _getActiveRaces(state.races);
    final groupedRaces = _groupRaces(activeRaces).take(5).toList();

    if (groupedRaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            localizations.home_no_upcoming_races,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            _pageWidth = constraints.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              physics: const PageScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int index = 0; index < groupedRaces.length; index++)
                    SizedBox(
                      width: _pageWidth,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: GroupedUpcomingRaceCard(races: groupedRaces[index]),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (groupedRaces.length > 1) ...[
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              groupedRaces.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                width: _currentPage == index ? 16.w : 6.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final state = ref.watch(dashboardUpcomingRacesProvider);

    // Слушаем ошибки
    ref.listen<UpcomingRacesState>(dashboardUpcomingRacesProvider, (
      previous,
      next,
    ) {
      if (next.hasError &&
          next.error != null &&
          previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ErrorHandler.showError(context, next.error!);
        });
      }
    });

    // Временно закомментирован фон Card
    // return Card(
    //   elevation: 0,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(12),
    //     side: BorderSide.none,
    //   ),
    //   clipBehavior: Clip.antiAlias,
    //   child: Padding(
    //     padding: const EdgeInsets.all(16.0),
    //     child: Column(
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header с заголовком и кнопкой "All >"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  localizations.home_upcoming_races,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
                InkWell(
                  onTap: () => _navigateToUpcomingRacesScreen(context),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: theme.colorScheme.onSurface,
                      size: 20.r,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Upcoming races content (только активные)
            _buildActiveRacesTab(context, state, localizations),

            SizedBox(height: 16.h),
            // Кнопка добавления новой гонки (временно закомментирована)
            // Center(
            //   child: AppButtonStyles.gradientElevatedButton(
            //     text: localizations.home_add_race,
            //     onPressed: () => _addUpcomingRace(context),
            //     icon: Icon(Icons.add, size: 20.r, color: Colors.white),
            //     padding: EdgeInsets.symmetric(
            //       horizontal: 24.w,
            //       vertical: 12.h,
            //     ),
            //   ),
            // ),
          ],
        ),
      );
      // ); // Закрывающая скобка Card - закомментирована
  }
}

// ─── Мои предстоящие гонки ────────────────────────────────────────────────────

class _MyUpcomingRacesExpandableSection extends ConsumerStatefulWidget {
  final int profileId;
  const _MyUpcomingRacesExpandableSection({required this.profileId});

  @override
  ConsumerState<_MyUpcomingRacesExpandableSection> createState() =>
      _MyUpcomingRacesExpandableSectionState();
}

class _MyUpcomingRacesExpandableSectionState
    extends ConsumerState<_MyUpcomingRacesExpandableSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(myDashboardUpcomingRacesProvider.notifier)
            .loadUpcomingRacesFirstPage(
              userProfileId: widget.profileId,
              onlyFuture: true,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myDashboardUpcomingRacesProvider);
    if (!state.isLoading && state.races.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: _MyUpcomingRacesExpandableCard(profileId: widget.profileId),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }
}

class _MyUpcomingRacesExpandableCard extends ConsumerStatefulWidget {
  final int profileId;

  const _MyUpcomingRacesExpandableCard({required this.profileId});

  @override
  ConsumerState<_MyUpcomingRacesExpandableCard> createState() =>
      _MyUpcomingRacesExpandableCardState();
}

class _MyUpcomingRacesExpandableCardState
    extends ConsumerState<_MyUpcomingRacesExpandableCard> {
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  double _pageWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_pageWidth > 0) {
        final page = (_scrollController.offset / _pageWidth).round();
        if (page != _currentPage) {
          setState(() => _currentPage = page);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<List<UpcomingRace>> _groupRaces(List<dynamic> races) {
    final Map<String, List<UpcomingRace>> grouped = {};
    for (final race in races) {
      final r = race as UpcomingRace;
      final key = '${r.raceType}|${r.location}|${r.raceDate}';
      grouped.putIfAbsent(key, () => []).add(r);
    }
    return grouped.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final state = ref.watch(myDashboardUpcomingRacesProvider);
    final groupedRaces = _groupRaces(state.races);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    color: theme.colorScheme.primary,
                    size: 32.r,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      localizations.my_races_title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (state.isLoading && state.races.isEmpty)
                    SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (groupedRaces.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${groupedRaces.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(width: 8.w),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurface,
                      size: 24.r,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (_isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  const Divider(height: 1),
                  if (state.isLoading && state.races.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (groupedRaces.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Text(
                        localizations.my_races_no_races,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        SizedBox(height: 12.h),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            _pageWidth = constraints.maxWidth;
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _scrollController,
                              physics: const PageScrollPhysics(),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (int i = 0; i < groupedRaces.length; i++)
                                    SizedBox(
                                      width: _pageWidth,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                                        child: GroupedUpcomingRaceCard(
                                          races: groupedRaces[i],
                                          showAthletes: false,
                                          showBorder: true,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (groupedRaces.length > 1) ...[
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              groupedRaces.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.symmetric(horizontal: 3.w),
                                width: _currentPage == index ? 16.w : 6.w,
                                height: 6.h,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 16.h),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Personal Bests ───────────────────────────────────────────────────────────

class _PersonalBestsExpandableCard extends ConsumerStatefulWidget {
  final int? profileId;
  final List<RaceResult> results;

  const _PersonalBestsExpandableCard({
    required this.profileId,
    required this.results,
  });

  @override
  ConsumerState<_PersonalBestsExpandableCard> createState() =>
      _PersonalBestsExpandableCardState();
}

class _PersonalBestsExpandableCardState
    extends ConsumerState<_PersonalBestsExpandableCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.profileId != null) {
        ref.read(recordsProvider(widget.profileId!).notifier).loadRecords();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profileId == null) return const SizedBox.shrink();
    final profileId = widget.profileId!;

    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final recordsState = ref.watch(recordsProvider(profileId));
    final personalBests = recordsState.records?.toPersonalBestsFormat();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header - всегда видимый
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  // Icon - иконка награды
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAward01,
                    color: const Color(0xFF4CAF50),
                    size: 32.r,
                  ),
                  SizedBox(width: 16.w),
                  // Title
                  Expanded(
                    child: Text(
                      localizations.home_personal_bests,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Expand/Collapse icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurface,
                      size: 24.r,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content - карточки лучших результатов
          if (_isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  const Divider(height: 1),
                  if (recordsState.isLoading && personalBests == null)
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (personalBests != null &&
                      (_safeGetPersonalBestsData(personalBests['ironman']) != null ||
                          _safeGetPersonalBestsData(personalBests['ironman_70_3']) != null ||
                          _safeGetPersonalBestsData(personalBests['5150']) != null))
                    Padding(
                      padding: EdgeInsets.fromLTRB(6.w, 6.h, 6.w, 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ironman
                          if (_safeGetPersonalBestsData(personalBests['ironman']) != null) ...[
                            _PersonalBestsCard(
                              title: 'Ironman',
                              data: _safeGetPersonalBestsData(personalBests['ironman'])!,
                              profileId: profileId,
                              results: widget.results,
                            ),
                            if (_safeGetPersonalBestsData(personalBests['ironman_70_3']) != null ||
                                _safeGetPersonalBestsData(personalBests['5150']) != null)
                              SizedBox(height: 12.h),
                          ],
                          // Ironman 70.3
                          if (_safeGetPersonalBestsData(personalBests['ironman_70_3']) != null) ...[
                            _PersonalBestsCard(
                              title: 'Ironman 70.3',
                              data: _safeGetPersonalBestsData(personalBests['ironman_70_3'])!,
                              profileId: profileId,
                              results: widget.results,
                            ),
                            if (_safeGetPersonalBestsData(personalBests['5150']) != null)
                              SizedBox(height: 12.h),
                          ],
                          // 5150
                          if (_safeGetPersonalBestsData(personalBests['5150']) != null)
                            _PersonalBestsCard(
                              title: '5150',
                              data: _safeGetPersonalBestsData(personalBests['5150'])!,
                              profileId: profileId,
                              results: widget.results,
                            ),
                        ],
                      ),
                    )
                  else if (!recordsState.isLoading)
                    Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Text(
                        localizations.home_no_personal_bests,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonalBestsCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final int profileId;
  final List<RaceResult> results;

  const _PersonalBestsCard({
    required this.title,
    required this.data,
    required this.profileId,
    required this.results,
  });

  String _getRaceTypeText(String title) {
    switch (title.toLowerCase()) {
      case 'ironman':
        return 'IRONMAN';
      case 'ironman 70.3':
        return 'IRONMAN 70.3';
      case '5150':
        return '5150';
      default:
        return 'IRONMAN';
    }
  }

  Map<String, dynamic>? _getDisciplineData(String discipline) {
    final value = data[discipline];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? _getTime(String discipline) {
    return _getDisciplineData(discipline)?['time'] as String?;
  }

  Map<String, dynamic>? _getRace(String discipline) {
    final race = _getDisciplineData(discipline)?['race'];
    if (race is Map<String, dynamic>) return race;
    if (race is Map) return Map<String, dynamic>.from(race);
    return null;
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final swimTime = _getTime('swim');
    final bikeTime = _getTime('bike');
    final runTime = _getTime('run');
    final swimRace = _getRace('swim');
    final bikeRace = _getRace('bike');
    final runRace = _getRace('run');

    return Padding(
      padding: EdgeInsets.all(6.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered race type text
          Center(
            child: Container(
              padding: EdgeInsets.only(bottom: 4.h),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.ironmanRed, width: 2),
                ),
              ),
              child: Text(
                _getRaceTypeText(title),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 17.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Swim
          if (swimTime != null)
            _DisciplineRow(
              imagePath: Theme.of(context).brightness == Brightness.dark ? 'assets/images/swim_light.png' : 'assets/images/swim_dark.png',
              time: swimTime,
              date: swimRace?['race_date'] as String?,
              location: swimRace?['location'] as String?,
              formatDate: _formatDate,
              raceType: title,
              profileId: profileId,
              results: results,
            ),
          if (swimTime != null && (bikeTime != null || runTime != null))
            SizedBox(height: 8.h),
          // Bike
          if (bikeTime != null)
            _DisciplineRow(
              imagePath: Theme.of(context).brightness == Brightness.dark ? 'assets/images/bike_light.png' : 'assets/images/bike_dark.png',
              time: bikeTime,
              date: bikeRace?['race_date'] as String?,
              location: bikeRace?['location'] as String?,
              formatDate: _formatDate,
              raceType: title,
              profileId: profileId,
              results: results,
            ),
          if (bikeTime != null && runTime != null) SizedBox(height: 8.h),
          // Run
          if (runTime != null)
            _DisciplineRow(
              imagePath: Theme.of(context).brightness == Brightness.dark ? 'assets/images/run_light.png' : 'assets/images/run_dark.png',
              time: runTime,
              date: runRace?['race_date'] as String?,
              location: runRace?['location'] as String?,
              formatDate: _formatDate,
              raceType: title,
              profileId: profileId,
              results: results,
            ),
          if (swimTime == null && bikeTime == null && runTime == null)
            Text(
              AppLocalizations.of(context)!.common_no_data,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _DisciplineRow extends StatelessWidget {
  final String imagePath;
  final String time;
  final String? date;
  final String? location;
  final String Function(String?) formatDate;
  final String raceType;
  final int profileId;
  final List<RaceResult> results;

  const _DisciplineRow({
    required this.imagePath,
    required this.time,
    this.date,
    this.location,
    required this.formatDate,
    required this.raceType,
    required this.profileId,
    required this.results,
  });

  String _getDisciplineFromImagePath() {
    if (imagePath.contains('swim')) return 'swim';
    if (imagePath.contains('bike')) return 'bike';
    if (imagePath.contains('run')) return 'run';
    return 'swim'; // fallback
  }

  String _calculatePace(BuildContext context) {
    final discipline = _getDisciplineFromImagePath();
    final distances = _getDistances(raceType);
    final distance = distances[discipline] ?? 0.0;

    switch (discipline) {
      case 'swim':
        return _calculateSwimPace(time, distance);
      case 'bike':
        return _calculateBikePace(time, distance);
      case 'run':
        return _calculateRunPace(time, distance);
      default:
        return '';
    }
  }

  String _getPaceUnit(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final discipline = _getDisciplineFromImagePath();

    switch (discipline) {
      case 'swim':
        return localizations.pace_calculator_min_per_100m;
      case 'bike':
        return localizations.pace_calculator_km_per_h;
      case 'run':
        return localizations.pace_calculator_min_per_km;
      default:
        return '';
    }
  }

  RaceResult? _findResult() {
    if (results.isEmpty || date == null || location == null) return null;

    // Ищем результат по дате и локации, только среди подтвержденных
    for (final result in results) {
      if (result.isApproved &&
          result.date == date &&
          result.location == location) {
        return result;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final result = _findResult();

    return InkWell(
      onTap: result != null
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResultDetailScreen(result: result),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(12.r),
      splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      highlightColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.15),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        margin: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : AppColors.resultsBorder,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Основное содержимое
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Верхняя строка: иконка слева, время справа
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon
                      Image.asset(
                        imagePath,
                        width: 40.w,
                        height: 40.h,
                        fit: BoxFit.contain,
                      ),
                      // Time and pace
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            time,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Builder(
                            builder: (BuildContext context) {
                              final pace = _calculatePace(context);
                              final paceUnit = _getPaceUnit(context);
                              if (pace.isNotEmpty && paceUnit.isNotEmpty) {
                                return Padding(
                                  padding: EdgeInsets.only(top: 2.h),
                                  child: Text(
                                    '$pace $paceUnit',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Нижняя строка: локация слева, дата справа
                  if (date != null || location != null) ...[
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Location
                        if (location != null)
                          Expanded(
                            child: Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedLocation01,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  size: 13.r,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    location!.isEmpty ? '' : location![0].toUpperCase() + location!.substring(1),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 13.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        // Date
                        if (date != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 13.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                formatDate(date),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Шеврон справа, по центру по вертикали
            if (result != null) ...[
              SizedBox(width: 12.w),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20.r,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _NotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationsProvider.select((s) => s.unreadCount));

    return IconButton(
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedNotification02,
            color: Theme.of(context).colorScheme.onSurface,
            size: 28.r,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 12.r,
                height: 12.r,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
