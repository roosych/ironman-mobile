import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../../features/auth/infrastructure/auth_api.dart';
import '../../features/profile/infrastructure/profile_api.dart';
import 'alert_helper.dart';

/// Centralized error handler for showing error alerts
class ErrorHandler {
  /// Shows an error alert based on the error type
  ///
  /// - AuthApiException: Shows the specific error message from the API (already localized)
  ///   For network errors without server response, uses Flutter localization
  /// - Network/connection errors: Shows localized "Please enable internet" message
  /// - Server errors: Shows localized "Something went wrong, try again later" message
  static void showError(BuildContext context, dynamic error) {
    if (!context.mounted) return;

    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    // Handle AuthApiException - show the specific error message from API
    // API messages are already localized on the backend, so show them directly
    if (error is AuthApiException) {
      final message = error.firstError;
      
      // Check if it's a network error code that needs client-side localization
      final localizedMessage = _localizeNetworkError(message, localizations);
      
      _showErrorSnackBar(context, localizedMessage, localizations);
      return;
    }

    // Handle ProfileApiException - show the specific error message from API
    // API messages are already localized on the backend, so show them directly
    if (error is ProfileApiException) {
      final message = error.message;
      
      // Check if it's a network error code that needs client-side localization
      final localizedMessage = _localizeNetworkError(message, localizations);
      
      _showErrorSnackBar(context, localizedMessage, localizations);
      return;
    }

    // Handle string errors directly (assume they're already localized from API)
    if (error is String) {
      _showErrorSnackBar(context, error, localizations);
      return;
    }

    final isNetworkError = _isNetworkError(error);
    final message = isNetworkError
        ? localizations.error_no_internet
        : localizations.error_server_error;

    _showErrorSnackBar(context, message, localizations);
  }

  /// Localizes network error codes that don't come from API
  /// Returns the original message if it's not a network error code
  static String _localizeNetworkError(String message, AppLocalizations localizations) {
    // Handle cooldown message
    if (message.startsWith('NETWORK_COOLDOWN_')) {
      final secondsStr = message.replaceFirst('NETWORK_COOLDOWN_', '');
      final seconds = int.tryParse(secondsStr) ?? 0;
      // Use localized message with parameter
      return localizations.error_cooldown(seconds);
    }
    
    switch (message) {
      case 'NETWORK_TIMEOUT':
        return localizations.error_no_internet;
      case 'NETWORK_CONNECTION_ERROR':
        return localizations.error_no_internet;
      case 'NETWORK_NO_CONNECTION':
        return localizations.error_no_network_connection;
      case 'NETWORK_ERROR':
        return localizations.error_network_error;
      case 'NETWORK_TOO_MANY_REQUESTS':
        return localizations.error_server_error;
      case 'error_unexpected':
        return localizations.error_unexpected;
      default:
        // If message starts with NETWORK_SERVER_ERROR_, it's a server error
        if (message.startsWith('NETWORK_SERVER_ERROR_')) {
          return localizations.error_server_error;
        }
        // Otherwise, assume it's a localized message from API - show it directly
        return message;
    }
  }

  /// Checks if the error is a network/connection error
  static bool _isNetworkError(dynamic error) {
    // Check if it's a DioException with connection error
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
    }

    // Check error message for network-related keywords
    final errorMessage = _getErrorMessage(error).toLowerCase();

    final networkKeywords = [
      'нет подключения',
      'no connection',
      'connection error',
      'connection timeout',
      'network',
      'интернет',
      'internet',
      'bağlantı',
      'şəbəkə',
      'подключения к сети',
      'подключения к серверу',
      'connectionerror',
      'connectiontimeout',
    ];

    return networkKeywords.any((keyword) => errorMessage.contains(keyword));
  }

  /// Extracts error message from various error types
  static String _getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    }

    if (error is DioException) {
      return error.message ?? error.toString();
    }

    if (error is Exception) {
      return error.toString();
    }

    return error?.toString() ?? 'Unknown error';
  }

  /// Shows error alert
  static void _showErrorSnackBar(
    BuildContext context,
    String message,
    AppLocalizations localizations,
  ) {
    AlertHelper.showError(
      context,
      message,
      buttonText: localizations.error_ok,
    );
  }
}
