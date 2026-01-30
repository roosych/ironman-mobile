import 'package:flutter/material.dart';

/// Центральный алерт, отображаемый по центру экрана
class CenterAlert extends StatelessWidget {
  final String message;
  final AlertType type;
  final String? buttonText;
  final VoidCallback? onPressed;

  const CenterAlert({
    super.key,
    required this.message,
    required this.type,
    this.buttonText,
    this.onPressed,
  });

  /// Показывает центральный алерт
  static Future<void> show(
    BuildContext context, {
    required String message,
    required AlertType type,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => CenterAlert(
        message: message,
        type: type,
        buttonText: buttonText,
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (type) {
      case AlertType.error:
        return Theme.of(context).colorScheme.error;
      case AlertType.success:
        return Colors.green;
      case AlertType.info:
        return Theme.of(context).colorScheme.primary;
      case AlertType.warning:
        return Colors.orange;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.info:
        return Icons.info_outline;
      case AlertType.warning:
        return Icons.warning_amber_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _getBackgroundColor(context);
    final icon = _getIcon();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Icon(
                icon,
                size: 48,
                color: backgroundColor,
              ),
            ),
            // Сообщение
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            // Кнопка
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed ?? () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    buttonText ?? 'OK',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Типы алертов
enum AlertType {
  error,
  success,
  info,
  warning,
}

