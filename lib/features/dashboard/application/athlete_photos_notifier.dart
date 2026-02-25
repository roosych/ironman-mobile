import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/api_exception.dart';
import '../infrastructure/athletes_api.dart';
import 'athlete_photos_state.dart';

class AthletePhotosNotifier extends StateNotifier<AthletePhotosState> {
  final int athleteId;
  final AthletesApi _api;

  AthletePhotosNotifier({required this.athleteId, AthletesApi? api})
      : _api = api ?? AthletesApi(),
        super(const AthletePhotosState());

  Future<void> loadPhotos() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.fetchAthletePhotos(athleteId, page: 1);
      state = state.copyWith(
        photos: result.photos,
        isLoading: false,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.localizationKey);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _api.fetchAthletePhotos(
        athleteId,
        page: state.currentPage + 1,
      );
      state = state.copyWith(
        photos: [...state.photos, ...result.photos],
        isLoadingMore: false,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.localizationKey);
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final athletePhotosProvider = StateNotifierProvider.family<
    AthletePhotosNotifier, AthletePhotosState, int>(
  (ref, athleteId) => AthletePhotosNotifier(athleteId: athleteId),
);
