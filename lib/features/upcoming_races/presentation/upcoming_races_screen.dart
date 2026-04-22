import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/widgets/grouped_upcoming_race_card.dart';
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

class _UpcomingRacesScreenState extends ConsumerState<UpcomingRacesScreen> {
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllRaces();
      }
    });
  }

  void _loadAllRaces() {
    ref.read(globalUpcomingRacesProvider.notifier).refreshUpcomingRaces(
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

  List<List<UpcomingRace>> _groupRaces(List<UpcomingRace> races) {
    final Map<String, List<UpcomingRace>> grouped = {};
    for (final race in races) {
      final key = '${race.raceType}|${race.location}|${race.raceDate}';
      grouped.putIfAbsent(key, () => []).add(race);
    }
    return grouped.values.toList();
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
        backgroundColor: theme.scaffoldBackgroundColor,
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(right: 8.w),
        child: Container(
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
            child: Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 24.r,
              ),
            ),
          ),
        ),
        ),
      ),
      body: _buildBody(state, localizations),
    );
  }

  Widget _buildBody(UpcomingRacesState state, AppLocalizations localizations) {
    if (state.isLoading && state.races.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.races.isEmpty) {
      return _buildErrorState(localizations, _loadAllRaces);
    }

    final grouped = _groupRaces(state.races);

    if (grouped.isEmpty) {
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
          itemCount: grouped.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == grouped.length) {
              return Padding(
                padding: EdgeInsets.all(16.r),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: GroupedUpcomingRaceCard(races: grouped[index]),
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
