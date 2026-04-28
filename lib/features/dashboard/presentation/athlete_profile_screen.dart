import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:country_flags/country_flags.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/dashboard/domain/athlete.dart';
import 'package:ironman_mobile/features/dashboard/application/athlete_detail_notifier.dart';
import 'package:ironman_mobile/features/dashboard/application/athlete_detail_state.dart';
import '../../../shared/utils/image_url_helper.dart';
import 'package:ironman_mobile/features/dashboard/application/records_notifier.dart';
import 'package:ironman_mobile/features/dashboard/application/records_state.dart';
import 'package:ironman_mobile/features/results/application/race_results_notifier.dart';
import 'package:ironman_mobile/features/results/application/race_results_state.dart';
import 'package:ironman_mobile/shared/widgets/result_card.dart';
import 'package:ironman_mobile/shared/widgets/result_detail_screen.dart';
import 'package:ironman_mobile/features/results/domain/race_result.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/utils/alert_helper.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_notifier.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_state.dart';
import 'package:ironman_mobile/shared/widgets/upcoming_race_card.dart';
import 'package:ironman_mobile/features/dashboard/application/athlete_photos_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'athlete_photo_viewer_screen.dart';

class AthleteProfileScreen extends ConsumerStatefulWidget {
  final Athlete athlete;

  const AthleteProfileScreen({super.key, required this.athlete});

  @override
  ConsumerState<AthleteProfileScreen> createState() =>
      _AthleteProfileScreenState();
}

