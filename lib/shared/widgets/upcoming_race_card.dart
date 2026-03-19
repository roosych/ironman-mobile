import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:country_flags/country_flags.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import '../../features/upcoming_races/domain/upcoming_race.dart';
import '../utils/image_url_helper.dart';

class UpcomingRaceCard extends StatelessWidget {
  final UpcomingRace race;
  final bool showAthleteName;

  const UpcomingRaceCard({
    super.key,
    required this.race,
    this.showAthleteName = true,
  });

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: 20.r,
        ),
      ),
    );
  }

  String _formatDate(String isoDate, BuildContext context) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  int _calculateDaysUntil(String isoDate) {
    try {
      final raceDate = DateTime.parse(isoDate);
      final now = DateTime.now();
      final raceDateOnly = DateTime(
        raceDate.year,
        raceDate.month,
        raceDate.day,
      );
      final nowOnly = DateTime(now.year, now.month, now.day);
      final difference = raceDateOnly.difference(nowOnly).inDays;
      return difference >= 0 ? difference : 0;
    } catch (_) {
      return 0;
    }
  }

  bool _isPast(String isoDate) {
    try {
      final raceDate = DateTime.parse(isoDate);
      final now = DateTime.now();
      final raceDateOnly = DateTime(
        raceDate.year,
        raceDate.month,
        raceDate.day,
      );
      final nowOnly = DateTime(now.year, now.month, now.day);
      return raceDateOnly.isBefore(nowOnly);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysUntil = _calculateDaysUntil(race.raceDate);
    final isPast = _isPast(race.raceDate);
    final localizations = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Race type as main title
            Text(
              race.raceTypeLabel.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
            // Flag and location
            Row(
              children: [
                if (race.countryIso != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: CountryFlag.fromCountryCode(
                      race.countryIso!,
                      height: 16.h,
                      width: 24.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  child: Text(
                    race.location,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // Date and countdown section
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left side: Date only
                Expanded(
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar03,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 16.r,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _formatDate(race.raceDate, context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right side: Countdown or Completed
                Text(
                  isPast
                      ? localizations.upcoming_completed
                      : localizations.common_days(daysUntil).toUpperCase(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: isPast
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                        : daysUntil <= 14
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            // Athlete section (if available and showAthleteName is true)
            if (showAthleteName && race.createdBy != null) ...[
              SizedBox(height: 12.h),
              const Divider(),
              SizedBox(height: 8.h),
              Row(
                children: [
                  // Avatar before name
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: race.createdBy!.avatar != null
                          ? Image.network(
                              ImageUrlHelper.getFullImageUrl(race.createdBy!.avatar!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar(theme);
                              },
                            )
                          : _buildDefaultAvatar(theme),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      race.createdBy!.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

