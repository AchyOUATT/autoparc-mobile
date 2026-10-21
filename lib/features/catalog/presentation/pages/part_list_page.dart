import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/part.dart';
import '../../data/models/part_category.dart';
import '../providers/catalog_providers.dart';
import '../widgets/niveau_categories.dart';
import '../../../../shared/models/paged_state.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/bande_filtres.dart';
import '../../../../core/widgets/bouton_flottant_effacable.dart';
import '../../../../core/widgets/catalog_image.dart';
import '../../../../core/widgets/grille_maconnerie.dart';
import '../../../../core/widgets/titre_barre.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/cart/presentation/pages/cart_page.dart';
import '../../../../features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../../features/notifications/presentation/widgets/notification_icon_button.dart';
import '../../../../features/garage/data/models/owned_vehicle.dart';
import '../../../../features/garage/presentation/providers/garage_provider.dart';
import '../../../../core/providers/shell_scaffold_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/ligne_compatibilite.dart';

// ── Labels des types/conditions ─────────────────────────────────────

/// Le libellé des quatre natures de pièce, dans la langue active.
///
/// C'ÉTAIT UNE TABLE `const`, et elle ne pouvait pas le rester : une constante
/// est construite avant qu'aucun `BuildContext` n'existe, donc avant que la
/// langue soit connue. Les quatre libellés y seraient restés français quelle
/// que soit la langue choisie.
///
/// Trois des quatre s'écrivent pareil dans les deux langues — « OEM », « OES »
/// sont des sigles, « Aftermarket » est un emprunt que le français fait déjà —
/// et ils passent quand même par une clé : en laisser trois en dur aurait rendu
/// le quatrième introuvable au lot suivant, et le badge est borné en largeur.
///
/// Le repli reste le code brut du serveur en capitales. Ce n'est pas un
/// libellé, c'est un aveu : une nature inconnue de cette table doit se voir.
String _libelleType(AppLocalizations l10n, String type) => switch (type) {
  'oem' => l10n.catalogPartTypeOem,
  'oes' => l10n.catalogPartTypeOes,
  'aftermarket' => l10n.catalogPartTypeAftermarket,
  'salvage' => l10n.catalogPartTypeSalvage,
  _ => type.toUpperCase(),
};

const _conditionColors = {
  'new': Colors.green,
  'refurbished': Colors.orange,
  'used': Colors.grey,
};

// ════════════════════════════════════════════════════════════════════
// Page principale
// ════════════════════════════════════════════════════════════════════

class PartListPage extends ConsumerStatefulWidget {
  const PartListPage({super.key});

  @override
  ConsumerState<PartListPage> createState() => _PartListPageState();
}

class _PartListPageState extends ConsumerState<PartListPage> {
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
      ref.read(partListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paged = ref.watch(partListProvider);
    final filter = ref.watch(partFilterProvider);
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
                  await context.push('/parts/new');
                  ref.read(partListProvider.notifier).refresh();
                },
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context).catalogPartAddCta),
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
        title: TitreBarre(AppLocalizations.of(context).catalogPartListTitle),
        actions: [
          const NotificationIconButton(),
          if (!isStaff) ...[
            IconButton(
              icon: const Icon(Icons.inbox_outlined),
              tooltip: AppLocalizations.of(context).catalogNeedTooltip,
              onPressed: () => context.push('/needs/new?type=part'),
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
              hintText: AppLocalizations.of(context).catalogPartSearchHint,
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(partFilterProvider.notifier).state = filter
                          .copyWith(clearSearch: true);
                    },
                  ),
              ],
              // Voir vehicle_list_page.dart. Sur CETTE liste le defaut etait
              // total : `PartFilter` n'avait pas de `clearSearch`, donc le
              // bouton « ✕ » ne nettoyait pas davantage que le clavier.
              onChanged: (q) => ref.read(partFilterProvider.notifier).state =
                  q.isEmpty
                      ? filter.copyWith(clearSearch: true)
                      : filter.copyWith(search: q),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          _FilterBar(filter: filter, cities: cities),
          // Filtre "pour mon véhicule" — visible uniquement pour les clients connectés.
          if (!isStaff) const _GarageFilterBanner(),
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
  final PagedState<Part> paged;
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
        onRetry: () => ref.read(partListProvider.notifier).refresh(),
      );
    }
    if (paged.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(partListProvider.notifier).refresh(),
      child: _PartList(
        parts: paged.items,
        total: paged.total,
        hasMore: paged.hasMore,
        isLoadingMore: paged.isLoadingMore,
        scrollCtrl: scrollCtrl,
      ),
    );
  }
}

