import 'package:flutter/material.dart';
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
        borderRadius: BorderRadius.circular(12),
      ),
      color: theme.colorScheme.errorContainer.withValues(alpha:0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha:0.2),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: theme.colorScheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
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
        borderRadius: BorderRadius.circular(12),
      ),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.transfer_no_request_description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Показываем loading если загружается статус или создается заявка
            (state.isLoading || state.isSubmitting)
                ? SizedBox(
                    height: 48,
                    child: Container(
                      decoration: AppButtonStyles.primaryGradientDecoration(
                        borderRadius: 12,
                        withShadow: false,
                      ),
                      child: const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
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
                    borderRadius: 10,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
      key: ValueKey(status), // Ключ для AnimatedSwitcher
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: statusColor.withValues(alpha:0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Заголовок с иконкой
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.2),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
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

            const SizedBox(height: 12),

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
              const SizedBox(height: 16),
              state.isSubmitting
                  ? SizedBox(
                      height: 48,
                      child: Container(
                        decoration: AppButtonStyles.primaryGradientDecoration(
                          borderRadius: 12,
                          withShadow: false,
                        ),
                        child: const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
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
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}