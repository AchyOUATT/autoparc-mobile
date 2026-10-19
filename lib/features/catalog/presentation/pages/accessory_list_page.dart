import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/accessory.dart';
import '../providers/catalog_providers.dart';
import '../../../../shared/models/paged_state.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/bande_filtres.dart';
import '../../../../core/widgets/bouton_flottant_effacable.dart';
import '../../../../core/widgets/catalog_image.dart';
import '../../../../core/widgets/titre_barre.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/cart/presentation/pages/cart_page.dart';
import '../../../../features/notifications/presentation/widgets/notification_icon_button.dart';
import '../../../../features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../../core/providers/shell_scaffold_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/ligne_compatibilite.dart';

/// LE LIBELLÉ A QUITTÉ CE TABLEAU : une liste `const` est construite avant
/// qu'aucun `BuildContext` n'existe, donc avant que la langue active soit
/// connue — un libellé écrit ici serait resté français pour tout le monde.
/// Le tableau garde l'ordre, la valeur envoyée au serveur et l'icône ;
/// [_libelleCategorie] rend le texte.
const _categories = [
  (value: 'esthetique', icon: Icons.auto_awesome),
  (value: 'confort', icon: Icons.airline_seat_recline_normal),
  (value: 'securite', icon: Icons.shield),
  (value: 'multimedia', icon: Icons.speaker),
  (value: 'utilitaire', icon: Icons.build),
];

/// Le libellé d'une des cinq catégories d'accessoires, dans la langue active.
///
/// CES CINQ-LÀ ENTRENT BIEN DANS LES `.arb`, et c'est ce qui les distingue des
/// catégories de PIÈCES : l'API ne fournit pour les accessoires ni libellé ni
/// icône — elle dit seulement lesquelles portent un article en vente —, donc
/// les cinq noms sont écrits dans l'application et nous appartiennent. Les
/// catégories de pièces, elles, arrivent nommées du référentiel du serveur et
/// restent en français jusqu'à la vague serveur.
///
/// Le repli rend la valeur brute : une catégorie inconnue de ce tableau ne peut
/// pas atteindre les puces, qui sont construites depuis le tableau lui-même.
String _libelleCategorie(AppLocalizations l10n, String valeur) =>
    switch (valeur) {
      'esthetique' => l10n.catalogAccessoryCategoryStyling,
      'confort' => l10n.catalogAccessoryCategoryComfort,
      'securite' => l10n.catalogAccessoryCategorySafety,
      'multimedia' => l10n.catalogAccessoryCategoryMultimedia,
      'utilitaire' => l10n.catalogAccessoryCategoryUtility,
      _ => valeur,
    };

class AccessoryListPage extends ConsumerStatefulWidget {
  const AccessoryListPage({super.key});

  @override
  ConsumerState<AccessoryListPage> createState() => _AccessoryListPageState();
}

class _AccessoryListPageState extends ConsumerState<AccessoryListPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(accessoryListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paged = ref.watch(accessoryListProvider);
    final filter = ref.watch(accessoryFilterProvider);
    final cities =
        ref.watch(catalogRefsProvider).valueOrNull?.cities ?? const <String>[];
    final auth = ref.watch(authProvider);
    final isStaff = auth.isStaff;

    return Scaffold(
      // Un magasinier ou un observateur n'a pas le droit de creer une fiche :
      // le bouton disparait plutot que de renvoyer un 403.
      floatingActionButton: auth.canManageCatalog
          ? BoutonFlottantEffacable(
              controleur: _scrollCtrl,
              enfant: FloatingActionButton.extended(
                onPressed: () async {
                  await context.push('/accessories/new');
                  ref.read(accessoryListProvider.notifier).refresh();
                },
                icon: const Icon(Icons.add),
                label: Text(
                  AppLocalizations.of(context).catalogAccessoryAddCta,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: AppLocalizations.of(context).commonMenuTooltip,
          onPressed: () =>
              ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: TitreBarre(AppLocalizations.of(context).commonAccessories),
        actions: [
          const NotificationIconButton(),
          if (!isStaff) ...[
            IconButton(
              icon: const Icon(Icons.inbox_outlined),
              tooltip: AppLocalizations.of(context).catalogNeedTooltip,
              onPressed: () => context.push('/needs/new?type=accessory'),
            ),
            const CartIconButton(),
          ],
        ],
        bottom: PreferredSize(
          // 48 au lieu de 56, et la SearchBar bornee a 40 : son minHeight par
          // defaut vaut 56, donc la contraindre est necessaire — reduire la
          // seule PreferredSize aurait rogne la barre sans l'amincir.
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: SearchBar(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
              controller: _searchCtrl,
              hintText: AppLocalizations.of(context).catalogAccessorySearchHint,
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(accessoryFilterProvider.notifier).state = filter
                          .copyWith(clearSearch: true);
                    },
                  ),
              ],
              onChanged: (q) =>
                  ref.read(accessoryFilterProvider.notifier).state = filter
                      .copyWith(search: q.isEmpty ? null : q),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          _FilterBar(filter: filter, cities: cities),
          Expanded(
            child: _Body(paged: paged, scrollCtrl: _scrollCtrl),
          ),
        ],
      ),
    );
  }
}

