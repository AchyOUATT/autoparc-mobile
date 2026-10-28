import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/product_gallery.dart';
import '../../../../core/api/api_exception.dart';

import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../data/models/vehicle.dart';
import '../../data/models/promotion.dart';
import '../promotion_affichage.dart';
import '../providers/catalog_providers.dart';
import '../../../../core/contact/autoparc_contact_provider.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/partage.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../vehicles/data/vehicle_admin_repository.dart';
import '../../../../shared/data/media_repository.dart';
import '../../../../shared/presentation/pages/media_upload_page.dart';
import '../../../vehicles/data/models/catalog_refs.dart';
import '../../../vehicles/presentation/widgets/vehicle_faults_section.dart';
import '../libelles_vehicule.dart';
import '../vehicle_price.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/presentation/widgets/seller_contact_bar.dart';

// LES DEUX `NumberFormat` FIGÉS EN `fr_FR` ONT DISPARU, et c'est une
// correction et non un rangement. Ils ponctuaient le kilométrage et la
// consommation de cette fiche en français quelle que soit la langue : la vague
// 2 aurait rendu « Mileage — 246 965 km » et « Fuel use — 7,5 L/100 km ». Le
// second est le pire des deux, parce qu'un anglophone lit « 7,5 » comme un
// séparateur de MILLIERS, c'est-à-dire soixante-quinze litres aux cent — un
// autre nombre, et plausible pour un camion.
//
// `formatEntier` existait déjà et rend EXACTEMENT la même sortie française
// (`decimalPattern('fr_FR')`, espace fine insécable U+202F) ; `formatDecimal` a
// été ajouté à côté, avec le même motif `#,##0.0` recopié d'ici. Le français
// ne change donc pas d'un signe.

/// L'ordre d'affichage des catégories d'équipements, et le libellé de chacune
/// dans la langue active.
///
/// La table était `const` et portait les libellés : une constante est
/// construite avant qu'aucun `BuildContext` n'existe, donc avant que la langue
/// soit connue, et les six noms seraient restés français pour tout le monde.
///
/// Le repli rend la clé brute du serveur. C'est volontaire et c'est déjà ce que
/// faisait `_categoryLabels[cat] ?? cat` : une catégorie que l'application ne
/// connaît pas doit se VOIR, et « autre » rangerait silencieusement un groupe
/// inconnu avec les vrais « Autres ».
String _libelleCategorie(AppLocalizations l10n, String cle) => switch (cle) {
  'dotation' => l10n.catalogFeatureCategoryStandard,
  'confort' => l10n.catalogFeatureCategoryComfort,
  'securite' => l10n.catalogFeatureCategorySafety,
  'multimedia' => l10n.catalogFeatureCategoryMultimedia,
  'aide_conduite' => l10n.catalogFeatureCategoryDriverAid,
  'autre' => l10n.catalogFeatureCategoryOther,
  _ => cle,
};
// La dotation ferme la marche : cric, gilet, carnet d'entretien sont présents
// sur tout le parc et ne départagent aucun véhicule. Les équipements qui font
// choisir un acheteur passent devant.
const _categoryOrder = [
  'confort',
  'securite',
  'multimedia',
  'aide_conduite',
  'autre',
  'dotation',
];

class VehicleDetailPage extends ConsumerWidget {
  final int vehicleId;

  /// Données passées depuis la liste (évite un aller-retour réseau pour l'affichage initial).
  final Vehicle? initialVehicle;

  const VehicleDetailPage({
    super.key,
    required this.vehicleId,
    this.initialVehicle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si on a les données de la liste, on les affiche immédiatement.
    // On lance quand même un fetch de détail en parallèle (pour avoir les médias complets, etc.)
    final detailAsync = ref.watch(vehicleDetailProvider(vehicleId));

    final vehicle = detailAsync.valueOrNull ?? initialVehicle;

    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(messageFor(e))),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }

    return _VehicleDetailView(vehicle: vehicle);
  }
}

