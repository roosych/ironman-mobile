/// Ключи ошибок API для локализации
class ApiErrorKeys {
  // Общие ошибки API
  static const String emptyResponse = 'api_error_empty_response';
  static const String timeout = 'api_error_timeout';
  static const String networkNoConnection = 'api_error_network_no_connection';
  static const String httpStatus = 'api_error_http_status';
  static const String generic = 'api_error_generic';
  static const String unexpected = 'api_error_unexpected';
  static const String invalidDataFormat = 'api_error_invalid_data_format';
  static const String invalidItemFormat = 'api_error_invalid_item_format';

  // Специфичные ошибки для гонок
  static const String racesFormat = 'api_error_races_format';
  static const String raceItemFormat = 'api_error_race_item_format';

  // Специфичные ошибки для рейтингов
  static const String rankingsFormat = 'api_error_rankings_format';
  static const String rankingItemFormat = 'api_error_ranking_item_format';

  // Специфичные ошибки для атлетов
  static const String athletesFormat = 'api_error_athletes_format';
  static const String athleteItemFormat = 'api_error_athlete_item_format';
  static const String athleteObjectFormat = 'api_error_athlete_object_format';
  static const String athleteNotFound = 'api_error_athlete_not_found';
  static const String recordsObjectFormat = 'api_error_records_object_format';
  static const String recordsNotFound = 'api_error_records_not_found';
  static const String athletesLoading = 'api_error_athletes_loading';
  static const String server = 'api_error_server';

  // Специфичные ошибки для предстоящих гонок
  static const String upcomingRaceCreateFailed = 'api_error_upcoming_race_create_failed';
  static const String upcomingRaceObjectFormat = 'api_error_upcoming_race_object_format';

  // Ошибки Transfer API
  static const String transferConflict = 'transfer_api_conflict';
  static const String transferValidation = 'transfer_api_validation';
  static const String transferServerError = 'transfer_api_server_error';
  static const String transferCreateFailed = 'api_error_transfer_create_failed';
  static const String transferStatusTimeout = 'transfer_status_timeout';
  static const String transferStatusLoadFailed = 'transfer_status_load_failed';
  static const String transferStatusCreateFailed = 'transfer_status_create_failed';
  static const String transferStatusUpdateFailed = 'transfer_status_update_failed';
}