class _AthleteProfileScreenState extends ConsumerState<AthleteProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);

    // Загружаем все данные при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAllData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Убрана автоматическая загрузка при didChangeDependencies, чтобы избежать бесконечных циклов
    // Данные загружаются только при initState
  }

  void _loadAllData() {
    if (mounted) {
      // Загружаем все данные параллельно
      _loadAthleteDetail();
      _loadResults();
      _loadRecords();
      _loadUpcomingRaces();
      _loadPhotos();
    }
  }

  void _loadPhotos() {
    if (mounted) {
      ref.read(athletePhotosProvider(widget.athlete.id).notifier).loadPhotos();
    }
  }

  void _loadAthleteDetail() {
    if (mounted) {
      ref
          .read(athleteDetailProvider(widget.athlete.id).notifier)
          .loadAthleteDetail();
    }
  }

  void _loadResults() {
    if (mounted) {
      ref
          .read(athleteRaceResultsProvider(widget.athlete.id).notifier)
          .loadResults(widget.athlete.id);
    }
  }

  void _loadRecords() {
    if (mounted) {
      ref.read(recordsProvider(widget.athlete.id).notifier).loadRecords();
    }
  }

  void _loadUpcomingRaces() {
    if (!mounted) return;
    
    // Используем отдельный провайдер для гонок атлета
    ref.read(athleteUpcomingRacesProvider(widget.athlete.id).notifier).loadUpcomingRaces(
      userProfileId: widget.athlete.id,
      onlyFuture: true, // Только будущие гонки
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Проверяем состояние загрузки всех данных
    final athleteDetailState = ref.watch(athleteDetailProvider(widget.athlete.id));
    final resultsState =
        ref.watch(athleteRaceResultsProvider(widget.athlete.id));
    final recordsState = ref.watch(recordsProvider(widget.athlete.id));
    final upcomingRacesState = ref.watch(athleteUpcomingRacesProvider(widget.athlete.id));

    // Показываем общий лоадер, если загружаются основные данные и они еще не загружены
    final isLoadingInitialData = 
        (athleteDetailState.isLoading && athleteDetailState.athlete == null) ||
        (resultsState.isLoading && resultsState.results.isEmpty) ||
        (recordsState.isLoading && recordsState.records == null) ||
        (upcomingRacesState.isLoading && upcomingRacesState.races.isEmpty);

    if (isLoadingInitialData) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24.r,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            localizations.athlete_profile_title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              leading: IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: theme.colorScheme.onSurface,
                  size: 24.r,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                localizations.athlete_profile_title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
              ),
              centerTitle: true,
              pinned: true,
              floating: false,
              snap: false,
              forceElevated: false,
            ),
            // Профиль атлета
            SliverToBoxAdapter(child: _buildProfileHeader(context, theme)),
            // Закрепленные табы
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: Container(
                  margin: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    top: 16.h,
                    bottom: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.all(4.r),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryGradientStart,
                          AppColors.primaryGradientEnd,
                        ],
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(
                        icon: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (!mounted) {
                              return const SizedBox.shrink();
                            }
                            final currentTheme = Theme.of(context);
                            final isSelected = _tabController.index == 0;
                            return HugeIcon(
                              icon: HugeIcons.strokeRoundedUser,
                              size: 20.r,
                              color: isSelected
                                  ? Colors.white
                                  : currentTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            );
                          },
                        ),
                      ),
                      Tab(
                        icon: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (!mounted) {
                              return const SizedBox.shrink();
                            }
                            final currentTheme = Theme.of(context);
                            final isSelected = _tabController.index == 1;
                            return HugeIcon(
                              icon: HugeIcons.strokeRoundedTimer01,
                              size: 20.r,
                              color: isSelected
                                  ? Colors.white
                                  : currentTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            );
                          },
                        ),
                      ),
                      Tab(
                        icon: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (!mounted) {
                              return const SizedBox.shrink();
                            }
                            final currentTheme = Theme.of(context);
                            final isSelected = _tabController.index == 2;
                            return HugeIcon(
                              icon: HugeIcons.strokeRoundedAward01,
                              size: 20.r,
                              color: isSelected
                                  ? Colors.white
                                  : currentTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            );
                          },
                        ),
                      ),
                      Tab(
                        icon: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (!mounted) {
                              return const SizedBox.shrink();
                            }
                            final currentTheme = Theme.of(context);
                            final isSelected = _tabController.index == 3;
                            return HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              size: 20.r,
                              color: isSelected
                                  ? Colors.white
                                  : currentTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            );
                          },
                        ),
                      ),
                      Tab(
                        icon: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            if (!mounted) {
                              return const SizedBox.shrink();
                            }
                            final currentTheme = Theme.of(context);
                            final isSelected = _tabController.index == 4;
                            return HugeIcon(
                              icon: HugeIcons.strokeRoundedImage01,
                              size: 20.r,
                              color: isSelected
                                  ? Colors.white
                                  : currentTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(context, theme, localizations),
            _buildResultsTab(context, theme, localizations),
            _buildPersonalBestsTab(context, theme, localizations),
            _buildUpcomingRacesTab(context, theme, localizations),
            _buildPhotosTab(context, theme, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme) {
    final athleteDetailState = ref.watch(
      athleteDetailProvider(widget.athlete.id),
    );
    final athlete = athleteDetailState.athlete ?? widget.athlete;
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            children: [
              // Аватар слева, весь контент справа
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Аватар с бейджем
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100.r,
                        height: 100.r,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: athlete.avatar != null
                              ? Image.network(
                                  ImageUrlHelper.getFullImageUrl(athlete.avatar!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar(theme, 100.r);
                                  },
                                )
                              : _buildDefaultAvatar(theme, 90.r),
                        ),
                      ),
                      if (athlete.ironmanNumber != null && athlete.ironmanNumber != 0)
                        Positioned(
                          bottom: 0.h,
                          right: 0.w,
                          child: Container(
                            width: 32.r,
                            height: 32.r,
                            decoration: const BoxDecoration(
                              color: AppColors.ironmanRed,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${athlete.ironmanNumber}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 20.w),
                  // Весь правый контент
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Имя с флагом
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (athlete.countryIso != null) ...[
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3.r),
                                  child: CountryFlag.fromCountryCode(
                                    athlete.countryIso!.toUpperCase(),
                                    height: 16,
                                    width: 22,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                            ],
                            Expanded(
                              child: Text(
                                athlete.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22.sp,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Страна
                        // if (athlete.countryIso != null) ...[
                        //   SizedBox(height: 8.h),
                        //   Row(
                        //     children: [
                        //       ClipRRect(
                        //         borderRadius: BorderRadius.circular(3.r),
                        //         child: CountryFlag.fromCountryCode(
                        //           athlete.countryIso!.toUpperCase(),
                        //           height: 14,
                        //           width: 20,
                        //         ),
                        //       ),
                        //       SizedBox(width: 6.w),
                        //       Flexible(
                        //         child: Text(
                        //           Countries.getCountryName(athlete.countryIso) ?? athlete.countryIso!,
                        //           style: theme.textTheme.bodyMedium?.copyWith(
                        //             color: AppColors.ironmanWhite,
                        //             fontSize: 15.sp,
                        //             fontWeight: FontWeight.w500,
                        //           ),
                        //           overflow: TextOverflow.ellipsis,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ],
                        SizedBox(height: 12.h),
                        // Блок количества гонок
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              // FULL
                              Expanded(
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IM',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${athlete.raceCounts.ironman}',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24.sp,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        localizations.home_finishes_count(athlete.raceCounts.ironman),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ),
                              // Разделитель
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: VerticalDivider(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                  thickness: 1,
                                  width: 1,
                                ),
                              ),
                              // HALF
                              Expanded(
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '70.3',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${athlete.raceCounts.ironman703}',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24.sp,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        localizations.home_finishes_count(athlete.raceCounts.ironman703),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Блок рейтинга (показываем только если есть данные рейтинга)
        if (athlete.ranking != null &&
            (athlete.ranking!.ironman != null || athlete.ranking!.ironman703 != null)) ...[
          SizedBox(height: athlete.countryIso != null ? 16.h : 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.athlete_rating_title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(24.r),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            localizations.athlete_rating_title,
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20.sp,
                                                ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: HugeIcon(
                                            icon: HugeIcons.strokeRoundedCancel01,
                                            size: 24.r,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          onPressed: () => Navigator.of(context).pop(),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      localizations.athlete_rating_info,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 20.r,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildRatingBlock(context, theme, athlete),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final athleteDetailState = ref.watch(
      athleteDetailProvider(widget.athlete.id),
    );

    // Слушаем ошибки
    ref.listen<AthleteDetailState>(athleteDetailProvider(widget.athlete.id), (
      previous,
      next,
    ) {
      if (next.hasError && previous?.error != next.error && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AlertHelper.showError(
            context,
            next.error ?? localizations.common_loading_error,
            buttonText: localizations.error_ok,
          );
        });
      }
    });

    if (athleteDetailState.isLoading && athleteDetailState.athlete == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final athlete = athleteDetailState.athlete ?? widget.athlete;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(athleteDetailProvider(widget.athlete.id).notifier)
            .loadAthleteDetail();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.h,
          bottom: 100.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.athlete_profile_info_tab,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
              ),
            ),
            SizedBox(height: 16.h),
            // Bio
            _buildBioCard(
              context,
              theme,
              localizations,
              athlete.bio,
            ),
            SizedBox(height: 16.h),
            // Social Links
            _buildSocialLinksCard(
              context,
              theme,
              localizations,
              athlete.socialLinks ??
                  const SocialLinks(
                    strava: null,
                    facebook: null,
                    instagram: null,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
    String? bio,
  ) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedEdit01,
                color: AppColors.ironmanRed,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                localizations.athlete_profile_bio,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (bio != null)
            Text(bio, style: theme.textTheme.bodyLarge)
          else
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                localizations.athlete_profile_info_not_available,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
    SocialLinks socialLinks,
  ) {
    final hasAny = socialLinks.strava != null ||
        socialLinks.facebook != null ||
        socialLinks.instagram != null;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedShare01,
                color: AppColors.ironmanRed,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                localizations.athlete_profile_social_links,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (hasAny)
            Row(
              children: [
                if (socialLinks.instagram != null)
                  _SocialIconButton(
                    value: socialLinks.instagram!,
                    platform: 'instagram',
                    icon: HugeIcons.strokeRoundedInstagram,
                    label: 'Instagram',
                    color: const Color(0xFFE1306C),
                  ),
                if (socialLinks.instagram != null && socialLinks.facebook != null)
                  SizedBox(width: 12.w),
                if (socialLinks.facebook != null)
                  _SocialIconButton(
                    value: socialLinks.facebook!,
                    platform: 'facebook',
                    icon: HugeIcons.strokeRoundedFacebook01,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                  ),
                if (socialLinks.facebook != null && socialLinks.strava != null)
                  SizedBox(width: 12.w),
                if (socialLinks.strava != null && socialLinks.instagram != null && socialLinks.facebook == null)
                  SizedBox(width: 12.w),
                if (socialLinks.strava != null)
                  _SocialIconButton(
                    value: socialLinks.strava!,
                    platform: 'strava',
                    icon: HugeIcons.strokeRoundedActivity01,
                    label: 'Strava',
                    color: const Color(0xFFFC4C02),
                  ),
              ],
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                localizations.athlete_profile_social_links_not_specified,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final resultsState = ref.watch(athleteRaceResultsProvider(widget.athlete.id));

    // Слушаем ошибки
    ref.listen<RaceResultsState>(athleteRaceResultsProvider(widget.athlete.id), (previous, next) {
      if (next.hasError && previous?.error != next.error && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ErrorHandler.showError(context, next.error ?? localizations.common_loading_error);
        });
      }
    });

    // Анимация появления контента
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey('${widget.athlete.id}_${resultsState.results.length}'),
        child: _buildResultsContent(
          context,
          theme,
          localizations,
          resultsState,
        ),
      ),
    );
  }

  Widget _buildResultsContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
    RaceResultsState resultsState,
  ) {
    // Фильтруем только подтвержденные результаты
    final approvedResults = resultsState.results.where((r) => r.isApproved).toList();
    
    if (resultsState.isLoading && resultsState.results.isEmpty) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (resultsState.hasError && resultsState.results.isEmpty) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                resultsState.error ?? localizations.common_loading_error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(athleteRaceResultsProvider(widget.athlete.id).notifier)
                      .loadResults(widget.athlete.id);
                },
                child: Text(localizations.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (approvedResults.isEmpty && !resultsState.isLoading) {
      return Center(
        key: const ValueKey('empty'),
        child: Text(
          localizations.results_no_results,
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      key: ValueKey('results_${approvedResults.length}'),
      onRefresh: () async {
        await ref
            .read(athleteRaceResultsProvider(widget.athlete.id).notifier)
            .loadResults(widget.athlete.id);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 16.h,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                localizations.athlete_profile_results_tab,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 16.h,
              bottom: 100.h,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: ResultCard(
                      result: approvedResults[index],
                      isMyResults: true,
                      showBorder: false,
                    ),
                  );
                },
                childCount: approvedResults.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestsTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final recordsState = ref.watch(recordsProvider(widget.athlete.id));
    final resultsState = ref.watch(athleteRaceResultsProvider(widget.athlete.id));

    // Слушаем ошибки
    ref.listen<RecordsState>(recordsProvider(widget.athlete.id), (
      previous,
      next,
    ) {
      if (next.hasError && previous?.error != next.error && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AlertHelper.showError(
            context,
            next.error ?? localizations.common_loading_error,
            buttonText: localizations.error_ok,
          );
        });
      }
    });

    // Данные уже загружены при открытии экрана, не загружаем повторно

    if (recordsState.hasError && recordsState.records == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                recordsState.error ?? localizations.common_loading_error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(recordsProvider(widget.athlete.id).notifier)
                      .loadRecords();
                },
                child: Text(localizations.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    final records = recordsState.records;
    final personalBestsData = records?.toPersonalBestsFormat();

    // Функция для проверки наличия данных в карточке типа гонки
    bool hasRaceTypeData(Map<String, dynamic>? raceTypeData) {
      if (raceTypeData == null) return false;
      final swim = raceTypeData['swim'] as Map<String, dynamic>?;
      final bike = raceTypeData['bike'] as Map<String, dynamic>?;
      final run = raceTypeData['run'] as Map<String, dynamic>?;
      return swim != null || bike != null || run != null;
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(recordsProvider(widget.athlete.id).notifier)
            .loadRecords();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.h,
          bottom: 100.h,
        ),
        child: personalBestsData != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    localizations.home_personal_bests,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Ironman
                  if (hasRaceTypeData(
                    personalBestsData['ironman'] as Map<String, dynamic>?,
                  ))
                    _PersonalBestsCard(
                      title: 'Ironman',
                      data:
                          personalBestsData['ironman'] as Map<String, dynamic>,
                      athleteId: widget.athlete.id,
                      results: resultsState.results,
                    ),
                  if (hasRaceTypeData(
                    personalBestsData['ironman'] as Map<String, dynamic>?,
                  ))
                    SizedBox(height: 12.h),
                  // Ironman 70.3
                  if (hasRaceTypeData(
                    personalBestsData['ironman_70_3'] as Map<String, dynamic>?,
                  ))
                    _PersonalBestsCard(
                      title: 'Ironman 70.3',
                      data:
                          personalBestsData['ironman_70_3']
                              as Map<String, dynamic>,
                      athleteId: widget.athlete.id,
                      results: resultsState.results,
                    ),
                  if (hasRaceTypeData(
                    personalBestsData['ironman_70_3'] as Map<String, dynamic>?,
                  ))
                    SizedBox(height: 12.h),
                  // 5150
                  if (hasRaceTypeData(
                    personalBestsData['5150'] as Map<String, dynamic>?,
                  ))
                    _PersonalBestsCard(
                      title: '5150',
                      data: personalBestsData['5150'] as Map<String, dynamic>,
                      athleteId: widget.athlete.id,
                      results: resultsState.results,
                    ),
                ],
              )
            : Center(
                child: Text('Нет данных', style: theme.textTheme.bodyLarge),
              ),
      ),
    );
  }

  Widget _buildUpcomingRacesTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final upcomingRacesState = ref.watch(athleteUpcomingRacesProvider(widget.athlete.id));

    // Слушаем ошибки
    ref.listen<UpcomingRacesState>(athleteUpcomingRacesProvider(widget.athlete.id), (previous, next) {
      if (next.hasError && previous?.error != next.error && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AlertHelper.showError(
            context,
            next.error ?? localizations.common_loading_error,
            buttonText: localizations.error_ok,
          );
        });
      }
    });

    // Данные уже загружены при открытии экрана, не показываем лоадер

    if (upcomingRacesState.hasError && upcomingRacesState.races.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                upcomingRacesState.error ?? localizations.common_loading_error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  ref.read(athleteUpcomingRacesProvider(widget.athlete.id).notifier).loadUpcomingRaces(
                    userProfileId: widget.athlete.id,
                    onlyFuture: true,
                  );
                },
                child: Text(localizations.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(athleteUpcomingRacesProvider(widget.athlete.id).notifier).loadUpcomingRaces(
          userProfileId: widget.athlete.id,
          onlyFuture: true,
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 16.h,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                localizations.home_upcoming_races,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),
          if (upcomingRacesState.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  localizations.home_no_upcoming_races,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 100.0,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: UpcomingRaceCard(
                        race: upcomingRacesState.races[index],
                        showAthleteName: false,
                      ),
                    );
                  },
                  childCount: upcomingRacesState.races.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme, double size) {
    return Container(
      width: size,
      height: size,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildRatingBlock(BuildContext context, ThemeData theme, Athlete athlete) {
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide.none,
        ),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Рейтинги
            Column(
              children: [
                if (athlete.ranking!.ironman != null)
                  _buildRatingRow(
                    context,
                    theme,
                    'IRONMAN',
                    athlete.ranking!.ironman!.position,
                    athlete.ranking!.ironman!.total,
                  ),
                if (athlete.ranking!.ironman != null && athlete.ranking!.ironman703 != null)
                  SizedBox(height: 8.h),
                if (athlete.ranking!.ironman703 != null)
                  _buildRatingRow(
                    context,
                    theme,
                    'IRONMAN 70.3',
                    athlete.ranking!.ironman703!.position,
                    athlete.ranking!.ironman703!.total,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context, ThemeData theme, String raceType, int position, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          raceType,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: position.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                ),
              ),
              TextSpan(
                text: '/$total',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final photosState = ref.watch(athletePhotosProvider(widget.athlete.id));

    if (photosState.isLoading && photosState.photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (photosState.hasError && photosState.photos.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                photosState.error ?? localizations.common_loading_error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadPhotos,
                child: Text(localizations.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (photosState.photos.isEmpty) {
      return Center(
        child: Text(
          localizations.athlete_profile_no_photos,
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadPhotos(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent * 0.8) {
            ref
                .read(athletePhotosProvider(widget.athlete.id).notifier)
                .loadNextPage();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(16.r),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.w,
                  mainAxisSpacing: 4.h,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final photo = photosState.photos[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AthletePhotoViewerScreen(
                              photos: photosState.photos,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: Image.network(
                          ImageUrlHelper.getFullImageUrl(photo.url),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedImageNotFound01,
                                  color: Colors.white38,
                                  size: 32.r,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  childCount: photosState.photos.length,
                ),
              ),
            ),
            if (photosState.isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
      ),
    );
  }
}

// Вспомогательные функции для расчёта темпа
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
  final pacePerHundredMetersSeconds = (totalSeconds / distance) * 0.1;

  final minutes = (pacePerHundredMetersSeconds / 60).floor();
  final seconds = (pacePerHundredMetersSeconds % 60).round();

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String _calculateBikePace(String timeStr, double distance) {
  final duration = _parseTime(timeStr);
  if (duration == null || distance <= 0) return '';

  final hours = duration.inSeconds / 3600;
  final speed = distance / hours;

  return speed.toStringAsFixed(1);
}

String _calculateRunPace(String timeStr, double distance) {
  final duration = _parseTime(timeStr);
  if (duration == null || distance <= 0) return '';

  final totalSeconds = duration.inSeconds;
  final pacePerKmSeconds = totalSeconds / distance;

  final minutes = (pacePerKmSeconds / 60).floor();
  final seconds = (pacePerKmSeconds % 60).round();

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class _PersonalBestsCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final int athleteId;
  final List<RaceResult>? results;

  const _PersonalBestsCard({
    required this.title,
    required this.data,
    required this.athleteId,
    this.results,
  });

  String _getRaceTypeText(String title) {
    switch (title.toLowerCase()) {
      case 'ironman':
        return 'IRONMAN';
      case 'ironman 70.3':
        return 'IRONMAN 70.3';
      case '5150':
        return '5150';
      default:
        return 'IRONMAN';
    }
  }

  Map<String, dynamic>? _getDisciplineData(String discipline) {
    final value = data[discipline];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? _getTime(String discipline) {
    return _getDisciplineData(discipline)?['time'] as String?;
  }

  Map<String, dynamic>? _getRace(String discipline) {
    final race = _getDisciplineData(discipline)?['race'];
    if (race is Map<String, dynamic>) return race;
    if (race is Map) return Map<String, dynamic>.from(race);
    return null;
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final swimTime = _getTime('swim');
    final bikeTime = _getTime('bike');
    final runTime = _getTime('run');
    final swimRace = _getRace('swim');
    final bikeRace = _getRace('bike');
    final runRace = _getRace('run');

    return Padding(
      padding: EdgeInsets.all(6.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered race type text
          Center(
            child: Container(
              padding: EdgeInsets.only(bottom: 4.h),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.ironmanRed,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _getRaceTypeText(title),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Swim
          if (swimTime != null)
            _DisciplineRow(
              imagePath: Theme.of(context).brightness == Brightness.dark ? 'assets/images/swim_light.png' : 'assets/images/swim_dark.png',
              time: swimTime,
              date: swimRace?['race_date'] as String?,
              location: swimRace?['location'] as String?,
              formatDate: _formatDate,
              raceType: title,
              athleteId: athleteId,
              results: results,
            ),
          if (swimTime != null && (bikeTime != null || runTime != null))
            SizedBox(height: 8.h),
          // Bike
          if (bikeTime != null)
            _DisciplineRow(
              imagePath: Theme.of(context).brightness == Brightness.dark ? 'assets/images/bike_light.png' : 'assets/images/bike_dark.png',
              time: bikeTime,
              date: bikeRace?['race_date'] as String?,
              location: bikeRace?['location'] as String?,
              formatDate: _formatDate,
              raceType: title,
              athleteId: athleteId,
              results: results,
            ),
          if (bikeTime != null && runTime != null) SizedBox(height: 8.h),
          // Run
          if (runTime != null)
            _DisciplineRow(
              imagePath: Theme.of(context).brightness == Brightness.dark ? 'assets/images/run_light.png' : 'assets/images/run_dark.png',
              time: runTime,
              date: runRace?['race_date'] as String?,
              location: runRace?['location'] as String?,
              formatDate: _formatDate,
              raceType: title,
              athleteId: athleteId,
              results: results,
            ),
          if (swimTime == null && bikeTime == null && runTime == null)
            Text(
              AppLocalizations.of(context)!.common_no_data,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 88.h;

  @override
  double get maxExtent => 88.h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

class _DisciplineRow extends StatelessWidget {
  final String imagePath;
  final String time;
  final String? date;
  final String? location;
  final String Function(String?) formatDate;
  final String raceType;
  final int athleteId;
  final List<RaceResult>? results;

  const _DisciplineRow({
    required this.imagePath,
    required this.time,
    this.date,
    this.location,
    required this.formatDate,
    required this.raceType,
    required this.athleteId,
    this.results,
  });

  String _getDisciplineFromImagePath() {
    if (imagePath.contains('swim')) return 'swim';
    if (imagePath.contains('bike')) return 'bike';
    if (imagePath.contains('run')) return 'run';
    return 'swim';
  }

  String _calculatePace(BuildContext context) {
    final discipline = _getDisciplineFromImagePath();
    final distances = _getDistances(raceType);
    final distance = distances[discipline] ?? 0.0;

    switch (discipline) {
      case 'swim':
        return _calculateSwimPace(time, distance);
      case 'bike':
        return _calculateBikePace(time, distance);
      case 'run':
        return _calculateRunPace(time, distance);
      default:
        return '';
    }
  }

  String _getPaceUnit(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final discipline = _getDisciplineFromImagePath();

    switch (discipline) {
      case 'swim':
        return localizations.pace_calculator_min_per_100m;
      case 'bike':
        return localizations.pace_calculator_km_per_h;
      case 'run':
        return localizations.pace_calculator_min_per_km;
      default:
        return '';
    }
  }

  RaceResult? _findResult() {
    if (results == null || date == null || location == null) return null;

    for (final result in results!) {
      if (result.isApproved && result.date == date && result.location == location) {
        return result;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final result = _findResult();

    return InkWell(
      onTap: result != null
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResultDetailScreen(result: result),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(12.r),
      splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        margin: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Основное содержимое
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Верхняя строка: иконка слева, время справа
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        imagePath,
                        width: 40.w,
                        height: 40.h,
                        fit: BoxFit.contain,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            time,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24.sp,
                            ),
                          ),
                          Builder(
                            builder: (BuildContext context) {
                              final pace = _calculatePace(context);
                              final paceUnit = _getPaceUnit(context);
                              if (pace.isNotEmpty && paceUnit.isNotEmpty) {
                                return Padding(
                                  padding: EdgeInsets.only(top: 2.h),
                                  child: Text(
                                    '$pace $paceUnit',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Нижняя строка: локация слева, дата справа
                  if (date != null || location != null) ...[
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (location != null)
                          Expanded(
                            child: Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedLocation01,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  size: 13.r,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    location!.isEmpty ? '' : location![0].toUpperCase() + location!.substring(1),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 13.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        if (date != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 13.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                formatDate(date),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Шеврон справа
            if (result != null) ...[
              SizedBox(width: 12.w),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20.r,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Кнопка-иконка соцсети с переходом по URL
class _SocialIconButton extends StatelessWidget {
  final String value;
  final String platform; // 'instagram' | 'strava' | 'facebook'
  final IconData icon;
  final String label;
  final Color color;

  const _SocialIconButton({
    required this.value,
    required this.platform,
    required this.icon,
    required this.label,
    required this.color,
  });

  String _buildUrl() {
    final v = value.trim().replaceAll(RegExp(r'^@'), '');
    switch (platform) {
      case 'instagram':
        return 'https://instagram.com/$v';
      case 'strava':
        return 'https://www.strava.com/athletes/$v';
      case 'facebook':
        return 'https://facebook.com/$v';
      default:
        return v.startsWith('http') ? v : 'https://$v';
    }
  }

  Future<void> _launch() async {
    final uri = Uri.tryParse(_buildUrl());
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: icon,
              color: color,
              size: 24.r,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