// ── Corps principal ──────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final PagedState<Accessory> paged;
  final ScrollController scrollCtrl;
  const _Body({required this.paged, required this.scrollCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (paged.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (paged.hasError) {
      return _ErrorView(
        error: messageFor(paged.error),
        onRetry: () => ref.read(accessoryListProvider.notifier).refresh(),
      );
    }
    if (paged.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(accessoryListProvider.notifier).refresh(),
      child: _AccessoryList(
        accessories: paged.items,
        total: paged.total,
        hasMore: paged.hasMore,
        isLoadingMore: paged.isLoadingMore,
        scrollCtrl: scrollCtrl,
      ),
    );
  }
}

// ── Barre de filtres ─────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  final AccessoryFilter filter;
  final List<String> cities;
  const _FilterBar({required this.filter, required this.cities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(AccessoryFilter Function(AccessoryFilter) fn) {
      ref.read(accessoryFilterProvider.notifier).state = fn(
        ref.read(accessoryFilterProvider),
      );
    }

    // Les cinq catégories sont codées en dur ici, avec leur libellé et leur
    // icône — l'API ne peut fournir ni l'un ni l'autre. Le serveur dit
    // seulement lesquelles portent un article en vente, et seules celles-là
    // sont proposées : le catalogue d'accessoires est vide en production, et
    // les cinq pastilles ne renvoyaient rien.
    final occupees = ref.watch(categoriesAccessoiresOccupeesProvider);
    final categories = _categories
        .where((c) => occupees.valueOrNull?.contains(c.value) ?? false)
        .toList();

    // Même garde que pour les pièces : la désélection passe par la pastille,
    // donc un filtre posé sur une catégorie qui n'est plus proposée ne pourrait
    // plus être retiré. Conditionné aux données reçues — pendant le chargement,
    // l'ensemble est vide sans rien dire de l'occupation.
    if (occupees.hasValue &&
        filter.category != null &&
        !occupees.requireValue.contains(filter.category)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        update((f) => f.copyWith(clearCategory: true));
      });
    }

    // La rangée s'affichait inconditionnellement : 48 dp de vide quand il n'y
    // avait ni catégorie occupée ni ville.
    if (categories.isEmpty && cities.isEmpty) {
      return const SizedBox.shrink();
    }

    // Même bande que les véhicules et les pièces depuis ce lot : la hauteur
    // vient du plancher de cible tactile des puces au lieu d'être écrite ici,
    // et les bords s'estompent — voir `BandeFiltres`.
    return BandeFiltres(
      children: [
        // Chips de catégorie
        ...categories.map((cat) {
          final selected = filter.category == cat.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(cat.icon, size: 16),
              label: Text(
                _libelleCategorie(AppLocalizations.of(context), cat.value),
              ),
              selected: selected,
              onSelected: (_) => update(
                (f) => f.copyWith(
                  category: selected ? null : cat.value,
                  clearCategory: selected,
                ),
              ),
            ),
          );
        }),
        // Chips de ville
        //
        // Un blanc de 20 points au lieu du `VerticalDivider` d'avant, et pour
        // une raison de mise en page, pas de goût : la bande ne fixe plus sa
        // hauteur, elle la lit sur ses puces. Un `VerticalDivider` n'a alors
        // plus aucune contrainte verticale à remplir et se réduit à rien —
        // le séparateur aurait disparu en silence. Vingt points est l'écart
        // qui sépare déjà les groupes sur la page des véhicules.
        if (cities.isNotEmpty) const SizedBox(width: 20),
        for (final city in cities)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: const Icon(Icons.location_on_outlined, size: 14),
              label: Text(city),
              selected: filter.city == city,
              onSelected: (_) => update(
                (f) => f.copyWith(
                  city: f.city == city ? null : city,
                  clearCity: f.city == city,
                  clearLocation: f.city == city,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Grille décalée ───────────────────────────────────────────────

// Hauteur unique, et 140 depuis le 2026-10-16 : voir la note detaillee sur la
// page des pieces. Les deux valeurs doivent rester egales, les deux listes
// etant cote a cote dans la meme barre d'onglets.
const _imgHeight = 140.0;

// Icônes par catégorie d'accessoire
const _categoryIcons = <String, IconData>{
  'esthetique': Icons.auto_awesome,
  'confort': Icons.airline_seat_recline_normal,
  'securite': Icons.shield_outlined,
  'multimedia': Icons.speaker_outlined,
  'utilitaire': Icons.build_outlined,
};

class _AccessoryList extends StatelessWidget {
  final List<Accessory> accessories;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollCtrl;
  const _AccessoryList({
    required this.accessories,
    required this.total,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollCtrl,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              AppLocalizations.of(context).catalogResultCount(total),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _StaggeredAccessoryGrid(accessories: accessories),
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (!hasMore && accessories.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).catalogResultTotal(total),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
        // Dégage la dernière rangée du bouton flottant — voir la note
        // détaillée sur la liste des pièces. Il manquait sur les deux.
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

class _StaggeredAccessoryGrid extends StatelessWidget {
  final List<Accessory> accessories;
  const _StaggeredAccessoryGrid({required this.accessories});

  @override
  Widget build(BuildContext context) {
    final left = <(Accessory, double)>[];
    final right = <(Accessory, double)>[];
    for (int i = 0; i < accessories.length; i++) {
      const h = _imgHeight;
      if (i.isEven)
        left.add((accessories[i], h));
      else
        right.add((accessories[i], h));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: left
                  .map(
                    (e) => _AccessoryCard(accessory: e.$1, imageHeight: e.$2),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: right
                  .map(
                    (e) => _AccessoryCard(accessory: e.$1, imageHeight: e.$2),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessoryCard extends ConsumerStatefulWidget {
  final Accessory accessory;
  final double imageHeight;
  const _AccessoryCard({required this.accessory, required this.imageHeight});

  @override
  ConsumerState<_AccessoryCard> createState() => _AccessoryCardState();
}

class _AccessoryCardState extends ConsumerState<_AccessoryCard> {
  bool _toggling = false;

  Future<void> _toggle() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ref
          .read(catalogRepositoryProvider)
          .toggleAccessoryAvailability(widget.accessory.id);
      ref.read(accessoryListProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final isStaff = auth.isStaff;
    final accessory = widget.accessory;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.hardEdge,
      elevation: 1.5,
      shadowColor: cs.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            context.push('/accessories/${accessory.id}', extra: accessory),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Zone image ─────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: widget.imageHeight,
                  width: double.infinity,
                  child: accessory.coverUrl != null
                      ? CatalogImage(
                          url: accessory.coverUrl!,
                          fallback: _AccessoryPlaceholder(
                            accessory: accessory,
                            cs: cs,
                          ),
                        )
                      : _AccessoryPlaceholder(accessory: accessory, cs: cs),
                ),
                // Bascule de disponibilite : reservee aux roles qui tiennent
                // le stock (direction et magasin), pas a tout le personnel.
                if (auth.canManageStock)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _toggling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : GestureDetector(
                            onTap: _toggle,
                            child: _SmallAvailabilityBadge(
                              isAvailable: accessory.stock.isAvailable,
                            ),
                          ),
                  ),
              ],
            ),

            // ── Infos ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Le nom en entier, dans la typographie qu'occupait la
                  // categorie. Meme raisonnement que sur la carte des pieces,
                  // et meme rendu : les deux listes se cotoient dans la meme
                  // barre d'onglets, elles ne doivent pas diverger.
                  //
                  // On reprend telle quelle la police de la categorie —
                  // labelSmall, sans surcharge de graisse. Seule la couleur
                  // change : onSurface et non outline, le nom etant le contenu
                  // principal de la carte.
                  Text(
                    accessory.name,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: cs.onSurface),
                  ),
                  // LES MODÈLES AUXQUELS L'ACCESSOIRE SE DESTINE, à la même
                  // place et avec le même widget que sur la carte des pièces.
                  // Les deux listes se côtoient dans la même barre d'onglets :
                  // deux formes de la même ligne se seraient mises à diverger,
                  // et c'est l'écran qui l'aurait montré.
                  LigneCompatibilite(resume: accessory.compatibility),
                  const SizedBox(height: 6),
                  Text(
                    formatXofShort(accessory.pricing.sellingPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      fontSize: 13,
                    ),
                  ),
                  if (!isStaff) ...[
                    const SizedBox(height: 4),
                    _AvailabilityBadge(
                      isAvailable: accessory.stock.isAvailable,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder dégradé pour accessoire sans photo.
class _AccessoryPlaceholder extends StatelessWidget {
  final Accessory accessory;
  final ColorScheme cs;
  const _AccessoryPlaceholder({required this.accessory, required this.cs});

  @override
  Widget build(BuildContext context) {
    final icon =
        _categoryIcons[accessory.categoryValue] ?? Icons.inventory_2_outlined;
    return Container(
      // `tertiary` est le lavande que Material derive du seed bleu ardoise :
      // il n'appartient pas a la gamme de la marque. On reste sur les surfaces
      // neutres, qui laissent l'icone et le texte porter l'information.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.surfaceContainerHighest, cs.surfaceContainerHigh],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // La categorie figure deja en sous-titre de la carte : la repeter
            // ici affichait « Securite » sous « Securite ». Seule l'icone reste.
            Icon(icon, size: 30, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Petit badge vert/rouge en overlay (staff).
class _SmallAvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _SmallAvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: (isAvailable ? Colors.green : Colors.red).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      isAvailable ? '✓' : '✗',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// Badge "Disponible" / "Indisponible" — tappable pour le staff.
class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    // Une information portee par 100 % des cartes n'en est plus une : seule
    // l'indisponibilite merite d'etre signalee.
    if (isAvailable) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.withOpacity(0.12) : cs.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAvailable
            ? AppLocalizations.of(context).catalogStockIn
            : AppLocalizations.of(context).catalogStockOut,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isAvailable ? Colors.green.shade700 : cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── États vide / erreur ─────────────────────────────────────────

/// Aucun résultat — en nommant les filtres qui l'expliquent.
class _EmptyView extends ConsumerWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final f = ref.watch(accessoryFilterProvider);
    final actifs = <String>[
      if (f.search?.isNotEmpty == true) l10n.catalogFilterTermQuery(f.search!),
      if (f.category != null) l10n.catalogFilterTermCategory,
      if (f.priceMax != null) l10n.catalogFilterTermPriceMax,
      // Le nom de la ville vient du référentiel du serveur et reste en
      // français jusqu'à la vague serveur : pas de clé.
      if (f.city != null) f.city!,
    ];

    // Il défile, pour la raison mesurée et écrite dans `_EmptyView` de
    // `vehicle_list_page.dart` : un `Center` autour d'une `Column` dépassait de
    // 166 points à 320 × 2,0, en français et sans aucun filtre posé, et son
    // dernier lien était hors d'atteinte. Le `ConstrainedBox` garde le contenu
    // centré tant qu'il tient.
    return LayoutBuilder(
      builder: (context, contraintes) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: contraintes.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: cs.outline),
                const SizedBox(height: 14),
                Text(
                  l10n.catalogAccessoryNoneFound,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    actifs.isEmpty
                        ? l10n.catalogAccessoryCatalogEmpty
                        : l10n.catalogActiveFilters(
                            actifs.join(l10n.catalogFilterListSeparator),
                          ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                if (actifs.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ref.read(accessoryFilterProvider.notifier).state =
                            const AccessoryFilter(),
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: Text(l10n.catalogClearFilters),
                  ),
                ],
                TextButton.icon(
                  onPressed: () => context.push('/needs/new?type=accessory'),
                  icon: const Icon(Icons.inbox_outlined, size: 18),
                  label: Text(l10n.catalogNeedCta),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off, size: 48),
        const SizedBox(height: 12),
        Text(error, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).commonRetry),
        ),
      ],
    ),
  );
}
