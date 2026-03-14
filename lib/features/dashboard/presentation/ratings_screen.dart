import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/rankings/application/rankings_notifier.dart';
import 'package:ironman_mobile/features/rankings/application/rankings_state.dart';
import 'package:ironman_mobile/features/rankings/domain/ranking.dart';
import 'package:ironman_mobile/features/dashboard/presentation/disciplines_comparison_widget.dart';
import 'package:ironman_mobile/shared/widgets/unauthenticated_bottom_nav.dart';
import '../../../shared/utils/image_url_helper.dart';
import 'package:ironman_mobile/features/auth/application/auth_notifier.dart';
import 'package:ironman_mobile/features/auth/application/auth_state.dart';
import 'package:intl/intl.dart';
import '../../../shared/utils/error_handler.dart';

class RatingsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final bool isActive;

  const RatingsScreen({super.key, this.onBack, this.isActive = true});

  @override
  ConsumerState<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends ConsumerState<RatingsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _mainTabController;
  bool _showHintAlert = true;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _mainTabController.addListener(_onMainTabChanged);
    // С PageView экран монтируется только при первом посещении —
    // initState безопасное место для начальной загрузки данных.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentState = ref.read(rankingsProvider);
      if (currentState.rankings.isEmpty && !currentState.isLoading && !currentState.hasError) {
        ref.read(rankingsProvider.notifier).loadRankings(raceType: 'ironman', discipline: 'total');
      }
    });
  }

  @override
  void dispose() {
    _mainTabController.removeListener(_onMainTabChanged);
    _mainTabController.dispose();
    super.dispose();
  }

  void _onMainTabChanged() {
    if (!_mainTabController.indexIsChanging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(rankingsProvider.notifier).clearRankings();

        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            final raceType = _mainTabController.index == 0
                ? 'ironman'
                : 'ironman_70_3';
            ref.read(rankingsProvider.notifier).loadRankings(
              raceType: raceType,
              discipline: 'total',
              forceLoading: true,
            );
          }
        });
      });
    }
  }

  List<Map<String, String>> _getDisciplines(AppLocalizations localizations) {
    return [
      {'value': 'total', 'label': localizations.ratings_discipline_total},
      {'value': 'swim', 'label': localizations.ratings_discipline_swim},
      {'value': 'bike', 'label': localizations.ratings_discipline_bike},
      {'value': 'run', 'label': localizations.ratings_discipline_run},
    ];
  }

  bool _isUserAuthenticated() {
    final authState = ref.read(authProvider);
    return authState.status == AuthStatus.authenticated && authState.user != null;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(rankingsProvider);

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo is ScrollUpdateNotification && _showHintAlert) {
                setState(() {
                  _showHintAlert = false;
                });
              }
              return false;
            },
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    leading: IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: theme.colorScheme.onSurface,
                        size: 24,
                      ),
                      onPressed:
                          widget.onBack ??
                          () => Navigator.of(context).maybePop(),
                    ),
                    title: Text(
                      localizations.ratings_title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    pinned: true,
                    floating: false,
                    snap: false,
                    forceElevated: false,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(kToolbarHeight + 16),
                      child: Container(
                        color: theme.scaffoldBackgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.ironmanGray,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: TabBar(
                              controller: _mainTabController,
                              labelColor: Colors.white,
                              labelStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              unselectedLabelColor: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              unselectedLabelStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryGradientStart,
                                    AppColors.primaryGradientEnd,
                                  ],
                                ),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              indicatorPadding: EdgeInsets.zero,
                              tabs: const [
                                Tab(text: 'IRONMAN'),
                                Tab(text: 'IRONMAN 70.3'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _mainTabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Таб Ironman
                  _RaceTypeTab(
                    raceType: 'ironman',
                    disciplines: _getDisciplines(localizations),
                    onDisciplineSelected: (discipline) {
                      ref.read(rankingsProvider.notifier).loadRankings(
                        raceType: 'ironman',
                        discipline: discipline,
                        forceLoading: true,
                      );
                    },
                  ),
                  // Таб Ironman 70.3
                  _RaceTypeTab(
                    raceType: 'ironman_70_3',
                    disciplines: _getDisciplines(localizations),
                    onDisciplineSelected: (discipline) {
                      ref.read(rankingsProvider.notifier).loadRankings(
                        raceType: 'ironman_70_3',
                        discipline: discipline,
                        forceLoading: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Плавающий алерт с подсказкой
          // Показываем только когда рейтинги реально загружены (есть данные) —
          // иначе алерт появляется слишком рано на пустом/загружающемся экране.
          // Скрываем алерт при ошибке, чтобы не накладываться на SnackBar с ошибкой
          if (_showHintAlert &&
              state.selectedAthleteIds.isEmpty &&
              state.rankings.isNotEmpty &&
              !state.isLoading &&
              !state.hasError)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ironmanRed,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.ironmanRed, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      localizations.ratings_tap_to_compare_hint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.ironmanWhite,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Add bottom navigation for unauthenticated users
      bottomNavigationBar: _isUserAuthenticated()
          ? null
          : const UnauthenticatedBottomNav(currentIndex: 1), // 1 = Ratings
    );
  }
}

// Таб с типами гонок и подтабами дисциплин
class _RaceTypeTab extends ConsumerStatefulWidget {
  final String raceType;
  final List<Map<String, String>> disciplines;
  final Function(String) onDisciplineSelected;

  const _RaceTypeTab({
    required this.raceType,
    required this.disciplines,
    required this.onDisciplineSelected,
  });

  @override
  ConsumerState<_RaceTypeTab> createState() => _RaceTypeTabState();
}

class _RaceTypeTabState extends ConsumerState<_RaceTypeTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  bool _showComparison = false;
  bool _didInitialLoad = false;
  String _searchQuery = '';
  late TextEditingController _searchController;

  String? _getDisciplineImagePath(String discipline) {
    switch (discipline.toLowerCase()) {
      case 'swim':
        return 'assets/images/svg/swim.png';
      case 'bike':
        return 'assets/images/svg/bike.png';
      case 'run':
        return 'assets/images/svg/run.png';
      case 'total':
        return 'assets/images/svg/flag.png';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(
      length: widget.disciplines.length,
      vsync: this,
      initialIndex: 0, // Флаг (total) активен по умолчанию
    );
    _subTabController.addListener(_onSubTabChanged);
    _searchController = TextEditingController();
    // ВАЖНО: не загружаем рейтинги здесь.
    // _RaceTypeTab создаётся внутри IndexedStack даже когда экран Ratings не активен,
    // поэтому любая автозагрузка в initState будет дергать API на главном экране.
  }

  @override
  void didUpdateWidget(covariant _RaceTypeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Загружаем данные при первом показе таба дисциплин (например, при свайпе на 70.3).
    // didUpdateWidget вызывается когда TabBarView перестраивает дочерний виджет.
    if (!_didInitialLoad) {
      _didInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentState = ref.read(rankingsProvider);
        if (!currentState.hasError) {
          widget.onDisciplineSelected('total');
        }
      });
    }
  }

  @override
  void dispose() {
    _subTabController.removeListener(_onSubTabChanged);
    _subTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSubTabChanged() {
    if (!_subTabController.indexIsChanging) {
      ref.read(rankingsProvider.notifier).clearRankings();

      // ПРАВИЛО: setState нельзя вызывать напрямую в listener TabController —
      // listener может сработать во время фазы layout/build (пока TabBarView
      // анимирует переключение), что вызывает "_elements.contains(element)"
      // assertion на iOS. addPostFrameCallback гарантирует вызов после кадра.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showComparison = false;
        });
      });

      // Небольшая задержка для плавной анимации перед загрузкой новых данных.
      // mounted проверяется внутри замыкания — виджет может быть удалён за 150 мс.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          final selectedDiscipline =
              widget.disciplines[_subTabController.index]['value']!;
          widget.onDisciplineSelected(selectedDiscipline);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rankingsProvider);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Подтабы с дисциплинами
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: TabBar(
              controller: _subTabController,
              labelColor: AppColors.ironmanRed,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              indicator: UnderlineTabIndicator(
                borderRadius: BorderRadius.circular(1.5),
                borderSide: BorderSide(
                  width: 3,
                  color: AppColors.ironmanRed,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              indicatorPadding: EdgeInsets.zero,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              isScrollable: false,
              tabs: widget.disciplines.map((discipline) {
                final imagePath = _getDisciplineImagePath(discipline['value']!);
                return Tab(
                  child: Center(
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            width: 60,
                            height: 24,
                            fit: BoxFit.contain,
                          )
                        : Text(discipline['label']!),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Поисковая строка
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                // Close comparison block when starting to type
                if (_showComparison && value.isNotEmpty) {
                  _showComparison = false;
                  ref.read(rankingsProvider.notifier).clearSelection();
                }
              });
            },
            decoration: InputDecoration(
              hintText: localizations.athletes_search_hint,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 24,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: theme.textTheme.bodyLarge,
          ),
        ),
        // Контент с рейтингами
        Expanded(child: _buildRankingsList(state, theme, localizations)),
      ],
    );
  }

  Widget _buildRankingsList(
    RankingsState state,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    if (state.isLoading && state.rankings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Показываем ошибку, если она есть и нет загрузки (включая случай pull-to-refresh)
    if (state.hasError && !state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.error != null
                    ? ErrorHandler.localizeErrorKey(state.error!, localizations)
                    : localizations.common_loading_error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final selectedDiscipline =
                      widget.disciplines[_subTabController.index]['value']!;
                  widget.onDisciplineSelected(selectedDiscipline);
                },
                child: Text(localizations.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Text(
          localizations.ratings_no_rankings,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.ironmanTextSecondary,
          ),
        ),
      );
    }

    // Если включен режим сравнения и выбрано 2 атлета, показываем сравнение
    if (_showComparison && state.canCompare) {
      return _buildComparisonView(state, theme, localizations);
    }

    // Применяем фильтр поиска
    var filteredRankings = state.rankings;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredRankings = filteredRankings.where((ranking) {
        return ranking.name.toLowerCase().contains(query) ||
            ranking.position.toString().contains(query);
      }).toList();
    }

    // Если после фильтрации нет результатов
    if (filteredRankings.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          localizations.results_no_results,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.ironmanTextSecondary,
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await ref.read(rankingsProvider.notifier).refreshRankings();
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 80.0, // Отступ для плавающей кнопки
            ),
            itemCount: filteredRankings.length,
            itemBuilder: (context, index) {
              final ranking = filteredRankings[index];
              return _buildRankingCard(ranking, state, theme, localizations);
            },
          ),
        ),
        // Плавающая кнопка сравнения
        if (state.selectedAthleteIds.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: ElevatedButton(
                onPressed: state.canCompare
                    ? () {
                        // Переключаем на режим сравнения
                        setState(() {
                          _showComparison = true;
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.canCompare
                      ? AppColors.ironmanRed
                      : AppColors.ironmanGray,
                  foregroundColor: AppColors.ironmanWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: state.canCompare
                          ? AppColors.ironmanRed
                          : AppColors.ironmanLightGray,
                      width: state.canCompare ? 2 : 1,
                    ),
                  ),
                  elevation: state.canCompare ? 4 : 0,
                  disabledBackgroundColor: AppColors.ironmanGray,
                  disabledForegroundColor: AppColors.ironmanTextSecondary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${localizations.ratings_compare} (${state.selectedAthleteIds.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: state.canCompare
                            ? AppColors.ironmanWhite
                            : AppColors.ironmanTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRankingCard(
    Ranking ranking,
    RankingsState state,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final isSelected = state.selectedAthleteIds.contains(ranking.athleteId);

    return GestureDetector(
      onTap: () {
        ref
            .read(rankingsProvider.notifier)
            .toggleAthleteSelection(ranking.athleteId);
        // Сбрасываем режим сравнения при изменении выбора
        if (_showComparison) {
          setState(() {
            _showComparison = false;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.ironmanRed : AppColors.ironmanGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 48.0,
                top: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Row(
                children: [
                  // Avatar (как на экране атлетов)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ironmanLightGray,
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: ranking.avatar != null
                          ? Image.network(
                              ImageUrlHelper.getFullImageUrl(ranking.avatar!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar(theme);
                              },
                            )
                          : _buildDefaultAvatar(theme),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ranking.name.toUpperCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                (theme.textTheme.titleMedium?.fontSize ?? 16) +
                                2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ranking.time,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              color: AppColors.ironmanTextSecondary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(ranking.raceDate),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.ironmanTextSecondary,
                                fontSize:
                                    (theme.textTheme.bodySmall?.fontSize ??
                                        12) +
                                    1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              color: AppColors.ironmanTextSecondary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ranking.location,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.ironmanTextSecondary,
                                  fontSize:
                                      (theme.textTheme.bodySmall?.fontSize ??
                                          12) +
                                      1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Position badge в левом верхнем углу
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${ranking.position}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ironmanWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildComparisonView(
    RankingsState state,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final selectedAthletes = state.selectedAthletes;
    if (selectedAthletes.length != 2) {
      return Center(
        child: Text(
          localizations.ratings_select_two_athletes,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.ironmanTextSecondary,
          ),
        ),
      );
    }

    final athlete1 = selectedAthletes[0];
    final athlete2 = selectedAthletes[1];
    final isAthlete1Faster = athlete1.seconds < athlete2.seconds;
    final difference = isAthlete1Faster
        ? athlete2.seconds - athlete1.seconds
        : athlete1.seconds - athlete2.seconds;

    String formatTime(int seconds) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(rankingsProvider.notifier).refreshRankings();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок и кнопка очистки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.ratings_compare,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(rankingsProvider.notifier).clearSelection();
                    setState(() {
                      _showComparison = false;
                    });
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Карточка сравнения
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.ironmanGray, width: 1),
              ),
              child: Column(
                children: [
                  // Атлет 1
                  _buildComparisonAthleteCard(
                    athlete1,
                    theme,
                    localizations,
                    isFaster: isAthlete1Faster,
                  ),
                  // Разделитель
                  Container(
                    height: 1,
                    color: AppColors.ironmanGray,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  // Атлет 2
                  _buildComparisonAthleteCard(
                    athlete2,
                    theme,
                    localizations,
                    isFaster: !isAthlete1Faster,
                  ),
                  // Разница
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations.ratings_difference,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '+${formatTime(difference)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.ironmanRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Выпадающий блок сравнения дисциплин
            _buildDisciplinesComparison(
              athlete1.athleteId,
              athlete2.athleteId,
              athlete1.name,
              athlete2.name,
              state.selectedRaceType,
              theme,
              localizations,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplinesComparison(
    int athlete1Id,
    int athlete2Id,
    String athlete1Name,
    String athlete2Name,
    String raceType,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return DisciplinesComparisonWidget(
      athlete1Id: athlete1Id,
      athlete2Id: athlete2Id,
      athlete1Name: athlete1Name,
      athlete2Name: athlete2Name,
      raceType: raceType,
      theme: theme,
      localizations: localizations,
    );
  }

  Widget _buildComparisonAthleteCard(
    Ranking athlete,
    ThemeData theme,
    AppLocalizations localizations, {
    required bool isFaster,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ironmanLightGray, width: 1),
            ),
            child: ClipOval(
              child: athlete.avatar != null
                  ? Image.network(
                      athlete.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(theme);
                      },
                    )
                  : _buildDefaultAvatar(theme),
            ),
          ),
          const SizedBox(width: 16),
          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  athlete.name.toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  athlete.time,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isFaster ? Colors.green : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(athlete.raceDate)} • ${athlete.location}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.ironmanTextSecondary,
                    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) + 1,
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

