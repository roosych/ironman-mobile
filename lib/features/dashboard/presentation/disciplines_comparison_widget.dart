import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
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
  bool _isExpanded = false;

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

  String _getFirstName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return parts[1]; // Возвращаем второе слово (имя)
    }
    // Если только одно слово, возвращаем его
    return fullName;
  }

  String _formatTimeDifference(int seconds1, int seconds2) {
    final diff = (seconds1 - seconds2).abs();
    final hours = diff ~/ 3600;
    final minutes = (diff % 3600) ~/ 60;
    final secs = diff % 60;
    final sign = seconds1 < seconds2 ? '-' : '+';
    return '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ironmanGray, width: 1),
      ),
      child: Column(
        children: [
          // Заголовок с кнопкой раскрытия
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.localizations.ratings_compare_records,
                      style: widget.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: (widget.theme.textTheme.titleMedium?.fontSize ?? 16) + 2,
                      ),
                    ),
                  ),
                  HugeIcon(
                    icon: _isExpanded
                        ? HugeIcons.strokeRoundedArrowUp01
                        : HugeIcons.strokeRoundedArrowDown01,
                    color: widget.theme.colorScheme.onSurface,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Содержимое таблицы
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildComparisonTable(records1, records2),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(
    PersonalRecord? records1,
    PersonalRecord? records2,
  ) {
    final disciplines = [
      {'key': 'swim', 'imagePath': 'assets/images/svg/swim.png'},
      {'key': 't1', 'label': 'T1'},
      {'key': 'bike', 'imagePath': 'assets/images/svg/bike.png'},
      {'key': 't2', 'label': 'T2'},
      {'key': 'run', 'imagePath': 'assets/images/svg/run.png'},
    ];

    return Table(
      columnWidths: {
        0: const FixedColumnWidth(60), // Фиксированная ширина для иконок
        1: const FlexColumnWidth(1), // Остальное пространство равномерно
        2: const FlexColumnWidth(1),
        3: const FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(
          color: AppColors.ironmanGray,
          width: 1,
        ),
      ),
      children: [
        // Заголовок таблицы
        TableRow(
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
          ),
          children: [
            _buildTableCell(
              '',
              isHeader: true,
              alignment: Alignment.centerLeft,
            ),
            _buildTableCell(
              _getFirstName(widget.athlete1Name),
              isHeader: true,
              alignment: Alignment.center,
            ),
            _buildTableCell(
              _getFirstName(widget.athlete2Name),
              isHeader: true,
              alignment: Alignment.center,
            ),
            _buildTableCell(
              '',
              isHeader: true,
              alignment: Alignment.center,
            ),
          ],
        ),
        // Строки дисциплин
        ...disciplines.map((discipline) {
          final key = discipline['key'] as String;
          final imagePath = discipline['imagePath'];
          final label = discipline['label'];

          DisciplineRecord? record1;
          DisciplineRecord? record2;

          switch (key) {
            case 'swim':
              record1 = records1?.swim;
              record2 = records2?.swim;
              break;
            case 't1':
              record1 = records1?.t1;
              record2 = records2?.t1;
              break;
            case 'bike':
              record1 = records1?.bike;
              record2 = records2?.bike;
              break;
            case 't2':
              record1 = records1?.t2;
              record2 = records2?.t2;
              break;
            case 'run':
              record1 = records1?.run;
              record2 = records2?.run;
              break;
          }

          final hasRecord1 = record1 != null;
          final hasRecord2 = record2 != null;
          final hasBoth = hasRecord1 && hasRecord2;

          String difference = '-';
          Color? differenceColor;

          if (hasBoth) {
            final diff = _formatTimeDifference(record1.seconds, record2.seconds);
            difference = diff;
            differenceColor = AppColors.ironmanRed;
          }

          return TableRow(
            children: [
              _buildTableCell(
                label ?? '',
                imagePath: imagePath,
                alignment: Alignment.centerLeft,
              ),
              _buildTableCell(
                hasRecord1 ? record1.time : '-',
                alignment: Alignment.center,
                color: hasRecord1 && hasBoth && record1.seconds < record2.seconds
                    ? Colors.green
                    : null,
              ),
              _buildTableCell(
                hasRecord2 ? record2.time : '-',
                alignment: Alignment.center,
                color: hasRecord2 && hasBoth && record2.seconds < record1.seconds
                    ? Colors.green
                    : null,
              ),
              _buildTableCell(
                difference,
                alignment: Alignment.center,
                color: differenceColor,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    Alignment alignment = Alignment.center,
    IconData? icon,
    String? imagePath,
    Color? color,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Align(
          alignment: alignment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: alignment == Alignment.centerLeft
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                )
              else if (icon != null) ...[
                HugeIcon(
                  icon: icon,
                  color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
              ],
              if (text.isNotEmpty)
                Flexible(
                  child: Text(
                    text,
                    style: isHeader
                        ? widget.theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )
                        : widget.theme.textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: color != null ? FontWeight.w600 : null,
                          ),
                    textAlign: alignment == Alignment.centerLeft
                        ? TextAlign.left
                        : TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