class _VehicleDetailView extends ConsumerWidget {
  final Vehicle vehicle;
  const _VehicleDetailView({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = vehicle.identity;
    final c = vehicle.commercial;
    final auth = ref.watch(authProvider);
    final isStaff = auth.isStaff;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    Future<void> deleteVehicle() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.catalogVehicleDeleteTitle),
          content: Text(l10n.catalogVehicleDeleteBody(id.fullName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.catalogDeleteAction),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      try {
        await ref
            .read(vehicleAdminRepositoryProvider)
            .deleteVehicle(vehicle.id);
        ref.invalidate(vehicleListProvider);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(messageFor(e)), backgroundColor: cs.error),
          );
        }
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Photo hero ─────────────────────────────────────────
          SliverAppBar(
            // 320 au lieu de 260, et la photo sortie de dessous la barre.
            // Meme traitement que la fiche d'une piece, pour la meme raison :
            // l'image etait collee au bord superieur, a moitie masquee par
            // les icones d'action.
            expandedHeight: 320,
            pinned: true,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            // La suppression est plus restreinte que la modification : elle ne
            // se rattrape pas depuis l'application.
            actions: [
              // La seule commande de cette barre qui existe pour un visiteur :
              // sans session personnel, `actions` ne portait rien du tout.
              // Partager un véhicule est même le geste le plus courant — on
              // envoie la fiche à un proche pour qu'il rappelle l'agence — donc
              // aucune capacité ne le conditionne, et il passe devant les
              // commandes de gestion.
              //
              // AUCUNE CAPACITÉ, MAIS UNE CONDITION, et elle n'est pas
              // négociable : un véhicule vendu, archivé ou jamais publié n'a
              // pas de page `/v/{id}`, et le message porte désormais cette
              // adresse. Le bouton fabriquerait un lien qui rend 404 chez le
              // destinataire — voir `Vehicle.aUnePagePublique`, où le critère
              // du serveur est recopié. Le catalogue, lui, montre ces
              // véhicules : c'est bien à l'écran de trancher.
              //
              // Il DISPARAÎT au lieu de rester grisé avec une explication :
              // l'infobulle devrait parler de publication et de statut, c'est-
              // à-dire exposer une mécanique de serveur à un acheteur qui n'en
              // a rien à faire. Ce commentaire existe pour que personne ne le
              // reposte sans condition.
              if (vehicle.aUnePagePublique)
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: l10n.catalogShareTooltip,
                  // LA DÉSIGNATION ET L'ADRESSE, RIEN D'AUTRE. Le prix de
                  // vente, le kilométrage, la carrosserie, la boîte et la
                  // motorisation partaient encore dans le texte ; la page
                  // `/v/{id}` les porte dans ses balises Open Graph, et la
                  // vignette de WhatsApp les affiche sous le message. Le
                  // destinataire lisait tout deux fois dans la même bulle —
                  // « le partage duplique les informations de l'article »,
                  // signalé par le propriétaire. Voir
                  // `composerMessagePartage`, et la garde de
                  // `partage_bouton_test.dart` : c'est la seule mesure de
                  // cette duplication, qui ne se voit nulle part à l'écran.
                  onPressed: () => partagerArticle(
                    context,
                    titre: id.fullName,
                    // `vehicle.id` et non `reference` : la route publique
                    // `/v/{id}` est indexée sur la clef primaire. La référence
                    // « VH-… » n'existe que pour les humains du parc.
                    type: TypeArticle.vehicule,
                    id: vehicle.id,
                    // Le marqueur de version, qui fait que WhatsApp
                    // reconstruit sa vignette après une modification au lieu
                    // de ressortir celle du premier partage — le défaut
                    // signalé par le propriétaire, « un véhicule déjà partagé
                    // ne met pas à jour ses données de partage après maj ».
                    // Null quand la réponse ne le dit pas : l'adresse reste
                    // nue et le bouton marche. Voir `adresseArticle`.
                    version: vehicle.shareVersion,
                  ),
                ),
              // Le second accès aux photos, celui que la pièce et
              // l'accessoire avaient déjà et que le véhicule n'avait pas.
              //
              // Le premier — le bouton de l'écran de modification — suffit à
              // les atteindre, mais en deux appuis et par un détour : on
              // ouvre un formulaire de trente champs pour changer une image.
              // Ici c'est un appui, depuis l'écran où l'on regarde justement
              // les photos.
              //
              // L'invalidation des deux providers au retour n'est pas un
              // ornement : sans elle, on remonte d'un écran de médias où l'on
              // vient d'ajouter une photo pour retrouver la fiche telle
              // qu'elle était, et l'on croit que l'envoi a échoué. C'est la
              // raison pour laquelle la fiche d'une pièce le fait déjà.
              if (auth.canManageCatalog)
                IconButton(
                  icon: const Icon(Icons.add_a_photo_outlined),
                  tooltip: l10n.catalogPhotosTooltip,
                  onPressed: () => context
                      .push(
                        '/media-upload',
                        extra: MediaUploadConfig(
                          type: MediaOwnerType.vehicle,
                          id: vehicle.id,
                          title: vehicle.identity.fullName,
                        ),
                      )
                      .then((_) {
                        ref.invalidate(vehicleDetailProvider(vehicle.id));
                        ref.invalidate(vehicleListProvider);
                      }),
                ),
              if (auth.canManageCatalog)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.catalogEditTooltip,
                  onPressed: () => context
                      .push('/vehicles/${vehicle.id}/edit', extra: vehicle)
                      .then(
                        (_) =>
                            ref.invalidate(vehicleDetailProvider(vehicle.id)),
                      ),
                ),
              if (auth.canDeleteCatalog)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: l10n.catalogDeleteAction,
                  onPressed: deleteVehicle,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 16,
                end: 16,
                bottom: 10,
              ),
              title: Text(
                id.fullName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // La galerie, et non plus la seule photo de couverture.
              //
              // Ce bandeau affichait mediaUrls.first et rien d'autre : les
              // autres photos du vehicule existaient, l'API les renvoyait
              // toutes, et aucune n'etait atteignable. Les fiches de pieces
              // et d'accessoires utilisaient deja ProductGallery — la fiche
              // vehicule, celle ou l'on regarde le plus de photos avant
              // d'acheter, etait la seule restee sur une image fixe.
              //
              // Les marges la sortent de dessous la barre, comme sur la fiche
              // d'une piece.
              background: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 48,
                  bottom: 44,
                  left: 12,
                  right: 12,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ProductGallery(
                    urls: vehicle.mediaUrls,
                    titre: id.fullName,
                    fallback: _CoverPlaceholder(slug: id.brandSlug),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Prix ───────────────────────────────────────
                  _PriceSection(commercial: c, promotion: vehicle.deal),

                  // Le badge suit le prix : c'est là qu'il pèse dans la
                  // décision. Il annonce son propre décompte, pour ne pas
                  // demander à l'acheteur de croire un mot sur parole.
                  if (vehicle.isFullOption) ...[
                    const SizedBox(height: 12),
                    _FullOptionBadge(count: vehicle.optionalFeatureCount),
                  ],
                  const SizedBox(height: 20),

                  // ── Identité ────────────────────────────────────
                  _SectionTitle(l10n.catalogSectionVehicle),
                  _InfoGrid([
                    if (id.brand != null) (l10n.catalogFieldBrand, id.brand),
                    if (id.model != null) (l10n.catalogFieldModel, id.model),
                    if (id.year != null) (l10n.catalogFieldYear, '${id.year}'),
                    if (id.trim != null) (l10n.catalogFieldTrim, id.trim!),
                    // La VALEUR reste française : la motorisation et les roues
                    // motrices arrivent déjà rédigées du référentiel du
                    // serveur — « Essence », « Électrique » — et c'est la
                    // vague serveur qui les traduira. Une clé `.arb` ici ne
                    // les traduirait pas, elle dupliquerait un texte que le
                    // serveur continue d'écrire.
                    if (id.engineType != null)
                      (l10n.catalogFieldEngine, id.engineType!),
                    if (id.drivetrain != null)
                      (l10n.catalogFieldDrivetrain, id.drivetrain!),
                    // Tout ce que le formulaire demande et que la fiche
                    // n'affichait pas : le modele ne lisait du bloc technique
                    // que le kilometrage, et jetait le reste.
                    if (vehicle.bodyStyle != null)
                      (
                        l10n.catalogFieldBodyStyle,
                        _libelleCarrosserie(l10n, vehicle.bodyStyle!),
                      ),
                    if (vehicle.transmission != null)
                      (
                        l10n.catalogFieldTransmission,
                        libelleTransmission(l10n, vehicle.transmission!),
                      ),
                    if (vehicle.powerHp != null)
                      (
                        l10n.catalogFieldPower,
                        l10n.catalogUnitHp(vehicle.powerHp!),
                      ),
                    if (vehicle.engineDisplacementCc != null)
                      (
                        l10n.catalogFieldDisplacement,
                        l10n.catalogUnitCc(vehicle.engineDisplacementCc!),
                      ),
                    if (vehicle.cylinders != null)
                      (l10n.catalogFieldCylinders, '${vehicle.cylinders}'),
                    if (vehicle.torqueNm != null)
                      (
                        l10n.catalogFieldTorque,
                        l10n.catalogUnitTorque(vehicle.torqueNm!),
                      ),
                    if (vehicle.gearCount != null)
                      (l10n.catalogFieldGears, '${vehicle.gearCount}'),
                    if (vehicle.seats != null)
                      (l10n.catalogFieldSeats, '${vehicle.seats}'),
                    if (vehicle.doors != null)
                      (l10n.catalogFieldDoors, '${vehicle.doors}'),
                    if (vehicle.engineCode != null)
                      (l10n.catalogFieldEngineCode, vehicle.engineCode!),
                    if (vehicle.combinedL100km != null)
                      (
                        l10n.catalogFieldConsumption,
                        l10n.catalogUnitConsumption(
                          formatDecimal(vehicle.combinedL100km!),
                        ),
                      ),
                  ]),

                  // ── Consommation officielle ─────────────────────
                  //
                  // Une fourchette, et non un chiffre : l'annonce connaît son
                  // modèle et son millésime, rarement sa motorisation. Entre
                  // le 2,5 l quatre cylindres et le 3,5 l V6 d'une même Camry,
                  // l'écart atteint 1,2 l/100. Choisir pour l'acheteur serait
                  // lui mentir sur une dépense qu'il paiera chaque semaine.
                  if (vehicle.officialConsumption != null)
                    _ConsommationOfficielle(cote: vehicle.officialConsumption!),

                  if (id.color != null)
                    _ColorRow(
                      name: id.color!,
                      hex: id.colorHex,
                      finish: id.colorFinish,
                    ),
                  _InfoGrid([(l10n.catalogFieldReference, vehicle.reference)]),
                  const SizedBox(height: 20),

                  // ── État ────────────────────────────────────────
                  _SectionTitle(l10n.catalogSectionCondition),
                  _InfoGrid([
                    (
                      l10n.catalogFieldCondition,
                      _conditionLabel(l10n, c.condition),
                    ),
                    // Le kilométrage décrit l'usure : sa place est ici, aux
                    // côtés de la condition, plutôt que dans l'identité.
                    if (vehicle.mileageKm != null)
                      (
                        l10n.catalogFieldMileage,
                        l10n.commonMileageKm(formatEntier(vehicle.mileageKm!)),
                      ),
                    if (vehicle.faultsCount > 0)
                      (l10n.catalogFieldFaults, '${vehicle.faultsCount}'),
                  ]),
                  const SizedBox(height: 20),

                  // ── Import (si non immatriculé) ─────────────────
                  if (vehicle.isImported && vehicle.import_ != null) ...[
                    _SectionTitle(l10n.catalogSectionImport),
                    _ImportSection(import_: vehicle.import_!),
                    const SizedBox(height: 20),
                  ],

                  // ── Localisation ────────────────────────────────
                  if (c.site != null) ...[
                    _SectionTitle(l10n.catalogSectionLocation),
                    _InfoRow(l10n.catalogFieldBranch, c.site!),
                    const SizedBox(height: 20),
                  ],

                  // ── Équipements & dotation ──────────────────────
                  if (vehicle.features.isNotEmpty) ...[
                    const Divider(height: 32),
                    _FeaturesSection(features: vehicle.features),
                  ],

                  // ── Partenaire source (staff seulement) ─────────
                  if (isStaff && c.partner != null) ...[
                    const Divider(height: 32),
                    _PartnerCard(partner: c.partner!),
                  ],

                  // ── Pannes (staff seulement) ────────────────────
                  if (isStaff) ...[
                    const Divider(height: 32),
                    VehicleFaultsSection(vehicleId: vehicle.id),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 80), // padding sous le bouton flottant
                ],
              ),
            ),
          ),
        ],
      ),

      // ── FAB staff : gérer les équipements ─────────────────────
      floatingActionButton: auth.canManageCatalog
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.checklist_outlined),
              label: Text(l10n.catalogSectionFeatures),
              onPressed: () => _manageFeatures(context, ref),
            )
          : null,

      // ── Barre d'action (clients uniquement) ───────────────────
      bottomNavigationBar: isStaff
          ? null
          : vehicle.seller != null
          ? SellerContactBar(seller: vehicle.seller!)
          : const _ActionBar(),
    );
  }

  Future<void> _manageFeatures(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final refs = ref.read(catalogRefsProvider).valueOrNull;
    if (refs == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.catalogRefsUnavailable)));
      return;
    }

    final initialSelected = vehicle.features.map((f) => f.id).toSet();

    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FeaturePickerSheet(
        allFeatures: refs.features,
        initialSelected: initialSelected,
      ),
    );

    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(vehicleAdminRepositoryProvider)
          .syncVehicleFeatures(vehicle.id, result.toList());
      ref.invalidate(vehicleDetailProvider(vehicle.id));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.catalogFeaturesUpdated)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageFor(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Le repli rend le code brut du serveur : une condition inconnue de cette
  /// table doit se voir plutôt que se ranger dans l'une des trois.
  String _conditionLabel(AppLocalizations l10n, String condition) =>
      switch (condition) {
        'new' => l10n.catalogConditionNew,
        'used' => l10n.catalogConditionUsed,
        'damaged' => l10n.catalogConditionDamaged,
        _ => condition,
      };
}

