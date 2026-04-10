import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/widgets/upcoming_race_card.dart';
import 'package:ironman_mobile/features/race_selection/presentation/widgets/race_selection_bottom_sheet.dart';
import 'package:ironman_mobile/features/results/presentation/add_result_screen.dart';
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

  int? get _userProfileId => ref.read(authProvider).user?.profile?.id;

  void _loadMyRaces() {
    final profileId = _userProfileId;
    if (profileId == null) {
      ref.read(myRacesProvider.notifier).setEmpty();
      return;
    }
    ref.read(myRacesProvider.notifier).loadUpcomingRaces(
      userProfileId: profileId,
      onlyFuture: false,
    );
  }

  Future<void> _refreshMyRaces() async {
    final profileId = _userProfileId;
    if (profileId == null) {
      ref.read(myRacesProvider.notifier).setEmpty();
      return;
    }
    try {
      await ref.read(myRacesProvider.notifier).refreshUpcomingRaces(
        userProfileId: profileId,
        onlyFuture: false,
      );
    } catch (_) {}
  }

  void _loadNextPage() {
    final profileId = _userProfileId;
    if (profileId == null) return;
    ref.read(myRacesProvider.notifier).loadNextPage(
      userProfileId: profileId,
      onlyFuture: false,
    );
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
      } catch (_) {
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
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort((a, b) {
        try {
          return DateTime.parse(b.raceDate).compareTo(DateTime.parse(a.raceDate));
        } catch (_) {
          return 0;
        }
      });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRacesProvider);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.my_races_title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
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
            onTap: () => showRaceSelectionBottomSheet(context),
            borderRadius: BorderRadius.circular(28),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      ),
      body: Column(
        children: [
          // TabBar
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: ListenableBuilder(
              listenable: _tabController,
              builder: (context, _) {
                final tabs = [
                  localizations.events_tab_active,
                  localizations.events_tab_past,
                ];
                return Row(
                  children: List.generate(2, (i) {
                    final isSelected = _tabController.index == i;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: GestureDetector(
                          onTap: () => _tabController.animateTo(i),
                          child: Container(
                            decoration: isSelected
                                ? BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primaryGradientStart,
                                        AppColors.primaryGradientEnd,
                                      ],
                                    ),
                                  )
                                : BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: Center(
                                child: Text(
                                  tabs[i],
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRacesList(
                  state: state,
                  localizations: localizations,
                  races: _getActiveRaces(state.races),
                  emptyMessage: localizations.my_races_no_races,
                  isPastTab: false,
                ),
                _buildRacesList(
                  state: state,
                  localizations: localizations,
                  races: _getPastRaces(state.races),
                  emptyMessage: localizations.events_no_past_races,
                  isPastTab: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddResult(UpcomingRace race) {
    DateTime? raceDate;
    try {
      raceDate = DateTime.parse(race.raceDate);
    } catch (_) {}

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddResultScreen(
          initialDate: raceDate,
          initialLocation: race.location,
          initialRaceType: race.raceType,
        ),
      ),
    );
  }

  Future<void> _onDidNotParticipate(UpcomingRace race) async {
    final confirmed = await _showDeleteConfirmDialog(race);
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(myRacesProvider.notifier).deleteUpcomingRace(id: race.id);
    } catch (e) {
      if (!mounted) return;
      _showErrorSafely(e, context);
    }
  }

  Future<bool?> _showDeleteConfirmDialog(UpcomingRace race) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок + крестик
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      localizations.upcoming_delete_confirm_title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 24.r,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                '${race.raceTypeLabel.toUpperCase()}, ${race.location}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                localizations.upcoming_delete_confirm_body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 24.h),
              // Кнопки
              Row(
                children: [
                  // Отмена
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        localizations.common_cancel,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Удалить (красный градиент)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF6F61), Color(0xFFE53935)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB71C1C).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            localizations.upcoming_delete_confirm_button,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }

  Widget _buildRacesList({
    required UpcomingRacesState state,
    required AppLocalizations localizations,
    required List<UpcomingRace> races,
    required String emptyMessage,
    required bool isPastTab,
  }) {
    if (state.isLoading && state.races.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.races.isEmpty) {
      return _buildErrorState(localizations, _loadMyRaces);
    }

    if (races.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMyRaces,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >=
              scrollInfo.metrics.maxScrollExtent * 0.8) {
            if (state.hasMorePages && !state.isLoadingMore && !state.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _loadNextPage();
              });
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: races.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == races.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: UpcomingRaceCard(
                race: races[index],
                showAthleteName: false,
                onParticipated: isPastTab ? () => _navigateToAddResult(races[index]) : null,
                onDidNotParticipate: isPastTab ? () => _onDidNotParticipate(races[index]) : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations localizations, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
