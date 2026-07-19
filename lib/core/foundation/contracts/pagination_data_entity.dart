class PaginationInfo {
  final bool isFirstPage;
  final bool isLastPage;

  const PaginationInfo({required this.isFirstPage, required this.isLastPage});
}

class PaginationDataEntity<T> {
  final List<T> data;
  final PaginationInfo paginationInfo;

  const PaginationDataEntity({
    required this.data,
    required this.paginationInfo,
  });

  PaginationDataEntity<T> copyWith({
    List<T>? data,
    PaginationInfo? paginationInfo,
  }) {
    return PaginationDataEntity<T>(
      data: data ?? this.data,
      paginationInfo: paginationInfo ?? this.paginationInfo,
    );
  }
}
