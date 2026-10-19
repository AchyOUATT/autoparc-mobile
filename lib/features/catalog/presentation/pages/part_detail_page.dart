import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/part.dart';
import '../../data/catalog_repository.dart';
import '../providers/catalog_providers.dart';
import '../widgets/fitments_section.dart';
import '../../../../features/garage/data/models/garage_compatibility.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/partage.dart';
import '../../../../features/cart/data/models/cart_item.dart';
import '../../../../features/cart/presentation/pages/cart_page.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../features/partners/presentation/widgets/product_partners_section.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/widgets/product_gallery.dart';
import '../../../../shared/data/media_repository.dart';
import '../../../../shared/presentation/pages/media_upload_page.dart';
import '../../../../l10n/app_localizations.dart';

/// La nature d'une pièce, DÉVELOPPÉE, dans la langue active.
///
/// Les deux tables de ce fichier étaient `const` : une constante est construite
/// avant qu'aucun `BuildContext` n'existe, donc avant que la langue soit
/// connue, et les sept libellés seraient restés français pour tout le monde.
///
/// LIBELLÉS DISTINCTS DE CEUX DE LA LISTE, et ce n'est pas une duplication :
/// la carte du catalogue n'a de place que pour le sigle (« OEM »), la fiche
/// développe (« OEM — Constructeur d'origine »). Les deux chaînes étaient déjà
/// différentes en français, d'où `catalogPartType*Long` ici et
/// `catalogPartType*` dans `part_list_page.dart`.
///
/// Le repli rend le code brut du serveur, comme avant : une nature inconnue de
/// cette table doit se voir.
String _libelleType(AppLocalizations l10n, String type) => switch (type) {
  'oem' => l10n.catalogPartTypeOemLong,
  'oes' => l10n.catalogPartTypeOesLong,
  'aftermarket' => l10n.catalogPartTypeAftermarketLong,
  'salvage' => l10n.catalogPartTypeSalvageLong,
  _ => type,
};

/// L'état d'une pièce dans la langue active.
///
/// Trois états et non deux : « Reconditionné » est remis en état par un atelier
/// et garanti, « Usagé » est vendu tel quel. C'est une colonne INDÉPENDANTE de
/// la nature — une pièce de récupération peut être reconditionnée —, et c'est
/// pourquoi « Usagé » et le « Occasion » de `catalogPartTypeSalvage` ne
/// partagent pas de clé.
String _libelleEtat(AppLocalizations l10n, String condition) =>
    switch (condition) {
      'new' => l10n.catalogPartConditionNew,
      'refurbished' => l10n.catalogPartConditionRefurbished,
      'used' => l10n.catalogPartConditionUsed,
      _ => condition,
    };

class PartDetailPage extends ConsumerWidget {
  final int partId;
  final Part? initialPart;

