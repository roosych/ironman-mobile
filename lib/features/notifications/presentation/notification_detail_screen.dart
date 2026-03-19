import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_button_styles.dart';
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
            size: 24.r,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.notification_detail_title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
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
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: theme.cardColor,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedTitle.isEmpty
                            ? AppLocalizations.of(context)!.notification_detail_title
                            : localizedTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                      if (notification.createdAt != null) ...[
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 14.r,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _dateFormat.format(notification.createdAt!.toLocal()),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (localizedBody.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          localizedBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                            fontSize: 14.sp,
                          ),
                        ),
                      ] else ...[
                        SizedBox(height: 16.h),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '-',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              AppButtonStyles.primaryGradientButton(
                text: AppLocalizations.of(context)!.notification_detail_understood,
                onPressed: () => Navigator.of(context).maybePop(),
                borderRadius: 12.r,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
