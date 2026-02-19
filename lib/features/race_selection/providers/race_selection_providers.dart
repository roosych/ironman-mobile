import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/races_api.dart';
import '../application/race_selection_state.dart';
import '../application/race_selection_notifier.dart';

/// Провайдер для API работы с гонками
final racesApiProvider = Provider<RacesApi>((ref) {
  return RacesApi();
});

/// Провайдер для состояния выбора гонки
/// AutoDispose для автоматической очистки памяти при закрытии BottomSheet
final raceSelectionProvider = StateNotifierProvider.autoDispose<
    RaceSelectionNotifier, RaceSelectionState>((ref) {
  final api = ref.read(racesApiProvider);
  return RaceSelectionNotifier(api: api);
});