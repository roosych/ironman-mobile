import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/dashboard/domain/athlete.dart';
import 'package:ironman_mobile/features/dashboard/application/athlete_detail_notifier.dart';
import 'package:ironman_mobile/features/dashboard/application/athlete_detail_state.dart';
import 'package:ironman_mobile/features/dashboard/application/records_notifier.dart';
import 'package:ironman_mobile/features/dashboard/application/records_state.dart';
import 'package:ironman_mobile/features/results/application/race_results_notifier.dart';
import 'package:ironman_mobile/features/results/application/race_results_state.dart';
import 'package:ironman_mobile/shared/widgets/result_card.dart';
import 'package:ironman_mobile/shared/widgets/result_detail_screen.dart';
import 'package:ironman_mobile/features/results/domain/race_result.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/utils/alert_helper.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_notifier.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_state.dart';
import 'package:ironman_mobile/shared/widgets/upcoming_race_card.dart';

class AthleteProfileScreen extends ConsumerStatefulWidget {
  final Athlete athlete;

  const AthleteProfileScreen({super.key, required this.athlete});

  @override
  ConsumerState<AthleteProfileScreen> createState() =>
      _AthleteProfileScreenState();
}

class _AthleteProfileScreenState extends ConsumerState<AthleteProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);

    // Загружаем все данные при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Убрана автоматическая загрузка при didChangeDependencies, чтобы избежать бесконечных циклов
    // Данные загружаются только при initState
  }

  void _loadAllData() {
    if (mounted) {
      // Загружаем все данные параллельно
      _loadAthleteDetail();
      _loadResults();
      _loadRecords();
      _loadUpcomingRaces();
    }
  }

  void _loadAthleteDetail() {
    if (mounted) {
      ref
          .read(athleteDetailProvider(widget.athlete.id).notifier)
          .loadAthleteDetail();
    }
  }

  void _loadResults() {
    if (mounted) {
      ref
          .read(athleteRaceResultsProvider(widget.athlete.id).notifier)
          .loadResults(widget.athlete.id);
    }
  }

  void _loadRecords() {
    if (mounted) {
      ref.read(recordsProvider(widget.athlete.id).notifier).loadRecords();
    }
  }

  void _loadUpcomingRaces() {
    if (!mounted) return;
    
    // Используем отдельный провайдер для гонок атлета
    ref.read(athleteUpcomingRacesProvider(widget.athlete.id).notifier).loadUpcomingRaces(
      userProfileId: widget.athlete.id,
      onlyFuture: true, // Только будущие гонки
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Проверяем состояние загрузки всех данных
    final athleteDetailState = ref.watch(athleteDetailProvider(widget.athlete.id));
    final resultsState =
        ref.watch(athleteRaceResultsProvider(widget.athlete.id));
    final recordsState = ref.watch(recordsProvider(widget.athlete.id));
    final upcomingRacesState = ref.watch(athleteUpcomingRacesProvider(widget.athlete.id));

    // Показываем общий лоадер, если загружаются основные данные и они еще не загружены
    final isLoadingInitialData = 
        (athleteDetailState.isLoading && athleteDetailState.athlete == null) ||
        (resultsState.isLoading && resultsState.results.isEmpty) ||
        (recordsState.isLoading && recordsState.records == null) ||
        (upcomingRacesState.isLoading && upcomingRacesState.races.isEmpty);

    if (isLoadingInitialData) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.ironmanWhite,
              size: 24,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            localizations.athlete_profile_title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.ironmanWhite,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.athlete_profile_title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Профиль атлета
            SliverToBoxAdapter(child: _buildProfileHeader(context, theme)),
            // Закрепленные табы
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.ironmanGray, width: 1),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.ironmanWhite,
                    unselectedLabelColor: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.ironmanRed,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(
                        icon: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (!mounted) {
                              return const SizedBox.shrink();
                            }
                            final currentTheme = Theme.of(context);
                            final isSelected = _tabController.index == 0;
                            return HugeIcon(
                              icon: HugeIcons.strokeRoundedUser,
                              size: 24,
                              color: isSelected
                                  ? AppColors.ironmanWhite
                                  : currentTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            );
                          },
                        ),
                      ),
                      Tab(
                        icon: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (!mounted) {
                              return const SizedBox.shrink();
                            }
                            final currentTheme = Theme.of(context);
                            final isSelected = _tabController.index == 1;
                            return HugeIcon(
                              icon: HugeIcons.strokeRoundedTimer01,
                              size: 24,
                              color: isSelected
                                  ? AppColors.ironmanWhite
                                  : currentTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            );
                          },
                        ),
                      ),
                      Tab(
                        icon: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (!mounted) {
                              return const SizedBox.shrink();
                            }
                            final currentTheme = Theme.of(context);
                            final isSelected = _tabController.index == 2;
                            return HugeIcon(
                              icon: HugeIcons.strokeRoundedAward01,
                              size: 24,
                              color: isSelected
                                  ? AppColors.ironmanWhite
                                  : currentTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            );
                          },
                        ),
                      ),
                      Tab(
                        icon: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (!mounted) {
                              return const SizedBox.shrink();
                            }
                            final currentTheme = Theme.of(context);
                            final isSelected = _tabController.index == 3;
                            return HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar01,
                              size: 24,
                              color: isSelected
                                  ? AppColors.ironmanWhite
                                  : currentTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(context, theme, localizations),
            _buildResultsTab(context, theme, localizations),
            _buildPersonalBestsTab(context, theme, localizations),
            _buildUpcomingRacesTab(context, theme, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme) {
    final athleteDetailState = ref.watch(
      athleteDetailProvider(widget.athlete.id),
    );
    final athlete = athleteDetailState.athlete ?? widget.athlete;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Аватар с бейджем
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: athlete.avatar != null
                      ? Image.network(
                          athlete.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar(theme, 120);
                          },
                        )
                      : _buildDefaultAvatar(theme, 120),
                ),
              ),
              // Бейдж с номером Ironman
              if (athlete.ironmanNumber != null && athlete.ironmanNumber != 0)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.ironmanRed,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${athlete.ironmanNumber}',
                        style: const TextStyle(
                          color: AppColors.ironmanWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Имя
          Text(
            athlete.name.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Рейтинг
          if (athlete.ranking != null)
            Column(
              children: [
                if (athlete.ranking!.ironman != null)
                  Text(
                    'FULL: ${athlete.ranking!.ironman!.position}/${athlete.ranking!.ironman!.total}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (athlete.ranking!.ironman != null &&
                    athlete.ranking!.ironman703 != null)
                  const SizedBox(height: 4),
                if (athlete.ranking!.ironman703 != null)
                  Text(
                    'HALF: ${athlete.ranking!.ironman703!.position}/${athlete.ranking!.ironman703!.total}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            )
          else
            Text(
              'PRO Athlete • Age Group 30-34',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final athleteDetailState = ref.watch(
      athleteDetailProvider(widget.athlete.id),
    );

    // Слушаем ошибки
    ref.listen<AthleteDetailState>(athleteDetailProvider(widget.athlete.id), (
      previous,
      next,
    ) {
      if (next.hasError && previous?.error != next.error && mounted) {
        AlertHelper.showError(
          context,
          next.error ?? 'Ошибка загрузки',
          buttonText: localizations.error_ok,
        );
      }
    });

    if (athleteDetailState.isLoading && athleteDetailState.athlete == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final athlete = athleteDetailState.athlete ?? widget.athlete;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(athleteDetailProvider(widget.athlete.id).notifier)
            .loadAthleteDetail();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 100.0, // Отступ снизу для кнопок устройства
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.athlete_profile_info_tab,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Bio
            _buildBioCard(
              context,
              theme,
              localizations,
              athlete.bio ?? localizations.athlete_profile_info_not_available,
            ),
            const SizedBox(height: 16),
            // Social Links
            _buildSocialLinksCard(
              context,
              theme,
              localizations,
              athlete.socialLinks ??
                  const SocialLinks(
                    strava: null,
                    facebook: null,
                    instagram: null,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
    String bio,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedEdit01,
                color: AppColors.ironmanRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.athlete_profile_bio,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(bio, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildSocialLinksCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
    SocialLinks socialLinks,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedShare01,
                color: AppColors.ironmanRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.athlete_profile_social_links,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (socialLinks.strava != null ||
              socialLinks.facebook != null ||
              socialLinks.instagram != null) ...[
            if (socialLinks.strava != null) ...[
              Row(
                children: [
                  Text(
                    'Strava: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      socialLinks.strava!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.ironmanRed,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (socialLinks.facebook != null) ...[
              if (socialLinks.strava != null) const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Facebook: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      socialLinks.facebook!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.ironmanRed,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (socialLinks.instagram != null) ...[
              if (socialLinks.strava != null || socialLinks.facebook != null)
                const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Instagram: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      socialLinks.instagram!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.ironmanRed,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                localizations.athlete_profile_social_links_not_specified,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final resultsState = ref.watch(athleteRaceResultsProvider(widget.athlete.id));

    // Слушаем ошибки
    ref.listen<RaceResultsState>(athleteRaceResultsProvider(widget.athlete.id), (previous, next) {
      if (next.hasError && previous?.error != next.error && mounted) {
        ErrorHandler.showError(context, next.error ?? 'Ошибка загрузки');
      }
    });

    // Анимация появления контента
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey('${widget.athlete.id}_${resultsState.results.length}'),
        child: _buildResultsContent(
          context,
          theme,
          localizations,
          resultsState,
        ),
      ),
    );
  }

  Widget _buildResultsContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
    RaceResultsState resultsState,
  ) {
    // Фильтруем только подтвержденные результаты
    final approvedResults = resultsState.results.where((r) => r.isApproved).toList();
    
    if (resultsState.isLoading && resultsState.results.isEmpty) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (resultsState.hasError && resultsState.results.isEmpty) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                resultsState.error ?? 'Ошибка загрузки',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(athleteRaceResultsProvider(widget.athlete.id).notifier)
                      .loadResults(widget.athlete.id);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (approvedResults.isEmpty && !resultsState.isLoading) {
      return Center(
        key: const ValueKey('empty'),
        child: Text(
          localizations.results_no_results,
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      key: ValueKey('results_${approvedResults.length}'),
      onRefresh: () async {
        await ref
            .read(athleteRaceResultsProvider(widget.athlete.id).notifier)
            .loadResults(widget.athlete.id);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                localizations.athlete_profile_results_tab,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 100.0,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ResultCard(
                      result: approvedResults[index],
                      isMyResults: true,
                    ),
                  );
                },
                childCount: approvedResults.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestsTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final recordsState = ref.watch(recordsProvider(widget.athlete.id));
    final resultsState = ref.watch(athleteRaceResultsProvider(widget.athlete.id));

    // Слушаем ошибки
    ref.listen<RecordsState>(recordsProvider(widget.athlete.id), (
      previous,
      next,
    ) {
      if (next.hasError && previous?.error != next.error && mounted) {
        AlertHelper.showError(
          context,
          next.error ?? 'Ошибка загрузки',
          buttonText: localizations.error_ok,
        );
      }
    });

    // Данные уже загружены при открытии экрана, не загружаем повторно

    if (recordsState.hasError && recordsState.records == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                recordsState.error ?? 'Ошибка загрузки',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(recordsProvider(widget.athlete.id).notifier)
                      .loadRecords();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final records = recordsState.records;
    final personalBestsData = records?.toPersonalBestsFormat();

    // Функция для проверки наличия данных в карточке типа гонки
    bool hasRaceTypeData(Map<String, dynamic>? raceTypeData) {
      if (raceTypeData == null) return false;
      final swim = raceTypeData['swim'] as Map<String, dynamic>?;
      final bike = raceTypeData['bike'] as Map<String, dynamic>?;
      final run = raceTypeData['run'] as Map<String, dynamic>?;
      return swim != null || bike != null || run != null;
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(recordsProvider(widget.athlete.id).notifier)
            .loadRecords();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 100.0,
        ),
        child: personalBestsData != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    localizations.home_personal_bests,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Ironman
                  if (hasRaceTypeData(
                    personalBestsData['ironman'] as Map<String, dynamic>?,
                  ))
                    _PersonalBestsCard(
                      title: 'Ironman',
                      data:
                          personalBestsData['ironman'] as Map<String, dynamic>,
                      athleteId: widget.athlete.id,
                      results: resultsState.results,
                    ),
                  if (hasRaceTypeData(
                    personalBestsData['ironman'] as Map<String, dynamic>?,
                  ))
                    const SizedBox(height: 12),
                  // Ironman 70.3
                  if (hasRaceTypeData(
                    personalBestsData['ironman_70_3'] as Map<String, dynamic>?,
                  ))
                    _PersonalBestsCard(
                      title: 'Ironman 70.3',
                      data:
                          personalBestsData['ironman_70_3']
                              as Map<String, dynamic>,
                      athleteId: widget.athlete.id,
                      results: resultsState.results,
                    ),
                  if (hasRaceTypeData(
                    personalBestsData['ironman_70_3'] as Map<String, dynamic>?,
                  ))
                    const SizedBox(height: 12),
                  // 5150
                  if (hasRaceTypeData(
                    personalBestsData['5150'] as Map<String, dynamic>?,
                  ))
                    _PersonalBestsCard(
                      title: '5150',
                      data: personalBestsData['5150'] as Map<String, dynamic>,
                      athleteId: widget.athlete.id,
                      results: resultsState.results,
                    ),
                ],
              )
            : Center(
                child: Text('Нет данных', style: theme.textTheme.bodyLarge),
              ),
      ),
    );
  }

  Widget _buildUpcomingRacesTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final upcomingRacesState = ref.watch(athleteUpcomingRacesProvider(widget.athlete.id));

    // Слушаем ошибки
    ref.listen<UpcomingRacesState>(athleteUpcomingRacesProvider(widget.athlete.id), (previous, next) {
      if (next.hasError && previous?.error != next.error && mounted) {
        AlertHelper.showError(
          context,
          next.error ?? 'Ошибка загрузки',
          buttonText: localizations.error_ok,
        );
      }
    });

    // Данные уже загружены при открытии экрана, не показываем лоадер

    if (upcomingRacesState.hasError && upcomingRacesState.races.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                upcomingRacesState.error ?? 'Ошибка загрузки',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(athleteUpcomingRacesProvider(widget.athlete.id).notifier).loadUpcomingRaces(
                    userProfileId: widget.athlete.id,
                    onlyFuture: true,
                  );
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(athleteUpcomingRacesProvider(widget.athlete.id).notifier).loadUpcomingRaces(
          userProfileId: widget.athlete.id,
          onlyFuture: true,
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                localizations.home_upcoming_races,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (upcomingRacesState.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  localizations.home_no_upcoming_races,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 100.0,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: UpcomingRaceCard(
                        race: upcomingRacesState.races[index],
                        showAthleteName: false,
                      ),
                    );
                  },
                  childCount: upcomingRacesState.races.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme, double size) {
    return Container(
      width: size,
      height: size,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: size * 0.5,
        ),
      ),
    );
  }
}

class _PersonalBestsCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final int athleteId;
  final List<RaceResult>? results;

  const _PersonalBestsCard({
    required this.title,
    required this.data,
    required this.athleteId,
    this.results,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Centered race type text
            Center(
              child: Container(
                padding: const EdgeInsets.only(bottom: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.ironmanRed,
                      width: 2,
                    ),
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
                athleteId: athleteId,
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
                athleteId: athleteId,
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
                athleteId: athleteId,
                results: results,
              ),
            if (swimTime == null && bikeTime == null && runTime == null)
              Text(
                'Нет данных',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 72; // TabBar height (~48) + padding (8) + bottom margin (16)

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

class _DisciplineRow extends StatelessWidget {
  final String imagePath;
  final String time;
  final String? date;
  final String? location;
  final String Function(String?) formatDate;
  final String raceType;
  final int athleteId;
  final List<RaceResult>? results;

  const _DisciplineRow({
    required this.imagePath,
    required this.time,
    this.date,
    this.location,
    required this.formatDate,
    required this.raceType,
    required this.athleteId,
    this.results,
  });

  RaceResult? _findResult() {
    if (results == null || date == null || location == null) return null;

    // Ищем результат по дате и локации, только среди подтвержденных
    for (final result in results!) {
      if (result.isApproved && result.date == date && result.location == location) {
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ironmanGray, width: 1),
        ),
        child: Row(
          children: [
            // Icon
            Image.asset(imagePath, width: 40, height: 40, fit: BoxFit.contain),
            const SizedBox(width: 16),
            // Time
            Expanded(
              child: Text(
                time,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // Date and location
            if (date != null || location != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (date != null)
                      Text(
                        formatDate(date),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    if (location != null) ...[
                      if (date != null) const SizedBox(height: 4),
                      Text(
                        location!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            // Chevron
            if (result != null) ...[
              const SizedBox(width: 8),
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
