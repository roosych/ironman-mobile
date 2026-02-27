import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/auth/application/auth_notifier.dart';
import 'package:ironman_mobile/features/home/presentation/pace_calculator_screen.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';

/// Home screen — initial screen of the app.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String _loginRoute = '/login';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Scaffold(
        backgroundColor: AppColors.ironmanBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.ironmanWhite),
        ),
      );
    }
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.ironmanBlack,
      body: const PaceCalculatorScreen(),
      bottomNavigationBar: _HomeBottomNav(
        isAuthenticated: isAuthenticated,
        onTap: (int index) {
          if (index == 3) {
            Navigator.of(context).pushNamed(_loginRoute);
            return;
          }
          if (isAuthenticated) {
            Navigator.of(context).pushNamed('/dashboard', arguments: index + 1);
          } else {
            const routes = ['/results', '/ratings', '/athletes'];
            Navigator.of(context).pushNamed(routes[index]);
          }
        },
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({required this.isAuthenticated, required this.onTap});

  final bool isAuthenticated;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fontSize = screenWidth < 360 ? 12.0 : 14.0;
    final iconSize = screenWidth < 360 ? 22.0 : 24.0;
    final navColor = AppColors.ironmanTextSecondary;

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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: HugeIcons.strokeRoundedStopWatch,
                label: loc.nav_results,
                fontSize: fontSize,
                iconSize: iconSize,
                color: navColor,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedAward01,
                label: loc.nav_ratings,
                fontSize: fontSize,
                iconSize: iconSize,
                color: navColor,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedUserGroup,
                label: loc.nav_athletes,
                fontSize: fontSize,
                iconSize: iconSize,
                color: navColor,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedUser,
                label: loc.nav_login,
                fontSize: fontSize,
                iconSize: iconSize,
                color: navColor,
                onTap: () => onTap(3),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: icon, size: iconSize, color: color),
              const SizedBox(height: 4),
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
