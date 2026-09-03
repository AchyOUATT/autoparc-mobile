/// Enveloppe générique pour les réponses paginées de Laravel.
///
/// Compatible avec la structure { data: [...], links: {...}, meta: {...} }
/// retournée par tous les controllers utilisant ->paginate().
class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final String? nextUrl;

  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    this.nextUrl,
  });

  bool get hasNextPage => currentPage < lastPage;
  bool get isFirstPage => currentPage == 1;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final meta  = json['meta']  as Map<String, dynamic>;
    final links = json['links'] as Map<String, dynamic>;

    return PaginatedResponse<T>(
      data:        (json['data'] as List)
                       .map((e) => fromItem(e as Map<String, dynamic>))
                       .toList(),
      currentPage: meta['current_page'] as int,
      lastPage:    meta['last_page']    as int,
      total:       meta['total']        as int,
      perPage:     meta['per_page']     as int,
      nextUrl:     links['next'] as String?,
    );
  }
}
