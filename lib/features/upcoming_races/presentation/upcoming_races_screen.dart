import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/widgets/upcoming_race_card.dart';
import 'package:ironman_mobile/features/race_selection/presentation/widgets/race_selection_bottom_sheet.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import '../domain/upcoming_race.dart';
import '../application/upcoming_races_notifier.dart';
import '../application/upcoming_races_state.dart';

class UpcomingRacesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const UpcomingRacesScreen({super.key, this.onBack});

  @override
  ConsumerState<UpcomingRacesScreen> createState() =>
      _UpcomingRacesScreenState();
}

class _UpcomingRacesScreenState extends ConsumerState<UpcomingRacesScreen>
    with SingleTickerProviderStateMixin {
  String? _lastShownError;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllRaces();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAllRaces() {
    ref.read(globalUpcomingRacesProvider.notifier).loadUpcomingRaces(
      onlyFuture: false,
    );
  }

  Future<void> _refreshAllRaces() async {
    try {
      await ref.read(globalUpcomingRacesProvider.notifier).refreshUpcomingRaces(
        onlyFuture: false,
      );
    } catch (e) {
      // Ошибка уже обработана в провайдере
    }
  }

  void _loadNextPage() {
    ref.read(globalUpcomingRacesProvider.notifier).loadNextPage(
      onlyFuture: false,
    );
  }

  void _showErrorSafely(dynamic error) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ErrorHandler.showError(context, error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalUpcomingRacesProvider);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    ref.listen<UpcomingRacesState>(globalUpcomingRacesProvider, (previous, next) {
      if (!mounted) return;
      if (next.hasError && next.error != null) {
        final error = next.error!;
        if (previous?.error != error && _lastShownError != error) {
          _lastShownError = error;
          _showErrorSafely(error);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24.r,
          ),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.home_upcoming_races,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
        ),
      ),
      floatingActionButton: Container(
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGradientStart,
              AppColors.primaryGradientEnd,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGradientShadow.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showRaceSelectionBottomSheet(context);
            },
            borderRadius: BorderRadius.circular(28.r),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 24.r,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // TabBar
          Container(
            margin: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.ironmanGray, width: 1),
            ),
            padding: EdgeInsets.all(4.r),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.ironmanWhite,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
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
              labelStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
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
          return dateB.compareTo(dateA);
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

  Widget _buildActiveRacesTab(UpcomingRacesState state, AppLocalizations localizations) {
    if (state.isLoading && state.races.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.races.isEmpty) {
      return _buildErrorState(localizations, _loadAllRaces);
    }

    final activeRaces = _getActiveRaces(state.races);

    if (activeRaces.isEmpty) {
      return Center(
        child: Text(
          localizations.home_no_upcoming_races,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAllRaces,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
            if (state.hasMorePages && !state.isLoadingMore && !state.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _loadNextPage();
              });
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
          itemCount: activeRaces.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == activeRaces.length) {
              return Padding(
                padding: EdgeInsets.all(16.r),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: UpcomingRaceCard(race: activeRaces[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPastRacesTab(UpcomingRacesState state, AppLocalizations localizations) {
    if (state.isLoading && state.races.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.races.isEmpty) {
      return _buildErrorState(localizations, _loadAllRaces);
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
      onRefresh: _refreshAllRaces,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
            if (state.hasMorePages && !state.isLoadingMore && !state.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _loadNextPage();
              });
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
          itemCount: pastRaces.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == pastRaces.length) {
              return Padding(
                padding: EdgeInsets.all(16.r),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: UpcomingRaceCard(race: pastRaces[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations localizations, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.common_loading_error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
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
