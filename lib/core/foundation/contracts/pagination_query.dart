class PaginationQuery {
  final int page;
  final int perPage;

  const PaginationQuery({this.page = 1, this.perPage = 15});

  PaginationQuery copyWith({int? page, int? perPage}) {
    return PaginationQuery(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'page': page, 'limit': perPage};
  }
}
