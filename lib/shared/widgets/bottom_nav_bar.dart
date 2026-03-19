import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_button_styles.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final fontSize = screenWidth < 360 ? 12.0 : 14.0;
        final iconSize = screenWidth < 360 ? 22.0 : 24.0;
        final horizontalPadding = screenWidth < 360 ? 4.0 : 8.0;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.07),
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.07),
                          Colors.transparent,
                        ]
                      : [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.07),
                          Colors.black.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 8, left: horizontalPadding, right: horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: HugeIcons.strokeRoundedHome01,
                    label: AppLocalizations.of(context)!.nav_home,
                    fontSize: fontSize,
                    iconSize: iconSize,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: HugeIcons.strokeRoundedTimer01,
                    label: AppLocalizations.of(context)!.nav_results,
                    fontSize: fontSize,
                    iconSize: iconSize,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: HugeIcons.strokeRoundedAward01,
                    label: AppLocalizations.of(context)!.nav_ratings,
                    fontSize: fontSize,
                    iconSize: iconSize,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    icon: HugeIcons.strokeRoundedUserGroup,
                    label: AppLocalizations.of(context)!.nav_athletes,
                    fontSize: fontSize,
                    iconSize: iconSize,
                  ),
                ],
              ),
            ),
          ),
        ),
          ],
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required double fontSize,
    required double iconSize,
  }) {
    final isSelected = currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                size: iconSize,
                color: isSelected
                    ? AppButtonStyles.activeElementColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppButtonStyles.activeElementColor
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
