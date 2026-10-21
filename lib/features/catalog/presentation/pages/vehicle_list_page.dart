import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/vehicle.dart';
import '../providers/catalog_providers.dart';
import '../../../../shared/models/paged_state.dart';
import '../libelles_vehicule.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/bande_filtres.dart';
import '../../../../core/widgets/bouton_flottant_effacable.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/catalog_image.dart';
import '../../../../core/widgets/grille_maconnerie.dart';
import '../../../../core/widgets/titre_barre.dart';
import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../notifications/presentation/widgets/notification_icon_button.dart';
import '../../../../core/providers/shell_scaffold_provider.dart';
import '../../../../l10n/app_localizations.dart';

class VehicleListPage extends ConsumerStatefulWidget {
  const VehicleListPage({super.key});

  @override
  ConsumerState<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends ConsumerState<VehicleListPage> {
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
      ref.read(vehicleListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paged = ref.watch(vehicleListProvider);
    final filter = ref.watch(vehicleFilterProvider);
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
                  // On rafraichit au retour, sans condition.
                  //
                  // Le test `added == true` ne se verifiait jamais apres un
                  // enregistrement reussi : la page d'enregistrement ne revient
                  // pas ici, elle fait pushReplacement vers l'envoi des photos.
                  // C'est donc cet ecran-la qui se depile, et il ne rend pas
                  // true. La liste restait telle qu'avant, et le vehicule tout
                  // juste cree y apparaissait sans sa photo — alors que le
                  // serveur la renvoyait deja.
                  await context.push<bool>('/vehicles/new');
                  if (context.mounted) {
                    ref.read(vehicleListProvider.notifier).refresh();
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context).catalogVehicleAddCta),
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
        title: TitreBarre(AppLocalizations.of(context).commonVehicles),
        actions: [
          const NotificationIconButton(),
          if (!isStaff)
            IconButton(
              icon: const Icon(Icons.inbox_outlined),
              tooltip: AppLocalizations.of(context).catalogNeedTooltip,
              onPressed: () => context.push('/needs/new?type=vehicle'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: SearchBar(
              // 40 au lieu des 56 par defaut de Material 3. Sans contrainte
              // explicite la SearchBar se fixe a 56, et le PreferredSize
              // reduit ne ferait que la rogner.
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
              controller: _searchCtrl,
              hintText: AppLocalizations.of(context).catalogVehicleSearchHint,
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(vehicleFilterProvider.notifier).state = filter
                          .copyWith(clearSearch: true);
                    },
                  ),
              ],
              // `clearSearch` ET NON `search: null` QUAND LE CHAMP SE VIDE.
              //
              // Dans ce `copyWith`, `null` signifie « ne change pas » :
              //     search: clearSearch ? null : (search ?? this.search)
              // Passer `search: null` laissait donc le terme PRECEDENT en
              // place. Signale par le proprietaire : « apres une recherche
              // dans la barre de recherche de vehicules je ne retrouve plus
              // tous les vehicules, d'autres ne s'affichent plus ».
              //
              // Le bouton « ✕ » juste au-dessus passait bien `clearSearch`,
              // ce qui masquait le defaut : effacer d'un geste marchait,
              // effacer au CLAVIER ne marchait pas. Deux chemins pour la meme
              // intention, un seul correct.
              onChanged: (q) => ref.read(vehicleFilterProvider.notifier).state =
                  q.isEmpty
                      ? filter.copyWith(clearSearch: true)
                      : filter.copyWith(search: q),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // UNE SEULE BANDE, et c'est l'objet du lot. Elles étaient deux, de 44
          // points chacune — 88 en tout —, et le plancher de 48 points de cible
          // tactile interdit d'en amincir une seule au-dessous de 48. Réduire
          // voulait donc dire en supprimer une : les quatre groupes défilent
          // maintenant dans la même bande. Mesure du gain dans
          // `carte_geometrie_test.dart`.
          _FilterChips(filter: filter, cities: cities),
          Expanded(
            child: _Body(paged: paged, scrollCtrl: _scrollCtrl),
          ),
        ],
      ),
    );
  }
}

// ── Corps principal ─────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final PagedState<Vehicle> paged;
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
        onRetry: () => ref.read(vehicleListProvider.notifier).refresh(),
      );
    }
    if (paged.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(vehicleListProvider.notifier).refresh(),
      child: VehicleGrid(
        vehicles: paged.items,
        total: paged.total,
        hasMore: paged.hasMore,
        isLoadingMore: paged.isLoadingMore,
        scrollCtrl: scrollCtrl,
      ),
    );
  }
}

// ── La bande de filtres : offre, type, ville, carrosserie ────────

