import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/dashboard/domain/athlete.dart';
import 'package:ironman_mobile/features/dashboard/application/athletes_notifier.dart';
import 'package:ironman_mobile/features/dashboard/application/athletes_state.dart';
import 'package:ironman_mobile/features/dashboard/presentation/athlete_profile_screen.dart';
import 'package:ironman_mobile/shared/widgets/unauthenticated_bottom_nav.dart';
import '../../../shared/utils/image_url_helper.dart';
import '../../../shared/utils/error_handler.dart';
import 'package:ironman_mobile/features/auth/application/auth_notifier.dart';
import 'package:ironman_mobile/features/auth/application/auth_state.dart';

class AthletesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final bool showBottomNav;

  const AthletesScreen({super.key, this.onBack, this.showBottomNav = true});

  @override
  ConsumerState<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends ConsumerState<AthletesScreen> {
  String _searchQuery = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final athletesState = ref.read(athletesProvider);
      if (athletesState.athletes.isEmpty && !athletesState.isLoading && !athletesState.hasError) {
        ref.read(athletesProvider.notifier).loadAthletes();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Athlete> _filteredAthletes(AthletesState state) {
    var filtered = state.athletes;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.name.toLowerCase().contains(query) ||
            a.id.toString().contains(query);
      }).toList();
    }

    return filtered;
  }

  bool _isUserAuthenticated() {
    final authState = ref.read(authProvider);
    return authState.status == AuthStatus.authenticated && authState.user != null;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final athletesState = ref.watch(athletesProvider);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.ironmanWhite,
              size: 24.r,
            ),
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            localizations.athletes_list_title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Поисковая строка
            Padding(
              padding: EdgeInsets.all(16.r),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: localizations.athletes_search_hint,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 24.r,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            size: 24.r,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),

            // Список атлетов
            Expanded(child: _buildAthletesList(athletesState)),
          ],
        ),
        bottomNavigationBar: (_isUserAuthenticated() || !widget.showBottomNav)
            ? null
            : const UnauthenticatedBottomNav(currentIndex: 2),
      ),
    );
  }

  Widget _buildAthleteCard(BuildContext context, Athlete athlete) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AthleteProfileScreen(athlete: athlete),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        child: Row(
          children: [
            // Аватар с бейджем
            Stack(
              children: [
                Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.ironmanLightGray,
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: athlete.avatar != null
                        ? Image.network(
                            ImageUrlHelper.getFullImageUrl(athlete.avatar!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(theme);
                            },
                          )
                        : _buildDefaultAvatar(theme),
                  ),
                ),
                // Бейдж с номером Ironman
                if (athlete.ironmanNumber != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: const BoxDecoration(
                        color: AppColors.ironmanRed,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${athlete.ironmanNumber}',
                          style: TextStyle(
                            color: AppColors.ironmanWhite,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            // Имя и IRONMAN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athlete.name.toUpperCase(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 18.sp,
                    ),
                  ),
                  if (athlete.raceCounts.ironman > 0) ...[
                    SizedBox(height: 4.h),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: 'IRONMAN',
                            style: TextStyle(
                              color: AppColors.ironmanWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' x${athlete.raceCounts.ironman}',
                            style: TextStyle(
                              color: AppColors.ironmanRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Стрелка навигации
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: AppColors.ironmanWhite,
              size: 20.r,
            ),
          ],
        ),
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
          size: 28.r,
        ),
      ),
    );
  }

  Widget _buildAthletesList(AthletesState state) {
    if (state.isLoading || (state.athletes.isEmpty && !state.hasError)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && !state.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.error != null
                    ? ErrorHandler.localizeErrorKey(state.error!, AppLocalizations.of(context)!)
                    : AppLocalizations.of(context)!.common_loading_error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  ref.read(athletesProvider.notifier).loadAthletes();
                },
                child: Text(AppLocalizations.of(context)!.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(athletesProvider.notifier).loadAthletes();
      },
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: _filteredAthletes(state).length,
        itemBuilder: (context, index) {
          return _buildAthleteCard(context, _filteredAthletes(state)[index]);
        },
      ),
    );
  }
}
