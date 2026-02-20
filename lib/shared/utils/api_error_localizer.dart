import 'package:flutter/material.dart';
import '../../core/errors/api_exception.dart';
import '../../l10n/app_localizations.dart';

/// Утилита для локализации API ошибок
class ApiErrorLocalizer {
  /// Локализует сообщение API исключения
  static String localize(BuildContext context, ApiException exception) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return exception.originalMessage ?? exception.localizationKey;
    }

    try {
      // Используем рефлексию для получения локализованной строки
      switch (exception.localizationKey) {
        case 'api_error_empty_response':
          return loc.api_error_empty_response;
        case 'api_error_timeout':
          return loc.api_error_timeout;
        case 'api_error_network_no_connection':
          return loc.api_error_network_no_connection;
        case 'api_error_http_status':
          final status = exception.parameters?['status'] ?? 0;
          return loc.api_error_http_status(status as int);
        case 'api_error_generic':
          final message = exception.parameters?['message'] ?? 'Unknown';
          return loc.api_error_generic(message as String);
        case 'api_error_unexpected':
          final error = exception.parameters?['error'] ?? 'Unknown';
          return loc.api_error_unexpected(error as String);
        case 'api_error_invalid_data_format':
          return loc.api_error_invalid_data_format;
        case 'api_error_invalid_item_format':
          return loc.api_error_invalid_item_format;
        case 'api_error_races_format':
          return loc.api_error_races_format;
        case 'api_error_race_item_format':
          return loc.api_error_race_item_format;
        case 'api_error_rankings_format':
          return loc.api_error_rankings_format;
        case 'api_error_ranking_item_format':
          return loc.api_error_ranking_item_format;
        // Athletes errors
        case 'api_error_athletes_format':
          return loc.api_error_athletes_format;
        case 'api_error_athlete_item_format':
          return loc.api_error_athlete_item_format;
        case 'api_error_athlete_object_format':
          return loc.api_error_athlete_object_format;
        case 'api_error_athlete_not_found':
          return loc.api_error_athlete_not_found;
        case 'api_error_records_object_format':
          return loc.api_error_records_object_format;
        case 'api_error_records_not_found':
          return loc.api_error_records_not_found;
        case 'api_error_athletes_loading':
          return loc.api_error_athletes_loading;
        case 'api_error_server':
          final status = exception.parameters?['status'] ?? 'Unknown';
          return loc.api_error_server(status as String);
        // Upcoming races errors
        case 'api_error_upcoming_race_create_failed':
          return loc.api_error_upcoming_race_create_failed;
        case 'api_error_upcoming_race_object_format':
          return loc.api_error_upcoming_race_object_format;
        // Transfer errors
        case 'transfer_api_conflict':
          return loc.transfer_api_conflict;
        case 'transfer_api_validation':
          return loc.transfer_api_validation;
        case 'transfer_api_server_error':
          return loc.transfer_api_server_error;
        case 'transfer_status_timeout':
          return loc.transfer_status_timeout;
        case 'transfer_status_load_failed':
          return loc.transfer_status_load_failed;
        case 'transfer_status_create_failed':
          return loc.transfer_status_create_failed;
        case 'transfer_status_update_failed':
          return loc.transfer_status_update_failed;
        default:
          return exception.originalMessage ?? exception.localizationKey;
      }
    } catch (e) {
      // Fallback к исходному сообщению
      return exception.originalMessage ?? exception.localizationKey;
    }
  }

  /// Локализует любое исключение, если оно является ApiException
  static String localizeAny(BuildContext context, Exception exception) {
    if (exception is ApiException) {
      return localize(context, exception);
    }
    return exception.toString();
  }
}