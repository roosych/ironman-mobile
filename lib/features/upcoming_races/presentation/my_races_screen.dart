import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/widgets/upcoming_race_card.dart';
import 'package:ironman_mobile/shared/widgets/add_upcoming_race_bottom_sheet.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import '../domain/upcoming_race.dart';
import '../application/upcoming_races_notifier.dart';
import '../application/upcoming_races_state.dart';
import '../../auth/application/auth_notifier.dart';

class MyRacesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const MyRacesScreen({super.key, this.onBack});

  @override
  ConsumerState<MyRacesScreen> createState() => _MyRacesScreenState();
}

class _MyRacesScreenState extends ConsumerState<MyRacesScreen>
    with SingleTickerProviderStateMixin {
  String? _lastShownError;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Загружаем все гонки (будущие и прошедшие) после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMyRaces();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMyRaces() {
    final authState = ref.read(authProvider);
    final user = authState.user;
    int? userProfileId;
    if (user?.profile is Map<String, dynamic>) {
      final profile = user!.profile as Map<String, dynamic>;
      userProfileId = profile['id'] as int?;
    }

    // Если профиль не найден — очищаем список и выходим
    if (userProfileId == null) {
      ref.read(myRacesProvider.notifier).setEmpty();
      return;
    }

    // Используем отдельный провайдер для "Мои гонки"
    ref
        .read(myRacesProvider.notifier)
        .loadUpcomingRaces(
          userProfileId: userProfileId,
          onlyFuture: false, // Все гонки, включая прошедшие
        );
  }

  Future<void> _refreshMyRaces() async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      int? userProfileId;
      if (user?.profile is Map<String, dynamic>) {
        final profile = user!.profile as Map<String, dynamic>;
        userProfileId = profile['id'] as int?;
      }

      if (userProfileId == null) {
        ref.read(myRacesProvider.notifier).setEmpty();
        return;
      }

      await ref
          .read(myRacesProvider.notifier)
          .refreshUpcomingRaces(
            userProfileId: userProfileId,
            onlyFuture: false, // Все гонки, включая прошедшие
          );
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

  List<UpcomingRace> _getActiveRaces(List<UpcomingRace> races) {
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

  List<UpcomingRace> _getPastRaces(List<UpcomingRace> races) {
    final now = DateTime.now();
    return races.where((race) {
      try {
        final raceDate = DateTime.parse(race.raceDate);
        return raceDate.isBefore(now) && !_isSameDay(raceDate, now);
      } catch (e) {
        return false;
      }
    }).toList()
      ..sort((a, b) {
        try {
          final dateA = DateTime.parse(a.raceDate);
          final dateB = DateTime.parse(b.raceDate);
          return dateB.compareTo(dateA); // Сортировка по убыванию даты
        } catch (e) {
          return 0;
        }
      });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRacesProvider);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Слушаем ошибки
    ref.listen<UpcomingRacesState>(myRacesProvider, (previous, next) {
      if (!mounted) return;
      if (next.hasError && next.error != null) {
        final error = next.error!;
        if (previous?.error != error && _lastShownError != error) {
          _lastShownError = error;
          _showErrorSafely(error, context);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.my_races_title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddUpcomingRaceBottomSheet(context);
          // Обновление списка произойдет автоматически через провайдер в BottomSheet
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // TabBar
          Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ironmanGray, width: 1),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.ironmanWhite,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                Tab(text: localizations.events_tab_active),
                Tab(text: localizations.events_tab_past),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveRacesTab(state, localizations),
                _buildPastRacesTab(state, localizations),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRacesTab(UpcomingRacesState state, AppLocalizations localizations) {
    if (state.isLoading && state.races.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.races.isEmpty) {
      return _buildErrorState(localizations, _loadMyRaces);
    }

    final activeRaces = _getActiveRaces(state.races);

    if (activeRaces.isEmpty) {
      return Center(
        child: Text(
          localizations.my_races_no_races,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMyRaces,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
        itemCount: activeRaces.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: UpcomingRaceCard(race: activeRaces[index], showAthleteName: false),
          );
        },
      ),
    );
  }

  Widget _buildPastRacesTab(UpcomingRacesState state, AppLocalizations localizations) {
    if (state.isLoading && state.races.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.races.isEmpty) {
      return _buildErrorState(localizations, _loadMyRaces);
    }

    final pastRaces = _getPastRaces(state.races);

    if (pastRaces.isEmpty) {
      return Center(
        child: Text(
          localizations.events_no_past_races,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMyRaces,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
        itemCount: pastRaces.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: UpcomingRaceCard(race: pastRaces[index], showAthleteName: false),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations localizations, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.common_loading_error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(localizations.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}
