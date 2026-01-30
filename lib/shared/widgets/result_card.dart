import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ironman_mobile/features/results/domain/race_result.dart';
import 'package:ironman_mobile/shared/widgets/result_detail_screen.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/settings/application/locale_notifier.dart';

class ResultCard extends ConsumerWidget {
  final RaceResult result;
  final bool isMyResults;

  const ResultCard({super.key, required this.result, this.isMyResults = false});

  String _formatDate(String isoDate, WidgetRef ref) {
    try {
      final date = DateTime.parse(isoDate);
      final locale = ref.read(localeProvider);
      return DateFormat.yMd(locale.languageCode).format(date);
    } catch (_) {
      return isoDate;
    }
  }

  String _getRaceTypeText(String raceType) {
    final type = raceType.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    // Check for 70.3 variations: "70.3", "703", "ironman703", "ironman_70_3"
    if (type.contains('70.3') || type.contains('703')) {
      return 'HALF 70.3';
    } else if (type.contains('5150')) {
      return 'Olympic';
    } else {
      return 'FULL 140.6';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
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
              // Race type text
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
                    _getRaceTypeText(result.raceType),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Имя атлета (только для "Все результаты")
              if (!isMyResults &&
                  result.athleteName != null &&
                  result.athleteName!.isNotEmpty)
                Center(
                  child: Text(
                    result.athleteName!,
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
              // Location (теперь над датой)
              Center(
                child: Text(
                  result.location,
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
