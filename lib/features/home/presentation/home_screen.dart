import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/auth/application/auth_notifier.dart';
import 'package:ironman_mobile/features/home/presentation/pace_calculator_screen.dart';
import 'package:ironman_mobile/features/dashboard/presentation/results_screen.dart';
import 'package:ironman_mobile/features/dashboard/presentation/ratings_screen.dart';
import 'package:ironman_mobile/features/dashboard/presentation/athletes_screen.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';

/// Home screen — initial screen of the app (unauthenticated).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const String _loginRoute = '/login';

  // 0 = PaceCalculator, 1 = Results, 2 = Ratings, 3 = Athletes
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const PaceCalculatorScreen(key: ValueKey('pace')),
      ResultsScreen(key: const ValueKey('results'), onBack: _backToHome, showBottomNav: false),
      RatingsScreen(key: const ValueKey('ratings'), onBack: _backToHome, showBottomNav: false),
      AthletesScreen(key: const ValueKey('athletes'), onBack: _backToHome, showBottomNav: false),
    ];
  }

  void _backToHome() {
    setState(() => _currentIndex = 0);
  }

  void _onNavTap(int navIndex) {
    if (navIndex == 3) {
      // Login — пушим отдельный экран
      Navigator.of(context).pushNamed(_loginRoute);
      return;
    }
    // navIndex 0→Results(1), 1→Ratings(2), 2→Athletes(3)
    final screenIndex = navIndex + 1;
    if (_currentIndex != screenIndex) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _currentIndex = screenIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Scaffold(
        backgroundColor: AppColors.ironmanBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.ironmanWhite),
        ),
      );
    }

    // Активный индекс для навбара: 0→PaceCalc(нет подсветки), 1→nav0, 2→nav1, 3→nav2
    final navActiveIndex = _currentIndex == 0 ? -1 : _currentIndex - 1;

    return Scaffold(
      backgroundColor: AppColors.ironmanBlack,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _screens.length,
          (i) => ExcludeFocus(
            excluding: i != _currentIndex,
            child: _screens[i],
          ),
        ),
      ),
      bottomNavigationBar: _HomeBottomNav(
        activeIndex: navActiveIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({required this.activeIndex, required this.onTap});

  final int activeIndex; // -1 = ничего не выбрано
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final fontSize = screenWidth < 360 ? 12.0 : 14.0;
    final iconSize = screenWidth < 360 ? 22.0 : 24.0;

    final items = [
      (icon: HugeIcons.strokeRoundedStopWatch, label: loc.nav_results),
      (icon: HugeIcons.strokeRoundedAward01, label: loc.nav_ratings),
      (icon: HugeIcons.strokeRoundedUserGroup, label: loc.nav_athletes),
      // (icon: HugeIcons.strokeRoundedUser, label: loc.nav_login), // icon+text version
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ironmanBlack,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: AppColors.ironmanBlack.withValues(alpha: 0.5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...List.generate(items.length, (i) {
                final isActive = i == activeIndex;
                final color = isActive
                    ? AppColors.ironmanRed
                    : AppColors.ironmanTextSecondary;
                return _NavItem(
                  icon: items[i].icon,
                  label: items[i].label,
                  fontSize: fontSize,
                  iconSize: iconSize,
                  color: color,
                  onTap: () => onTap(i),
                );
              }),
              // Login — только иконка с градиентным фоном
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(3),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(13.r),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryGradientStart,
                                AppColors.primaryGradientEnd,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Transform.scale(
                            scaleX: -1,
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedLogin01,
                              size: iconSize,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.fontSize,
    required this.iconSize,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double fontSize;
  final double iconSize;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: icon, size: iconSize, color: color),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
