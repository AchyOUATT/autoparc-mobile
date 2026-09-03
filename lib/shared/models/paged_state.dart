/// État générique pour une liste paginée avec scroll infini.
class PagedState<T> {
  final List<T> items;
  final int total;
  final bool hasMore;
  final bool isLoading;      // chargement initial / rechargement complet
  final bool isLoadingMore;  // chargement de la page suivante
  final Object? error;       // erreur initiale (première page)

  const PagedState({
    required this.items,
    required this.total,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    this.error,
  });

  /// État initial : spinner centré.
  const PagedState.loading()
      : items = const [],
        total = 0,
        hasMore = false,
        isLoading = true,
        isLoadingMore = false,
        error = null;

  /// État vide après réinitialisation (entre deux filtres).
  const PagedState.idle()
      : items = const [],
        total = 0,
        hasMore = false,
        isLoading = false,
        isLoadingMore = false,
        error = null;

  PagedState<T> copyWith({
    List<T>? items,
    int? total,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) =>
      PagedState<T>(
        items:         items         ?? this.items,
        total:         total         ?? this.total,
        hasMore:       hasMore       ?? this.hasMore,
        isLoading:     isLoading     ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error:         clearError    ? null : (error ?? this.error),
      );

  bool get isEmpty      => !isLoading && items.isEmpty && error == null;
  bool get hasError     => error != null && items.isEmpty;
  bool get showList     => items.isNotEmpty;
}
