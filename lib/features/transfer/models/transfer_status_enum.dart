/// Статусы заявки на перенос результатов
enum TransferStatus {
  /// Заявка ожидает рассмотрения
  pending('pending'),

  /// Заявка одобрена
  approved('approved'),

  /// Заявка отклонена
  rejected('rejected');

  const TransferStatus(this.value);

  /// Строковое значение статуса
  final String value;

  /// Создает статус из строкового значения
  static TransferStatus fromString(String value) {
    return TransferStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TransferStatus.pending,
    );
  }
}

/// Расширения для удобной работы со статусами
extension TransferStatusExtensions on TransferStatus {
  /// Заявка находится в ожидании
  bool get isPending => this == TransferStatus.pending;

  /// Заявка одобрена
  bool get isApproved => this == TransferStatus.approved;

  /// Заявка отклонена
  bool get isRejected => this == TransferStatus.rejected;
}