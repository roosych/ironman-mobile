import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../infrastructure/athletes_api.dart';
import 'records_state.dart';

final recordsProvider =
    StateNotifierProvider.family<RecordsNotifier, RecordsState, int>(
  (ref, athleteId) {
    return RecordsNotifier(athleteId);
  },
);

class RecordsNotifier extends StateNotifier<RecordsState> {
  final int _athleteId;
  final AthletesApi _api;
  static const Duration _requestTimeout = Duration(seconds: 20);

  RecordsNotifier(this._athleteId, {AthletesApi? api})
      : _api = api ?? AthletesApi(),
        super(const RecordsState());

  Future<void> loadRecords() async {
    if (state.isLoading) return;

    final showLoading = state.records == null;

    state = state.copyWith(isLoading: showLoading, clearError: true);

    try {
      final records = await _api.fetchRecords(_athleteId).timeout(_requestTimeout);
      state = state.copyWith(
        records: records,
        isLoading: false,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: 'Превышено время ожидания. Проверьте интернет и попробуйте ещё раз.',
      );
    } on AthletesApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Произошла ошибка',
      );
    }
  }
}

