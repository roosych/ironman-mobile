import 'package:flutter/material.dart';
import '../widgets/center_alert.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';

/// Утилита для показа центральных алертов
class AlertHelper {
  /// Показывает алерт об ошибке
  static Future<void> showError(
    BuildContext context,
    String message, {
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    if (!context.mounted) return Future.value();
    
    final localizations = AppLocalizations.of(context);
    return CenterAlert.show(
      context,
      message: message,
      type: AlertType.error,
      buttonText: buttonText ?? localizations?.error_ok ?? 'OK',
      onPressed: onPressed,
    );
  }

  /// Показывает алерт об успехе
  static Future<void> showSuccess(
    BuildContext context,
    String message, {
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    if (!context.mounted) return Future.value();
    
    final localizations = AppLocalizations.of(context);
    return CenterAlert.show(
      context,
      message: message,
      type: AlertType.success,
      buttonText: buttonText ?? localizations?.error_ok ?? 'OK',
      onPressed: onPressed,
    );
  }

  /// Показывает информационный алерт
  static Future<void> showInfo(
    BuildContext context,
    String message, {
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    if (!context.mounted) return Future.value();
    
    final localizations = AppLocalizations.of(context);
    return CenterAlert.show(
      context,
      message: message,
      type: AlertType.info,
      buttonText: buttonText ?? localizations?.error_ok ?? 'OK',
      onPressed: onPressed,
    );
  }

  /// Показывает предупреждение
  static Future<void> showWarning(
    BuildContext context,
    String message, {
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    if (!context.mounted) return Future.value();
    
    final localizations = AppLocalizations.of(context);
    return CenterAlert.show(
      context,
      message: message,
      type: AlertType.warning,
      buttonText: buttonText ?? localizations?.error_ok ?? 'OK',
      onPressed: onPressed,
    );
  }
}

