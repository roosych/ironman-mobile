import 'transfer_status_enum.dart';

/// Модель заявки на перенос результатов
class TransferRequestModel {
  /// ID заявки
  final int id;

  /// ID атлета-источника результатов
  final int sourceAthleteId;

  /// Имя атлета-источника результатов
  final String sourceAthleteName;

  /// Статус заявки
  final TransferStatus status;

  /// Текстовая метка статуса
  final String statusLabel;

  /// Комментарий к заявке
  final String? comment;

  /// Дата создания заявки
  final DateTime createdAt;

  /// Дата рассмотрения заявки (если рассмотрена)
  final DateTime? reviewedAt;

  /// ID рассматривающего (если рассмотрена)
  final int? reviewedBy;

  const TransferRequestModel({
    required this.id,
    required this.sourceAthleteId,
    required this.sourceAthleteName,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    this.comment,
    this.reviewedAt,
    this.reviewedBy,
  });

  /// Создает модель из JSON данных
  factory TransferRequestModel.fromJson(Map<String, dynamic> json) {
    // Извлекаем данные source_athlete
    final sourceAthlete = json['source_athlete'] as Map<String, dynamic>?;

    return TransferRequestModel(
      id: _parseIntSafe(json['id']),
      sourceAthleteId: sourceAthlete != null
          ? _parseIntSafe(sourceAthlete['id'])
          : 0,
      sourceAthleteName: sourceAthlete != null
          ? sourceAthlete['name']?.toString() ?? 'Неизвестный атлет'
          : 'Неизвестный атлет',
      status: TransferStatus.fromString(json['status']?.toString() ?? 'pending'),
      statusLabel: json['status_label']?.toString() ?? 'Pending',
      comment: json['comment']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      reviewedBy: _parseIntSafeNullable(json['reviewed_by']),
    );
  }

  /// Безопасный парсинг int из dynamic (может быть String, int, num или null)
  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// Безопасный парсинг int? из dynamic (может быть String, int, num или null)
  static int? _parseIntSafeNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Преобразует модель в JSON данные
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_athlete': {
        'id': sourceAthleteId,
        'name': sourceAthleteName,
      },
      'status': status.value,
      'status_label': statusLabel,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
    };
  }

  /// Создает копию модели с измененными полями
  TransferRequestModel copyWith({
    int? id,
    int? sourceAthleteId,
    String? sourceAthleteName,
    TransferStatus? status,
    String? statusLabel,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? comment,
    int? reviewedBy,
    bool clearReviewedAt = false,
    bool clearComment = false,
    bool clearReviewedBy = false,
  }) {
    return TransferRequestModel(
      id: id ?? this.id,
      sourceAthleteId: sourceAthleteId ?? this.sourceAthleteId,
      sourceAthleteName: sourceAthleteName ?? this.sourceAthleteName,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: clearReviewedAt ? null : (reviewedAt ?? this.reviewedAt),
      comment: clearComment ? null : (comment ?? this.comment),
      reviewedBy: clearReviewedBy ? null : (reviewedBy ?? this.reviewedBy),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferRequestModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransferRequestModel{id: $id, sourceAthleteId: $sourceAthleteId, '
           'sourceAthleteName: $sourceAthleteName, status: $status, statusLabel: $statusLabel}';
  }
}