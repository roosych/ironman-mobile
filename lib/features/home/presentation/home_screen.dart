import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/auth/application/auth_notifier.dart';
import 'package:ironman_mobile/features/settings/application/locale_notifier.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/utils/alert_helper.dart';

/// Home screen — initial screen of the app.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String _paceCalculatorRoute = '/pace-calculator';
  static const String _profileRoute = '/profile';
  static const String _loginRoute = '/login';

  static const String _paceCardAsset = 'assets/images/pace.jpg';
  static const String _athleteCardAsset = 'assets/images/profile.jpg';

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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final currentLocale = ref.watch(localeProvider);
    final cardRadius = _cardBorderRadius(theme);

    return Scaffold(
      backgroundColor: AppColors.ironmanBlack,
      appBar: AppBar(
        backgroundColor: AppColors.ironmanBlack,
        elevation: 0,
        foregroundColor: AppColors.ironmanWhite,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _LanguageDropdown(
              currentLocale: currentLocale,
              onLocaleChanged: (Locale newLocale) async {
                ScaffoldMessenger.of(context).clearSnackBars();
                await ref.read(localeProvider.notifier).setLocale(newLocale);
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      final loc = AppLocalizations.of(context);
                      if (loc != null) {
                        AlertHelper.showInfo(
                          context,
                          loc.settings_language_changed,
                        );
                      }
                    }
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeFeatureCard(
                      backgroundImageAsset: _paceCardAsset,
                      cardRadius: cardRadius,
                      accentColor: AppColors.ironmanRed,
                      title: loc.home_card_pace_title,
                      subtitle: loc.home_card_pace_subtitle,
                      helperText: loc.home_card_pace_helper,
                      buttonLabel: loc.home_card_pace_button,
                      isPrimaryButton: true,
                      onButtonTap: () {
                        Navigator.of(context).pushNamed(_paceCalculatorRoute);
                      },
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 16),
                    HomeFeatureCard(
                      backgroundImageAsset: _athleteCardAsset,
                      cardRadius: cardRadius,
                      accentColor: AppColors.ironmanRed,
                      imageLoadDelayMs: 80,
                      title: loc.home_card_profile_title,
                      subtitle: loc.home_card_profile_subtitle,
                      helperText: loc.home_card_profile_helper,
                      buttonLabel: loc.home_card_profile_button,
                      isPrimaryButton: false,
                      onButtonTap: () {
                        if (isAuthenticated) {
                          Navigator.of(context).pushNamed(_profileRoute);
                        } else {
                          Navigator.of(context).pushNamed(_loginRoute);
                        }
                      },
                      textTheme: textTheme,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(top: false, child: _Footer(textTheme: textTheme)),
        ],
      ),
      bottomNavigationBar: _HomeBottomNav(
        isAuthenticated: isAuthenticated,
        onTap: (int index) {
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

  static BorderRadius _cardBorderRadius(ThemeData theme) {
    final shape = theme.cardTheme.shape;
    if (shape is RoundedRectangleBorder) {
      final br = shape.borderRadius;
      if (br is BorderRadius) return br;
    }
    return BorderRadius.circular(16);
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  final Locale currentLocale;
  final Future<void> Function(Locale) onLocaleChanged;

  static String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'az':
        return 'Azərbaycan';
      case 'en':
      default:
        return 'English';
    }
  }

  static const List<Locale> _localesInOrder = [
    Locale('az'),
    Locale('en'),
    Locale('ru'),
  ];

  @override
  Widget build(BuildContext context) {
    final value = _localesInOrder.contains(currentLocale)
        ? currentLocale
        : _localesInOrder.first;
    return DropdownButton<Locale>(
      value: value,
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowDown01,
        size: 20,
        color: AppColors.ironmanTextSecondary,
      ),
      underline: Container(),
      dropdownColor: AppColors.ironmanGray,
      borderRadius: BorderRadius.circular(12),
      items: _localesInOrder.map<DropdownMenuItem<Locale>>((Locale locale) {
        return DropdownMenuItem<Locale>(
          value: locale,
          child: Text(
            _getLanguageName(locale),
            style: const TextStyle(color: AppColors.ironmanWhite, fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          onLocaleChanged(newLocale);
        }
      },
    );
  }
}

/// Откладывает загрузку фона карточки на следующий кадр, чтобы не блокировать первый кадр.
class _DeferredCardImage extends StatefulWidget {
  const _DeferredCardImage({required this.assetPath, this.delayMs = 0});

  final String assetPath;
  final int delayMs;

  @override
  State<_DeferredCardImage> createState() => _DeferredCardImageState();
}

class _DeferredCardImageState extends State<_DeferredCardImage> {
  bool _showImage = false;

  @override
  void initState() {
    super.initState();
    void showImage() {
      if (mounted) setState(() => _showImage = true);
    }

    if (widget.delayMs <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => showImage());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: widget.delayMs), () {
          if (mounted) showImage();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showImage) return const SizedBox.expand();
    return Image.asset(
      widget.assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.expand(),
    );
  }
}

class HomeFeatureCard extends StatelessWidget {
  const HomeFeatureCard({
    super.key,
    required this.backgroundImageAsset,
    required this.cardRadius,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.helperText,
    required this.buttonLabel,
    required this.isPrimaryButton,
    required this.onButtonTap,
    required this.textTheme,
    this.cardIcon,
    this.cardIconBgColor,
    this.imageLoadDelayMs = 0,
  });

  final String backgroundImageAsset;
  final BorderRadius cardRadius;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String helperText;
  final String buttonLabel;
  final bool isPrimaryButton;
  final VoidCallback onButtonTap;
  final TextTheme textTheme;
  final IconData? cardIcon;
  final Color? cardIconBgColor;
  final int imageLoadDelayMs;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: cardRadius,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: cardRadius,
          color: AppColors.ironmanDarkGray,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _DeferredCardImage(
              assetPath: backgroundImageAsset,
              delayMs: imageLoadDelayMs,
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.ironmanBlack.withValues(alpha: 0.4),
                              AppColors.ironmanBlack.withValues(alpha: 0.97),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 4, color: accentColor),
                    ),
                    if (cardIcon != null && cardIconBgColor != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cardIconBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: HugeIcon(
                            icon: cardIcon!,
                            size: 20,
                            color: cardIconBgColor == AppColors.ironmanRed
                                ? AppColors.ironmanWhite
                                : AppColors.ironmanWhite,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleLarge?.copyWith(
                              color: AppColors.ironmanWhite,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.ironmanWhite,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  helperText,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.ironmanWhite,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              PrimaryActionButton(
                                label: buttonLabel,
                                isPrimary: isPrimaryButton,
                                onPressed: onButtonTap,
                                textTheme: textTheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.isPrimary,
    required this.onPressed,
    required this.textTheme,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;
  final TextTheme textTheme;

  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 20,
  );

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      style: textTheme.labelLarge?.copyWith(
        color: isPrimary ? AppColors.ironmanWhite : AppColors.ironmanRed,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        child: child,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: _buttonPadding,
          decoration: BoxDecoration(
            color: AppColors.ironmanWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Engineered for endurance athletes',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.ironmanTextSecondary,
              ),
            ),
          ],
        ),
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
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 6,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.ironmanGray.withValues(alpha: 0.6),
                    AppColors.ironmanGray.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
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
                ],
              ),
            ),
          ),
        ],
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