/// Fond du bandeau quand le véhicule n'a pas de photo — ou qu'elle n'arrive pas.
///
/// Le logo de la marque vaut mieux qu'un aplat gris : il reste identifiable.
class _CoverPlaceholder extends StatelessWidget {
  final String? slug;
  const _CoverPlaceholder({required this.slug});

  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: BrandLogo(slug: slug, size: 96),
  );
}

/// Mention « Full option », calculée par l'API à partir des équipements.
///
/// Le terme vient du marché de l'import et n'engage d'ordinaire que le
/// vendeur : deux véhicules annoncés « full option » n'ont pas forcément le
/// même équipement. Le badge affiche donc son décompte, que l'acheteur
/// retrouve détaillé dans la section « Équipements » plus bas.
///
/// Couleur en dur plutôt qu'un rôle du thème : les puces commerciales de
/// l'application sont déjà codées par couleur (sarcelle pour la vente, ambre
/// pour les bonnes affaires), et cette mention parle d'équipement, pas de
/// prix — elle a besoin d'une teinte à elle. Contraste sur blanc : 10:1.
class _FullOptionBadge extends StatelessWidget {
  final int? count;
  const _FullOptionBadge({required this.count});

  static const _color = Color(0xFF4A3B6B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).catalogFullOption,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).catalogFullOptionCount(count!),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section prix ───────────────────────────────────────────────────

