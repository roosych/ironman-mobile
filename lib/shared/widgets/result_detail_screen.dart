import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/features/results/domain/race_result.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
class ResultDetailScreen extends ConsumerWidget {
  final RaceResult result;

  const ResultDetailScreen({
    super.key,
    required this.result,
  });

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  String _getRaceTypeText(String raceType, BuildContext context) {
    final type = raceType.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    final localizations = AppLocalizations.of(context)!;

    // Check for 70.3 variations: "70.3", "703", "ironman703", "ironman_70_3"
    if (type.contains('70.3') || type.contains('703')) {
      return localizations.pace_calculator_tab_70_3; // "IRONMAN 70.3"
    } else if (type.contains('5150')) {
      return localizations.pace_calculator_tab_5150; // "5150"
    } else {
      return localizations.pace_calculator_tab_full; // "IRONMAN"
    }
  }

  Map<String, double> _getDistances(String raceType) {
    final type = raceType.toLowerCase().replaceAll(' ', '').replaceAll('_', '');

    if (type.contains('70.3') || type.contains('703')) {
      return {'swim': 1.9, 'bike': 90.0, 'run': 21.1};
    } else if (type.contains('5150')) {
      return {'swim': 1.5, 'bike': 40.0, 'run': 10.0};
    } else {
      return {'swim': 3.8, 'bike': 180.0, 'run': 42.2};
    }
  }

  Duration? _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 3) return null;

      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);

      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } catch (_) {
      return null;
    }
  }

  String _calculateSwimPace(String timeStr, double distance) {
    final duration = _parseTime(timeStr);
    if (duration == null || distance <= 0) return '';

    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) return ''; // Только блокируем нулевое время

    final pacePerHundredMetersSeconds = (totalSeconds / distance) * 0.1; // 100 meters

    final minutes = (pacePerHundredMetersSeconds / 60).floor();
    final seconds = (pacePerHundredMetersSeconds % 60).round();

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _calculateBikePace(String timeStr, double distance) {
    final duration = _parseTime(timeStr);
    if (duration == null || distance <= 0) return '';

    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) return ''; // Только блокируем нулевое время

    final hours = totalSeconds / 3600;
    final speed = distance / hours;

    return speed.toStringAsFixed(1);
  }

  String _calculateRunPace(String timeStr, double distance) {
    final duration = _parseTime(timeStr);
    if (duration == null || distance <= 0) return '';

    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) return ''; // Только блокируем нулевое время

    final pacePerKmSeconds = totalSeconds / distance;

    final minutes = (pacePerKmSeconds / 60).floor();
    final seconds = (pacePerKmSeconds % 60).round();

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          result.athleteName != null && result.athleteName!.isNotEmpty
              ? _capitalizeWords(result.athleteName!)
              : localizations.result_detail_title,
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
                        _getRaceTypeText(result.raceType, context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20, // Уменьшенный размер шрифта
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Location
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            result.location,
                            style: theme.textTheme.titleMedium?.copyWith( // Уменьшенный размер шрифта
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Date
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(result.date),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Total time
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide.none, // Remove border
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0), // Уменьшенные вертикальные отступы
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/svg/flag.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(width: 24, height: 24);
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(
                      result.totalTime,
                      style: theme.textTheme.headlineSmall?.copyWith( // Уменьшенный размер шрифта
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
              pace: _calculateSwimPace(result.swimTime, _getDistances(result.raceType)['swim']!),
              paceUnit: localizations.pace_calculator_min_per_100m,
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
              pace: _calculateBikePace(result.bikeTime, _getDistances(result.raceType)['bike']!),
              paceUnit: localizations.pace_calculator_km_per_h,
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
              pace: _calculateRunPace(result.runTime, _getDistances(result.raceType)['run']!),
              paceUnit: localizations.pace_calculator_min_per_km,
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
  final String? pace;
  final String? paceUnit;

  const _DisciplineCard({
    required this.imagePath,
    required this.label,
    required this.time,
    this.pace,
    this.paceUnit,
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
          // Time and pace
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (pace != null && pace!.isNotEmpty && paceUnit != null) ...[
                const SizedBox(height: 2),
                Text(
                  '~$pace $paceUnit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Уменьшенные вертикальные отступы
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
