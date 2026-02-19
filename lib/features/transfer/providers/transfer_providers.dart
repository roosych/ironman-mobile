import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/transfer_status_notifier.dart';
import '../application/transfer_status_state.dart';
import '../application/eligible_athletes_notifier.dart';
import '../application/eligible_athletes_state.dart';

/// Провайдер для управления статусом заявки на перенос результатов
final transferStatusProvider =
    StateNotifierProvider<TransferStatusNotifier, TransferStatusState>((ref) {
  return TransferStatusNotifier();
});

/// Провайдер для поиска доступных атлетов (auto-dispose для экономии памяти)
final eligibleAthletesProvider = StateNotifierProvider.autoDispose<
    EligibleAthletesNotifier, EligibleAthletesState>((ref) {
  return EligibleAthletesNotifier();
});