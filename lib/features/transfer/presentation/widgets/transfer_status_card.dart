import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_button_styles.dart';
import '../../application/transfer_status_state.dart';
import '../../models/transfer_status_enum.dart';

/// Карточка отображения статуса заявки на перенос результатов
class TransferStatusCard extends StatelessWidget {
  /// Состояние статуса заявки
  final TransferStatusState state;

  /// Callback для создания заявки на перенос
  final VoidCallback onTransferRequest;

  const TransferStatusCard({
    super.key,
    required this.state,
    required this.onTransferRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Показываем ошибку, если есть
    if (state.hasError) {
      return _buildErrorCard(context, theme, localizations, state.error!);
    }

    final request = state.request;

    // Если нет заявки - показываем кнопку (с лоадером если загружается)
    if (request == null) {
      return _buildNoRequestCard(context, theme, localizations);
    }

    // Если заявка одобрена - не показываем блок, результаты уже видны
    if (request.status == TransferStatus.approved) {
      return const SizedBox.shrink();
    }

    // Есть заявка (pending/rejected) - показываем статус с анимацией
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildStatusCard(
        context,
        request.status,
        request.sourceAthleteName,
        request.comment,
        theme,
        localizations,
      ),
    );
  }

  /// Карточка ошибки
  Widget _buildErrorCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
    String error,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: theme.colorScheme.error,
                size: 20.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка для создания новой заявки
  Widget _buildNoRequestCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.transfer_no_request_description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            (state.isLoading || state.isSubmitting)
                ? SizedBox(
                    height: 48.h,
                    child: Container(
                      decoration: AppButtonStyles.primaryGradientDecoration(
                        borderRadius: 12.r,
                        withShadow: false,
                      ),
                      child: Center(
                        child: SizedBox(
                          height: 20.r,
                          width: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  )
                : AppButtonStyles.primaryGradientButton(
                    text: localizations.transfer_attach_results,
                    onPressed: onTransferRequest,
                    borderRadius: 10.r,
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// Карточка со статусом заявки
  Widget _buildStatusCard(
    BuildContext context,
    TransferStatus status,
    String sourceAthleteName,
    String? comment,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    // Определяем цвета и иконки по статусу
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (status) {
      case TransferStatus.pending:
        statusColor = Colors.amber.shade700;
        statusIcon = HugeIcons.strokeRoundedClock01;
        statusText = localizations.transfer_status_pending;
        statusDescription = localizations.transfer_status_pending_description;
        break;

      case TransferStatus.approved:
        statusColor = Colors.green.shade600;
        statusIcon = HugeIcons.strokeRoundedCheckmarkCircle01;
        statusText = localizations.transfer_status_approved;
        statusDescription = localizations.transfer_status_approved_description;
        break;

      case TransferStatus.rejected:
        statusColor = Colors.red.shade600;
        statusIcon = HugeIcons.strokeRoundedCancel01;
        statusText = localizations.transfer_status_rejected;
        statusDescription = comment ?? localizations.transfer_status_rejected_description;
        break;
    }

    return Card(
      key: ValueKey(status),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // Заголовок с иконкой
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: statusIcon,
                    color: statusColor,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    statusText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Описание статуса
            Text(
              statusDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            // Кнопка "Подать снова" для отклоненных заявок
            if (status == TransferStatus.rejected) ...[
              SizedBox(height: 16.h),
              state.isSubmitting
                  ? SizedBox(
                      height: 48.h,
                      child: Container(
                        decoration: AppButtonStyles.primaryGradientDecoration(
                          borderRadius: 12.r,
                          withShadow: false,
                        ),
                        child: Center(
                          child: SizedBox(
                            height: 20.r,
                            width: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    )
                  : AppButtonStyles.primaryGradientButton(
                      text: localizations.transfer_submit_again,
                      onPressed: onTransferRequest,
                      borderRadius: 10.r,
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
