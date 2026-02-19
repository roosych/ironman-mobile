import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ironman_mobile/features/results/domain/race_result.dart';
import 'package:ironman_mobile/shared/widgets/result_detail_screen.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';

class ResultCard extends ConsumerWidget {
  final RaceResult result;
  final bool isMyResults;
  final bool showBorder;

  const ResultCard({
    super.key,
    required this.result,
    this.isMyResults = false,
    this.showBorder = true,
  });

  String _formatDate(String isoDate, WidgetRef ref) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  String _getRaceTypePrefix(String raceType) {
    final type = raceType.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    // Check for race type variations and return prefix
    if (type.contains('70.3') || type.contains('703')) {
      return '70.3';
    } else if (type.contains('5150')) {
      return '5150';
    } else {
      return 'IM'; // ironman full
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: showBorder
            ? BorderSide(
                color: AppColors.resultsBorder,
                width: 1,
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResultDetailScreen(result: result),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верстка для "Мои результаты" и "Все результаты" (одинаковая)
              // Имя атлета (только для "Все результаты")
              if (!isMyResults &&
                  result.athleteName != null &&
                  result.athleteName!.isNotEmpty)
                Center(
                  child: Text(
                    result.athleteName!.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          (Theme.of(context).textTheme.titleMedium?.fontSize ??
                              16) +
                          3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!isMyResults &&
                  result.athleteName != null &&
                  result.athleteName!.isNotEmpty)
                const SizedBox(height: 4),
              // Location with race type prefix
              Center(
                child: Text(
                  '${_getRaceTypePrefix(result.raceType)} ${result.location}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              // Date (теперь под локацией)
              Center(
                child: Text(
                  _formatDate(result.date, ref),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              // Total Time на всю ширину
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    result.totalTime,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
