import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../infrastructure/athletes_api.dart';
import 'athlete_detail_state.dart';

final athleteDetailProvider = StateNotifierProvider.family<
    AthleteDetailNotifier, AthleteDetailState, int>((ref, athleteId) {
  return AthleteDetailNotifier(athleteId);
});

class AthleteDetailNotifier extends StateNotifier<AthleteDetailState> {
  final int athleteId;
  final AthletesApi _api;
  static const Duration _requestTimeout = Duration(seconds: 20);

  AthleteDetailNotifier(this.athleteId, {AthletesApi? api})
      : _api = api ?? AthletesApi(),
        super(const AthleteDetailState());

  Future<void> loadAthleteDetail() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final athlete = await _api.fetchAthleteById(athleteId).timeout(_requestTimeout);
      state = state.copyWith(
        athlete: athlete,
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