/// Les quatre groupes de filtres, dans UNE bande qui défile.
///
/// POURQUOI UNE SEULE BANDE. « CARROSSERIE » vivait dans une seconde rangée, et
/// les deux rangées faisaient 88 points mesurés au-dessus de la liste. La cible
/// tactile de 48 points interdit d'amincir une rangée au-dessous de 48 — voir
/// [BandeFiltres], qui démontre que les 44 points d'alors rabotaient DÉJÀ cette
/// cible à 44. Rendre de la hauteur à la liste ne pouvait donc pas passer par
/// l'épaisseur d'une rangée : il fallait en supprimer une.
///
/// LE COÛT EST RÉEL ET IL EST DIT : les onze puces de carrosserie étaient
/// visibles sans geste, en bas à gauche ; elles sont maintenant au bout d'un
/// défilement horizontal, derrière les sept puces d'offre et de type. Elles
/// gardent leur rang de dernier groupe — c'était déjà le leur, « en dessous »
/// devenant « après » — et le dégradé du bord droit annonce qu'il y a une
/// suite. Le groupe « VILLE » les précède parce que le parc n'en renseigne
/// aucune en production : la bande des pièces a été vue vide pour cette raison
/// exacte.
class _FilterChips extends ConsumerWidget {
  final VehicleFilter filter;
  final List<String> cities;
  const _FilterChips({required this.filter, required this.cities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    void update(VehicleFilter Function(VehicleFilter) fn) {
      ref.read(vehicleFilterProvider.notifier).state = fn(
        ref.read(vehicleFilterProvider),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BandeFiltres(
          children: [
            LibelleGroupeFiltres(l10n.catalogFilterGroupOffer),
            FilterChip(
              label: Text(l10n.catalogOfferSale),
              selected: filter.availability == 'sale',
              onSelected: (_) => update(
                (f) => f.copyWith(
                  availability: f.availability == 'sale' ? null : 'sale',
                  clearAvailability: f.availability == 'sale',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(l10n.catalogOfferRent),
              selected: filter.availability == 'rent',
              onSelected: (_) => update(
                (f) => f.copyWith(
                  availability: f.availability == 'rent' ? null : 'rent',
                  clearAvailability: f.availability == 'rent',
                ),
              ),
            ),
            const SizedBox(width: 8),
            _DealChip(filter: filter),
            const SizedBox(width: 8),
            FilterChip(
              avatar: const Icon(Icons.verified_outlined, size: 14),
              label: Text(l10n.catalogCustomsCleared),
              selected: filter.customsCleared == true,
              onSelected: (_) => update(
                (f) => f.customsCleared == true
                    ? f.copyWith(clearCustomsCleared: true)
                    : f.copyWith(customsCleared: true),
              ),
            ),
            const SizedBox(width: 20),
            LibelleGroupeFiltres(l10n.catalogFilterGroupType),
            FilterChip(
              avatar: const Icon(Icons.airport_shuttle_outlined, size: 14),
              label: Text(l10n.catalogVehicleTypeUtility),
              selected: filter.vehicleType == 'utility',
              onSelected: (_) => update(
                (f) => f.copyWith(
                  vehicleType: f.vehicleType == 'utility' ? null : 'utility',
                  clearVehicleType: f.vehicleType == 'utility',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              avatar: const Icon(Icons.local_shipping_outlined, size: 14),
              label: Text(l10n.catalogVehicleTypeHeavy),
              selected: filter.vehicleType == 'heavy',
              onSelected: (_) => update(
                (f) => f.copyWith(
                  vehicleType: f.vehicleType == 'heavy' ? null : 'heavy',
                  clearVehicleType: f.vehicleType == 'heavy',
                ),
              ),
            ),
            if (cities.isNotEmpty) ...[
              const SizedBox(width: 20),
              LibelleGroupeFiltres(l10n.catalogFilterGroupCity),
              for (final city in cities) ...[
                FilterChip(
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
                const SizedBox(width: 8),
              ],
            ],
          ],
        ),
        // ── Les carrosseries, sur leur propre ligne ────────────────
        //
        // Elles ont vécu un temps au bout de la bande unique, derrière les
        // puces d'offre et de type : la fusion rendait 40 points à la liste,
        // mais il fallait un défilement horizontal pour atteindre les onze
        // carrosseries. Le propriétaire les a redemandées visibles sans geste.
        //
        // LE PRIX EST CONNU ET ASSUMÉ : deux bandes conformes font 96 points
        // contre 48, et contre 88 avant toute cette passe — l'allègement est
        // donc perdu, et au-delà. La cause est la cible tactile de 48 points,
        // que les 44 points d'origine enfreignaient déjà en silence ; on ne
        // peut pas avoir deux rangées ET la hauteur, seulement choisir.
        BandeFiltres(
          children: [
            LibelleGroupeFiltres(l10n.catalogFilterGroupBodyStyle),
            ..._bodyStyles.map((s) {
              final selected = filter.bodyStyle == s.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(s.icon, size: 14),
                  label: Text(libelleCarrosserieFiltre(l10n, s.value)),
                  selected: selected,
                  onSelected: (_) {
                    ref.read(vehicleFilterProvider.notifier).state = filter
                        .copyWith(
                          bodyStyle: selected ? null : s.value,
                          clearBodyStyle: selected,
                        );
                  },
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

/// Puce « Bonne affaire », qui remplace l'ancien filtre « Neuf ».
///
/// Elle pulse doucement tant qu'il existe des promotions et qu'elle n'est pas
/// encore activée : c'est ce qui la fait remarquer dans une rangée de filtres
/// par ailleurs immobile. L'animation s'arrête dès qu'on l'active — une puce
/// qui continue de bouger après avoir été prise en compte devient une gêne.
///
/// Elle est également désactivée lorsque le système signale une préférence
/// pour la réduction des animations.
class _DealChip extends ConsumerStatefulWidget {
  final VehicleFilter filter;
  const _DealChip({required this.filter});

  @override
  ConsumerState<_DealChip> createState() => _DealChipState();
}

class _DealChipState extends ConsumerState<_DealChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// La pulsation ne se joue qu'une fois par affichage de la page.
  bool _pulsed = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.filter.deal == true;
    final count = ref.watch(dealCountProvider).valueOrNull ?? 0;
    final animate =
        count > 0 && !selected && !MediaQuery.disableAnimationsOf(context);

    // Trois battements, puis plus rien. Une pulsation perpétuelle forcerait un
    // rendu à chaque vsync tant que la page est ouverte — coûteux en batterie
    // et vite agaçant — sans attirer davantage l'attention qu'un signal bref.
    if (animate && !_pulsed) {
      _pulsed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ctrl.repeat(reverse: true, count: 3);
      });
    } else if (!animate && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }

    final chip = FilterChip(
      avatar: const Icon(Icons.local_offer_outlined, size: 14),
      label: Text(
        count > 0
            ? AppLocalizations.of(context).catalogDealFilterCount(count)
            : AppLocalizations.of(context).catalogDealFilter,
      ),
      selected: selected,
      onSelected: (_) {
        ref.read(vehicleFilterProvider.notifier).state = selected
            ? widget.filter.copyWith(clearDeal: true)
            : widget.filter.copyWith(deal: true);
      },
    );

    return AnimatedBuilder(
      animation: _ctrl,
      // Transform.scale ne modifie pas la mise en page : les puces voisines
      // ne bougent pas pendant la pulsation.
      builder: (_, child) => Transform.scale(
        scale: 1 + 0.05 * Curves.easeInOut.transform(_ctrl.value),
        child: child,
      ),
      child: chip,
    );
  }
}

// ── Les carrosseries, dernier groupe de la bande ─────────────────

/// Les onze carrosseries du référentiel, dans l'ordre du parc.
///
/// Elles avaient leur propre rangée ; elles sont le dernier groupe de la bande
/// unique depuis ce lot — voir [_FilterChips] pour le compte et pour le coût.
/// LE LIBELLÉ A QUITTÉ CE TABLEAU, et il ne pouvait pas y rester : une liste
/// `const` est construite une fois pour toutes, avant qu'aucun `BuildContext`
/// n'existe, donc avant que la langue active soit connue. Un libellé écrit ici
/// ne pourrait jamais suivre un changement de langue — il serait figé au
/// premier rendu, c'est-à-dire en français pour tout le monde.
///
/// Le tableau garde ce qui ne dépend pas de la langue — l'ordre, la valeur
/// envoyée au serveur, l'icône —, et [libelleCarrosserieFiltre] rend le texte.
const _bodyStyles = [
  (value: 'sedan', icon: Icons.directions_car),
  (value: 'suv', icon: Icons.directions_car_filled),
  (value: 'hatchback', icon: Icons.directions_car_outlined),
  (value: 'pickup', icon: Icons.fire_truck),
  (value: 'minibus', icon: Icons.airport_shuttle),
  (value: 'bus', icon: Icons.directions_bus),
  (value: 'van', icon: Icons.local_shipping),
  (value: 'estate', icon: Icons.drive_eta),
  (value: 'truck', icon: Icons.local_shipping_outlined),
  (value: 'convertible', icon: Icons.wb_sunny_outlined),
  (value: 'coupe', icon: Icons.speed),
];

/// Le libellé d'une puce de carrosserie, dans la langue active.
///
/// DISTINCT DE CELUI DE LA FICHE DÉTAILLÉE, et c'est un constat et non un
/// choix : le français de `vehicle_detail_page.dart` dit « Citadine / Hayon »
/// et « Fourgonnette » là où cette bande dit « Citadine » et « Fourgon », pour
/// les mêmes valeurs `hatchback` et `van`. La divergence est antérieure à la
/// traduction ; l'unifier aurait changé le français de l'un des deux écrans,
/// ce qui n'est pas demandé. D'où deux jeux de clés, `catalogBodyStyle*` ici
/// et `catalogBodyLabel*` là-bas.
///
/// Le repli rend la valeur brute du serveur : une carrosserie inconnue de ce
/// tableau n'est pas censée arriver jusqu'ici — les puces viennent du tableau
/// lui-même —, et afficher le code est plus honnête qu'une chaîne vide.
String libelleCarrosserieFiltre(AppLocalizations l10n, String valeur) =>
    switch (valeur) {
      'sedan' => l10n.catalogBodyStyleSedan,
      'suv' => l10n.catalogBodyStyleSuv,
      'hatchback' => l10n.catalogBodyStyleHatchback,
      'pickup' => l10n.catalogBodyStylePickup,
      'minibus' => l10n.catalogBodyStyleMinibus,
      'bus' => l10n.catalogBodyStyleBus,
      'van' => l10n.catalogBodyStyleVan,
      'estate' => l10n.catalogBodyStyleEstate,
      'truck' => l10n.catalogBodyStyleTruck,
      'convertible' => l10n.catalogBodyStyleConvertible,
      'coupe' => l10n.catalogBodyStyleCoupe,
      _ => valeur,
    };

// ── Deux colonnes en maçonnerie, et le seuil a disparu ──────────

/// LE SEUIL N'EXISTE PLUS, et il faut dire ce qu'il était avant de dire ce qui
/// le remplace.
///
/// Le lot précédent calculait une largeur d'écran — 808 points — au-dessous de
/// laquelle la grille passait à UNE colonne, parce qu'une case de deux colonnes
/// ne laissait que 119,0 points de texte à 320 points d'écran et que le titre y
/// était tronqué. Aucun téléphone ne franchissait ce seuil : le parc visé
/// n'avait qu'une colonne.
///
/// LE PROPRIÉTAIRE A TRANCHÉ POUR DEUX ANNONCES PAR RANGÉE, à toutes les
/// largeurs de téléphone. La troncature ne se règle donc plus par la largeur
/// mais par la HAUTEUR : ce qui coupait le titre n'était pas les 119,0 points,
/// c'était le `childAspectRatio` du délégué, qui donnait à toutes les cases la
/// MÊME hauteur et ne laissait au texte que l'ellipse. Mesure du relecteur, et
/// remesurée ici dans la coque réelle : à 320 points comme à 411, à l'échelle
/// 1,0 comme à 2,0, le titre était COUPÉ dans les douze configurations.
///
/// Des cartes à hauteur INTRINSÈQUE suppriment ce budget : chaque carte prend la
/// hauteur de son contenu, le titre se replie, et rien n'est coupé. Le prix est
/// que les cartes sont inégales entre elles — depuis la maçonnerie elles sont
/// aussi DÉCALÉES, le propriétaire ayant dit que l'alignement n'était pas
/// nécessaire. Voir [VehicleGrid._sliverDesCartes].
///
/// Reste la conséquence que la largeur impose quand même, et elle est le vrai
/// sujet de ce lot : une carte qui n'a que 119,0 points de texte se replie
/// beaucoup, et le repli est de la HAUTEUR. Mesure, dans la coque réelle, à 320
/// points d'écran et à l'échelle de texte 1,0 — le réglage par DÉFAUT : une
/// carte portant titre, finition, caractéristiques, ville et prix fait une
/// rangée de 299,9 points pour les 320,0 que la page laisse à la liste, soit
/// ZÉRO annonce entière à l'écran. La seconde colonne rendait des annonces, le
/// repli les reprenait. Le contenu de la carte a donc été tranché par la mesure
/// — voir le tableau des cinq combinaisons dans [VehicleCard].

/// Ce que la grille retient avant d'arriver au texte d'une carte.
///
/// La grille vit dans un `SliverPadding.all(12)`, donc la largeur utile vaut
/// `écran − 24` ; N colonnes séparées de [_ecartColonnes] y mesurent
/// `(écran − 24 − 10 × (N − 1)) / N` chacune — et la maçonnerie n'y change
/// rien, l'écart restant un `SizedBox` entre les `Expanded`. SUR TÉLÉPHONE N
/// VAUT 2, à toutes les largeurs du parc visé, et les chiffres ci-dessous sont
/// ceux de ce cas-là : `nombreDeColonnes` ne rend 3 qu'à partir de 499 points
/// d'écran sur cette page. De cette case, `Card` retire 4 points de
/// marge de chaque côté — une valeur qui n'est écrite nulle part dans ce
/// fichier et qui a déjà faussé un calcul de lot — et le `Padding` du bloc de
/// texte 8 de plus, soit 24 en tout.
///
/// Les largeurs de texte qui en découlent, LUES dans les contraintes des
/// paragraphes et non recalculées ici : 119,0 points à 320 points d'écran,
/// 139,0 à 360, 164,5 à 411 — l'émulateur de référence. Le badge posé sur la
/// photo en reçoit 107,0 à 320 points : les 16 du `Positioned` et les 12 que
/// son `Container` ne rend pas.
const double _ecartColonnes = 10.0;

/// Combien de lignes une ligne de la carte peut prendre.
///
/// LE REPLI EST CE QUI REMPLACE LE SEUIL, et la borne est posée UNE ligne
/// au-dessus du maximum mesuré, pour la même raison que dans le lot précédent :
/// le titre vient d'un référentiel qui grandit, et un modèle plus long que
/// « Range Rover Sport » entrerait au prochain catalogue sans que personne ne
/// l'ait mesuré.
///
/// Comptage des lignes RÉELLEMENT POSÉES par le `TextPainter` à la largeur
/// REÇUE — pas une largeur voulue divisée par une largeur disponible, qui
/// ignorerait que le repli se fait mot à mot. Le pire cas est le titre à 320 et
/// à 360 points d'écran, à l'échelle 2,0 :
///
///   titre « Land Rover Range Rover Sport (2018) »  478,4 / 119,0 → 6 lignes
///   specs « 246 965 km • Électrique »              258,3 / 119,0 → 3 lignes
///   badge « Vente & Location »                     157,2 / 107,0 → 2 lignes
///   affaire « Bonne affaire »                      139,9 / 119,0 → 2 lignes
///   prix  « 99 999 999 FCFA »                      réduit par `_PrixAjuste`
///
/// Six lignes mesurées, donc, et la borne est à SEPT. Sur les vingt-quatre
/// cases du tableau — trois largeurs, quatre échelles, deux modes — c'est la
/// seule qui dépasse trois lignes.
///
/// UNE SECONDE VÉRIFICATION EST NÉCESSAIRE, et elle manquait : `maxLines` et
/// `didExceedMaxLines` ne disent RIEN d'un mot plus large que la ligne. Un tel
/// mot est posé seul sur sa ligne, dépasse horizontalement, et le
/// `clipBehavior` du `Card` le coupe en silence — le même rognage muet qui a
/// coûté un lot sur le badge. Le banc compare donc aussi
/// `TextPainter.minIntrinsicWidth`, qui est la largeur du plus long segment
/// insécable, à la contrainte reçue. Le pire est « Dioulasso » dans la ligne de
/// ville, et c'est l'une des raisons pour lesquelles la ville est partie.
const int _lignesDeLaCarte = 7;

// ── Grille de véhicules ─────────────────────────────────────────

/// La liste des cartes du catalogue, en maçonnerie, sur un nombre de colonnes
/// QUI SUIT LA LARGEUR DISPONIBLE.
///
/// Cette phrase disait « DEUX COLONNES à toutes les largeurs », et c'était
/// vrai — c'est précisément ce que le propriétaire a signalé depuis sa
/// tablette : « même la tablette affiche les recherches en 2 lignes en
/// portrait comme en paysage, et les objets sont très gros ». À 1280 points,
/// deux colonnes donnaient des cartes de 629 points.
///
/// La décision du nombre de colonnes vit désormais dans
/// `core/widgets/grille_maconnerie.dart`, en UN seul endroit que les trois
/// listes lisent : elle était écrite trois fois, et c'est pour cela que le
/// défaut existait en triple. Deux colonnes restent garanties sous 420 points
/// — la demande d'origine du propriétaire, « non je veux 2 annonces par
/// lignes » —, et mesurées inchangées au centième à 320, 360, 411 et 419.
///
/// Publique pour être mesurée en test. Le relecteur du lot précédent a montré
/// qu'une carte posée dans un `SizedBox` fait à la main, sous un `MaterialApp`
/// sans thème, donne des chiffres qui ne décrivent pas la vraie grille : la
/// largeur d'une case dépend du délégué ET du `SliverPadding`, et les corps de
/// texte dépendent du thème. `carte_geometrie_test.dart` monte donc CE widget,
/// avec `themeAutoParc`, et lit la contrainte que chaque paragraphe a
/// réellement reçue.
class VehicleGrid extends StatelessWidget {
  final List<Vehicle> vehicles;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollCtrl;
  const VehicleGrid({
    super.key,
    required this.vehicles,
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          sliver: SliverToBoxAdapter(
            // LA MENTION DE TVA PARTAGE CETTE LIGNE, et ne va pas sur les
            // cartes. Demande du propriétaire : « n'affiche pas TTC sur les
            // widgets de présentation, floque l'info en même alignement que
            // résultats trouvés, juste en bas de carrosserie, peut excentré à
            // droite ». Une étiquette par carte aurait dit douze fois ce qui se
            // dit une, sur une carte qu'on a passé du temps à désencombrer.
            //
            // `Expanded` sur le compte, et pas sur les deux : c'est LUI qui
            // grandit — « 1 résultat » contre « 148 résultats », et davantage
            // en anglais. La mention est courte et fixe, donc elle garde sa
            // largeur et c'est le compte qui s'ellipse si la place manque.
            // L'inverse effacerait l'information fiscale pour sauver un
            // nombre que la liste elle-même donne déjà.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).catalogResultCount(total),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context).catalogPricesIncludeVat,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
        _sliverDesCartes(context),
        // Spinner "chargement suivant"
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        // Message "tout chargé"
        if (!hasMore && vehicles.isNotEmpty)
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
        // Dégage la dernière rangée de la barre de navigation et du FAB.
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }

  /// Les cartes : UNE MAÇONNERIE À N COLONNES, N venant de la largeur.
  ///
  /// DEUX COLONNES SUR TÉLÉPHONE, et c'est la décision du propriétaire, qui
  /// n'est pas remise en cause. Ce qui a changé, c'est que le 2 n'est plus
  /// écrit ici : il est RENDU par `nombreDeColonnes`, dans
  /// core/widgets/grille_maconnerie.dart, qui décide sur la largeur disponible
  /// et garantit deux colonnes bien au-delà de toute largeur de téléphone. Les
  /// trois listes du catalogue lisent la même règle — elles écrivaient chacune
  /// la leur, et c'est pour cela que la tablette a été oubliée trois fois.
  ///
  /// Les mesures de vide intérieur ci-dessous ont été relevées à deux colonnes,
  /// sur des écrans de téléphone, et elles y restent vraies : la grille y rend
  /// exactement la même mise en page qu'avant ce lot.
  ///
  /// POURQUOI PLUS DE RANGÉES. Les rangées étaient le montage du lot précédent :
  /// un `SliverList` dont chaque élément était un `Row` de deux `Expanded`. Une
  /// rangée prend la hauteur de sa carte la PLUS HAUTE, donc elle laisse un vide
  /// sous la plus courte, et ce vide est mesuré sur le jeu de quatre annonces du
  /// banc de captures : 16,0 points sous la première rangée et 60,0 sous la
  /// seconde à 360 points d'écran, 36,0 et 24,0 à 411. Le propriétaire a dit que
  /// l'alignement n'était PAS nécessaire — les annonces peuvent se décaler —,
  /// donc chaque colonne se remplit désormais pour son compte et le vide
  /// intérieur disparaît.
  ///
  /// CE QUE LA MAÇONNERIE REND, ET CE QU'ELLE NE REND PAS, mesuré sur ces mêmes
  /// quatre annonces : la hauteur TOTALE de la liste ne change pas d'un point —
  /// 444,4 à 360 avant comme après, 437,1 à 411, 441,9 à 320. C'est
  /// arithmétique et il faut le dire plutôt que le cacher : avec deux cartes par
  /// colonne, la liste fait la hauteur de la colonne la plus LONGUE, et
  /// l'alternance met ici les deux cartes les plus hautes — la Toyota et la
  /// Mercedes, aux index 0 et 2 — dans la même colonne.
  ///
  /// CE QU'ELLE REND VRAIMENT, c'est le vide INTÉRIEUR, et il se mesure au
  /// déplacement de la quatrième annonce : la Suzuki remonte de 16,0 points à
  /// 360, de 36,0 à 411 et de 36,0 à 320 — exactement le vide que la première
  /// rangée laissait sous sa carte la plus courte. Le reste du vide n'était pas
  /// intérieur : les 60,0 points sous la seconde rangée à 360 étaient déjà en bas
  /// de liste, et ils y restent. Ils se cumulent même : la colonne courte finit
  /// 76,0 points au-dessus de l'autre à 360, 60,0 à 411 et 96,0 à 320. Sur quatre
  /// annonces la maçonnerie ne rend donc AUCUNE hauteur ; elle rend de la hauteur
  /// à partir d'une liste assez longue pour que chaque vide intérieur soit repris
  /// par la carte suivante, c'est-à-dire sur le vrai parc — 20 annonces par page,
  /// soit 10 cartes par colonne.
  ///
  /// LA RÉPARTITION EST L'ALTERNANCE, et c'est le choix le plus prévisible :
  /// la carte `i` va dans la colonne `i % N`. À deux colonnes c'est le pair à
  /// gauche et l'impair à droite, mot pour mot ce que faisait le pas de 2 en
  /// dur. Elle garde l'ordre de lecture du catalogue — la première annonce en
  /// haut à gauche, la deuxième à sa droite — que la seule autre répartition
  /// simple, « la première moitié à gauche », fait perdre : la deuxième annonce
  /// s'y retrouverait au milieu de l'écran.
  ///
  /// CE QU'ELLE IMPLIQUE QUAND UNE COLONNE DEVIENT PLUS LONGUE QUE L'AUTRE, et
  /// c'est le défaut de l'alternance : elle ne corrige rien. Une colonne qui a
  /// reçu les titres longs reste en avance sur l'autre, et l'écart ne se résorbe
  /// que par chance — il se cumule aussi bien qu'il s'annule. En bas de liste la
  /// colonne courte s'arrête donc au-dessus de l'autre, et le vide qu'on vient de
  /// chasser de chaque rangée se retrouve en UN SEUL bloc, à la fin. Une
  /// répartition « à la colonne la plus courte » l'éviterait, mais elle réclame
  /// la hauteur des cartes déjà posées, que rien ne connaît au moment de les
  /// construire : seul le rendu la produit.
  ///
  /// LE DÉFAUT DU MONTAGE, SIGNALÉ ET NON CORRIGÉ : un `Row` de deux `Column`
  /// dans un `SliverToBoxAdapter` construit TOUTES les cartes chargées d'un
  /// coup. Mesure à 360 × 720, le même écran dans les deux montages : le
  /// `SliverList` posait 8 cartes et 238 objets de rendu, que la liste porte 20,
  /// 40 ou 60 annonces ; la maçonnerie en pose autant qu'il y en a — 20 cartes et
  /// 595 objets pour une page, 60 et 1785 pour trois. C'est BORNÉ parce que la
  /// page pagine : [VehicleListNotifier] charge 20 annonces par page et
  /// `_onScroll` n'en demande une de plus qu'à 300 points du bas. Le coût est
  /// donc de 20 cartes par page défilée, cumulé, et il croît LINÉAIREMENT — 29,8
  /// objets de rendu par carte, mesuré sur les trois points ci-dessus. Ce n'est
  /// plus borné par rien d'autre que la patience du doigt : à la cinquième ou
  /// sixième page, 100 à 120 annonces, l'extrapolation donne 3000 à 3600 objets
  /// de rendu vivants là où le `SliverList` en gardait 238, et c'est à ce
  /// volume-là qu'il faudra regarder un téléphone d'entrée de gamme — le chiffre
  /// est extrapolé, pas mesuré, et le parc en production n'y est pas encore. Au
  /// delà il faudra une vraie maçonnerie paresseuse, c'est-à-dire deux slivers
  /// côte à côte dans un `CustomScrollView` à deux viewports, ou le délégué
  /// qu'une dépendance apporterait.
  ///
  /// SANS NOUVELLE DÉPENDANCE : pas de `flutter_staggered_grid_view`. Ce projet a
  /// déjà payé une résolution de versions bloquée (share_plus 13 contre
  /// package_info_plus 8), et deux `Column` dans un `Row` suffisent.
  ///
  /// POURQUOI PAS `IntrinsicHeight` + `CrossAxisAlignment.stretch`, qui est la
  /// forme qu'on écrivait d'instinct pour étirer deux cartes voisines à la même
  /// hauteur. Le banc l'a refusée net, et la cause n'a pas changé :
  ///
  ///   LayoutBuilder does not support returning intrinsic dimensions.
  ///   _RenderLayoutBuilder.computeMaxIntrinsicHeight
  ///
  /// Ce `_RenderLayoutBuilder`, c'est `_PrixAjuste` : il lit la largeur qu'il
  /// reçoit pour décider du corps du prix, donc il ne peut répondre à aucune
  /// question de taille intrinsèque. Retirer le `LayoutBuilder` aurait voulu dire
  /// retirer le filet qui empêche un prix tronqué, c'est-à-dire un prix FAUX :
  /// hors de question. La maçonnerie rend la question sans objet — plus rien ne
  /// demande à deux cartes d'avoir la même hauteur.
  ///
  /// LA DERNIÈRE ANNONCE D'UNE COLONNE INCOMPLÈTE GARDE SA LARGEUR DE COLONNE.
  /// C'est acquis par construction et non par un `Expanded` vide : les colonnes
  /// SONT les `Expanded` du `Row`, donc elles se partagent la largeur utile à
  /// parts égales quel que soit le nombre de cartes qu'elles portent. Toutes
  /// les photos de la liste gardent la même hauteur pour la même raison — même
  /// largeur, ratio fixe (voir [_ratioPhoto]) —, mais seules les cartes de la
  /// première rangée ont encore le même bord inférieur : au-delà, la maçonnerie
  /// les décale.
  ///
  /// LA PHOTO N'A PAS DE HAUTEUR À RÉGLER, contrairement aux vignettes des
  /// pièces et des accessoires : [_ratioPhoto] la tient déjà proportionnelle à
  /// la largeur de la colonne. C'est pourquoi ce fichier ne lit pas
  /// `hauteurVignetteCatalogue` — il n'a rien à y corriger.
  Widget _sliverDesCartes(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverToBoxAdapter(
        // La maçonnerie, ses colonnes et le choix de leur nombre vivent
        // désormais dans core/widgets/grille_maconnerie.dart, avec les raisons
        // des deux `CrossAxisAlignment` et la liste des montages déjà essayés
        // et retirés.
        child: MaconnerieColonnes(
          nombre: vehicles.length,
          ecartHorizontal: _ecartColonnes,
          // 10 points, la valeur que le pas de 2 en dur posait déjà entre deux
          // cartes d'une même colonne. La carte d'un véhicule n'a pas de marge
          // basse à elle, contrairement à celle d'une pièce.
          ecartVertical: 10,
          carte: (_, i, _) => VehicleCard(vehicle: vehicles[i]),
        ),
      ),
    );
  }
}

// ── Ligne de caractéristiques ───────────────────────────────────

// Le séparateur de milliers du kilométrage passe désormais par
// `formatEntier`, dans core/utils/currency_format.dart, qui suit la langue
// active : « 95 000 km » en français — espace fine insécable U+202F, et non une
// espace ordinaire —, « 95,000 km » en anglais. Il était écrit ici sur
// `NumberFormat.decimalPattern('fr_FR')` en dur, à côté d'un prix qui, lui,
// basculait : la même carte aurait affiché « 95 000 km » sous
// « 99,999,999 FCFA ».
//
// DIVERGENCE CONNUE, ET DÉCLARÉE PLUTÔT QUE TAIRE : `vehicle_detail_page.dart`
// garde ses propres `NumberFormat(..., 'fr_FR')` écrits en dur. En anglais, la
// liste écrit donc « 95,000 km » et la fiche « 95 000 km » pour le même
// véhicule. La règle d'avant — « la liste et la fiche écrivent le même
// kilométrage, un acheteur qui passe de l'une à l'autre ne doit pas voir le
// nombre changer de forme » — vaut toujours ; c'est la fiche qui doit suivre,
// au lot qui la traduira. La corriger ici aurait voulu dire toucher un écran
// que ce lot ne traduit pas, et laisser la liste en `fr_FR` aurait mis
// « 95 000 km » sous « 99,999,999 FCFA » sur la MÊME carte.

/// La ligne de caractéristiques : « 95 000 km • Essence ».
///
/// DEUX VALEURS, ET LA BOÎTE DE VITESSES N'Y REVIENT PAS. Elle y était entrée
/// le temps d'un lot, celui de la carte en colonne unique, qui donnait 160,0
/// points de texte à 320 points d'écran. Deux annonces par rangée en donnent
/// 119,0 : « 246 965 km • Automatique • Électrique » y réclame 218,0 points à
/// l'échelle 1,0 et 421,2 à 2,0, soit deux lignes au réglage par défaut et
/// trois au dernier cran. Ces lignes-là sont de la HAUTEUR, et la hauteur est
/// exactement ce que la seconde colonne vient de rendre rare — c'est le
/// raisonnement du lot, et la boîte de vitesses est la première chose qu'il
/// retire. Elle reste sur la fiche du véhicule, où l'acheteur s'engage.
///
/// Les deux valeurs gardées sont celles sur lesquelles un acheteur tranche :
/// l'une dit l'usure, l'autre dit le coût à l'usage et la disponibilité à la
/// pompe.
///
/// Le kilométrage reste en tête : c'est la fin de la ligne qu'on perd quand
/// elle s'ellipse, et le kilométrage est ce qui trie une liste.
///
/// Une valeur absente disparaît avec son séparateur : le catalogue contient
/// des véhicules neufs sans kilométrage relevé et des électriques dont la
/// motorisation n'est pas renseignée. Un « • • » ou un « null » y aurait l'air
/// d'un défaut d'affichage, et un tiret y aurait l'air d'un zéro.
///
/// `engineType` arrive déjà libellé du serveur — « Essence », « Diesel »,
/// « Électrique », « Hybride » sont les intitulés de la table de référence, et
/// la fiche détaillée les affiche tels quels sous « Motorisation ».
/// ── LA FINITION REVIENT, SOUS SA FORME COURTE ────────────────────────────
///
/// Elle avait été RETIRÉE de la carte après mesure, et le commentaire de
/// `garde` plus haut en garde la trace : « sans finition ni ville » et
/// « titre + prix seuls » rendaient le même compte d'annonces entières, donc
/// la finition coûtait sans rendre. Le propriétaire la redemande.
///
/// CE QUI A CHANGÉ, et c'est pourquoi la mesure d'alors ne tranche pas
/// celle-ci : ce qu'on avait mesuré était le nom ENTIER. Depuis, le
/// référentiel dédouble certains noms pour distinguer deux mécaniques sous une
/// même désignation — « 528i (4 cyl. 2011-2016) », vingt-trois caractères — et
/// `finitionCourte` ne garde que ce qui précède la parenthèse. Sur les deux
/// véhicules du catalogue qui en portent une, la carte affiche « 528i » et
/// « S » : quatre caractères et un.
///
/// ELLE EST EN TÊTE DE LA LIGNE et non après le kilométrage, parce qu'elle
/// qualifie le véhicule — on lit « S • 95 000 km • Essence » comme une suite
/// qui va du modèle vers l'usage. Et parce qu'en tête elle survit à
/// l'ellipse : c'est la fin de la ligne qui se perd, et le carburant est la
/// moins décisive des trois.
String? _ligneSpecs(AppLocalizations l10n, Vehicle vehicle) {
  final finition = finitionCourte(vehicle.identity.trim);

  final specs = <String>[
    if (finition.isNotEmpty) finition,
    if (vehicle.mileageKm != null)
      l10n.commonMileageKm(formatEntier(vehicle.mileageKm!)),
    if (vehicle.identity.engineType != null) vehicle.identity.engineType!,
  ];
  return specs.isEmpty ? null : specs.join(' • ');
}

// ── Carte véhicule ──────────────────────────────────────────────

/// Le ratio de la photo de la carte.
///
/// FIXE, ET C'EST CE QUI DONNE AUX DEUX COLONNES LA MÊME HAUTEUR DE VIGNETTE.
/// Les colonnes ont la même largeur, donc toutes les photos de la liste ont la
/// même hauteur, et les deux premières cartes — les seules que la maçonnerie
/// laisse partir du même haut — ont aussi le même bord inférieur de photo. Si la
/// photo suivait la hauteur de la carte — ce que faisait la carte horizontale du
/// lot précédent, par un `Positioned` calé haut et bas —, les vignettes seraient
/// de hauteurs TOUTES différentes, et une liste de vignettes inégales en hauteur
/// comme en position n'a plus de trame du tout.
///
/// 16:9 ET NON 4:3, ET C'EST LA MESURE QUI L'A IMPOSÉ, contre la cohérence avec
/// le reste de l'application. Le 4:3 est le ratio de la fiche de détail et du
/// carrousel de l'accueil ; le lot précédent l'avait gardé en montrant que, sur
/// une carte dont le texte faisait au moins 168 points, le ratio ne changeait
/// AUCUN compte d'annonces. Ce n'est plus vrai : à deux colonnes la photo fait
/// toute la largeur de la case, et c'est ELLE qui décide — à 320 points d'écran
/// et à l'échelle 1,0, la rangée mesure 257,3 points en 4:3 et 231,9 en 16:9, et
/// les 25,4 de différence sont exactement ceux de la photo.
///
/// Mesure dans la coque réelle, sur le contenu gardé (titre, caractéristiques,
/// prix), hauteur de rangée puis nombre d'annonces ENTIÈRES, aux échelles
/// 1,0 / 1,3 / 1,5 / 2,0 :
///
///   320 pt  4:3  257,3 / 292,3 / 343,3 / 551,3 → 2 0 0 0
///   320 pt  3:2  246,0 / 281,0 / 332,0 / 540,0 → 2 0 0 0
///   320 pt 16:9  231,9 / 266,9 / 317,9 / 525,9 → 2 2 0 0
///   360 pt  4:3  236,3 / 311,3 / 332,3 / 538,3 → 2 2 2 0
///   360 pt  3:2  223,3 / 298,3 / 319,3 / 525,3 → 2 2 2 0
///   360 pt 16:9  207,2 / 282,2 / 303,2 / 509,2 → 2 2 2 0
///   411 pt  4:3  255,4 / 304,4 / 355,4 / 410,4 → 4 2 2 2
///   411 pt  3:2  240,3 / 289,3 / 340,3 / 395,3 → 4 2 2 2
///   411 pt 16:9  221,5 / 270,5 / 321,5 / 376,5 → 4 4 2 2
///
/// Le 16:9 achète donc deux annonces entières à 320 points dès « Grande
/// police » — le deuxième cran d'Android, sur le plus petit téléphone du parc,
/// et la configuration qui a motivé deux lots : on y passe de ZÉRO annonce
/// entière à deux. Il en achète deux de plus à 411 points au même cran. Le 3:2
/// n'achète RIEN, dans aucune des douze cases. Vingt-cinq points de photo
/// valent ici deux annonces, et c'est la seule fois dans l'histoire de ce
/// fichier que le ratio a déplacé un compte.
///
/// Ce que ça coûte : la même photo est recadrée plus serré dans la liste que sur
/// la fiche. `BoxFit.cover` recadre, il ne déforme pas, et une voiture est un
/// sujet large — c'est le seul sujet du catalogue pour lequel le 16:9 ne coupe
/// pas l'essentiel. La capture `catalogue-320-x13-clair` est là pour le
/// vérifier à l'œil, parce que ça ne se vérifie pas au chiffre.
const double _ratioPhoto = 16 / 9;

/// Repère de la photo, pour la mesurer en test.
///
/// Une clé plutôt qu'un `find.byType` : l'arbre de la carte contient plusieurs
/// `AspectRatio` potentiels selon le repli, et chercher le type aurait fait
/// mesurer autre chose sans le dire — exactement comme `find.text` mesurait le
/// texte voulu au lieu du texte peint.
const Key clePhoto = Key('photo-carte');

/// Une fiche du catalogue, dans la seule forme qu'elle ait désormais.
///
/// Publique pour être mesurée en test : `carte_geometrie_test.dart` la pose dans
/// la vraie grille, sous le vrai thème, avec Roboto chargée ET vérifiée, et lit
/// la largeur que chaque paragraphe demande contre celle qu'il a reçue. Un
/// relecteur a montré qu'une carte posée à la main dans un `SizedBox`, sous un
/// `MaterialApp` sans thème, donne des chiffres qui ne décrivent pas la grille
/// réelle : les corps de `titleSmall` et de `bodySmall` viennent du thème, et
/// c'est d'eux que dépend chaque largeur.
///
/// LA FORME, et elle est unique depuis que le propriétaire a tranché pour deux
/// annonces par rangée : photo en haut à ratio fixe, texte dessous, hauteur
/// dictée par le contenu. Ni `Expanded` ni ligne à hauteur réservée — c'étaient
/// les deux pièces qui imposaient au texte un budget vertical, et ce budget
/// était la cause de toutes les troncatures et de toutes les bandes rayées de ce
/// fichier. Les lignes se replient, elles ne s'ellipsent pas.
///
/// CE QU'ELLE PORTE EST TRANCHÉ PAR LA MESURE, pas par le goût : voir
/// [_lignesDeLaCarte] et le tableau de densité de `carte_geometrie_test.dart`.
///
/// À état depuis le retour au toucher : voir `_appuyee`.
class VehicleCard extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  /// Doigt posé sur la carte. Ne sert qu'au retour visuel : l'`InkWell`
  /// garde la charge de décider ce qui est un appui.
  bool _appuyee = false;

  void _appui(bool valeur) {
    if (_appuyee != valeur) setState(() => _appuyee = valeur);
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final c = vehicle.commercial;
    final id = vehicle.identity;
    final cs = Theme.of(context).colorScheme;
    final specs = _ligneSpecs(AppLocalizations.of(context), vehicle);

    // Sans photo, le logo de la marque rend la grille identifiable — auparavant
    // les 80 cartes affichaient exactement la même icône grise. Il sert aussi
    // de repli pendant le chargement de la photo, et si elle échoue.
    final cover = Container(
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: BrandLogo(slug: id.brandSlug, size: 56),
    );

    final vignette = Stack(
      fit: StackFit.expand,
      children: [
        // `coverUrl` et non `mediaUrls.first` : cette carte ne montre qu'une
        // image, et le dire ainsi évite de laisser croire que l'ordre de la
        // liste lui est indifférent — c'est précisément cet ordre qui s'était
        // perdu une fois. Les deux valent le même, par construction du parseur.
        if (vehicle.coverUrl == null)
          cover
        else
          CatalogImage(url: vehicle.coverUrl!, fallback: cover),

        // UN SEUL badge sur la photo, et c'est celui-ci.
        //
        // L'étiquette d'affaire occupait le coin bas gauche. Elle était peinte
        // en 0xFFB26A00 — exactement l'ocre du « À louer » de
        // `_AvailabilityBadge` —, si bien qu'un véhicule en location portant
        // une affaire affichait deux badges de teinte identique, l'un au-dessus
        // de l'autre. C'est le badge de disponibilité qui reste : sans lui, le
        // prix de la carte ne dit pas s'il est un prix de vente ou un loyer,
        // donc il ne dit rien. L'étiquette d'affaire est descendue à côté du
        // prix, qu'elle qualifie — déplacée, pas supprimée : voir `_PriceRow`.
        //
        // `right: 8` EST LA CORRECTION DU ROGNAGE SILENCIEUX. Avec le seul
        // couple `top`/`left`, un `Positioned` donne à son enfant une largeur
        // ILLIMITÉE : le badge prenait sa largeur naturelle, dépassait la
        // vignette, et le `clipBehavior: Clip.antiAlias` du `Card` le coupait
        // net — sans ellipse, sans `RenderFlex`, sans rien pour le signaler.
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Align(
            alignment: Alignment.topLeft,
            // DEUX LIGNES, ET C'EST UNE MESURE DU LOT. Dans la carte à deux
            // colonnes d'origine le badge tenait sur une ligne parce que la
            // photo faisait toute la largeur de la case ; elle la fait encore,
            // mais la case est celle d'un TÉLÉPHONE et non d'une tablette. Le
            // libellé reçoit 107,0 points à 320 points d'écran, et « Vente &
            // Location » — le plus large des quatre — en demande 157,2 à
            // l'échelle 2,0 et 118,9 à 1,5 : sur UNE ligne il était coupé dès
            // le troisième cran des réglages Android, et coupé en silence.
            // Replié, il tient : « Vente & » puis « Location ».
            child: _AvailabilityBadge(vehicle: vehicle),
          ),
        ),

        // Le coin bas droit annonce les autres photos.
        //
        // BORNÉ À GAUCHE, et c'est un débordement mesuré, pas une précaution.
        // Sans borne gauche, le `Positioned` laisse la pastille prendre sa
        // largeur naturelle et le `Card` la rogne sans rien dire. Avec la
        // borne, le défaut devient VISIBLE au lieu d'être muet : à 320 points et
        // à l'échelle 2,0, « 12 photos » en corps 20 réclame 92,0 points et
        // l'icône et son espace 14 de plus, pour 107,0 reçus. D'où les deux
        // lignes, comme pour le badge.
        if (vehicle.mediaUrls.length > 1)
          Positioned(
            bottom: 8,
            right: 8,
            left: 8,
            child: Align(
              alignment: Alignment.bottomRight,
              child: _PhotoCount(count: vehicle.mediaUrls.length),
            ),
          ),

        // Le statut douanier a ete retire de la carte. Il repondait a une
        // question que personne ne se pose en parcourant une liste — on y
        // cherche un modele, un prix, un etat — et il occupait le coin oppose
        // au badge de disponibilite, donc le peu de place qui restait sur la
        // photo. Il reste sur la fiche du vehicule, ou il a sa place : c'est la
        // qu'on s'engage.
      ],
    );

    // IL SE REPLIE, et c'est ce qui ferme la troncature du titre. Elle touchait
    // les DOUZE configurations remesurées dans la coque réelle, échelle par
    // défaut comprise, et sur un nom long le MODÈLE disparaissait : « Land Rover
    // Range Rover Sport (2018) » — la plus longue combinaison marque + modèle du
    // référentiel du serveur — demande 241,0 points en corps 14 gras, pour 119,0
    // disponibles à 320 points d'écran. Replier ne coûte rien ici : la hauteur de
    // la carte suit son contenu.
    final titre = Text(
      id.fullName,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      maxLines: _lignesDeLaCarte,
      overflow: TextOverflow.ellipsis,
    );

    final caracteristiques = specs == null
        ? null
        : Text(
            specs,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: _lignesDeLaCarte,
            overflow: TextOverflow.ellipsis,
          );

    final prix = _PriceRow(commercial: c);

    // ── CE QUE LA CARTE PORTE, ET CE QUI EST PARTI À LA FICHE ─────────────
    //
    // LA FINITION ET LA VILLE SONT PARTIES, et ce n'est pas un allègement de
    // goût : c'est le seul moyen mesuré d'avoir deux annonces par rangée qui
    // tiennent à l'écran. Une carte de 119,0 points de texte qui porte titre +
    // finition + caractéristiques + ville + prix se replie sur huit à dix
    // lignes.
    //
    // CINQ COMBINAISONS, mesurées dans la coque réelle, sur le pire contenu du
    // référentiel, toutes avec la photo en 16:9 du code livré — hauteur de
    // RANGÉE aux échelles 1,0 / 1,3 / 1,5 / 2,0, puis nombre d'annonces
    // ENTIÈRES dans les 320,0 points de liste que la page laisse à 320 points
    // d'écran :
    //
    //   tout                        299,9 / 375,9 / 441,9 / 785,9 → 0 0 0 0
    //   sans la finition            281,9 / 352,9 / 415,9 / 719,9 → 0 0 0 0
    //   sans finition ni ville      231,9 / 266,9 / 317,9 / 525,9 → 2 2 0 0
    //   titre + prix seuls          197,9 / 222,9 / 267,9 / 427,9 → 2 2 0 0
    //   ville réduite à la commune  249,9 / 310,9 / 367,9 / 623,9 → 2 0 0 0
    //
    // (le tableau complet, aux trois largeurs, est dans
    //  `carte_geometrie_test.dart`.)
    //
    // Les deux premières combinaisons rendent ZÉRO annonce entière à 320
    // points, y compris au réglage de texte PAR DÉFAUT : garder tout aurait
    // rendu la liste pire que la colonne unique qu'on remplace, qui en montrait
    // une. Et à l'échelle 2,0 la ville y était COUPÉE — pas ellipsée : le mot
    // « Dioulasso » réclame 121 points pour les 105 que sa ligne reçoit, il est
    // donc posé seul sur sa ligne et rogné par le `clipBehavior` du `Card`,
    // sans ellipse et sans exception. C'est la mesure du segment insécable qui
    // l'a vue, pas `didExceedMaxLines`.
    //
    // « Sans finition ni ville » et « titre + prix seuls » donnent EXACTEMENT
    // le même compte dans les douze cases du tableau — trois largeurs, quatre
    // échelles. Les caractéristiques sont donc gratuites, et elles restent :
    // c'est le premier filtre d'un acheteur, l'usure et le coût à l'usage.
    //
    // La ville a été réessayée réduite à la seule commune, sans le nom de
    // l'agence : « Bobo-Dioulasso » au lieu de « Showroom Paspanga —
    // Bobo-Dioulasso ». Elle coûte encore une annonce entière à 320 points dès
    // « Grande police », une à 360 points à l'échelle 1,5 et deux à 411 points
    // à l'échelle 1,3. Elle part aussi.
    //
    // Les deux sont sur la fiche du véhicule, à un appui, et c'est là qu'elles
    // servent : on choisit un modèle et un prix dans une liste, on vérifie une
    // finition et une agence quand on se déplace.
    final garde = <Widget>[
      titre,
      if (caracteristiques != null) ...[
        const SizedBox(height: 2),
        caracteristiques,
      ],
      const SizedBox(height: 4),
      prix,
    ];

    // RIEN DE RÉSERVÉ, RIEN D'ELLIPSÉ. Les lignes absentes ne laissent pas de
    // trou, et la hauteur du bloc est la somme de ce qu'il contient — donc aucun
    // budget vertical à dépasser, et par construction plus de bande rayée, à
    // aucune échelle.
    final blocTexte = Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: garde,
      ),
    );

    // Retour au toucher. `AnimatedScale` ne touche pas à la mise en page : la
    // rangée garde sa hauteur, et aucun débordement ne peut naître d'ici.
    // L'élévation, elle, est animée par le `Material` interne du `Card`, qui
    // interpole tout changement d'élévation.
    //
    // L'`InkWell` reste : l'ondulation est le signal que Material donne au
    // doigt, et la remplacer par une mise à l'échelle seule serait une perte.
    // Elle se cumule, elle ne se substitue pas.
    return AnimatedScale(
      scale: _appuyee ? 0.97 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Card(
        // `null` et non `1` : l'élévation au repos reste celle du thème.
        elevation: _appuyee ? 6 : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/vehicles/${vehicle.id}', extra: vehicle),
          onTapDown: (_) => _appui(true),
          onTapUp: (_) => _appui(false),
          onTapCancel: () => _appui(false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // `AspectRatio` ET NON `Expanded` : c'est toute la différence
              // entre la grille d'avant et celle-ci. `Expanded` partageait une
              // hauteur imposée par le `childAspectRatio` du délégué, et ce
              // partage a produit tous les débordements de ce fichier.
              // `AspectRatio` déduit la hauteur de la largeur reçue et la REND à
              // la colonne, qui l'additionne au texte.
              AspectRatio(
                key: clePhoto,
                aspectRatio: _ratioPhoto,
                child: vignette,
              ),
              blocTexte,
            ],
          ),
        ),
      ),
    );
  }
}

/// Compteur de photos, dans le coin bas droit de la vignette.
///
/// Le propriétaire du parc a signalé que les autres photos d'un véhicule ne se
/// découvraient pas : la carte n'en montre qu'une et rien ne disait qu'il y en
/// avait d'autres. Ce compteur dit qu'il reste à voir.
///
/// Il n'apparaît qu'à partir de deux. « 1 photos » est faux, et « 1 photo »
/// n'annoncerait rien — c'est exactement ce que la vignette montre déjà.
class _PhotoCount extends StatelessWidget {
  final int count;

  const _PhotoCount({required this.count});

  @override
  Widget build(BuildContext context) {
    final libelle = Text(
      AppLocalizations.of(context).catalogPhotoCount(count),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      // DEUX LIGNES, et le chiffre qui l'impose : la pastille reçoit 107,0
      // points sur une photo de 135, soit 93,0 à son libellé une fois retirées
      // l'icône et son espace. « 12 photos » en corps 20 — l'échelle 2,0 — en
      // réclame 92,0 : un point de marge. Sur UNE ligne, le premier libellé à
      // trois chiffres le dépasserait, et le `clipBehavior` du `Card` le
      // couperait sans rien signaler.
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        // Un voile noir, pas un rôle du `ColorScheme` : cette pastille est
        // posée sur une photo, et une photo n'est ni claire ni sombre selon le
        // thème. Le badge de disponibilité juste au-dessus suit la même règle,
        // et le couple noir/blanc tient donc dans les deux modes.
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      // `min` est obligatoire : la contrainte d'un `Positioned` sans largeur
      // est illimitée, et un `Row` en `MainAxisSize.max` y prendrait une
      // largeur infinie.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          // `Flexible`, ET IL EXIGE QUE LE `Positioned` SOIT BORNÉ À GAUCHE. Un
          // `Row` en `MainAxisSize.min` mesure ses enfants non flexibles sans
          // borne, si bien que le libellé recevait une contrainte INFINIE et ne
          // pouvait ni se replier ni s'ellipser : il débordait, et le `Card` le
          // rognait. Posé en flexible il reçoit enfin la largeur réelle — mais
          // un enfant flexible sous contrainte infinie est lui-même une erreur
          // de mise en page, d'où le `left` du `Positioned` dans `VehicleCard`.
          // Les deux pièces vont ensemble, et retirer l'une casse l'autre.
          Flexible(child: libelle),
        ],
      ),
    );
  }
}

/// Le badge de disponibilité, en haut à gauche de la vignette.
///
/// IL ÉTAIT ROGNÉ EN SILENCE, et c'est le pire des quatre défauts de cette
/// carte parce que rien ne le disait. Son `Text` n'avait ni `maxLines` ni
/// `overflow`, et il vit dans un `Positioned` posé sur `top`/`left`
/// seulement : la contrainte de largeur y est ILLIMITÉE, donc le badge prenait
/// sa largeur naturelle et le `clipBehavior: Clip.antiAlias` du `Card` le
/// coupait au bord de la carte. Pas d'ellipse, pas de `RenderFlex`, pas
/// d'exception — « Vente & Location », le plus large des quatre libellés,
/// perdait sa fin sans laisser de trace. Un rognage silencieux est pire qu'une
/// ellipse : l'ellipse dit au moins qu'il manque quelque chose.
///
/// Deux pièces le corrigent, et il faut les deux : le `right: 8` du
/// `Positioned` dans `VehicleCard`, qui donne enfin une borne, et le couple
/// `maxLines`/`overflow` ci-dessous, sans quoi un `Text` borné déborde au lieu
/// de s'ellipser.
class _AvailabilityBadge extends StatelessWidget {
  final Vehicle vehicle;

  const _AvailabilityBadge({required this.vehicle});
  @override
  Widget build(BuildContext context) {
    final c = vehicle.commercial;
    final cs = Theme.of(context).colorScheme;
    // Palette explicite plutôt que les rôles du ColorScheme : le thème naît
    // d'un seed bleu ardoise, dont Material dérive un `secondary` désaturé
    // (le badge se lisait comme « indisponible ») et un `tertiary` lavande
    // étranger à la marque. Ces trois tons sont profonds et désaturés comme
    // le bleu de marque, et restent distincts entre eux.
    final l10n = AppLocalizations.of(context);
    final (label, bg) = switch (c.availability) {
      'both' => (l10n.catalogOfferBoth, const Color(0xFF2E6F6B)), // sarcelle
      'sale' => (l10n.catalogOfferSale, const Color(0xFF1F5C7A)), // ardoise
      'rent' => (l10n.catalogOfferRent, const Color(0xFFB26A00)), // ocre
      _ => (l10n.catalogOfferNone, cs.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        // DEUX LIGNES, ET C'EST UNE MESURE DU LOT. Dans la grille d'origine le
        // badge tenait sur une ligne, et le relecteur a montré qu'il était
        // quand même coupé dès l'échelle 1,5. Le libellé reçoit 107,0 points
        // sur une photo de 135, et « Vente & Location » — le plus large des
        // quatre — en demande 118,9 à l'échelle 1,5 et 157,2 à 2,0 : sur une
        // ligne il était coupé, et coupé en SILENCE, le `clipBehavior` du
        // `Card` ne signalant rien. Replié, il tient : « Vente & » puis
        // « Location », 80,0 points de segment insécable pour 107,0.
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Le prix, réduit jusqu'à tenir, jamais coupé.
///
/// UN PRIX TRONQUÉ EST UN PRIX FAUX, et c'est la seule troncature de cette
/// carte qui ne se rattrape pas. « 9 500 000 FCFA » coupé en « 9 500 00… » ne
/// se lit pas de travers : il se lit comme neuf cent cinquante mille, soit un
/// dixième du prix réel. Une ligne de caractéristiques ellipsée fait perdre
/// une information ; un prix ellipsé en donne une fausse, sur une place de
/// marché.
///
/// Mesure du défaut d'origine, avec Roboto, sur une case de 320 points d'écran
/// à deux colonnes — le prix y disposait de 119,0 points : à l'échelle 1,0 il
/// en demandait 97,2 et tenait ; à l'échelle 1,3, le réglage « Grande police »
/// ordinaire d'Android, il en demandait 125,9 et dépassait de 6,9. Aucun
/// `RenderFlex` ne se déclenche dans cette configuration — le dépassement est
/// horizontal, et l'ellipse l'absorbe —, donc rien ne le signalait : pas de
/// bande rayée, pas d'exception, juste un prix faux.
///
/// LA RÉDUCTION PLUTÔT QUE LE REPLI. Le repli gardait le prix entier mais
/// coûtait trop cher en hauteur — mesuré : 159,6 points de bloc de texte pour
/// 166,4 disponibles, le prix étalé sur trois lignes. Un prix rendu 10 % plus
/// petit reste vrai ; un prix tronqué est faux. On réduit donc le corps.
///
/// IL RESTE, ET IL SERT TOUS LES JOURS. Deux annonces par rangée ne laissent au
/// prix que 119,0 points à 320 points d'écran, 139,0 à 360 et 164,5 à 411.
/// Mesure sur « 99 999 999 FCFA », corps peint et largeur peinte :
///
///   320 pt, x1,0 : corps 14,0 nominal,  105,3 pour 119,0 — pas de réduction
///   320 pt, x1,3 : corps 15,6 au lieu de 18,2, 116,8 pour 119,0 — RÉDUIT
///   320 pt, x2,0 : corps 15,6 au lieu de 28,0, 117,3 pour 119,0 — RÉDUIT
///   360 pt, x1,3 : corps 18,2 nominal,  136,5 pour 139,0 — pas de réduction
///   411 pt, x1,5 : corps 21,0 nominal,  157,3 pour 164,5 — pas de réduction
///
/// La réduction se déclenche donc dès « Grande police » sur le plus petit
/// téléphone du parc, et elle s'arrête à 15,6 — au-dessus du plancher de
/// confort de 14,0, qui est le corps qu'aurait ce prix sur un téléphone n'ayant
/// rien réglé. Ce n'est plus un filet de bord : c'est le mécanisme qui rend le
/// prix lisible sur un petit écran, et un chiffre du catalogue n'a pas de borne
/// haute.
class _PrixAjuste extends StatelessWidget {
  final String texte;
  final TextStyle style;
  const _PrixAjuste({required this.texte, required this.style});

  /// Combien de fois on remesure avant d'abandonner.
  ///
  /// Le premier facteur est une règle de trois sur la largeur voulue, qui
  /// suppose les avances des glyphes proportionnelles au corps. ELLES NE LE
  /// SONT PAS TOUT À FAIT, et c'est mesuré : dans les trois configurations qui
  /// demandaient une réduction, la règle de trois retombait systématiquement
  /// 0,3 point TROP HAUT — à 320 points et à l'échelle 1,5 elle proposait 17,2
  /// pour 119,0 de large, et ces 17,2 redemandaient 119,3. Les arrondis du
  /// rendu jouent contre nous, pas pour nous.
  ///
  /// D'où la boucle : on retire 2 % et on REMESURE, jusqu'à ce que la largeur
  /// lue soit réellement sous la contrainte. Deux tours suffisaient dans les
  /// six configurations du tableau d'alors ; les essais sont là pour qu'une
  /// police ou un corps futurs n'aient pas à être devinés. Publier le résultat
  /// de la règle de trois sans le remesurer aurait reconduit le défaut d'un
  /// cran plus bas.
  ///
  /// Porté de 6 à 20 avec le plancher absolu : 2 % par tour, il faut
  /// 24 tours pour descendre de 14,0 à 11,0, et 6 n'en couvraient que 1,7
  /// point. La boucle s'arrêtait avant le plancher et rendait un prix coupé
  /// alors qu'un corps plus petit l'aurait logé. Le premier tour étant une
  /// règle de trois qui fait l'essentiel du chemin, 20 suffisent largement.
  static const _essais = 20;

  /// LE PLANCHER ABSOLU, et c'est la correction du défaut (b).
  ///
  /// L'ancien plancher valait `math.min(nominal, demande)`. À l'échelle de
  /// texte 1,0 — LE RÉGLAGE PAR DÉFAUT — `demande` vaut exactement `nominal`,
  /// donc le plancher valait le corps de départ et la condition `corps >
  /// plancher` de la boucle était fausse dès le premier tour : LA RÉDUCTION NE
  /// POUVAIT RIEN RÉDUIRE. Un prix à huit chiffres se tronquait donc au
  /// réglage par défaut, c'est-à-dire chez tout le monde, et le garde-fou
  /// censé l'en empêcher ne s'exécutait jamais.
  ///
  /// 11,0 points, et pas moins : c'est le corps de `labelSmall`, celui de
  /// l'étiquette d'affaire peinte juste à côté du prix sur la même carte. Un
  /// corps déjà jugé lisible là ne devient pas illisible ici.
  static const _corpsPlancher = 11.0;

  @override
  Widget build(BuildContext context) {
    final nominal = style.fontSize!;
    final demande = MediaQuery.textScalerOf(context).scale(nominal);

    // PLANCHER DE CONFORT : le corps que ce prix aurait sur un téléphone réglé
    // à l'échelle 1,0 — et pas davantage si l'utilisateur a demandé moins.
    // Descendre sous le corps par défaut viserait précisément les gens qui
    // grossissent leurs polices parce qu'ils lisent mal : on leur rendrait le
    // prix plus petit qu'à quelqu'un qui n'a rien réglé.
    //
    // DEUX PLANCHERS ET PAS UN, et c'est tout le correctif. Le confort est
    // celui qu'on respecte tant qu'il suffit ; sous lui il reste
    // [_corpsPlancher], parce que l'alternative n'est pas « un prix un peu
    // petit » mais « un prix faux ». La boucle s'arrête donc au confort quand
    // le prix y tient, et continue en dessous quand il n'y tient pas.
    final confort = math.min(nominal, demande);

    return LayoutBuilder(
      builder: (context, contraintes) {
        final dispo = contraintes.maxWidth;
        var corps = demande;

        if (dispo.isFinite) {
          // `TextScaler.noScaling` ici ET sur le `Text` rendu : `corps` est
          // déjà la taille peinte voulue. Laisser l'échelle du système
          // s'appliquer par-dessus la multiplierait deux fois.
          double largeur(double c) => (TextPainter(
            text: TextSpan(
              text: texte,
              style: style.copyWith(fontSize: c),
            ),
            textDirection: Directionality.of(context),
            textScaler: TextScaler.noScaling,
            maxLines: 1,
          )..layout()).width;

          var voulue = largeur(corps);
          var plancher = confort;

          // Deux passes : jusqu'au confort, puis jusqu'au plancher absolu si
          // le confort n'a pas suffi. La seconde ne s'ouvre que là, et c'est
          // ce qui garde la promesse faite aux gens qui ont grossi leurs
          // polices : on ne descend sous leur réglage que pour éviter un
          // chiffre faux.
          for (var passe = 0; passe < 2; passe++) {
            for (
              var i = 0;
              i < _essais && voulue > dispo && corps > plancher;
              i++
            ) {
              corps = math.max(
                plancher,
                i == 0 ? corps * dispo / voulue : corps * 0.98,
              );
              voulue = largeur(corps);
            }
            if (voulue <= dispo) break;
            plancher = _corpsPlancher;
          }
        }

        return Text(
          texte,
          style: style.copyWith(fontSize: corps),
          textScaler: TextScaler.noScaling,
          maxLines: 1,
          softWrap: false,
          // Dernier recours, si le plancher absolu était atteint avant que le
          // prix tienne. L'ellipse reste préférable au débordement peint :
          // « … » dit au moins qu'il manque des chiffres, là où un prix rogné
          // par le bord de la carte se lit comme un prix complet. Aucune des
          // configurations du tableau n'y arrive, et le test le verrouille.
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// Le prix, et l'étiquette d'affaire qui le qualifie.
class _PriceRow extends StatelessWidget {
  final VehicleCommercial commercial;
  const _PriceRow({required this.commercial});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // `!` et non `?.` : `_PrixAjuste` a besoin d'un `fontSize` non nul pour
    // calculer sa réduction, et `titleSmall` est posé par le thème Material —
    // s'il manquait, c'est le thème qui serait cassé, et le dire tout de suite
    // vaut mieux qu'un prix peint à une taille par défaut silencieuse.
    final style = Theme.of(context).textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.primary,
    );

    final Widget prix;
    if (commercial.isForSale && commercial.salePrice != null) {
      prix = _PrixAjuste(
        texte: formatXofShort(commercial.salePrice),
        style: style,
      );
    } else if (commercial.isForRent && commercial.rentalDailyRate != null) {
      prix = _PrixAjuste(
        // LE SUFFIXE SUIT LA LANGUE, ET IL NE LA SUIVAIT PAS. `formatXofShort`
        // est passé à la locale active au lot de traduction ; le « /j » est
        // resté en dur juste derrière. Un anglophone lisait donc
        // « 25,000 FCFA/j » — le nombre traduit, l'unité non. La clé existait
        // déjà et la tuile de la vitrine l'employait depuis le même lot : ce
        // site-ci avait seulement été oublié.
        //
        // Aucune espace avant, et c'est la raison d'être de la clé : le
        // suffixe doit rester dans le MÊME segment insécable que le montant,
        // sinon il part seul à la ligne. `_PrixAjuste` réduit le corps de
        // toute la chaîne, suffixe compris.
        texte:
            '${formatXofShort(commercial.rentalDailyRate)}'
            '${AppLocalizations.of(context).commonPerDaySuffix}',
        style: style,
      );
    } else {
      // « Prix non communiqué » s'ellipse, lui, et ce n'est pas une
      // inconséquence : une phrase coupée en « Prix non communi… » se lit
      // encore comme la même phrase, alors qu'un nombre coupé devient un autre
      // nombre. Il n'y a aucun chiffre faux à craindre ici, donc rien à
      // réduire.
      prix = Text(
        AppLocalizations.of(context).catalogPriceOnRequest,
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final affaire = commercial.dealLabel;
    if (affaire == null) return prix;

    // `Wrap` et non `Row` : chaque enfant y est mesuré sur toute la largeur
    // disponible. Le prix garde donc ses chiffres, et l'étiquette passe
    // au-dessous quand elle ne tient plus à côté. Dans un `Row`, deux
    // `Flexible` se partageraient la largeur à parts égales et rogneraient le
    // prix d'abord.
    //
    // Il reste un `Wrap` MALGRÉ la réduction du prix, et c'est mesuré : sur une
    // case de 320 points d'écran, « Bonne affaire » demande 73,2 points à
    // l'échelle 1,0 et le prix 105,3 — 184,5 avec le séparateur, pour 119,0 de
    // large. L'étiquette passe donc de toute façon à la ligne, et la faire
    // tenir à côté aurait supposé de réduire le prix de plus de moitié, loin
    // sous le plancher de confort. À 411 points elle y tient : 105,3 + 6 + 73,2
    // pour 164,5 — c'est le `Wrap` qui le décide tout seul, sans que rien
    // n'ait à le lui dire.
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        prix,
        // Couleur prise au `ColorScheme`, et c'est le fond de l'affaire : en
        // badge sur la photo, cette étiquette était en 0xFFB26A00, soit la
        // teinte exacte du « À louer » de `_AvailabilityBadge`. Un ocre écrit
        // en dur ne se vérifie pas non plus dans les deux modes du thème.
        //
        // `tertiary` malgré ce qu'en dit `_AvailabilityBadge` plus haut : ce
        // qu'on y reprochait, c'est un aplat lavande sur une photo. Ici c'est
        // un texte de onze points sur la surface de la carte, et des trois
        // rôles d'accent c'est le seul qui ne soit ni le `primary` du prix ni
        // le gris des lignes secondaires. Son contraste est mesuré dans les
        // deux modes — voir `vehicle_card_test.dart`.
        Text(
          affaire,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.tertiary,
            fontWeight: FontWeight.w600,
          ),
          // DEUX LIGNES, ET C'EST LA DERNIÈRE TRONCATURE QUE LE BANC AIT
          // TROUVÉE DANS CE LOT. Elle était à `maxLines: 1` depuis l'origine,
          // ce qui tenait quand la carte était large ; à 119,0 points
          // « Bonne affaire » réclame 139,9 à l'échelle 2,0 et était COUPÉE à
          // 320 comme à 360 points. Repliée en « Bonne » / « affaire », son
          // plus long segment insécable fait 68,0 points et tient partout.
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── États vide / erreur ─────────────────────────────────────────

/// Aucun résultat — en nommant les filtres qui l'expliquent.
///
/// La barre en compte une douzaine, dont plusieurs restent actifs hors de
/// l'écran une fois la liste défilée. « Aucun véhicule trouvé » obligeait à
/// remonter les décocher un par un pour trouver le coupable.
class _EmptyView extends ConsumerWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final f = ref.watch(vehicleFilterProvider);
    final actifs = <String>[
      if (f.search?.isNotEmpty == true) l10n.catalogFilterTermQuery(f.search!),
      if (f.availability != null)
        f.availability == 'sale'
            ? l10n.catalogFilterTermSale
            : l10n.catalogFilterTermRent,
      if (f.deal == true) l10n.catalogFilterTermDeal,
      if (f.customsCleared == true) l10n.catalogFilterTermCustoms,
      if (f.vehicleType != null) l10n.catalogFilterTermVehicleType,
      if (f.bodyStyle != null) l10n.catalogFilterTermBodyStyle,
      if (f.condition != null) l10n.catalogFilterTermCondition,
      if (f.yearMin != null || f.yearMax != null) l10n.catalogFilterTermYear,
      if (f.priceMax != null) l10n.catalogFilterTermPriceMax,
      // La VILLE n'a pas de clé : son nom vient du référentiel du serveur et
      // reste en français jusqu'à la vague serveur, comme les catégories de
      // pièces et les intitulés de carburant.
      if (f.city != null) f.city!,
    ];

    // ── IL DÉFILE, ET C'EST UN DÉFAUT MESURÉ, PAS UNE PRÉCAUTION ───────────
    //
    // Cet écran était un `Center` autour d'une `Column` : une boîte qui ne
    // défile pas. Le nouveau banc « Les écrans vides du catalogue » de
    // `bandes_filtres_test.dart` l'a pris en flagrant délit à 320 points et à
    // l'échelle 2,0, SANS AUCUN FILTRE POSÉ et en FRANÇAIS :
    //
    //     A RenderFlex overflowed by 166 pixels on the bottom.
    //
    // Donc une bande rayée en jaune et noir, le lien « Dites-nous ce que vous
    // cherchez » hors d'atteinte, et rien pour y accéder. `support/echelles.dart`
    // ne rachète pas ce défaut-là : au-delà de 1,5 on cesse d'exiger la
    // densité, jamais que l'écran ne jette ni que son bas soit atteignable.
    // Avec quatre filtres posés, il dépassait déjà de 2 points à l'échelle 1,0.
    //
    // LE DÉFAUT EST ANTÉRIEUR À LA TRADUCTION : le texte français n'a pas
    // changé d'un signe dans ce lot, et les deux langues débordaient
    // exactement de la même hauteur. C'est le banc qui est neuf, pas le
    // défaut.
    //
    // LE `ConstrainedBox` EST CE QUI PRÉSERVE L'APPARENCE. Un
    // `SingleChildScrollView` seul colle le contenu en haut : l'écran vide
    // cesserait d'être centré à l'échelle normale, c'est-à-dire dans le cas
    // que tout le monde voit. En imposant au contenu une hauteur MINIMALE
    // égale à la hauteur reçue, le `Center` garde son effet tant que ça tient,
    // et le défilement n'apparaît que lorsqu'il ne tient plus.
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
                  Icon(Icons.search_off, size: 56, color: cs.outline),
                  const SizedBox(height: 14),
                  Text(
                    l10n.catalogVehicleNoneFound,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    actifs.isEmpty
                        ? l10n.catalogVehicleCatalogEmpty
                        : l10n.catalogActiveFilters(
                            actifs.join(l10n.catalogFilterListSeparator),
                          ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (actifs.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          ref.read(vehicleFilterProvider.notifier).state =
                              const VehicleFilter(),
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                      label: Text(l10n.catalogClearFilters),
                    ),
                  ],
                  TextButton.icon(
                    onPressed: () => context.push('/needs/new?type=vehicle'),
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
