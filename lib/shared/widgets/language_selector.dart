import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/utils/alert_helper.dart';
import '../../features/settings/application/locale_notifier.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return PopupMenuButton<Locale>(
      onSelected: (Locale newLocale) async {
        ScaffoldMessenger.of(context).clearSnackBars();
        await ref.read(localeProvider.notifier).setLocale(newLocale);
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              final loc = AppLocalizations.of(context);
              if (loc != null) {
                AlertHelper.showInfo(context, loc.settings_language_changed);
              }
            }
          });
        }
      },
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        const Locale('az'),
        const Locale('en'),
        const Locale('ru'),
      ].map((l) {
        final isActive = l.languageCode == locale.languageCode;
        return PopupMenuItem<Locale>(
          value: l,
          child: Row(
            children: [
              if (isActive)
                const Icon(Icons.check, color: AppColors.primaryGradientStart, size: 18)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(
                _getLanguageName(l),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: const HugeIcon(
        icon: HugeIcons.strokeRoundedEarth,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}