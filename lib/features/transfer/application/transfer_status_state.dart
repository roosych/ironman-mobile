import '../models/transfer_request_model.dart';
import '../models/transfer_status_enum.dart';

/// Состояние статуса заявки на перенос результатов
class TransferStatusState {
  /// Текущая заявка (null если нет активной заявки)
  final TransferRequestModel? request;

  /// Загружается ли статус заявки
  final bool isLoading;

  /// Создается ли новая заявка
  final bool isSubmitting;

  /// Сообщение об ошибке
  final String? error;

  const TransferStatusState({
    this.request,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  /// Есть ли активная заявка
  bool get hasRequest => request != null;

  /// Есть ли ошибка
  bool get hasError => error != null;

  /// Заявка в статусе ожидания
  bool get isPending => request?.status.isPending ?? false;

  /// Заявка одобрена
  bool get isApproved => request?.status.isApproved ?? false;

  /// Заявка отклонена
  bool get isRejected => request?.status.isRejected ?? false;

  /// Можно ли подать новую заявку
  bool get canSubmitNewRequest => !hasRequest && !isLoading && !isSubmitting;

  /// Создает копию состояния с измененными полями
  TransferStatusState copyWith({
    TransferRequestModel? request,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearRequest = false,
    bool clearError = false,
  }) {
    return TransferStatusState(
      request: clearRequest ? null : (request ?? this.request),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferStatusState &&
          runtimeType == other.runtimeType &&
          request == other.request &&
          isLoading == other.isLoading &&
          isSubmitting == other.isSubmitting &&
          error == other.error;

  @override
  int get hashCode =>
      request.hashCode ^
      isLoading.hashCode ^
      isSubmitting.hashCode ^
      error.hashCode;

  @override
  String toString() {
    return 'TransferStatusState{request: $request, isLoading: $isLoading, '
           'isSubmitting: $isSubmitting, error: $error}';
  }
}