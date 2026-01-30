import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/features/results/domain/race_result.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/settings/application/locale_notifier.dart';

class ResultDetailScreen extends ConsumerWidget {
  final RaceResult result;

  const ResultDetailScreen({
    super.key,
    required this.result,
  });

  String _formatDate(String isoDate, WidgetRef ref) {
    try {
      final date = DateTime.parse(isoDate);
      final locale = ref.read(localeProvider);
      return DateFormat.yMMMMd(locale.languageCode).format(date);
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
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.result_detail_title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Race header
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    // Race type text
                    Container(
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
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Location
                    Text(
                      result.location,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Date
                    Text(
                      _formatDate(result.date, ref),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Total time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/svg/flag.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(width: 32, height: 32);
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(
                      result.totalTime,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Disciplines section
            Text(
              localizations.result_disciplines,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Swim
            _DisciplineCard(
              imagePath: 'assets/images/svg/swim.png',
              label: AppLocalizations.of(context)!.result_swim,
              time: result.swimTime,
            ),
            const SizedBox(height: 8),

            // T1
            _TransitionCard(
              label: 'T1',
              time: result.t1Time,
            ),
            const SizedBox(height: 8),

            // Bike
            _DisciplineCard(
              imagePath: 'assets/images/svg/bike.png',
              label: AppLocalizations.of(context)!.result_bike,
              time: result.bikeTime,
            ),
            const SizedBox(height: 8),

            // T2
            _TransitionCard(
              label: 'T2',
              time: result.t2Time,
            ),
            const SizedBox(height: 8),

            // Run
            _DisciplineCard(
              imagePath: 'assets/images/svg/run.png',
              label: AppLocalizations.of(context)!.result_run,
              time: result.runTime,
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _DisciplineCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final String time;

  const _DisciplineCard({
    required this.imagePath,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.ironmanGray,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Image.asset(
            imagePath,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 32, height: 32);
            },
          ),
          const SizedBox(width: 16),
          // Label
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Time
          Text(
            time,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransitionCard extends StatelessWidget {
  final String label;
  final String time;

  const _TransitionCard({
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeftRight,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              time,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
