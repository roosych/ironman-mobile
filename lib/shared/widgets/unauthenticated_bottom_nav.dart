import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Bottom navigation bar for unauthenticated users
/// Shows navigation between Results, Ratings, and Athletes screens
class UnauthenticatedBottomNav extends StatelessWidget {
  const UnauthenticatedBottomNav({
    super.key,
    this.currentIndex = -1, // -1 means no item is selected
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final fontSize = screenWidth < 360 ? 12.0 : 14.0;
    final iconSize = screenWidth < 360 ? 22.0 : 24.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ironmanBlack,
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
                isSelected: currentIndex == 0,
                onTap: () => _navigateTo(context, '/results'),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedAward01,
                label: loc.nav_ratings,
                fontSize: fontSize,
                iconSize: iconSize,
                isSelected: currentIndex == 1,
                onTap: () => _navigateTo(context, '/ratings'),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedUserGroup,
                label: loc.nav_athletes,
                fontSize: fontSize,
                iconSize: iconSize,
                isSelected: currentIndex == 2,
                onTap: () => _navigateTo(context, '/athletes'),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedUser,
                label: loc.nav_login,
                fontSize: fontSize,
                iconSize: iconSize,
                isSelected: false,
                onTap: () => _navigateTo(context, '/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != route) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.fontSize,
    required this.iconSize,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double fontSize;
  final double iconSize;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.ironmanRed
        : AppColors.ironmanTextSecondary;

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