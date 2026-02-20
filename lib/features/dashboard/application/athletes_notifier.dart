import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../infrastructure/athletes_api.dart';
import '../../../core/errors/api_exception.dart';
import 'athletes_state.dart';

final athletesProvider =
    StateNotifierProvider<AthletesNotifier, AthletesState>((ref) {
  return AthletesNotifier();
});

class AthletesNotifier extends StateNotifier<AthletesState> {
  final AthletesApi _api;
  static const Duration _requestTimeout = Duration(seconds: 20);

  AthletesNotifier({AthletesApi? api})
      : _api = api ?? AthletesApi(),
        super(const AthletesState());

  Future<void> loadAthletes() async {
    if (state.isLoading) return;

    // Show loading only if no cached data
    final showLoading = state.athletes.isEmpty;

    state = state.copyWith(isLoading: showLoading, clearError: true);

    try {
      final athletes = await _api.fetchAthletes().timeout(_requestTimeout);
      state = state.copyWith(
        athletes: athletes,
        isLoading: false,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: 'api_error_timeout',
      );
    } on AthletesApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.localizationKey,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'error_unexpected',
      );
    }
  }
}

