import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:country_flags/country_flags.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../../features/upcoming_races/domain/upcoming_race.dart';
import '../../features/dashboard/domain/athlete.dart';
import '../../features/dashboard/presentation/athlete_profile_screen.dart';
import '../utils/image_url_helper.dart';

/// Карточка гонки с поддержкой нескольких атлетов.
///
/// [races] — список записей на одну и ту же гонку (одинаковые raceType + location + raceDate).
/// Если записей несколько, показывает стопку аватаров атлетов и количество.
/// По тапу на блок атлетов открывает боттомшит со списком.
class GroupedUpcomingRaceCard extends StatelessWidget {
  final List<UpcomingRace> races;
  final bool showAthletes;
  final bool showBorder;

  const GroupedUpcomingRaceCard({
    super.key,
    required this.races,
    this.showAthletes = true,
    this.showBorder = false,
  });

  UpcomingRace get _race => races.first;

  List<CreatedBy> get _athletes => races
      .where((r) => r.createdBy != null)
      .map((r) => r.createdBy!)
      .toList();

  String _formatDate(String isoDate) {
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
      final raceDateOnly =
          DateTime(raceDate.year, raceDate.month, raceDate.day);
      final nowOnly = DateTime(now.year, now.month, now.day);
      final diff = raceDateOnly.difference(nowOnly).inDays;
      return diff >= 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  bool _isPast(String isoDate) {
    try {
      final raceDate = DateTime.parse(isoDate);
      final now = DateTime.now();
      final raceDateOnly =
          DateTime(raceDate.year, raceDate.month, raceDate.day);
      final nowOnly = DateTime(now.year, now.month, now.day);
      return raceDateOnly.isBefore(nowOnly);
    } catch (_) {
      return false;
    }
  }

  void _showAthletesBottomSheet(
      BuildContext context, List<CreatedBy> athletes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AthletesBottomSheet(
        race: _race,
        athletes: athletes,
        formattedDate: _formatDate(_race.raceDate),
      ),
    );
  }

  Widget _buildAvatar(CreatedBy athlete, ThemeData theme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: athlete.avatar != null
            ? Image.network(
                ImageUrlHelper.getFullImageUrl(athlete.avatar!),
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _buildDefaultAvatar(theme, size),
              )
            : _buildDefaultAvatar(theme, size),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme, double size) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: size * 0.55,
        ),
      ),
    );
  }

  Widget _buildAthletesRow(
      BuildContext context, ThemeData theme, List<CreatedBy> athletes) {
    if (athletes.isEmpty) return const SizedBox.shrink();

    const maxVisible = 3;
    final double avatarSize = 32.r;
    final double overlap = 20.w;

    final visibleAthletes = athletes.take(maxVisible).toList();
    final extraCount = athletes.length - maxVisible;
    // Ширина стопки: первый аватар + смещения остальных
    final stackWidth =
        avatarSize + (visibleAthletes.length - 1) * overlap + (extraCount > 0 ? overlap : 0);

    final bool isMultiple = athletes.length > 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isMultiple ? () => _showAthletesBottomSheet(context, athletes) : null,
      child: Row(
        children: [
          // Стопка аватаров
          SizedBox(
            width: stackWidth,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < visibleAthletes.length; i++)
                  Positioned(
                    left: i * overlap,
                    child: _buildAvatar(visibleAthletes[i], theme, avatarSize),
                  ),
                if (extraCount > 0)
                  Positioned(
                    left: visibleAthletes.length * overlap,
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: theme.cardTheme.color ??
                              theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '+$extraCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          // Имя одного атлета или количество
          Expanded(
            child: isMultiple
                ? Row(
                    children: [
                      Text(
                        '${athletes.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedUserGroup,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                        size: 16.r,
                      ),
                      const Spacer(),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                        size: 16.r,
                      ),
                    ],
                  )
                : Text(
                    athletes.first.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final daysUntil = _calculateDaysUntil(_race.raceDate);
    final isPast = _isPast(_race.raceDate);
    final athletes = _athletes;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: showBorder
            ? BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.4), width: 1)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Тип гонки
            Text(
              _race.raceTypeLabel.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
            // Флаг + локация
            Row(
              children: [
                if (_race.countryIso != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: CountryFlag.fromCountryCode(
                      _race.countryIso!,
                      height: 16.h,
                      width: 24.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  child: Text(
                    _race.location,
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
            // Дата и обратный отсчёт
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar03,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                        size: 16.r,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _formatDate(_race.raceDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
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
            // Блок атлетов
            if (showAthletes && athletes.isNotEmpty) ...[
              SizedBox(height: 12.h),
              const Divider(),
              SizedBox(height: 8.h),
              _buildAthletesRow(context, theme, athletes),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Боттомшит со списком атлетов ─────────────────────────────────────────────

class _AthletesBottomSheet extends StatelessWidget {
  final UpcomingRace race;
  final List<CreatedBy> athletes;
  final String formattedDate;

  const _AthletesBottomSheet({
    required this.race,
    required this.athletes,
    required this.formattedDate,
  });

  Widget _buildAvatar(CreatedBy athlete, ThemeData theme) {
    const double size = 44;
    return Container(
      width: size.r,
      height: size.r,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: athlete.avatar != null
            ? Image.network(
                ImageUrlHelper.getFullImageUrl(athlete.avatar!),
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _buildDefaultAvatar(theme),
              )
            : _buildDefaultAvatar(theme),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: 22.r,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
            border: Border.all(color: theme.colorScheme.outline, width: 1),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 8.h),
                width: 32.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Header: название гонки + кнопка закрытия
              Padding(
                padding: EdgeInsets.all(20.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Левая часть: тип, локация, дата
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            race.raceTypeLabel.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 20.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              if (race.countryIso != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3.r),
                                  child: CountryFlag.fromCountryCode(
                                    race.countryIso!,
                                    height: 14.h,
                                    width: 20.w,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                              ],
                              Flexible(
                                child: Text(
                                  race.location,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                                size: 14.r,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Кнопка закрытия
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: theme.colorScheme.onSurface,
                        size: 24.r,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              Divider(height: 1.h),

              // Список атлетов
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top: 12.h,
                    bottom: 16.h + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: athletes.length,
                  separatorBuilder: (_, i) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final athlete = athletes[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AthleteProfileScreen(
                              athlete: Athlete(
                                id: athlete.id,
                                name: athlete.name,
                                avatar: athlete.avatar,
                                raceCounts: RaceCounts(
                                  ironman: 0,
                                  ironman703: 0,
                                  race5150: 0,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                            color: Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.r),
                          child: Row(
                            children: [
                              _buildAvatar(athlete, theme),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Text(
                                  athlete.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