  const PartDetailPage({super.key, required this.partId, this.initialPart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partAsync = ref.watch(partDetailProvider(partId));

    // Affichage immédiat avec les données de la liste, mise à jour dès que
    // la requête complète est disponible.
    final part = partAsync.valueOrNull ?? initialPart;

    if (part == null) {
      return Scaffold(
        appBar: AppBar(),
        body: partAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(messageFor(e))),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final isStaff = auth.isStaff;
    final inStock = part.stock.quantity > 0;

    Future<void> deletePart() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.catalogPartDeleteTitle),
          content: Text(l10n.catalogPartDeleteBody(part.name)),
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
        await ref.read(catalogRepositoryProvider).deletePart(part.id);
        ref.invalidate(partListProvider);
        // La dernière pièce d'une catégorie doit en retirer la pastille : sinon
        // elle resterait proposée et ne renverrait plus rien.
        ref.invalidate(categoriesAvecPiecesProvider);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(messageFor(e)), backgroundColor: cs.error),
          );
        }
      }
    }

    final inCart = ref.watch(
      cartProvider.select(
        (items) => items.any(
          (i) => i.id == part.id && i.itemType == CartItemType.part,
        ),
      ),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar ─────────────────────────────────────────────────
          SliverAppBar(
            // 300 au lieu de 160. A 160, et avec la photo qui passait SOUS la
            // barre, il restait une bande ou l'on ne distinguait pas une
            // cartouche de filtre d'un carton. Une fiche produit se juge
            // d'abord sur sa photo.
            expandedHeight: 300,
            pinned: true,
            // La barre prend la couleur de la surface plutot que celle du
            // theme : le bandeau n'est plus un aplat colore mais un cadre
            // autour d'une photo, et le titre y est desormais sombre.
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              // Le partage en tête, et sans aucune condition de capacité.
              //
              // Les autres commandes de cette barre sont des commandes de
              // gestion, réservées au personnel. Le partage ne l'est pas : la
              // personne qui partage est le plus souvent un client, pour qu'un
              // proche voie la pièce et rappelle le magasin. Le conditionner à
              // `canManageCatalog` l'aurait rendu invisible à presque tous ceux
              // qui s'en servent.
              //
              // En tête, il garde la même place que le personnel soit connecté
              // ou non, et c'est la dernière commande de la rangée — jamais
              // celle-ci — qui serait rognée si la barre venait à déborder.
              //
              // Pas de capacité, donc, mais UNE condition : une pièce
              // désactivée n'a pas de page `/p/{id}`, et le message porte
              // cette adresse depuis qu'il ne porte plus celle du magasin
              // d'applications. Partager une pièce désactivée, c'est envoyer un
              // 404 — voir `Part.aUnePagePublique`.
              //
              // Masqué et non grisé : la raison est une règle de catalogue, et
              // l'écrire dans une infobulle ferait porter à cet écran une
              // mécanique de serveur. D'où ce commentaire, faute de quoi
              // quelqu'un le repostera sans condition.
              if (part.aUnePagePublique)
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: l10n.catalogShareTooltip,
                  // LE NOM ET L'ADRESSE, RIEN D'AUTRE. Le prix, la catégorie,
                  // l'état et la référence partaient encore dans le texte ; la
                  // page `/p/{id}` les porte dans ses balises Open Graph, et
                  // WhatsApp les affiche dans sa vignette sous le message. Le
                  // destinataire lisait donc tout deux fois dans la même bulle
                  // — « le partage duplique les informations de l'article »,
                  // signalé par le propriétaire. Voir `composerMessagePartage`,
                  // et la garde de `partage_bouton_test.dart`, qui est le seul
                  // endroit où cette duplication se mesure.
                  onPressed: () => partagerArticle(
                    context,
                    titre: part.name,
                    // `id` et non `sku` : c'est la clef primaire que la route
                    // publique `/p/{id}` attend. Le SKU, lui, ne part plus du
                    // tout — il n'était qu'une précision parmi les autres.
                    type: TypeArticle.piece,
                    id: part.id,
                  ),
                ),
              // Les photos s'ajoutaient uniquement dans la seconde qui suivait
              // la creation : le formulaire basculait sur l'ecran de
              // televersement, et plus rien n'y menait ensuite. Passer cette
              // etape, ou publier autrement que par le formulaire — ce qui est
              // le cas des dix filtres a huile du catalogue —, rendait les
              // photos definitivement inaccessibles.
              if (auth.canManageCatalog)
                IconButton(
                  icon: const Icon(Icons.add_a_photo_outlined),
                  tooltip: l10n.catalogPhotosTooltip,
                  onPressed: () => context
                      .push(
                        '/media-upload',
                        extra: MediaUploadConfig(
                          type: MediaOwnerType.part,
                          id: part.id,
                          title: part.name,
                        ),
                      )
                      .then((_) {
                        ref.invalidate(partDetailProvider(part.id));
                        ref.invalidate(partListProvider);
                      }),
                ),
              if (auth.canManageCatalog)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.catalogEditTooltip,
                  onPressed: () => context
                      .push('/parts/${part.id}/edit', extra: part)
                      .then((_) => ref.invalidate(partDetailProvider(part.id))),
                ),
              if (auth.canDeleteCatalog)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: l10n.catalogDeleteAction,
                  onPressed: deletePart,
                ),
              if (!isStaff) const CartIconButton(),
            ],
            flexibleSpace: FlexibleSpaceBar(
              // Sombre, sur la surface, et non plus blanc sur un voile noir.
              //
              // Le voile etait une rustine : il assombrissait le bas de la
              // photo pour qu'un titre blanc y survive. Or les photos de
              // produit sont presque toujours sur fond BLANC — une boite de
              // filtre, un carton — et le voile devait alors lutter contre
              // l'image entiere. Le titre descend maintenant sous la photo,
              // sur la surface de l'application, ou son contraste est garanti
              // quelle que soit l'image.
              titlePadding: const EdgeInsetsDirectional.only(
                start: 16,
                end: 16,
                bottom: 10,
              ),
              title: Text(
                part.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // La photo de couverture, et l'engrenage seulement a defaut.
              //
              // Ce bandeau affichait l'icone en dur : il ne consultait ni
              // coverUrl ni media. Les photos existaient, l'API les renvoyait,
              // la carte de la liste les affichait — seule la fiche, ou on les
              // cherche justement, n'en montrait aucune.
              //
              // Les marges sortent la photo de dessous la barre : elle etait
              // collee au bord superieur, a moitie masquee par les icones
              // d'action, et le peu qui restait visible touchait l'encoche.
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
                    urls: part.photoUrls,
                    titre: part.name,
                    fallback: _PartCover(cs: cs),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── SKU + Badge type ──────────────────────────────────
                // `Wrap` ET NON `Row`, ET C'EST UN DÉBORDEMENT MESURÉ. Les deux
                // pastilles réclamaient chacune sa largeur naturelle, et rien
                // ne les repliait : à 320 points et à l'échelle 1,5 la rangée
                // dépassait de 12 points, à 411 et 2,0 de 4,1 —
                //
                //     A RenderFlex overflowed by 12 pixels on the right.
                //
                // EN FRANÇAIS COMME EN ANGLAIS : le SKU est une valeur du
                // serveur et « OEM » un sigle identique dans les deux langues,
                // donc le défaut est antérieur à la traduction. C'est le banc
                // « Les écrans de la vague 2 » qui est neuf.
                //
                // `spacing: 8` reprend exactement l'écart que le `SizedBox`
                // posait : l'apparence ne change pas quand les deux tiennent.
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (part.sku != null)
                      Chip(
                        label: Text(
                          part.sku!,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        avatar: const Icon(Icons.tag, size: 16),
                      ),
                    if (part.isOem)
                      Chip(
                        // Le SIGLE seul, et non le libellé développé que la
                        // carte d'informations affiche plus bas : cette
                        // pastille vit dans une rangée avec le SKU, et
                        // « OEM — Constructeur d'origine » y occuperait toute
                        // la largeur. D'où `catalogPartTypeOem` ici et
                        // `catalogPartTypeOemLong` là.
                        label: Text(l10n.catalogPartTypeOem),
                        backgroundColor: cs.primaryContainer,
                        labelStyle: TextStyle(color: cs.onPrimaryContainer),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Prix ──────────────────────────────────────────────
                _PriceCard(pricing: part.pricing),
                const SizedBox(height: 12),

                // ── Stock ─────────────────────────────────────────────
                _StockCard(stock: part.stock, inStock: inStock),
                const SizedBox(height: 12),

                // ── Infos produit ─────────────────────────────────────
                _InfoCard(part: part),
                const SizedBox(height: 12),

                // ── Description ───────────────────────────────────────
                if (part.description != null &&
                    part.description!.isNotEmpty) ...[
                  Text(
                    l10n.catalogSectionDescription,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    part.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Compatibilité avec le garage (clients uniquement) ─
                if (!isStaff) _GarageCompatibilitySection(partId: part.id),

                // ── Véhicules compatibles ─────────────────────────────
                //
                // Pour tout le monde, et non plus pour le seul staff.
                //
                // Le bloc du dessus répond à une question étroite : « est-ce
                // que ça va sur MES véhicules ». Utile, mais il ne dit rien à
                // qui achète pour la voiture d'un proche, qui compare avant
                // d'enregistrer son véhicule, ou dont le modèle n'est pas au
                // référentiel. Ces trois cas lisaient une page muette sur la
                // destination de la pièce.
                //
                // Les deux blocs se complètent : l'un confronte, l'autre
                // énumère. Seul le bouton de modification reste au staff.
                CompatibilitesDeclarees(
                  lignes: part.fitments,
                  rienDeclare: l10n.catalogPartNoFitments,
                  onModifier: isStaff
                      ? () => GoRouter.of(
                          context,
                        ).push('/parts/${part.id}/edit', extra: part)
                      : null,
                ),

                // ── Partenaires (visible staff uniquement) ────────────
                PartPartnersSection(partId: part.id),

                // ── Chargement en arrière-plan ────────────────────────
                if (partAsync.isLoading) const LinearProgressIndicator(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),

      // ── Bouton Commander (clients uniquement) ─────────────────────
      bottomNavigationBar: isStaff
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: inStock
                      ? () {
                          ref
                              .read(cartProvider.notifier)
                              .add(CartItem.fromPart(part));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.catalogAddedToCart(part.name)),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: l10n.catalogSeeCart,
                                onPressed: () => context.push('/cart'),
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: Icon(
                    inCart ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  ),
                  label: Text(
                    inStock
                        ? (inCart
                              ? l10n.catalogAddToCartAgain
                              : l10n.catalogAddToCart)
                        : l10n.catalogOutOfStock,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Carte prix ────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final PartPricing pricing;
  const _PriceCard({required this.pricing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).catalogSectionPrice,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            // Les deux textes étaient posés bruts : chacun réclamait sa
            // largeur naturelle, et la ligne débordait dès qu'un prix à sept
            // chiffres rencontrait un petit écran ou des caractères grossis.
            //
            // « IL PASSE À LA LIGNE PLUTÔT QUE D'ÊTRE TRONQUÉ » DISAIT CE
            // COMMENTAIRE, ET C'ÉTAIT FAUX. Un montant est UN SEUL segment
            // insécable — U+202F entre les milliers, U+00A0 devant la devise —,
            // donc le moteur n'a aucune césure légale et ne passe pas à la
            // ligne : il coupe DANS le mot. Mesuré par le banc « Les écrans de
            // la vague 2 » à 320 points et à l'échelle 2,0 : « 3 000 FCFA »
            // réclame 139,7 points pour la largeur reçue, « 3,000 FCFA » 143,6
            // en anglais, et le `Flexible` les repliait en « 3 000 FCF » puis
            // « A ». C'est le défaut que `coupeDansLeMot` existe pour voir, et
            // le seul que l'échelle 2,0 ne rachète pas : un nombre coupé est
            // FAUX, pas incomplet.
            //
            // `BoxFit.scaleDown` réduit le corps jusqu'à ce que tous les
            // chiffres tiennent, et ne fait rien quand ils tiennent déjà.
            // Même arbitrage que la carte de prix d'un véhicule et que
            // `_PrixAjuste` sur la carte du catalogue.
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).catalogFieldSalePrice,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatXof(pricing.sellingPrice),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte stock ───────────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final PartStock stock;
  final bool inStock;
  const _StockCard({required this.stock, required this.inStock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = inStock
        ? (stock.isLow ? Colors.orange : Colors.green)
        : Colors.red;
    final label = inStock
        ? (stock.isLow
              ? l10n.catalogStockQuantityLow(stock.quantity)
              : l10n.catalogStockQuantity(stock.quantity))
        : l10n.catalogOutOfStock;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(
          inStock
              ? (stock.isLow ? Icons.warning_amber : Icons.check_circle)
              : Icons.cancel,
          color: color,
        ),
        title: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        subtitle: stock.location != null
            ? Text(l10n.catalogStockLocation(stock.location!))
            : null,
      ),
    );
  }
}

// ── Carte infos produit ───────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Part part;
  const _InfoCard({required this.part});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typeLabel = _libelleType(l10n, part.type);
    final conditionLabel = _libelleEtat(l10n, part.condition);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.catalogSectionInformation,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _InfoRow(l10n.catalogFieldType, typeLabel),
            _InfoRow(l10n.catalogFieldState, conditionLabel),
            // Le NOM de la catégorie et celui du fabricant viennent du
            // référentiel du serveur et restent en français jusqu'à la vague
            // serveur : seuls leurs libellés sont traduits.
            if (part.categoryName != null)
              _InfoRow(l10n.catalogFieldCategory, part.categoryName!),
            if (part.manufacturer != null)
              _InfoRow(l10n.catalogFieldManufacturer, part.manufacturer!),
            // garantie désactivée temporairement
            // if (part.warrantyMonths != null)
            //   _InfoRow('Garantie', '${part.warrantyMonths} mois'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

// ── Section compatibilité garage ──────────────────────────────────────

/// Affiche, pour chaque véhicule du garage du client, si la pièce est compatible.
///
/// Chargée en arrière-plan — silencieuse en cas d'erreur (ex. : utilisateur
/// non connecté via Firebase). Ne bloque pas l'affichage de la fiche.
class _GarageCompatibilitySection extends ConsumerWidget {
  final int partId;
  const _GarageCompatibilitySection({required this.partId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compatAsync = ref.watch(garageCompatibilityProvider(partId));

    return compatAsync.when(
      // Chargement discret — ne pas décaler la mise en page.
      loading: () => const SizedBox.shrink(),
      // Erreur silencieuse (non connecté, réseau, etc.).
      error: (e, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).catalogGarageSectionTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 56, endIndent: 0),
                    CompatibilityTile(item: items[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class CompatibilityTile extends StatelessWidget {
  final GarageCompatibility item;
  const CompatibilityTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Quatre états, pas trois.
    //
    // Le cas « compatible, mais on ignore la motorisation » était affiché en
    // vert comme une certitude : `compatible` court-circuitait le test, et
    // `compatibilityReady` n'était consulté que sur la branche négative.
    //
    // Ce n'est pas un détail d'affichage. Une même génération reçoit plusieurs
    // moteurs, et deux filtres différents : un Hilux AN10 existe en diesel 1KD
    // et en V6 essence 1GR. Sans le code moteur du véhicule, la recherche les
    // renvoie tous les deux — et les annonçait tous les deux en vert. L'un des
    // deux ne se visse pas.
    final l10n = AppLocalizations.of(context);
    final (IconData icon, Color color, String label, String? detail) = switch ((
      item.compatible,
      item.compatibilityReady,
    )) {
      (true, true) => (
        Icons.check_circle,
        Colors.green,
        l10n.catalogFitmentYes,
        null,
      ),
      (true, false) => (
        Icons.help_outline,
        Colors.amber.shade700,
        l10n.catalogFitmentUnsure,
        l10n.catalogFitmentUnsureDetail,
      ),
      (false, true) => (Icons.cancel, Colors.red, l10n.catalogFitmentNo, null),
      (false, false) => (
        Icons.help_outline,
        Colors.amber.shade700,
        l10n.catalogFitmentUnknown,
        l10n.catalogFitmentUnknownDetail,
      ),
    };

    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        l10n.catalogVehicleWithYear(item.displayName, item.year),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: detail == null
          ? null
          : Text(
              detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
      isThreeLine: detail != null,
      trailing: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Le repli du bandeau : l'engrenage, quand la piece n'a aucune photo.
///
/// C'est volontairement l'icone qui etait codee en dur ici auparavant — un
/// article sans photo garde donc exactement l'allure qu'il avait. Seuls ceux
/// qui en ont une changent. Il sert aussi de repli a chaque image de la
/// galerie : une URL qui echoue retombe dessus plutot que de laisser un trou.
class _PartCover extends StatelessWidget {
  const _PartCover({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
    color: cs.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.settings_outlined,
        size: 72,
        color: cs.outline.withValues(alpha: 0.4),
      ),
    ),
  );
}
