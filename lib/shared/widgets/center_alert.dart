import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';

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
    try {
      debugPrint('CenterAlert.show called with type: $type, message: $message');

      if (!context.mounted) {
        debugPrint('Context not mounted in CenterAlert.show');
        return Future.value();
      }

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
    } catch (e, stackTrace) {
      debugPrint('Error in CenterAlert.show: $e');
      debugPrint('Stack trace: $stackTrace');
      return Future.value();
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (type) {
      case AlertType.error:
        return Theme.of(context).colorScheme.error;
      case AlertType.success:
        return AppColors.primaryGradientStart;
      case AlertType.info:
        return Theme.of(context).colorScheme.primary;
      case AlertType.warning:
        return Colors.orange;
    }
  }

  Gradient? _getButtonGradient() {
    switch (type) {
      case AlertType.success:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGradientStart,
            AppColors.primaryGradientEnd,
          ],
        );
      default:
        return null;
    }
  }

  Color _getButtonColor(BuildContext context) {
    switch (type) {
      case AlertType.error:
        return Theme.of(context).colorScheme.error;
      case AlertType.success:
        return AppColors.primaryGradientStart;
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
    final iconColor = _getIconColor(context);
    final icon = _getIcon();
    final buttonGradient = _getButtonGradient();
    final buttonColor = _getButtonColor(context);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка
            Padding(
              padding: EdgeInsets.only(top: 24.h, bottom: 8.h),
              child: Icon(
                icon,
                size: 48.r,
                color: iconColor,
              ),
            ),
            // Сообщение
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16.sp,
                  height: 1.4,
                ),
              ),
            ),
            // Кнопка
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: SizedBox(
                width: double.infinity,
                child: buttonGradient != null
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: buttonGradient,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onPressed ?? () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(8.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              child: Text(
                                buttonText ?? 'OK',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onPressed ?? () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          buttonText ?? 'OK',
                          style: TextStyle(
                            fontSize: 16.sp,
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
