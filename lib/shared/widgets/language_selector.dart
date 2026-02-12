import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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

    return DropdownButton<Locale>(
      value: locale,
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedArrowDown01,
        size: 20,
        color: Colors.white70,
      ),
      underline: Container(),
      dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      items: const [
        Locale('az'),
        Locale('en'),
        Locale('ru'),
      ].map<DropdownMenuItem<Locale>>((Locale locale) {
        return DropdownMenuItem<Locale>(
          value: locale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getLanguageName(locale),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (Locale? newLocale) async {
        if (newLocale != null) {
          // Hide all current SnackBars before language change
          ScaffoldMessenger.of(context).clearSnackBars();

          await ref.read(localeProvider.notifier).setLocale(newLocale);

          // Wait for Flutter to rebuild with new locale
          if (context.mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                final updatedLocalizations = AppLocalizations.of(context);
                if (updatedLocalizations != null) {
                  AlertHelper.showInfo(
                    context,
                    updatedLocalizations.settings_language_changed
                  );
                }
              }
            });
          }
        }
      },
    );
  }
}