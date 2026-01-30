import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/application/locale_notifier.dart';
import '../domain/app_notification.dart';

class NotificationDetailScreen extends ConsumerWidget {
  final AppNotification notification;

  NotificationDetailScreen({super.key, required this.notification});

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final localizedTitle = notification.getLocalizedTitle(locale.languageCode);
    final localizedBody = notification.getLocalizedBody(locale.languageCode);
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.notification_detail_title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: theme.cardColor,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedTitle.isEmpty
                            ? AppLocalizations.of(context)!
                                .notification_detail_title
                            : localizedTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (notification.createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _dateFormat.format(notification.createdAt!.toLocal()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                      if (localizedBody.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizedBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '-',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  AppLocalizations.of(context)!.notification_detail_understood,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


