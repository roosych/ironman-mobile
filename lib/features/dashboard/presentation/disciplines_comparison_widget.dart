import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/features/dashboard/application/records_notifier.dart';
import 'package:ironman_mobile/features/dashboard/domain/personal_record.dart';

class DisciplinesComparisonWidget extends ConsumerStatefulWidget {
  final int athlete1Id;
  final int athlete2Id;
  final String athlete1Name;
  final String athlete2Name;
  final String raceType;
  final ThemeData theme;
  final AppLocalizations localizations;

  const DisciplinesComparisonWidget({
    super.key,
    required this.athlete1Id,
    required this.athlete2Id,
    required this.athlete1Name,
    required this.athlete2Name,
    required this.raceType,
    required this.theme,
    required this.localizations,
  });

  @override
  ConsumerState<DisciplinesComparisonWidget> createState() =>
      _DisciplinesComparisonWidgetState();
}

class _DisciplinesComparisonWidgetState
    extends ConsumerState<DisciplinesComparisonWidget> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadRecordsIfNeeded();
    });
  }

  @override
  void didUpdateWidget(DisciplinesComparisonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.athlete1Id != widget.athlete1Id ||
        oldWidget.athlete2Id != widget.athlete2Id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadRecordsIfNeeded();
      });
    }
  }

  void _loadRecordsIfNeeded() {
    final records1State = ref.read(recordsProvider(widget.athlete1Id));
    if (!records1State.isLoading && records1State.records == null) {
      ref.read(recordsProvider(widget.athlete1Id).notifier).loadRecords();
    }
    final records2State = ref.read(recordsProvider(widget.athlete2Id));
    if (!records2State.isLoading && records2State.records == null) {
      ref.read(recordsProvider(widget.athlete2Id).notifier).loadRecords();
    }
  }

  PersonalRecord? _getRecordsForRaceType(Records? records) {
    if (records == null) return null;
    switch (widget.raceType) {
      case 'ironman':
        return records.ironman;
      case 'ironman_70_3':
        return records.ironman703;
      case '5150':
        return records.race5150;
      default:
        return null;
    }
  }


  String _formatDiffReadable(int diffSeconds) {
    final loc = widget.localizations;
    if (diffSeconds < 60) {
      return '$diffSeconds ${loc.unit_sec}';
    } else if (diffSeconds < 3600) {
      final m = diffSeconds ~/ 60;
      final s = diffSeconds % 60;
      if (s == 0) return '$m ${loc.unit_min}';
      return '$m ${loc.unit_min} $s ${loc.unit_sec}';
    } else {
      final h = diffSeconds ~/ 3600;
      final m = (diffSeconds % 3600) ~/ 60;
      if (m == 0) return '$h ${loc.unit_hr}';
      return '$h ${loc.unit_hr} $m ${loc.unit_min}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final records1State = ref.watch(recordsProvider(widget.athlete1Id));
    final records2State = ref.watch(recordsProvider(widget.athlete2Id));

    final records1 = _getRecordsForRaceType(records1State.records);
    final records2 = _getRecordsForRaceType(records2State.records);

    final isLoading = records1State.isLoading || records2State.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Header with expand toggle
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.localizations.ratings_compare_records,
                      style: widget.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                  HugeIcon(
                    icon: _isExpanded
                        ? HugeIcons.strokeRoundedArrowUp01
                        : HugeIcons.strokeRoundedArrowDown01,
                    color: widget.theme.colorScheme.onSurface,
                    size: 24.r,
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (_isExpanded)
            isLoading
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: const CircularProgressIndicator(),
                    ),
                  )
                : _buildDisciplineCards(records1, records2),
        ],
      ),
    );
  }

  Widget _buildDisciplineCards(
    PersonalRecord? records1,
    PersonalRecord? records2,
  ) {
    final isDark = widget.theme.brightness == Brightness.dark;
    final disciplines = [
      {
        'key': 'swim',
        'label': widget.localizations.ratings_discipline_swim,
        'imagePath': isDark ? 'assets/images/swim_light.png' : 'assets/images/swim_dark.png',
      },
      {'key': 't1', 'label': 'T1'},
      {
        'key': 'bike',
        'label': widget.localizations.ratings_discipline_bike,
        'imagePath': isDark ? 'assets/images/bike_light.png' : 'assets/images/bike_dark.png',
      },
      {'key': 't2', 'label': 'T2'},
      {
        'key': 'run',
        'label': widget.localizations.ratings_discipline_run,
        'imagePath': isDark ? 'assets/images/run_light.png' : 'assets/images/run_dark.png',
      },
    ];

    final cards = <Widget>[];
    for (final d in disciplines) {
      final key = d['key'] as String;
      DisciplineRecord? record1;
      DisciplineRecord? record2;
      switch (key) {
        case 'swim':
          record1 = records1?.swim;
          record2 = records2?.swim;
        case 't1':
          record1 = records1?.t1;
          record2 = records2?.t1;
        case 'bike':
          record1 = records1?.bike;
          record2 = records2?.bike;
        case 't2':
          record1 = records1?.t2;
          record2 = records2?.t2;
        case 'run':
          record1 = records1?.run;
          record2 = records2?.run;
      }
      if (record1 == null && record2 == null) continue;
      if (cards.isNotEmpty) {
        cards.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 16.w,
            endIndent: 16.w,
            color: widget.theme.colorScheme.outlineVariant,
          ),
        );
      }
      cards.add(
        _buildDisciplineCard(
          label: d['label'] as String,
          imagePath: d['imagePath'],
          record1: record1,
          record2: record2,
        ),
      );
    }
    return Column(children: cards);
  }

  Widget _buildDisciplineCard({
    required String label,
    String? imagePath,
    DisciplineRecord? record1,
    DisciplineRecord? record2,
  }) {
    final hasBoth = record1 != null && record2 != null;

    final theme = widget.theme;
    final name1 = widget.athlete1Name;
    final name2 = widget.athlete2Name;

    // Faster athlete: full bar + green gradient; slower: proportional bar + gray gradient
    final bool isFaster1 = hasBoth ? record1.seconds <= record2.seconds : true;
    const greenGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFABEBC6), Color(0xFF27AE60)],
    );
    const grayGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFE0E0E0), Color(0xFF616161)],
    );
    const greenThumb = Color(0xFF27AE60);
    const grayThumb = Color(0xFF616161);

    final double ratio1;
    final double ratio2;
    final LinearGradient gradient1;
    final LinearGradient gradient2;
    final Color thumbColor1;
    final Color thumbColor2;

    if (hasBoth) {
      final fasterSecs = min(record1.seconds, record2.seconds);
      final slowerSecs = max(record1.seconds, record2.seconds);
      final slowerRatio = fasterSecs / slowerSecs;
      if (isFaster1) {
        ratio1 = 1.0;
        ratio2 = slowerRatio;
        gradient1 = greenGradient;
        gradient2 = grayGradient;
        thumbColor1 = greenThumb;
        thumbColor2 = grayThumb;
      } else {
        ratio1 = slowerRatio;
        ratio2 = 1.0;
        gradient1 = grayGradient;
        gradient2 = greenGradient;
        thumbColor1 = grayThumb;
        thumbColor2 = greenThumb;
      }
    } else {
      ratio1 = 1.0;
      ratio2 = 1.0;
      gradient1 = greenGradient;
      gradient2 = greenGradient;
      thumbColor1 = greenThumb;
      thumbColor2 = greenThumb;
    }

    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discipline header: icon + name
          Row(
            children: [
              if (imagePath != null) ...[
                Image.asset(
                  imagePath,
                  width: 32.r,
                  height: 32.r,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: 8.w),
              ],
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 20.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Athlete 1
          if (record1 != null)
            _buildAthleteBar(
              name: name1,
              time: record1.time,
              ratio: ratio1,
              gradient: gradient1,
              thumbColor: thumbColor1,
            ),
          if (record1 != null && record2 != null) SizedBox(height: 8.h),
          // Athlete 2
          if (record2 != null)
            _buildAthleteBar(
              name: name2,
              time: record2.time,
              ratio: ratio2,
              gradient: gradient2,
              thumbColor: thumbColor2,
            ),
          // Difference
          if (hasBoth) ...[
            SizedBox(height: 10.h),
            Center(
              child: Text(
                record1.seconds <= record2.seconds
                    ? widget.localizations.ratings_faster_by(
                        name1,
                        _formatDiffReadable(
                          (record2.seconds - record1.seconds).abs(),
                        ),
                      )
                    : widget.localizations.ratings_faster_by(
                        name2,
                        _formatDiffReadable(
                          (record1.seconds - record2.seconds).abs(),
                        ),
                      ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.titleMedium?.color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAthleteBar({
    required String name,
    required String time,
    required double ratio,
    required LinearGradient gradient,
    required Color thumbColor,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
              ),
            ),
            Text(
              time,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final thumbDiameter = 14.r;
            final trackHeight = 6.h;
            final filledWidth = (totalWidth - thumbDiameter) * ratio.clamp(0.0, 1.0);

            return SizedBox(
              height: thumbDiameter,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Track
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                  ),
                  // Filled portion
                  Positioned(
                    left: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (filledWidth > 0)
                            Container(
                              width: filledWidth,
                              height: trackHeight,
                              decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(3.r),
                                  bottomLeft: Radius.circular(3.r),
                                ),
                              ),
                            ),
                          // Thumb
                          Container(
                            width: thumbDiameter,
                            height: thumbDiameter,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.surface,
                              border: Border.all(color: thumbColor, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
