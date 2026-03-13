import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:ironman_mobile/shared/widgets/upcoming_race_card.dart';
import 'package:ironman_mobile/features/race_selection/presentation/widgets/race_selection_bottom_sheet.dart';
import 'package:ironman_mobile/core/theme/app_button_styles.dart';
import '../../notifications/application/notifications_notifier.dart';
import '../../../core/services/notification_permission_service.dart';
import '../application/records_notifier.dart';

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

  int? _getTotalRaces() {
    final user = ref.watch(authProvider).user;
    final profile = user?.profile;
    final stats = profile?.stats;
    final totalRaces = stats?.summary?.totalRaces;

    debugPrint('=== HomeTab: _getTotalRaces ULTRA DETAILED DEBUG ===');
    debugPrint('User: ${user != null ? "EXISTS" : "NULL"}');
    debugPrint('User ID: ${user?.id}');
    debugPrint('User name: ${user?.name}');
    debugPrint('User verified: ${user?.verified}');
    debugPrint('User email: ${user?.email}');
    debugPrint('User toJson: ${user?.toJson()}');
    debugPrint('Profile: ${profile != null ? "EXISTS" : "NULL"}');
    debugPrint('Profile ID: ${profile?.id}');
    debugPrint('Profile role: ${profile?.role}');
    debugPrint('Profile toJson: ${profile?.toJson()}');
    debugPrint('Stats: ${stats != null ? "EXISTS" : "NULL"}');
    debugPrint('Stats summary: ${stats?.summary != null ? "EXISTS" : "NULL"}');
    debugPrint('Stats summary totalRaces: $totalRaces');
    debugPrint('Stats summary totalDistances: ${stats?.summary?.totalDistances}');
    debugPrint('Stats bestTotalTime: ${stats?.bestTotalTime}');
    debugPrint('Stats toJson: ${stats?.toJson()}');
    debugPrint('Raw Stats object: $stats');

    // Fallback 1: получаем количество из результатов гонок (через resultsState)
    final resultsState = ref.watch(raceResultsProvider);
    final approvedResultsCount = resultsState.results.where((r) => r.isApproved).length;
    debugPrint('Fallback 1 - Approved results count from state: $approvedResultsCount');

    // Fallback 2: получаем количество из race_results в профиле
    final profileRaceResults = profile?.raceResults?.length ?? 0;
    debugPrint('Fallback 2 - Profile race results count: $profileRaceResults');

    // Fallback 3: используем ironman_races_count из профиля
    final ironmanRacesCount = profile?.ironmanRacesCount ?? 0;
    debugPrint('Fallback 3 - Profile ironman_races_count: $ironmanRacesCount');

    debugPrint('======================================');

    // Возвращаем статистику или лучший доступный fallback
    if (totalRaces != null) {
      return totalRaces;
    } else if (profileRaceResults > 0) {
      return profileRaceResults;
    } else if (ironmanRacesCount > 0) {
      return ironmanRacesCount;
    } else if (approvedResultsCount > 0) {
      return approvedResultsCount;
    }
    return null;
  }

  int? _getProfileId() {
    final user = ref.watch(authProvider).user;
    return user?.profile?.id;
  }

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
      final profileId = _getProfileId();
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
      await ref.read(dashboardUpcomingRacesProvider.notifier).refreshUpcomingRaces(
        onlyFuture: true,
      );
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
    final totalRaces = _getTotalRaces();
    final resultsState = ref.watch(raceResultsProvider);
    final profileId = _getProfileId();

    // Данные о количестве гонок берутся из profile.stats, которые приходят при авторизации
    // resultsState используется только для отображения списка результатов в карточке

    return Scaffold(
      backgroundColor: AppColors.ironmanBlack,
      body: Stack(
        children: [
          // Background image with gradient overlay
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
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
                    AppColors.ironmanBlack.withValues(alpha: 0.2),
                    AppColors.ironmanBlack.withValues(alpha: 0.6),
                    AppColors.ironmanBlack,
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                        radius: 32,
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
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 8), // Отступ между иконками
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
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.home_greeting_welcome,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        user.name.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),

              // Notification permission card (manages its own spacing)
              _NotificationPermissionCard(),

              // My Results expandable section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _MyResultsExpandableCard(
                  totalRaces: totalRaces,
                  resultsState: resultsState,
                  profileId: profileId,
                ),
              ),

              const SizedBox(height: 12),

              // Personal Bests Expandable Section
              if (profileId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _PersonalBestsExpandableCard(
                    profileId: profileId,
                    results: resultsState.results
                        .where((r) => r.isApproved)
                        .toList(),
                  ),
                ),

              const SizedBox(height: 12),

              // Pace Calculator card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _PaceCalculatorCard(),
              ),

              const SizedBox(height: 12),

              // Upcoming Races Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _UpcomingRacesSection(),
              ),

              const SizedBox(height: 12),
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
  const _NotificationPermissionCard();

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
    // Проверяем разрешения при возврате в приложение из настроек
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification02,
                    color: AppColors.primaryGradientEnd,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 8),
              Text(
                localizations.dashboard_notification_card_message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButtonStyles.primaryGradientButton(
                      text: localizations.dashboard_notification_card_enable,
                      onPressed: _enableNotifications,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _dismissCard,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: AppColors.primaryGradientEnd.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        localizations.dashboard_notification_card_later,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryGradientEnd,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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
    final resultsState = ref.watch(raceResultsProvider);

    // Загружаем данные при изменении profileId или если данные еще не загружены
    if (widget.profileId != null &&
        resultsState.results.isEmpty &&
        !resultsState.isLoading &&
        !_hasLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadResultsIfNeeded();
        }
      });
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon - PNG картинка флага
                  Image.asset(
                    'assets/images/svg/flag.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
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
                            ),
                          )
                        else
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.home_finishes,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 18,
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
                      size: 24,
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
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (resultsState.hasError &&
                      resultsState.results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
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
                      padding: const EdgeInsets.all(24.0),
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
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.6,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16.0,
                                  16.0,
                                  16.0,
                                  48.0,
                                ),
                                itemCount:
                                    approvedResults.length +
                                    (resultsState.isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // Показываем индикатор загрузки в конце списка
                                  if (index == approvedResults.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/pace-calculator');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.home_pace_calculator_subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Кнопка справа — градиентный стиль
              AppButtonStyles.primaryGradientButton(
                text: loc.home_pace_calculator_button,
                onPressed: () {
                  Navigator.of(context).pushNamed('/pace-calculator');
                },
                borderRadius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
  @override
  void initState() {
    super.initState();
    // Загружаем гонки после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllRaces();
      }
    });
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

  void _addUpcomingRace(BuildContext context) {
    showRaceSelectionBottomSheet(context);
  }

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

  Widget _buildActiveRacesTab(BuildContext context, UpcomingRacesState state, AppLocalizations localizations) {
    if (state.isLoading && state.races.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeRaces = _getActiveRaces(state.races);
    // Берем только первые 5 активных гонок для отображения на главном экране
    final limitedActiveRaces = activeRaces.take(5).toList();

    if (limitedActiveRaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            localizations.home_no_upcoming_races,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final cardWidth = screenWidth * 0.9;
        final cardSpacing = 12.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: cardSpacing / 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int index = 0; index < limitedActiveRaces.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                    right: index < limitedActiveRaces.length - 1 ? cardSpacing : 0,
                  ),
                  child: SizedBox(
                    width: cardWidth,
                    child: UpcomingRaceCard(race: limitedActiveRaces[index]),
                  ),
                ),
            ],
          ),
        );
      },
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
        ErrorHandler.showError(context, next.error!);
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
      padding: const EdgeInsets.all(16.0),
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
                    fontSize: 20,
                  ),
                ),
                InkWell(
                  onTap: () => _navigateToUpcomingRacesScreen(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Upcoming races content (только активные)
            _buildActiveRacesTab(context, state, localizations),

            const SizedBox(height: 16),
            // Кнопка добавления новой гонки
            Center(
              child: AppButtonStyles.gradientElevatedButton(
                text: localizations.home_add_race,
                onPressed: () => _addUpcomingRace(context),
                icon: const Icon(Icons.add, size: 20, color: Colors.white),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
      // ); // Закрывающая скобка Card - закомментирована
  }
}

class _PersonalBestsExpandableCard extends ConsumerStatefulWidget {
  final int profileId;
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
      if (mounted) {
        ref.read(recordsProvider(widget.profileId).notifier).loadRecords();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final recordsState = ref.watch(recordsProvider(widget.profileId));
    final personalBests = recordsState.records?.toPersonalBestsFormat();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon - иконка награды
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAward01,
                    color: const Color(0xFF4CAF50),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Text(
                      localizations.home_personal_bests,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
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
                      size: 24,
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
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (personalBests != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ironman
                          if (_safeGetPersonalBestsData(personalBests['ironman']) != null) ...[
                            _PersonalBestsCard(
                              title: 'Ironman',
                              data: _safeGetPersonalBestsData(personalBests['ironman'])!,
                              profileId: widget.profileId,
                              results: widget.results,
                            ),
                            if (_safeGetPersonalBestsData(personalBests['ironman_70_3']) != null ||
                                _safeGetPersonalBestsData(personalBests['5150']) != null)
                              const SizedBox(height: 12),
                          ],
                          // Ironman 70.3
                          if (_safeGetPersonalBestsData(personalBests['ironman_70_3']) != null) ...[
                            _PersonalBestsCard(
                              title: 'Ironman 70.3',
                              data: _safeGetPersonalBestsData(personalBests['ironman_70_3'])!,
                              profileId: widget.profileId,
                              results: widget.results,
                            ),
                            if (_safeGetPersonalBestsData(personalBests['5150']) != null)
                              const SizedBox(height: 12),
                          ],
                          // 5150
                          if (_safeGetPersonalBestsData(personalBests['5150']) != null)
                            _PersonalBestsCard(
                              title: '5150',
                              data: _safeGetPersonalBestsData(personalBests['5150'])!,
                              profileId: widget.profileId,
                              results: widget.results,
                            ),
                        ],
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
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered race type text
          Center(
            child: Container(
              padding: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.ironmanRed, width: 2),
                ),
              ),
              child: Text(
                _getRaceTypeText(title),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Swim
          if (swimTime != null)
            _DisciplineRow(
              imagePath: 'assets/images/svg/swim.png',
              time: swimTime,
              date: swimRace?['race_date'] as String?,
              location: swimRace?['location'] as String?,
              formatDate: _formatDate,
              raceType: title,
              profileId: profileId,
              results: results,
            ),
          if (swimTime != null && (bikeTime != null || runTime != null))
            const SizedBox(height: 8),
          // Bike
          if (bikeTime != null)
            _DisciplineRow(
              imagePath: 'assets/images/svg/bike.png',
              time: bikeTime,
              date: bikeRace?['race_date'] as String?,
              location: bikeRace?['location'] as String?,
              formatDate: _formatDate,
              raceType: title,
              profileId: profileId,
              results: results,
            ),
          if (bikeTime != null && runTime != null) const SizedBox(height: 8),
          // Run
          if (runTime != null)
            _DisciplineRow(
              imagePath: 'assets/images/svg/run.png',
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
      borderRadius: BorderRadius.circular(12),
      splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      highlightColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.resultsBorder, width: 1),
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
                        width: 40,
                        height: 40,
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
                                  color: Colors.white,
                                ),
                          ),
                          Builder(
                            builder: (BuildContext context) {
                              final pace = _calculatePace(context);
                              final paceUnit = _getPaceUnit(context);
                              if (pace.isNotEmpty && paceUnit.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    '~$pace $paceUnit',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 11,
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
                  // Нижняя строка: дата слева, локация справа
                  if (date != null || location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Date
                        if (date != null)
                          Text(
                            formatDate(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          const SizedBox.shrink(),
                        // Location
                        if (location != null)
                          Expanded(
                            child: Text(
                              location!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
              const SizedBox(width: 12),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20,
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
    final authState = ref.watch(authProvider);
    final unreadCount = ref.watch(notificationsProvider.select((s) => s.unreadCount));

    // Ensure we have unread_count for the badge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.isAuthenticated) {
        ref.read(notificationsProvider.notifier).load();
      }
    });

    return IconButton(
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedNotification02,
            color: Theme.of(context).colorScheme.onSurface,
            size: 28, // Увеличенный размер
          ),
          if (unreadCount > 0)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 12,
                height: 12,
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
