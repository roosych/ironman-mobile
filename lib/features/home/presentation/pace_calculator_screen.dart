import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/auth/application/auth_notifier.dart';
import 'package:ironman_mobile/features/settings/application/theme_notifier.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/widgets/language_selector.dart';

// ---------------------------------------------------------------------------
// Distance presets (triathlon formats)
// ---------------------------------------------------------------------------

enum DistanceTab { full, half70_3, olympic }

extension DistanceTabExtension on DistanceTab {
  double get swimKm {
    switch (this) {
      case DistanceTab.full:
        return 3.8;
      case DistanceTab.half70_3:
        return 1.9;
      case DistanceTab.olympic:
        return 1.5;
    }
  }

  double get bikeKm {
    switch (this) {
      case DistanceTab.full:
        return 180;
      case DistanceTab.half70_3:
        return 90;
      case DistanceTab.olympic:
        return 40;
    }
  }

  double get runKm {
    switch (this) {
      case DistanceTab.full:
        return 42;
      case DistanceTab.half70_3:
        return 21;
      case DistanceTab.olympic:
        return 10;
    }
  }
}

// ---------------------------------------------------------------------------
// Pace / speed formatting
// ---------------------------------------------------------------------------

String formatDurationHhMmSs(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String formatPacePer100m(Duration swimTime, double distanceMeters) {
  if (distanceMeters <= 0) return '00:00';
  final secPer100 = (swimTime.inSeconds / distanceMeters) * 100;
  final minutes = secPer100 ~/ 60;
  final seconds = (secPer100 % 60).round();
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String formatSpeedKmh(double bikeKm, Duration bikeTime) {
  if (bikeTime.inSeconds <= 0) return '0.0';
  final hours = bikeTime.inSeconds / 3600;
  final kmh = bikeKm / hours;
  return kmh.toStringAsFixed(1);
}

String formatPacePerKm(Duration runTime, double runKm) {
  if (runKm <= 0) return '00:00';
  final secPerKm = runTime.inSeconds / runKm;
  final minutes = secPerKm ~/ 60;
  final seconds = (secPerKm % 60).round();
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Pace Calculator Screen
// ---------------------------------------------------------------------------

class PaceCalculatorScreen extends ConsumerStatefulWidget {
  const PaceCalculatorScreen({super.key});

  @override
  ConsumerState<PaceCalculatorScreen> createState() => _PaceCalculatorScreenState();
}

class _PaceCalculatorScreenState extends ConsumerState<PaceCalculatorScreen> {
  DistanceTab _selectedTab = DistanceTab.full;
  Duration _swimTime = Duration.zero;
  Duration _t1Time = Duration.zero;
  Duration _bikeTime = Duration.zero;
  Duration _t2Time = Duration.zero;
  Duration _runTime = Duration.zero;
  int _selectedDisciplineIndex = -1; // none selected by default

  Duration get _totalTime =>
      _swimTime + _t1Time + _bikeTime + _t2Time + _runTime;

  double get _swimKm => _selectedTab.swimKm;
  double get _bikeKm => _selectedTab.bikeKm;
  double get _runKm => _selectedTab.runKm;

  void _onTabSelected(DistanceTab tab) {
    setState(() => _selectedTab = tab);
  }

  void _clearAllTimes() {
    setState(() {
      _swimTime = Duration.zero;
      _t1Time = Duration.zero;
      _bikeTime = Duration.zero;
      _t2Time = Duration.zero;
      _runTime = Duration.zero;
      _selectedDisciplineIndex = -1;
    });
  }

  /// Opens a Cupertino-style timer picker (hours, minutes, seconds) in a modal.
  /// On confirm: updates the discipline [Duration], recalculates total time and
  /// paces, and refreshes UI via setState. On cancel: dismisses without changes.
  Future<void> _pickTime({
    required String title,
    required Duration initial,
    required ValueChanged<Duration> onConfirm,
  }) async {
    // Clamp to CupertinoTimerPicker range (0–23:59:59); picker uses this as initial.
    final clampedInitial = Duration(
      hours: initial.inHours.clamp(0, 23),
      minutes: initial.inMinutes.remainder(60),
      seconds: initial.inSeconds.remainder(60),
    );
    Duration selected = clampedInitial;

    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        final ctxTheme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: ctxTheme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          loc.common_cancel,
                          style: TextStyle(color: ctxTheme.colorScheme.primary),
                        ),
                      ),
                      Text(
                        title,
                        style: ctxTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        onPressed: () {
                          onConfirm(selected);
                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          loc.pace_calculator_done,
                          style: TextStyle(
                            color: ctxTheme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 220.h,
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hms,
                    initialTimerDuration: clampedInitial,
                    onTimerDurationChanged: (Duration d) => selected = d,
                    backgroundColor: ctxTheme.colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _tabLabel(DistanceTab tab, AppLocalizations loc) {
    switch (tab) {
      case DistanceTab.full:
        return loc.pace_calculator_tab_full;
      case DistanceTab.half70_3:
        return loc.pace_calculator_tab_70_3;
      case DistanceTab.olympic:
        return loc.pace_calculator_tab_5150;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
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
              ),
            ),
            child: const SizedBox.shrink(),
          ),
          // Main content
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: (ModalRoute.of(context)?.canPop ?? false)
                  ? IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: theme.colorScheme.onSurface,
                        size: 24.r,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              title: Text(
                loc.pace_calculator_appbar_title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                ),
              ),
              centerTitle: true,
              actions: ref.watch(authProvider).isAuthenticated
                  ? null
                  : [
                      IconButton(
                        icon: HugeIcon(
                          icon: ref.watch(themeModeProvider) == ThemeMode.dark
                              ? HugeIcons.strokeRoundedSun01
                              : HugeIcons.strokeRoundedMoon02,
                          color: theme.colorScheme.onSurface,
                          size: 24.r,
                        ),
                        onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 16.w),
                        child: const LanguageSelector(),
                      ),
                    ],
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DistanceTabs(
                    selectedTab: _selectedTab,
                    onTabSelected: _onTabSelected,
                    getTabLabel: (tab) => _tabLabel(tab, loc),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDisciplineIndex = -1),
                      behavior: HitTestBehavior.opaque,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TotalTimeCard(
                              totalTime: _totalTime,
                              totalRaceTimeLabel: loc.pace_calculator_total_race_time,
                              onReset: _clearAllTimes,
                            ),
                            SizedBox(height: 20.h),
                            DisciplineCard(
                              icon: Icons.pool_outlined,
                              iconAsset: 'assets/images/svg/swim.svg',
                              label: '${_swimKm.toStringAsFixed(_swimKm >= 1 ? 1 : 2)} ${loc.pace_calculator_km_unit}',
                              duration: _swimTime,
                              rightLabel: loc.pace_calculator_min_per_100m,
                              rightValue: formatPacePer100m(_swimTime, _swimKm * 1000),
                              isLocked: false,
                              isSelected: _selectedDisciplineIndex == 0,
                              onTap: () {
                                setState(() => _selectedDisciplineIndex = 0);
                                _pickTime(
                                  title: loc.pace_calculator_swim_time,
                                  initial: _swimTime,
                                  onConfirm: (d) => setState(() => _swimTime = d),
                                );
                              },
                            ),
                            SizedBox(height: 6.h),
                            DisciplineCard(
                              icon: Icons.swap_horiz,
                              label: 'T1',
                              duration: _t1Time,
                              rightLabel: null,
                              rightValue: null,
                              isLocked: false,
                              isSelected: _selectedDisciplineIndex == 1,
                              onTap: () {
                                setState(() => _selectedDisciplineIndex = 1);
                                _pickTime(
                                  title: loc.pace_calculator_t1_time,
                                  initial: _t1Time,
                                  onConfirm: (d) => setState(() => _t1Time = d),
                                );
                              },
                            ),
                            SizedBox(height: 6.h),
                            DisciplineCard(
                              icon: Icons.directions_bike_outlined,
                              iconAsset: 'assets/images/svg/bike.svg',
                              label: '${_bikeKm % 1 == 0 ? _bikeKm.toInt() : _bikeKm.toStringAsFixed(1)} ${loc.pace_calculator_km_unit}',
                              duration: _bikeTime,
                              rightLabel: loc.pace_calculator_km_per_h,
                              rightValue: formatSpeedKmh(_bikeKm, _bikeTime),
                              isLocked: false,
                              isSelected: _selectedDisciplineIndex == 2,
                              onTap: () {
                                setState(() => _selectedDisciplineIndex = 2);
                                _pickTime(
                                  title: loc.pace_calculator_bike_time,
                                  initial: _bikeTime,
                                  onConfirm: (d) => setState(() => _bikeTime = d),
                                );
                              },
                            ),
                            SizedBox(height: 6.h),
                            DisciplineCard(
                              icon: Icons.swap_horiz,
                              label: 'T2',
                              duration: _t2Time,
                              rightLabel: null,
                              rightValue: null,
                              isLocked: false,
                              isSelected: _selectedDisciplineIndex == 3,
                              onTap: () {
                                setState(() => _selectedDisciplineIndex = 3);
                                _pickTime(
                                  title: loc.pace_calculator_t2_time,
                                  initial: _t2Time,
                                  onConfirm: (d) => setState(() => _t2Time = d),
                                );
                              },
                            ),
                            SizedBox(height: 6.h),
                            DisciplineCard(
                              icon: Icons.directions_run_outlined,
                              iconAsset: 'assets/images/svg/run.svg',
                              label: '${_runKm % 1 == 0 ? _runKm.toInt() : _runKm.toStringAsFixed(1)} ${loc.pace_calculator_km_unit}',
                              duration: _runTime,
                              rightLabel: loc.pace_calculator_min_per_km,
                              rightValue: formatPacePerKm(_runTime, _runKm),
                              isLocked: false,
                              isSelected: _selectedDisciplineIndex == 4,
                              onTap: () {
                                setState(() => _selectedDisciplineIndex = 4);
                                _pickTime(
                                  title: loc.pace_calculator_run_time,
                                  initial: _runTime,
                                  onConfirm: (d) => setState(() => _runTime = d),
                                );
                              },
                            ),
                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Distance Tabs (segmented control)
// ---------------------------------------------------------------------------

class DistanceTabs extends StatelessWidget {
  const DistanceTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.getTabLabel,
  });

  final DistanceTab selectedTab;
  final ValueChanged<DistanceTab> onTabSelected;
  final String Function(DistanceTab) getTabLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
      child: Row(
        // 5150 (olympic) tab hidden
        children: DistanceTab.values
            .where((tab) => tab != DistanceTab.olympic)
            .map((tab) {
          final isSelected = tab == selectedTab;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
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
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  child: InkWell(
                    onTap: () => onTabSelected(tab),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Center(
                        child: Text(
                          getTabLabel(tab),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 16.sp,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Total Race Time Card
// ---------------------------------------------------------------------------

class TotalTimeCard extends StatelessWidget {
  const TotalTimeCard({
    super.key,
    required this.totalTime,
    required this.totalRaceTimeLabel,
    required this.onReset,
  });

  final Duration totalTime;
  final String totalRaceTimeLabel;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          totalRaceTimeLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 60.w,
              child: IconButton(
                onPressed: onReset,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedRefresh,
                  color: theme.colorScheme.onSurface,
                  size: 22.r,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Очистить все значения',
              ),
            ),
            Text(
              formatDurationHhMmSs(totalTime),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 32.sp,
              ),
            ),
            SizedBox(width: 60.w),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Discipline icon (asset image or fallback icon)
// ---------------------------------------------------------------------------

class _DisciplineIcon extends StatelessWidget {
  const _DisciplineIcon({
    required this.icon,
    required this.color,
    required this.size,
    this.iconAsset,
  });

  final IconData icon;
  final String? iconAsset;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconAsset != null && iconAsset!.isNotEmpty) {
      return SvgPicture.asset(
        iconAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Icon(icon, color: color, size: size);
  }
}

// ---------------------------------------------------------------------------
// Discipline Card (reusable)
// ---------------------------------------------------------------------------

class DisciplineCard extends StatelessWidget {
  const DisciplineCard({
    super.key,
    required this.icon,
    required this.label,
    required this.duration,
    required this.isLocked,
    required this.isSelected,
    required this.onTap,
    this.iconAsset,
    this.rightLabel,
    this.rightValue,
  });

  final IconData icon;

  /// Optional PNG/SVG asset path (e.g. assets/images/svg/swim.svg). When set, shown instead of [icon].
  final String? iconAsset;
  final String label;
  final Duration duration;
  final String? rightLabel;
  final String? rightValue;
  final bool isLocked;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                _DisciplineIcon(
                  icon: icon,
                  iconAsset: iconAsset,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 36.r,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            formatDurationHhMmSs(duration),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 20.sp,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (isLocked) ...[
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.lock_outline,
                              size: 18.r,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rightLabel != null && rightValue != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rightValue!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        rightLabel!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