// ── Barre de filtres ─────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  final PartFilter filter;
  final List<String> cities;
  const _FilterBar({required this.filter, required this.cities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(PartFilter Function(PartFilter) fn) {
      ref.read(partFilterProvider.notifier).state = fn(
        ref.read(partFilterProvider),
      );
    }

    // La barre ne contenait que des villes. Aucune n'etant renseignee, elle
    // s'affichait vide — 48 dp de rien — alors que la page presente 200
    // references sans aucun moyen de les trier par nature. Les accessoires,
    // eux, ont leurs categories pour seulement 80 articles.
    //
    // Les pastilles viennent de l'arbre ÉLAGUÉ, pas de l'arbre complet, et le
    // niveau n'est plus figé sur les racines : neuf pastilles étaient proposées
    // et une seule menait quelque part. `niveauDiscriminant` descend jusqu'au
    // niveau qui partage réellement le catalogue, et ne rend rien quand aucun
    // niveau ne le partage — mieux vaut pas de barre qu'une barre qui ne trie
    // rien. Le serveur inclut les descendantes dans le filtre, donc une
    // pastille de niveau intermédiaire couvre bien ses feuilles.
    final elague = ref.watch(categoriesAvecPiecesProvider);
    final categories = niveauDiscriminant(
      elague.valueOrNull ?? const <PartCategory>[],
    );

    // Un filtre posé sur une catégorie qui n'est plus proposée ne pourrait
    // plus être retiré : la désélection passe par la pastille elle-même, et
    // elle a disparu. La liste resterait vide sans qu'aucun geste n'y change
    // quoi que ce soit.
    //
    // Conditionné à `hasValue` : pendant le chargement, la liste est vide sans
    // rien dire de l'occupation, et effacer là réinitialiserait le filtre à
    // chaque ouverture de l'écran.
    if (elague.hasValue &&
        filter.categoryId != null &&
        !categories.any((c) => c.id == filter.categoryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        update((f) => f.copyWith(clearCategory: true));
      });
    }

    if (categories.isEmpty && cities.isEmpty) {
      return const SizedBox.shrink();
    }

    // Même bande que les véhicules et les accessoires depuis ce lot. Les 48
    // points étaient écrits ici à la main ; ils viennent désormais du plancher
    // de cible tactile des puces elles-mêmes, et les bords s'estompent au lieu
    // de se couper net — voir `BandeFiltres`. En laisser deux pages à l'ancien
    // dessin aurait eu l'air d'un défaut, comme pour les barres de recherche.
    return BandeFiltres(
      children: [
        for (final c in categories)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(c.name),
              selected: filter.categoryId == c.id,
              onSelected: (_) => update(
                (f) => f.categoryId == c.id
                    ? f.copyWith(clearCategory: true)
                    : f.copyWith(categoryId: c.id),
              ),
            ),
          ),

        // Chips de ville
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

// ── Grille décalée ───────────────────────────────────────────────────

// LA CONSTANTE `_imgHeight = 140.0` A QUITTÉ CE FICHIER. Elle y était écrite
// deux fois — ici et dans `accessory_list_page.dart` — avec la consigne « les
// deux valeurs doivent rester egales », qu'aucun banc ne tenait. Elle est
// devenue le PLANCHER de `hauteurVignetteCatalogue`, dans
// core/widgets/grille_maconnerie.dart, qui porte aussi la raison du 140 et
// celle du rapport qui prend le relais au-dessus des largeurs de téléphone.

class _PartList extends StatelessWidget {
  final List<Part> parts;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollCtrl;
  const _PartList({
    required this.parts,
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
        SliverToBoxAdapter(child: _StaggeredPartsGrid(parts: parts)),
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (!hasMore && parts.isNotEmpty)
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
        // Dégage la dernière rangée du bouton flottant.
        //
        // IL MANQUAIT ICI, et la liste des véhicules l'avait : le bouton
        // « Nouvelle pièce » fait 56,0 points de haut et le `Scaffold` le pose
        // à 16 du bas, donc la dernière carte finissait dessous sans qu'aucun
        // défilement ne puisse l'en sortir. 88 points, la même valeur que la
        // liste des véhicules — deux listes côte à côte dans la même barre
        // d'onglets ne se dégagent pas différemment.
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

/// L'écart entre deux colonnes de cette liste.
///
/// 6 et non 10 comme sur les véhicules : la carte d'une pièce porte déjà une
/// marge de `Card`, et les deux listes n'ont jamais été réglées ensemble. La
/// valeur est inchangée par ce lot — elle est seulement nommée, parce que la
/// maçonnerie partagée la réclame et qu'un 6 anonyme passé en argument se
/// serait lu comme un choix neuf.
const double _ecartColonnes = 6.0;

/// La grille des pièces : la maçonnerie partagée, à N colonnes.
///
/// ELLE RÉPARTISSAIT SUR `i.isEven`, c'est-à-dire DEUX colonnes en dur, et la
/// liste des accessoires portait la même écriture recopiée. Les deux lisent
/// maintenant `nombreDeColonnes` — voir core/widgets/grille_maconnerie.dart
/// pour le seuil, son raisonnement et la garantie des deux colonnes sous 420
/// points.
///
/// LA HAUTEUR DE VIGNETTE SUIT LA COLONNE, et c'est la seconde moitié du
/// défaut : la constante seule laissait une image de 140 points dans une carte
/// de 629 à 1280 points d'écran. `hauteurVignetteCatalogue` la calcule depuis
/// la largeur reçue, avec un plancher à 140 qui rend les téléphones
/// rigoureusement identiques à ce qu'ils étaient.
class _StaggeredPartsGrid extends StatelessWidget {
  final List<Part> parts;
  const _StaggeredPartsGrid({required this.parts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: MaconnerieColonnes(
        nombre: parts.length,
        ecartHorizontal: _ecartColonnes,
        // Pas d'écart vertical ajouté : `_PartCard` pose déjà un
        // `Card(margin: EdgeInsets.only(bottom: 8))`. En ajouter un ici
        // doublerait l'espace entre deux cartes d'une même colonne.
        carte: (_, i, largeurColonne) => _PartCard(
          part: parts[i],
          imageHeight: hauteurVignetteCatalogue(largeurColonne),
        ),
      ),
    );
  }
}

class _PartCard extends ConsumerStatefulWidget {
  final Part part;
  final double imageHeight;
  const _PartCard({required this.part, required this.imageHeight});

  @override
  ConsumerState<_PartCard> createState() => _PartCardState();
}

class _PartCardState extends ConsumerState<_PartCard> {
  bool _toggling = false;

  Future<void> _toggle() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ref
          .read(catalogRepositoryProvider)
          .togglePartAvailability(widget.part.id);
      ref.read(partListProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final isStaff = auth.isStaff;
    final part = widget.part;
    final typeLabel = _libelleType(AppLocalizations.of(context), part.type);

    final selectedVehicle = ref.watch(selectedGarageVehicleProvider);
    final idsAsync = ref.watch(
      compatiblePartIdsProvider(selectedVehicle?.id ?? -1),
    );
    final isCompatible =
        selectedVehicle != null &&
        (idsAsync.valueOrNull?.contains(part.id) ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.hardEdge,
      elevation: 1.5,
      shadowColor: cs.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/parts/${part.id}', extra: part),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Zone image ─────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: widget.imageHeight,
                  width: double.infinity,
                  child: part.coverUrl != null
                      ? CatalogImage(
                          url: part.coverUrl!,
                          fallback: _PartPlaceholder(
                            type: typeLabel,
                            isOem: part.isOem,
                            cs: cs,
                          ),
                        )
                      : _PartPlaceholder(
                          type: typeLabel,
                          isOem: part.isOem,
                          cs: cs,
                        ),
                ),
                // Bascule de disponibilite : reservee aux roles qui tiennent le
                // stock (direction et magasin), pas a tout le personnel.
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
                              isAvailable: part.stock.isAvailable,
                            ),
                          ),
                  ),
                if (isCompatible)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
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
                  // categorie.
                  //
                  // La categorie ne figure plus ici : elle redisait le filtre
                  // deja actif en haut de l'ecran, et elle volait la ligne dont
                  // le nom avait besoin. Les references de pieces se
                  // distinguent souvent par leur fin — « Cartouche de filtre a
                  // huile 04152-YZZA1 » — donc une troncature a deux lignes
                  // coupait precisement ce qui permet de les reconnaitre.
                  //
                  // On reprend telle quelle la police de la categorie —
                  // labelSmall, sans surcharge de graisse. Un cran plus petit
                  // que bodySmall, ce qui laisse le nom tenir en entier sans
                  // allonger la carte.
                  //
                  // Seule la couleur change : onSurface et non outline. Le nom
                  // est le contenu principal de la carte ; en gris d'habillage
                  // il passerait pour une mention secondaire.
                  Text(
                    part.name,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: cs.onSurface),
                  ),
                  // LES MODÈLES COMPATIBLES, SOUS LE NOM ET AU-DESSUS DU PRIX.
                  //
                  // Cette place n'est pas indifférente. Sous le prix, la ligne
                  // aurait séparé le prix du badge de disponibilité, qui se
                  // lisent ensemble ; au-dessus du nom, elle aurait pris le
                  // premier regard pour une mention secondaire. Elle prolonge
                  // donc le nom, qui est ce qu'elle qualifie.
                  //
                  // `LigneCompatibilite` s'efface d'elle-même quand la clé
                  // `compatibility` manque ou qu'elle est vide, donc rien n'est
                  // conditionné ici : l'article sans compatibilité rend un
                  // `SizedBox.shrink()` et l'écart ci-dessous se referme
                  // dessus.
                  LigneCompatibilite(resume: part.compatibility),
                  const SizedBox(height: 6),
                  Text(
                    formatXofShort(part.pricing.sellingPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      fontSize: 13,
                    ),
                  ),
                  if (!isStaff) ...[
                    const SizedBox(height: 4),
                    _AvailabilityBadge(isAvailable: part.stock.isAvailable),
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

/// Placeholder dégradé pour pièce sans photo.
class _PartPlaceholder extends StatelessWidget {
  final String type;
  final bool isOem;
  final ColorScheme cs;
  const _PartPlaceholder({
    required this.type,
    required this.isOem,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isOem
            ? [cs.primaryContainer, cs.primary.withValues(alpha: 0.45)]
            : [cs.secondaryContainer, cs.secondary.withValues(alpha: 0.35)],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_outlined,
            size: 30,
            color: isOem ? cs.onPrimaryContainer : cs.onSecondaryContainer,
          ),
          const SizedBox(height: 4),
          Text(
            type,
            style: TextStyle(
              color: isOem ? cs.onPrimaryContainer : cs.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Petit badge disponibilité en overlay (staff).
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
        color: isAvailable
            ? Colors.green.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest,
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

// ── Bannière "Filtrer pour mon véhicule" ─────────────────────────────

/// Affichée pour les clients connectés ayant au moins un véhicule au garage.
/// Permet de sélectionner un véhicule et d'accéder directement à ses pièces
/// compatibles via [CompatiblePartsPage].
class _GarageFilterBanner extends ConsumerStatefulWidget {
  const _GarageFilterBanner();

  @override
  ConsumerState<_GarageFilterBanner> createState() =>
      _GarageFilterBannerState();
}

class _GarageFilterBannerState extends ConsumerState<_GarageFilterBanner> {
  OwnedVehicle? _selected;

  /// Restreint la liste aux pièces compatibles avec le véhicule choisi.
  ///
  /// Le filtrage est fait par le serveur : `getParts` bascule sur la route
  /// des pièces compatibles dès qu'un `vehicleModelId` lui est passé. Filtrer
  /// localement la page courante donnerait des pages de deux résultats et une
  /// pagination incohérente.
  bool _onlyCompatible = false;

  void _applyCompatibleFilter(bool on) {
    setState(() => _onlyCompatible = on);

    // Un véhicule au modèle tapé à la main n'a pas d'identifiant de catalogue
    // à transmettre : le filtre resterait vide et la liste paraîtrait vide
    // elle aussi. On ne l'applique pas — la bannière dit pourquoi.
    final modelId = _selected?.vehicleModelId;

    final filter = ref.read(partFilterProvider);
    ref.read(partFilterProvider.notifier).state = on && modelId != null
        ? filter.copyWith(vehicleModelId: modelId)
        : filter.copyWith(clearVehicleModel: true);
  }

  @override
  void initState() {
    super.initState();
    // Initialise le provider au premier véhicule après le premier frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vehicles = ref.read(garageProvider).valueOrNull;
      if (vehicles != null && vehicles.isNotEmpty) {
        final v = vehicles.first;
        setState(() => _selected = v);
        ref.read(selectedGarageVehicleProvider.notifier).state = v;
      }
    });
  }

  @override
  void deactivate() {
    // Efface le filtre actif quand on quitte la page des pièces — sans quoi
    // on retrouverait la liste silencieusement restreinte à un véhicule.
    //
    // Dans `dispose()`, Riverpod refuse `ref` : le widget est déjà démonté, et
    // chaque sortie de la page levait « Cannot use "ref" after the widget was
    // disposed ». `deactivate()` s'exécute juste avant, alors que `ref` est
    // encore valide.
    //
    // Mais écrire directement ici ne marche pas non plus : `deactivate()`
    // s'exécute PENDANT la mise à jour de l'arbre, et Riverpod l'interdit.
    // Passer à l'onglet Accessoires affichait « Tried to modify a provider
    // while the widget tree was building », en rouge sur tout l'écran. Le
    // déplacement de `dispose()` vers `deactivate()` avait corrigé une erreur
    // et introduit l'autre.
    //
    // On lit donc les notifiers maintenant — `ref` est valide — et on écrit
    // après la frame. L'état courant est relu dans le rappel plutôt que
    // capturé ici, pour ne pas réécrire une valeur devenue obsolète
    // entre-temps.
    //
    // L'assertion n'existe qu'en debug (flutter_riverpod framework.dart:309,
    // sous `if (kDebugMode)`), donc rien de ceci n'était visible en
    // production — mais la violation de cycle de vie, elle, était réelle.
    //
    // ── LE `mounted` N'EST PAS UNE PRÉCAUTION, C'EST UNE CORRECTION ─────────
    //
    // Ce commentaire affirmait : « Les deux sont des StateProvider simples,
    // non autoDispose : leurs contrôleurs sont encore là au moment du rappel. »
    // C'est faux dès que le `ProviderScope` lui-même disparaît entre la trame
    // et le rappel — le rappel écrit alors dans un contrôleur jeté et lève
    // « Tried to use StateController<OwnedVehicle?> after dispose was
    // called ». Mesuré : le groupe « Les écrans vides du catalogue » de
    // bandes_filtres_test.dart a fait tomber ses 48 cases « pièces, client »
    // sur cette erreur à la seconde où il a monté un CLIENT, parce que c'est
    // `if (!isStaff)` qui insère ce bandeau.
    //
    // Deux fichiers de banc portaient l'avertissement en commentaire et
    // contournaient le cas en ne montant jamais de client sur cette page : un
    // rôle entier d'un écran client restait donc hors de portée pour éviter
    // une erreur de cycle de vie à deux lignes de la corriger. `mounted` est
    // public sur `StateNotifier`, dont `StateController` hérite.
    final vehiculeSelectionne = ref.read(
      selectedGarageVehicleProvider.notifier,
    );
    final filtre = ref.read(partFilterProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!vehiculeSelectionne.mounted || !filtre.mounted) return;
      vehiculeSelectionne.state = null;
      filtre.state = filtre.state.copyWith(clearVehicleModel: true);
    });

    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final garageAsync = ref.watch(garageProvider);
    final vehicles = garageAsync.valueOrNull;

    // Ne rien afficher si le garage est vide, en erreur (non connecté) ou en chargement.
    if (vehicles == null || vehicles.isEmpty) return const SizedBox.shrink();

    // Resync local state si le véhicule sélectionné a été supprimé du garage.
    if (_selected == null || !vehicles.any((v) => v.id == _selected!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final v = vehicles.first;
        setState(() => _selected = v);
        ref.read(selectedGarageVehicleProvider.notifier).state = v;
      });
      return const SizedBox.shrink(); // évite le flash d'un état incohérent
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car_outlined, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<OwnedVehicle>(
                  value: _selected,
                  isExpanded: true,
                  // itemHeight non nul vaut kMinInteractiveDimension (48) :
                  // c'etait lui, et non les marges, qui fixait la hauteur du
                  // bandeau. A null, le bouton se contente de son contenu, et
                  // la cible tactile reste celle de la ligne entiere.
                  itemHeight: null,
                  iconSize: 20,
                  style: Theme.of(context).textTheme.bodySmall,
                  items: vehicles
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            v.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selected = v);
                    ref.read(selectedGarageVehicleProvider.notifier).state = v;
                    // Changer de véhicule alors que le filtre est actif doit
                    // relancer la recherche sur le nouveau, pas conserver
                    // silencieusement les pièces du précédent.
                    if (_onlyCompatible) _applyCompatibleFilter(true);
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Filtrer sur place plutôt qu'ouvrir un second écran : le véhicule
            // est déjà choisi ici, et la liste sait déjà quelles pièces lui
            // correspondent. Partir ailleurs faisait perdre la recherche, la
            // catégorie et la ville déjà saisies.
            // Désactivé pour un véhicule au modèle tapé à la main : le
            // catalogue ne le connaît pas, et le filtre n'aurait rien à quoi
            // se raccrocher. Grisé avec son motif plutôt qu'actif et sans
            // effet — un bouton qui ne fait rien se lit comme une panne.
            Tooltip(
              message: _selected!.modeleHorsCatalogue
                  ? AppLocalizations.of(
                      context,
                    ).catalogGarageFitmentUnknownModel
                  : AppLocalizations.of(context).catalogGarageFitmentTooltip,
              child: FilterChip(
                label: Text(
                  AppLocalizations.of(context).catalogGarageFitmentChip,
                ),
                selected: _onlyCompatible && !_selected!.modeleHorsCatalogue,
                onSelected: _selected!.modeleHorsCatalogue
                    ? null
                    : (on) => _applyCompatibleFilter(on),
                visualDensity: VisualDensity.compact,
                // Meme motif que le menu deroulant : le chip reservait 48
                // points de cible tactile au milieu d'un bandeau qui n'en
                // fait plus 48.
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: Theme.of(context).textTheme.labelMedium,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── États vide / erreur ──────────────────────────────────────────────

/// Aucun résultat — en nommant les filtres qui l'expliquent.
///
/// « Aucune pièce trouvée » laissait chercher lequel des quatre critères
/// actifs est de trop. Le catalogue compte 200 pièces : quand l'écran est
/// vide, c'est presque toujours un filtre, pas un catalogue vide.
class _EmptyView extends ConsumerWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final filtre = ref.watch(partFilterProvider);
    final actifs = <String>[
      if (filtre.search?.isNotEmpty == true)
        l10n.catalogFilterTermQuery(filtre.search!),
      if (filtre.oem?.isNotEmpty == true) l10n.catalogFilterTermOem,
      if (filtre.categoryId != null) l10n.catalogFilterTermCategory,
      if (filtre.vehicleModelId != null) l10n.catalogFilterTermFitment,
      // Le nom de la ville vient du référentiel du serveur et reste en
      // français jusqu'à la vague serveur : pas de clé.
      if (filtre.city != null) filtre.city!,
      if (filtre.inStockOnly) l10n.catalogFilterTermInStock,
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
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_outlined, size: 56, color: cs.outline),
                  const SizedBox(height: 14),
                  Text(
                    l10n.catalogPartNoneFound,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (actifs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.catalogActiveFilters(
                        actifs.join(l10n.catalogFilterListSeparator),
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          ref.read(partFilterProvider.notifier).state =
                              const PartFilter(),
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                      label: Text(l10n.catalogClearFilters),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.catalogPartCatalogEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  TextButton.icon(
                    onPressed: () => context.push('/needs/new?type=part'),
                    icon: const Icon(Icons.inbox_outlined, size: 18),
                    label: Text(l10n.catalogNeedCta),
                  ),
                ],
              ),
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
