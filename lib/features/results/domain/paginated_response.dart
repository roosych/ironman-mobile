import 'race_result.dart';

class PaginatedResponse {
  final List<RaceResult> results;
  final PaginationMeta meta;

  const PaginatedResponse({
    required this.results,
    required this.meta,
  });
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMorePages => currentPage < lastPage;
  int get nextPage => currentPage + 1;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int? ?? json['currentPage'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? json['lastPage'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? json['perPage'] as int? ?? 15,
      total: json['total'] as int? ?? 0,
    );
  }
}