class _PriceSection extends StatelessWidget {
  final VehicleCommercial commercial;

  /// La promotion en cours, ou null. `commercial.salePrice` porte déjà le
  /// prix du jour : ce bloc ajoute ce qu'il remplace et jusqu'à quand.
  final Promotion? promotion;

  const _PriceSection({required this.commercial, this.promotion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rentalPrices = vehicleRentalPriceLabels(commercial, AppLocalizations.of(context));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (commercial.isForSale && commercial.salePrice != null) ...[
            // ── LE PRIX SE RÉDUIT, LA RANGÉE NE DÉBORDE PLUS ───────────────
            //
            // Un `Row` donne à chacun de ses enfants sa largeur naturelle et ne
            // replie rien. Cette carte reçoit 256 points à 320 points d'écran,
            // et l'icône (18) + son écart (6) + « 9 500 000 FCFA » en
            // `titleLarge` gras + l'écart (8) + la pastille « Négociable » en
            // demandaient 257,2 :
            //
            //     A RenderFlex overflowed by 1.2 pixels on the right.
            //
            // AU RÉGLAGE DE TEXTE PAR DÉFAUT ET EN FRANÇAIS, et 69 points de
            // trop à l'échelle 2,0. Le défaut est antérieur à la traduction —
            // le texte français n'a pas changé d'un signe — ; c'est le banc
            // « Les écrans de la vague 2 » de `accueil_langues_test.dart` qui
            // regarde cette carte pour la première fois.
            //
            // LE PRIX NE PEUT NI SE COUPER NI SE REPLIER. « 9 500 000 FCFA »
            // est UN SEUL segment insécable — U+202F entre les milliers,
            // U+00A0 devant la devise —, donc le moteur n'a aucune césure
            // légale et se rabat sur une coupure caractère par caractère :
            // « 9 500 000 FCF » puis « A ». Un nombre coupé est FAUX et non
            // seulement incomplet, et c'est le seul défaut que l'échelle 2,0 ne
            // rachète pas — voir `coupeDansLeMot` dans
            // test/support/mesures.dart.
            //
            // D'où `BoxFit.scaleDown` : il RÉDUIT LE CORPS jusqu'à ce que tous
            // les chiffres tiennent, et ne fait rien quand ils tiennent déjà,
            // donc l'apparence ne change pas en deçà. C'est exactement
            // l'arbitrage de `_PrixAjuste` sur la carte du catalogue, et pour
            // la même raison : un montant abrégé vaut moins que pas de montant.
            //
            // La PASTILLE garde sa largeur naturelle et c'est le prix qui cède,
            // parce qu'une pastille rognée perdrait son mot entier alors que le
            // prix ne perd que des points de corps.
            Row(
              children: [
                const Icon(Icons.sell, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatXof(commercial.salePrice),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                if (promotion != null && !promotion!.finie) ...[
                  const SizedBox(width: 8),
                  // Le prix barre et la remise, cote a cote avec le prix du
                  // jour : c est la seule facon de lire l offre d un coup.
                  PrixNormalBarre(
                    promotion: promotion,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(width: 6),
                  PastillePromotion(promotion: promotion),
                ],
                if (commercial.priceNegotiable) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      AppLocalizations.of(context).catalogPriceNegotiable,
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ],
          if (rentalPrices.isNotEmpty) ...[
            for (final price in rentalPrices) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.key, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        price,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.secondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (commercial.rentalDeposit != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 24),
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).catalogRentalDeposit(formatXof(commercial.rentalDeposit)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Section import ─────────────────────────────────────────────────

class _ImportSection extends StatelessWidget {
  final VehicleImport import_;
  const _ImportSection({required this.import_});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        if (import_.originCountry != null)
          _InfoRow(l10n.catalogFieldOrigin, import_.originCountry!),
        if (import_.portOfEntry != null)
          _InfoRow(l10n.catalogFieldPortOfEntry, import_.portOfEntry!),
        // Le kilométrage d'import ne s'affiche plus ici : c'est deux fois le
        // même nombre sur la même fiche. L'API résout déjà `mileage_km` sur
        // l'odomètre relevé à l'import quand le véhicule n'est pas
        // immatriculé — la ligne « Kilométrage » plus haut le porte donc
        // déjà, et la répéter sous « Import » laissait croire à deux relevés
        // distincts.
        _InfoRow(
          l10n.catalogCustomsCleared,
          import_.customsCleared
              ? l10n.catalogCustomsYes
              : l10n.catalogCustomsPending,
        ),
        if (import_.isRightHandDrive)
          _InfoRow(l10n.catalogFieldHandedness, l10n.catalogRightHandDrive),
      ],
    );
  }
}

// ── Barre d'actions ────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref.watch(autoparcContactProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        // Les deux actions ouvrent le même numéro commercial, par appel ou par
        // WhatsApp. Elles remplacent des boutons dont le `onPressed` était vide.
        //
        // ── LES DEUX LIBELLÉS SE RÉDUISENT PLUTÔT QUE DE SE FAIRE ROGNER ──
        //
        // Chaque bouton reçoit la moitié de la largeur, icône comprise. À 320
        // points et à l'échelle 1,5, « WhatsApp » réclame 85,3 points pour la
        // largeur reçue : c'est UN MOT, donc il n'a aucune césure légale, et il
        // débordait de son bouton sans qu'aucune ellipse ne le signale —
        // `didExceedMaxLines` ne voit pas ce cas, seul `motLePlusLarge > recue`
        // le voit. Mesuré par le banc « Les écrans de la vague 2 ».
        //
        // EN FRANÇAIS COMME EN ANGLAIS : « WhatsApp » est un nom de marque et
        // ne se traduit pas, donc ce défaut-là est antérieur à la traduction.
        // Le banc est neuf, pas le défaut.
        //
        // `BoxFit.scaleDown` plutôt qu'un repli sur deux lignes, qui
        // grandirait la barre d'action de tout l'écran, et plutôt qu'une
        // ellipse, qui rendrait « Whatsa… » — un nom de marque amputé ne se
        // reconnaît plus.
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(contact.phoneUri),
                icon: const Icon(Icons.phone),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(AppLocalizations.of(context).catalogCallAction),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => launchUrl(
                  contact.whatsappUri,
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.chat),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('WhatsApp'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Picker équipements (bottom sheet staff) ────────────────────────

class _FeaturePickerSheet extends StatefulWidget {
  final List<FeatureRef> allFeatures;
  final Set<int> initialSelected;
  const _FeaturePickerSheet({
    required this.allFeatures,
    required this.initialSelected,
  });

  @override
  State<_FeaturePickerSheet> createState() => _FeaturePickerSheetState();
}

class _FeaturePickerSheetState extends State<_FeaturePickerSheet> {
  late final Set<int> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Regrouper par catégorie dans l'ordre défini
    final grouped = <String, List<FeatureRef>>{};
    for (final f in widget.allFeatures) {
      final cat = f.category ?? 'autre';
      grouped.putIfAbsent(cat, () => []).add(f);
    }
    final orderedKeys = [
      ..._categoryOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !_categoryOrder.contains(k)),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // ── Poignée + titre ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.checklist_outlined),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context).catalogFeaturesSheetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : FilledButton(
                            onPressed: () => Navigator.pop(context, _selected),
                            child: Text(
                              AppLocalizations.of(context).catalogFeaturesSave,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Liste avec cases à cocher ──────────────────────────
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              children: [
                for (final cat in orderedKeys) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      _libelleCategorie(AppLocalizations.of(context), cat),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cat == 'dotation'
                            ? Colors.amber.shade700
                            : cs.primary,
                      ),
                    ),
                  ),
                  for (final f in grouped[cat]!)
                    CheckboxListTile(
                      dense: true,
                      value: _selected.contains(f.id),
                      title: Text(f.name),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) => setState(() {
                        if (v == true)
                          _selected.add(f.id);
                        else
                          _selected.remove(f.id);
                      }),
                    ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section équipements ────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final List<VehicleFeature> features;
  const _FeaturesSection({required this.features});

  @override
  Widget build(BuildContext context) {
    // Regrouper par catégorie dans l'ordre défini
    final grouped = <String, List<VehicleFeature>>{};
    for (final f in features) {
      grouped.putIfAbsent(f.category, () => []).add(f);
    }

    // Tri alphabétique dans chaque catégorie : l'ordre naturel suivait les
    // identifiants en base, donc rien de repérable à l'œil.
    for (final list in grouped.values) {
      list.sort((a, b) => _sortKey(a.name).compareTo(_sortKey(b.name)));
    }

    // Catégories présentes, triées selon _categoryOrder (extras à la fin)
    final orderedKeys = [
      ..._categoryOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !_categoryOrder.contains(k)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(AppLocalizations.of(context).catalogSectionFeatures),
        for (final cat in orderedKeys) ...[
          const SizedBox(height: 14),
          _FeatureCategoryLabel(
            _libelleCategorie(AppLocalizations.of(context), cat),
          ),
          // La dotation est une information de conformité, pas un argument de
          // vente : contour discret plutôt que pastille pleine.
          _FeaturePills(items: grouped[cat]!, outlined: cat == 'dotation'),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Clé de tri insensible aux accents.
///
/// `compareTo` compare des unités UTF-16 : « â » (U+00E2) y passe après « r »,
/// si bien que « Câbles de démarrage » se rangeait derrière « Cric ».
String _sortKey(String s) {
  const accents = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿœæ';
  const plain = 'aaaaaceeeeiiiinooooouuuuyyoa';

  final out = StringBuffer();
  for (final char in s.toLowerCase().split('')) {
    final i = accents.indexOf(char);
    out.write(i == -1 ? char : plain[i]);
  }

  return out.toString();
}

/// Intitulé de sous-catégorie. Volontairement subordonné aux `_SectionTitle`
/// (« Véhicule », « Import »…) : « Confort » est une sous-partie du bloc
/// équipements, pas une section de même rang.
class _FeatureCategoryLabel extends StatelessWidget {
  final String text;
  const _FeatureCategoryLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      // Meme correction que les libelles de `_InfoRow` : ce sont des textes,
      // pas des bordures.
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    ),
  );
}

/// Pastilles d'équipement.
///
/// Plates et sans relief à dessein : elles ne sont pas cliquables, alors que
/// les `Chip` employées auparavant étaient quasi identiques aux `FilterChip`
/// de la page de recherche, qui le sont — on tapait dessus sans effet.
///
/// Aucune coche non plus : tout ce qui figure ici est présent, rien d'absent
/// n'est affiché, donc une icône de validation par ligne ne dirait rien et
/// suggérerait à tort qu'il existe des cases décochées.
class _FeaturePills extends StatelessWidget {
  final List<VehicleFeature> items;

  /// Contour seul au lieu d'un fond plein — réservé à la dotation.
  final bool outlined;

  const _FeaturePills({required this.items, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Le gris `surfaceContainerHighest` ne tenait pas sur ce fond quasi blanc :
    // 1,23:1 mesuré, soit une pastille invisible, alors que sa forme porte une
    // information — c'est elle qui sépare « Freins à disques avant » de
    // « Freins à disques 4 roues ». C'est la bordure qui assure désormais la
    // délimitation (3,23:1, au-dessus du seuil WCAG 1.4.11 de 3:1) ; le fond
    // reste discret pour que 26 étiquettes ne pèsent pas plus que le prix.
    final tint = cs.primary;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                // La dotation garde son statut de second rang par l'absence de fond,
                // pas par une bordure plus pâle qui la rendrait illisible.
                color: outlined ? null : tint.withValues(alpha: 0.12),
                border: Border.all(color: tint.withValues(alpha: 0.70)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                f.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: outlined ? cs.onSurfaceVariant : cs.onSurface,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Carte partenaire source (staff) ───────────────────────────────

class _PartnerCard extends StatelessWidget {
  final VehiclePartner partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppLocalizations.of(context).catalogSectionPartner,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: cs.secondaryContainer,
              child: Text(
                partner.companyName[0].toUpperCase(),
                style: TextStyle(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(partner.companyName),
            subtitle: partner.contactName != null
                ? Text(partner.contactName!)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // WhatsApp
                IconButton(
                  icon: const Icon(Icons.chat_outlined, size: 20),
                  color: const Color(0xFF25D366),
                  tooltip: 'WhatsApp',
                  onPressed: () {
                    final n = (partner.whatsapp ?? partner.phone).replaceAll(
                      RegExp(r'[^\d+]'),
                      '',
                    );
                    launchUrl(Uri.parse('https://wa.me/$n'));
                  },
                ),
                // Appel
                IconButton(
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  color: cs.primary,
                  tooltip: AppLocalizations.of(context).catalogCallAction,
                  onPressed: () => launchUrl(Uri.parse('tel:${partner.phone}')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers UI ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

/// Une ligne « libellé — valeur » de la fiche, QUI S'EMPILE QUAND LA VALEUR NE
/// TIENT PLUS.
///
/// ── LA COLONNE DE 140 POINTS NE SUIVAIT PAS L'ÉCHELLE DU TEXTE ─────────────
///
/// Elle est écrite en dur, donc elle garde ses 140 points quand les glyphes
/// grossissent de moitié, et c'est la valeur — l'`Expanded` — qui encaisse tout
/// le grossissement. À 320 points d'écran, la ligne dispose de 288,0 points
/// (`ListView(padding: all(16))`), et la valeur n'en reçoit donc jamais que
/// 148,0 quelle que soit l'échelle.
///
/// CE QUE ÇA COÛTAIT, mesuré par le banc « Les écrans de la vague 2 » dès que
/// `coupeDansLeMot` est entré dans `aucuneTroncature` : à 320 × 1,5, la
/// référence « VH-WHVQKVHM » réclame 158,0 points pour 148,0 reçus, et le plus
/// long segment insécable retombe de 158,0 à 123,1 — le moteur a coupé à
/// l'intérieur, « VH- » puis « WHVQKVHM » sur deux lignes. Les DEUX langues
/// tombaient : une référence ne se traduit pas.
///
/// ── POURQUOI EMPILER, ET NON RÉTRÉCIR LA COLONNE ──────────────────────────
///
/// Rétrécir la colonne des libellés à 130,0 points rendrait à la valeur
/// exactement les 158,0 qu'elle réclame — c'est-à-dire ZÉRO marge, et un
/// libellé plus long ou une police un peu plus large rouvrirait le défaut sans
/// que rien ne le dise. Empilé, la valeur reçoit les 288,0 points de la ligne,
/// donc 130,0 de marge sur le cas mesuré.
///
/// LE SEUIL EST MESURÉ ET NE REGARDE PAS L'ÉCHELLE DE TEXTE : on compare ce que
/// le plus long segment insécable de la valeur réclame à ce que la forme côte à
/// côte lui laisserait. C'est l'idiome de `engine_prompt.dart`, et pour la même
/// raison — une borne d'échelle passerait outre le réglage d'accessibilité, et
/// un seuil sur l'échelle figerait une décision que la largeur d'écran et la
/// langue changent aussi.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  /// La largeur de la colonne des libellés dans la forme côte à côte.
  ///
  /// Inchangée : c'est la forme que presque tout le monde voit, et personne ne
  /// l'a reprochée. Le seuil ne la rétrécit jamais, il choisit entre elle et la
  /// forme empilée.
  static const double _colonneLibelle = 140.0;

  @override
  Widget build(BuildContext context) {
    // `outline` est un role de bordure : a 4,27:1 mesure, ces libelles
    // passaient sous le seuil AA de 4,5:1 pour du texte de 12sp.
    // `onSurfaceVariant` est le role prevu pour du texte secondaire.
    final styleLibelle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final styleValeur = Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, contraintes) {
          // LE STYLE EST FUSIONNÉ AVEC CELUI DE L'ARBRE, et ce n'est pas
          // décoratif : un `Text` fusionne toujours son style avec le
          // `DefaultTextStyle` ambiant, dont vient la FAMILLE DE POLICE. Un
          // `TextPainter` construit sur le style nu mesurerait la police de
          // repli, presque deux fois plus large — voir test/support/polices.dart
          // pour ce que cette confusion a déjà coûté — et le seuil basculerait
          // au mauvais endroit.
          final ambiant = DefaultTextStyle.of(context).style;
          final sens = Directionality.of(context);
          final echelle = MediaQuery.textScalerOf(context);

          /// Le plus long segment INSÉCABLE de [texte], remis en page SANS
          /// BORNE.
          ///
          /// Sans borne, et c'est tout le point : borné à la largeur reçue, le
          /// moteur a déjà coupé dans le mot et `minIntrinsicWidth` est alors
          /// retombé à la largeur d'un caractère — 123,1 pour « VH-WHVQKVHM »
          /// au lieu de 158,0. Mesurer sur la largeur reçue reviendrait à
          /// demander au défaut s'il existe.
          double mot(String texte, TextStyle? style) => (TextPainter(
            text: TextSpan(text: texte, style: ambiant.merge(style)),
            textDirection: sens,
            textScaler: echelle,
          )..layout()).minIntrinsicWidth;

          final libelle = Text(label, style: styleLibelle);
          final valeur = Text(value, style: styleValeur);

          if (mot(value, styleValeur) <=
              contraintes.maxWidth - _colonneLibelle) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: _colonneLibelle, child: libelle),
                Expanded(child: valeur),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [libelle, valeur],
          );
        },
      ),
    );
  }
}

/// Ligne « Couleur », avec une pastille de la teinte réelle.
///
/// Le nom seul ne renseigne pas : « Bordeaux », « Gris titanium » ou
/// « Blanc nacré » ne se visualisent pas. La teinte vient de `colors.hex_code`
/// en base — jamais d'une correspondance devinée à partir du libellé, qui
/// serait fausse dès la première nuance inhabituelle.
class _ColorRow extends StatelessWidget {
  final String name;
  final String? hex;
  final String? finish;

  const _ColorRow({required this.name, this.hex, this.finish});

  Color? get _swatch {
    final raw = hex?.replaceFirst('#', '');
    if (raw == null || raw.length != 6) return null;
    final value = int.tryParse(raw, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  /// Le nom et sa finition. [l10n] est passé plutôt que lu : ce getter n'a pas
  /// de `BuildContext`, et le `build` ci-dessous en a un.
  String _label(AppLocalizations l10n) => switch (finish) {
    'metallise' => l10n.catalogColourMetallic(name),
    'nacre' => l10n.catalogColourPearl(name),
    _ => name,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final swatch = _swatch;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              l10n.catalogFieldColour,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (swatch != null) ...[
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: swatch,
                      borderRadius: BorderRadius.circular(3),
                      // Sans cette bordure, « Blanc » (#FFFFFF) serait
                      // invisible sur le fond quasi blanc de la page.
                      border: Border.all(color: cs.outline),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _label(l10n),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<(String, String?)> items;
  const _InfoGrid(this.items);

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((e) => e.$2 != null).toList();
    return Column(
      children: filtered.map((e) => _InfoRow(e.$1, e.$2!)).toList(),
    );
  }
}

/// La consommation officielle du modèle, sur la fiche d'une annonce.
///
/// Elle vit hors de la grille d'identité, parce qu'elle ne décrit pas ce
/// véhicule-ci mais son modèle : une fourchette, sa provenance et son cycle
/// d'essai. Rangée entre « Finition » et « Transmission », elle se lirait
/// comme une caractéristique mesurée sur l'exemplaire en vente.
class _ConsommationOfficielle extends StatelessWidget {
  final OfficialConsumption cote;

  const _ConsommationOfficielle({required this.cote});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_gas_station_outlined, size: 18, color: cs.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  ).catalogOfficialConsumption(cote.libelle),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  // LA SECONDE PHRASE ÉTAIT COMPOSÉE DE QUATRE MORCEAUX, dont
                  // l'un se terminait par une espace pour tenir au suivant.
                  // Une phrase traduite ne se découpe pas ainsi : l'anglais ne
                  // met ni la parenthèse ni l'incise au même endroit, et
                  // « Millésime » précède l'année en français quand l'anglais
                  // la fait précéder (« 2016 model year »). Les deux variantes
                  // sont donc deux clés entières.
                  cote.estUnique
                      ? AppLocalizations.of(
                          context,
                        ).catalogOfficialConsumptionSingle(
                          cote.modelYear,
                          cote.source,
                          cote.cycle,
                        )
                      : AppLocalizations.of(
                          context,
                        ).catalogOfficialConsumptionRange(
                          cote.motorisations,
                          cote.modelYear,
                          cote.source,
                          cote.cycle,
                        ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Les memes libelles que le formulaire d'enregistrement : une carrosserie
/// saisie « Berline » doit se relire « Berline », pas « sedan ».
///
/// JEU DE CLÉS DISTINCT DE CELUI DES PUCES DE FILTRE, et c'est un constat et
/// non un choix : `vehicle_list_page.dart` dit « Citadine » et « Fourgon » là
/// où cette table dit « Citadine / Hayon » et « Fourgonnette », pour les mêmes
/// valeurs `hatchback` et `van`. La divergence est antérieure à la traduction ;
/// l'unifier aurait changé le français de l'un des deux écrans, ce qu'un lot de
/// traduction n'a pas à faire en passant. D'où `catalogBodyLabel*` ici et
/// `catalogBodyStyle*` là-bas.
///
/// À noter : l'anglais la fait DISPARAÎTRE — « Hatchback » et « Van » sont les
/// mots uniques de la langue —, ce qui est un signe de plus que la divergence
/// française n'avait pas de raison.
String _libelleCarrosserie(AppLocalizations l10n, String code) =>
    switch (code) {
      'sedan' => l10n.catalogBodyLabelSedan,
      'hatchback' => l10n.catalogBodyLabelHatchback,
      'suv' => l10n.catalogBodyLabelSuv,
      'estate' => l10n.catalogBodyLabelEstate,
      'coupe' => l10n.catalogBodyLabelCoupe,
      'convertible' => l10n.catalogBodyLabelConvertible,
      'pickup' => l10n.catalogBodyLabelPickup,
      'van' => l10n.catalogBodyLabelVan,
      'minibus' => l10n.catalogBodyLabelMinibus,
      'bus' => l10n.catalogBodyLabelBus,
      'truck' => l10n.catalogBodyLabelTruck,
      'other' => l10n.catalogBodyLabelOther,
      _ => code,
    };
