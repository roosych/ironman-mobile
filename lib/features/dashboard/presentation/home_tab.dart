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
import 'package:ironman_mobile/features/dashboard/presentation/profile_screen.dart'
    as profile;
import 'package:ironman_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_notifier.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_state.dart';
import 'package:ironman_mobile/features/upcoming_races/presentation/upcoming_races_screen.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/widgets/upcoming_race_card.dart';
import 'package:ironman_mobile/shared/widgets/add_upcoming_race_bottom_sheet.dart';
import 'package:ironman_mobile/core/theme/app_button_styles.dart';
import '../../notifications/application/notifications_notifier.dart';

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
  // Убрана автоматическая загрузка результатов - данные берутся из profile.stats
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _loadResults();
  //   });
  // }

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

  // Извлечение данных из profile.stats
  Map<String, dynamic>? _getProfileStats() {
    final user = ref.watch(authProvider).user;
    debugPrint('=== HomeTab: _getProfileStats ===');
    debugPrint('User: ${user?.id}');
    debugPrint('User profile: ${user?.profile}');
    if (user?.profile is Map<String, dynamic>) {
      final profile = user!.profile as Map<String, dynamic>;
      final stats = profile['stats'] as Map<String, dynamic>?;
      debugPrint('Profile stats: $stats');
      if (stats != null) {
        debugPrint('Stats keys: ${stats.keys}');
        final summary = stats['summary'];
        debugPrint('Summary: $summary');
        if (summary is Map<String, dynamic>) {
          debugPrint('Summary total_races: ${summary['total_races']}');
        }
      }
      return stats;
    }
    debugPrint('Profile is not Map or null');
    return null;
  }

  int? _getTotalRaces() {
    // Берем количество гонок из profile.stats.summary.total_races, которые приходят при авторизации
    final stats = _getProfileStats();
    if (stats != null) {
      // Получаем summary из stats
      final summary = stats['summary'];
      if (summary is Map<String, dynamic>) {
        // Пытаемся получить total_races из summary
        final totalRaces = summary['total_races'];
        debugPrint('=== HomeTab: _getTotalRaces ===');
        debugPrint('Stats: $stats');
        debugPrint('Summary: $summary');
        debugPrint('total_races from summary: $totalRaces');
        if (totalRaces is int) {
          debugPrint('Returning total_races: $totalRaces');
          return totalRaces;
        }
        if (totalRaces is num) {
          final result = totalRaces.toInt();
          debugPrint('Returning total_races (converted): $result');
          return result;
        }
      } else {
        debugPrint('Summary is not Map: ${summary.runtimeType}');
      }
    } else {
      debugPrint('Stats is null');
    }
    // Если данных нет в stats, возвращаем null (покажем спиннер)
    debugPrint('Returning null for total_races');
    return null;
  }

  Map<String, dynamic>? _getPersonalBests() {
    final stats = _getProfileStats();
    final personalBests = stats?['personal_bests'];

    // personal_bests может быть Map или List, обрабатываем оба случая
    if (personalBests is Map<String, dynamic>) {
      return personalBests;
    }

    // Если это List или другой тип, возвращаем null
    return null;
  }

  int? _getProfileId() {
    final user = ref.watch(authProvider).user;
    if (user?.profile is Map<String, dynamic>) {
      final profile = user!.profile as Map<String, dynamic>;
      return profile['id'] as int?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final totalRaces = _getTotalRaces();
    final personalBests = _getPersonalBests();
    final resultsState = ref.watch(raceResultsProvider);
    final profileId = _getProfileId();

    // Данные о количестве гонок берутся из profile.stats, которые приходят при авторизации
    // resultsState используется только для отображения списка результатов в карточке

    return Scaffold(
      body: Stack(
        children: [
          // Background image with gradient overlay
          Transform.rotate(
            angle: 3.14159, // 180 градусов (π радиан)
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5, // До середины экрана
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.matrix([
                    0.299, 0.587, 0.114, 0, 0, // Red channel -> grayscale
                    0.299, 0.587, 0.114, 0, 0, // Green channel -> grayscale
                    0.299, 0.587, 0.114, 0, 0, // Blue channel -> grayscale
                    0, 0, 0, 1, 0,             // Alpha channel unchanged
                  ]),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
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
                      child: CircleAvatar(
                        radius: 32, // Увеличенный размер
                        backgroundColor: (user?.avatarUrl != null && user?.avatarUrl?.isNotEmpty == true)
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        backgroundImage: (user?.avatarUrl != null && user?.avatarUrl?.isNotEmpty == true)
                            ? NetworkImage(user!.avatarUrl!)
                            : null,
                        child: (user?.avatarUrl == null || user?.avatarUrl?.isEmpty == true)
                            ? HugeIcon(
                                icon: HugeIcons.strokeRoundedUser,
                                size: 32,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              )
                            : null,
                      ),
                    ),
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
              ),

              // Greeting section
              if (user != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    '${AppLocalizations.of(context)!.home_greeting} ${user.name.toUpperCase()}!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

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
              if (personalBests != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _PersonalBestsExpandableCard(
                    personalBests: personalBests,
                    profileId: profileId ?? 0,
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
        ],
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
                                  32.0,
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

class _PersonalBestsExpandableCard extends StatefulWidget {
  final Map<String, dynamic> personalBests;
  final int profileId;
  final List<RaceResult> results;

  const _PersonalBestsExpandableCard({
    required this.personalBests,
    required this.profileId,
    required this.results,
  });

  @override
  State<_PersonalBestsExpandableCard> createState() =>
      _PersonalBestsExpandableCardState();
}

class _PersonalBestsExpandableCardState
    extends State<_PersonalBestsExpandableCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Card(
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ironman
                        if (widget.personalBests['ironman'] != null) ...[
                          _PersonalBestsCard(
                            title: 'Ironman',
                            data:
                                widget.personalBests['ironman']
                                    as Map<String, dynamic>,
                            profileId: widget.profileId,
                            results: widget.results,
                          ),
                          if (widget.personalBests['ironman_70_3'] != null ||
                              widget.personalBests['5150'] != null)
                            const SizedBox(height: 12),
                        ],
                        // Ironman 70.3
                        if (widget.personalBests['ironman_70_3'] != null) ...[
                          _PersonalBestsCard(
                            title: 'Ironman 70.3',
                            data:
                                widget.personalBests['ironman_70_3']
                                    as Map<String, dynamic>,
                            profileId: widget.profileId,
                            results: widget.results,
                          ),
                          if (widget.personalBests['5150'] != null)
                            const SizedBox(height: 12),
                        ],
                        // 5150
                        if (widget.personalBests['5150'] != null)
                          _PersonalBestsCard(
                            title: '5150',
                            data:
                                widget.personalBests['5150']
                                    as Map<String, dynamic>,
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

  String? _getTime(String discipline) {
    final disciplineData = data[discipline] as Map<String, dynamic>?;
    return disciplineData?['time'] as String?;
  }

  Map<String, dynamic>? _getRace(String discipline) {
    final disciplineData = data[discipline] as Map<String, dynamic>?;
    return disciplineData?['race'] as Map<String, dynamic>?;
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
          border: Border.all(color: AppColors.ironmanGray, width: 1),
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
    // Используем отдельный провайдер для главного экрана
    ref
        .read(globalUpcomingRacesProvider.notifier)
        .loadUpcomingRaces(
          onlyFuture: false, // Загружаем все гонки (будущие и прошедшие)
        );
  }

  void _navigateToUpcomingRacesScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UpcomingRacesScreen()));
  }

  void _addUpcomingRace(BuildContext context) {
    showAddUpcomingRaceBottomSheet(context);
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
    final state = ref.watch(globalUpcomingRacesProvider);

    // Слушаем ошибки
    ref.listen<UpcomingRacesState>(globalUpcomingRacesProvider, (
      previous,
      next,
    ) {
      if (next.hasError &&
          next.error != null &&
          previous?.error != next.error) {
        ErrorHandler.showError(context, next.error!);
      }
    });

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
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

    // Ensure we have unread_count for the badge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).load();
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
