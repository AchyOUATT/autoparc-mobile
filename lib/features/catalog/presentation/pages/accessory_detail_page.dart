import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/accessory.dart';
import '../../data/catalog_repository.dart';
import '../providers/catalog_providers.dart';
import '../widgets/fitments_section.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/product_gallery.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/partage.dart';
import '../../../../features/cart/data/models/cart_item.dart';
import '../../../../features/cart/presentation/pages/cart_page.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../features/partners/presentation/widgets/product_partners_section.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../shared/data/media_repository.dart';
import '../../../../shared/presentation/pages/media_upload_page.dart';
import '../../../../l10n/app_localizations.dart';

class AccessoryDetailPage extends ConsumerWidget {
  final int accessoryId;
  final Accessory? initialAccessory;

  const AccessoryDetailPage({
    super.key,
    required this.accessoryId,
    this.initialAccessory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(accessoryDetailProvider(accessoryId));
    final accessory = detailAsync.valueOrNull ?? initialAccessory;

    if (accessory == null) {
      return Scaffold(
        appBar: AppBar(),
        body: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(messageFor(e))),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }

    return _AccessoryDetailView(accessory: accessory);
  }
}

class _AccessoryDetailView extends ConsumerWidget {
  final Accessory accessory;
  const _AccessoryDetailView({required this.accessory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final isStaff = auth.isStaff;
    final p = accessory.pricing;

    Future<void> deleteAccessory() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.catalogAccessoryDeleteTitle),
          content: Text(l10n.catalogAccessoryDeleteBody(accessory.name)),
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
        await ref.read(catalogRepositoryProvider).deleteAccessory(accessory.id);
        ref.invalidate(accessoryListProvider);
        // Le dernier article d'une catégorie doit en retirer la pastille.
        ref.invalidate(categoriesAccessoiresOccupeesProvider);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(messageFor(e)), backgroundColor: cs.error),
          );
        }
      }
    }

    final s = accessory.stock;
    final inCart = ref.watch(
      cartProvider.select(
        (items) => items.any(
          (i) => i.id == accessory.id && i.itemType == CartItemType.accessory,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          accessory.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // La première des commandes, et la seule que tout le monde voie.
          //
          // Même raisonnement que sur la fiche d'une pièce : partager n'est pas
          // une action de gestion, c'est le plus souvent un client qui le fait.
          // Aucune capacité ne le conditionne donc, et il précède les trois
          // commandes du personnel pour garder sa place quand elles s'affichent.
          //
          // CETTE BARRE A DÉBORDÉ, et c'est réglé — par la puce de catégorie
          // qui a quitté la rangée, pas par ce bouton.
          //
          // La mesure, qui garde toute sa valeur : à 320 points, le plus petit
          // format que `responsive_test.dart` exige, vue par un administrateur
          // et sur le libellé de catégorie le plus long (« Multimédia »,
          // 10 signes, à égalité avec « Esthétique » et « Utilitaire »), la
          // barre débordait de 9,0 points à l'échelle de texte 1,0 et de
          // 40 points à 1,3. À 360, elle tenait. Sans ce bouton, elle tenait
          // aussi — mais le partage est la commande demandée, et c'est
          // l'occupant qui n'était pas une commande qui est parti.
          //
          // `actions` est une rangée de COMMANDES. La puce de catégorie en
          // était le seul occupant à n'en pas être une, et la catégorie
          // n'apparaissait nulle part dans le corps de la fiche : elle y
          // descend donc, en première ligne de « Informations », au lieu
          // d'être supprimée. Elle y gagne même en lisibilité — 11 points de
          // corps dans une puce, contre le corps de texte normal.
          //
          // Ce que ce départ rend : 129,0 points de puce à l'échelle 1,0
          // (95,7 pour « Confort ») plus l'espaceur de 8, soit ~137 — bien
          // plus que les 40 points du pire cas mesuré.
          //
          // Et ce départ répare au passage un défaut plus ancien, qui n'était
          // pas un débordement et qu'aucun banc d'essai ne rendait : le titre
          // mesurait 0 point de large, à 320 comme à 360 avec « Multimédia »
          // — le nom de l'article était simplement invisible. Il mesure
          // maintenant 96,0 points à 320 et 136,0 à 360, aux deux échelles de
          // texte. C'est la place que la puce occupait.
          //
          // UNE condition tout de même, et elle ne tient pas à la session : un
          // accessoire désactivé ou indisponible n'a pas de page `/a/{id}`, et
          // le message porte cette adresse depuis qu'il ne porte plus celle du
          // magasin d'applications. Le partage enverrait un 404 — voir
          // `Accessory.aUnePagePublique`, qui recopie les deux `abort_if` du
          // serveur. Le catalogue des accessoires masque déjà les
          // indisponibles ; une fiche atteinte autrement, ou devenue
          // indisponible depuis, les montre encore.
          //
          // Le bouton disparaît plutôt que de rester grisé : la raison est une
          // règle de catalogue, et l'expliquer dans une infobulle ferait porter
          // à cette fiche une mécanique de serveur. Ce commentaire est là pour
          // qu'on ne le repose pas sans condition.
          if (accessory.aUnePagePublique)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: l10n.catalogShareTooltip,
              // LE NOM ET L'ADRESSE, RIEN D'AUTRE. Le prix et la catégorie
              // partaient encore dans le texte ; la page `/a/{id}` les porte
              // dans ses balises Open Graph, et WhatsApp les affiche dans sa
              // vignette sous le message — le destinataire les lisait deux fois
              // dans la même bulle. Voir `composerMessagePartage`, et la garde
              // de `partage_bouton_test.dart` : la duplication ne se voit que
              // dans une conversation, jamais à l'écran de l'application.
              onPressed: () => partagerArticle(
                context,
                titre: accessory.name,
                // La clef primaire, celle que la route publique `/a/{id}`
                // attend. Le partage ne fabrique aucune autre adresse.
                type: TypeArticle.accessoire,
                id: accessory.id,
              ),
            ),
          // Voir la fiche piece : l'ecran de televersement n'etait atteignable
          // qu'au moment de la creation, et plus jamais ensuite.
          if (auth.canManageCatalog)
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: l10n.catalogPhotosTooltip,
              onPressed: () => context
                  .push(
                    '/media-upload',
                    extra: MediaUploadConfig(
                      type: MediaOwnerType.accessory,
                      id: accessory.id,
                      title: accessory.name,
                    ),
                  )
                  .then((_) {
                    ref.invalidate(accessoryDetailProvider(accessory.id));
                    ref.invalidate(accessoryListProvider);
                  }),
            ),
          if (auth.canManageCatalog)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.catalogEditTooltip,
              onPressed: () => context
                  .push('/accessories/${accessory.id}/edit', extra: accessory)
                  .then(
                    (_) =>
                        ref.invalidate(accessoryDetailProvider(accessory.id)),
                  ),
            ),
          if (auth.canDeleteCatalog)
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              tooltip: l10n.catalogDeleteAction,
              onPressed: deleteAccessory,
            ),
          if (!isStaff) const CartIconButton(),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Photo de couverture, icone de categorie a defaut ──
          //
          // Ce bloc affichait l'icone en dur : il ne consultait ni coverUrl ni
          // media. Meme oubli que sur la fiche d'une piece.
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: ProductGallery(
                urls: accessory.photoUrls,
                titre: accessory.name,
                fallback: _AccessoryCover(
                  iconeDeRepli: _categoryIcon(accessory.categoryValue),
                  cs: cs,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Prix ──────────────────────────────────────────────
          _PriceCard(pricing: p),
          const SizedBox(height: 20),

          // ── Stock ─────────────────────────────────────────────
          _StockCard(stock: s),
          const SizedBox(height: 20),

          // ── Informations ──────────────────────────────────────
          Text(
            l10n.catalogSectionInformation,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // La catégorie, en première ligne et sans condition : elle était
          // dans la barre de titre, sous forme de puce, et c'est elle qui la
          // faisait déborder à 320 points. Elle n'est pas perdue pour autant
          // — elle n'était affichée nulle part ailleurs sur la fiche, et une
          // ligne d'information est sa place : la barre porte des commandes,
          // le corps porte ce que l'article est.
          //
          // Avant le SKU parce qu'un accessoire a toujours une catégorie,
          // jamais forcément une référence.
          _InfoRow(l10n.catalogFieldCategory, accessory.categoryLabel),
          if (accessory.sku != null)
            _InfoRow(l10n.catalogFieldSku, accessory.sku!),
          if (accessory.manufacturer != null)
            _InfoRow(l10n.catalogFieldManufacturer, accessory.manufacturer!),
          // garantie désactivée temporairement
          // if (accessory.warrantyMonths != null)
          //   _InfoRow('Garantie', '${accessory.warrantyMonths} mois'),
          if (accessory.description != null &&
              accessory.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.catalogSectionDescription,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              accessory.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],

          // ── Véhicules compatibles ─────────────────────────────
          //
          // Pour tout le monde : qui achète pour la voiture d'un proche, ou
          // compare avant d'enregistrer son véhicule, a besoin de savoir à
          // quoi l'accessoire se destine. Seul le bouton de modification
          // reste au staff. Voir part_detail_page.dart, même raisonnement.
          CompatibilitesDeclarees(
            lignes: accessory.fitments,
            rienDeclare: l10n.catalogAccessoryNoFitments,
            onModifier: isStaff
                ? () => GoRouter.of(
                    context,
                  ).push('/accessories/${accessory.id}/edit', extra: accessory)
                : null,
          ),

          // ── Partenaires (visible staff uniquement) ────────────
          AccessoryPartnersSection(accessoryId: accessory.id),

          const SizedBox(height: 80),
        ],
      ),

      // ── Bouton commander (clients uniquement) ─────────────────
      bottomNavigationBar: isStaff
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: s.quantity > 0
                      ? () {
                          ref
                              .read(cartProvider.notifier)
                              .add(CartItem.fromAccessory(accessory));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.catalogAddedToCart(accessory.name),
                              ),
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
                    inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                  ),
                  label: Text(
                    s.quantity > 0
                        ? (inCart
                              ? l10n.catalogAddToCartAgain
                              : l10n.catalogAddToCart)
                        // `catalogOfferNone` et non `catalogOutOfStock` : la fiche
                        // d'un accessoire écrit « Indisponible » là où celle d'une
                        // pièce écrit « Rupture de stock ». La divergence est
                        // antérieure à la traduction et ce lot la reporte au lieu de
                        // la corriger — unifier changerait le français de l'un des
                        // deux écrans.
                        : l10n.catalogOfferNone,
                  ),
                ),
              ),
            ),
    );
  }

  IconData _categoryIcon(String category) => switch (category) {
    'esthetique' => Icons.auto_awesome,
    'confort' => Icons.airline_seat_recline_normal,
    'securite' => Icons.shield,
    'multimedia' => Icons.speaker,
    'utilitaire' => Icons.build,
    _ => Icons.tune,
  };
}

// ── Carte prix ─────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final AccessoryPricing pricing;
  const _PriceCard({required this.pricing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
      ),
      // LA SEULE CARTE DE PRIX DU DÉPÔT QUI N'AVAIT PAS SON `BoxFit.scaleDown`,
      // et elle était la seule à casser son montant. Les trois autres sites
      // — la fiche d'une pièce, les deux de la fiche d'un véhicule et
      // `_PrixAjuste` sur la carte du catalogue — portent cet arbitrage depuis
      // la passe de densité ; celui-ci est resté sur un `Text` nu.
      //
      // CE QUE ÇA DONNAIT, mesuré par le banc « Les écrans de la vague 2 » dès
      // que `coupeDansLeMot` est entré dans `aucuneTroncature` : à 320 points
      // d'écran et à l'échelle 2,0, « 18 000 FCFA » réclame 267,4 points pour
      // 256,0 reçus, et le plus long segment insécable retombe à 32,3 — la
      // largeur d'un caractère. Un montant est UN SEUL segment insécable
      // (U+202F entre les milliers, U+00A0 devant la devise), donc le moteur
      // n'a aucune césure légale et coupe caractère par caractère :
      // « 18 000 FCF » puis « A ». L'anglais tombait de même, à 267,4 pour
      // « 18,000 FCFA ».
      //
      // Un nombre coupé est FAUX et non seulement incomplet : c'est le seul
      // défaut que l'échelle 2,0 ne rachète pas — voir `porteUnNombre` dans
      // test/support/mesures.dart. `scaleDown` ne réduit que lorsqu'il faut, et
      // ne change donc rien en deçà : un montant abrégé vaut moins que pas de
      // montant.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          formatXof(pricing.sellingPrice),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

// ── Carte stock ────────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final AccessoryStock stock;
  const _StockCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inStock = stock.quantity > 0;
    final color = inStock ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(inStock ? Icons.check_circle : Icons.cancel, color: color),
          const SizedBox(width: 12),
          // Colonne, et non plus un simple Text : l'emplacement se place
          // dessous. La fiche d'une piece l'affichait deja, celle d'un
          // accessoire ne le montrait nulle part — on le saisissait au
          // formulaire et il disparaissait.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  inStock
                      ? l10n.catalogStockQuantity(stock.quantity)
                      : l10n.catalogOutOfStock,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (stock.location != null)
                  Text(
                    l10n.catalogStockLocation(stock.location!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          // Plus de Spacer : l'Expanded ci-dessus pousse deja la pastille a
          // droite. Les deux se partageraient l'espace libre, et la colonne de
          // texte perdrait la moitie de sa largeur pour rien.
          if (stock.isLow && inStock) ...[
            Chip(
              label: Text(
                l10n.catalogStockLowChip,
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: Colors.orange.shade100,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helper UI ──────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

/// Le repli du bandeau : l'icone de categorie, quand il n'y a aucune photo.
///
/// Il reprend exactement le bloc code en dur auparavant — hauteur, coins
/// arrondis, teinte — pour qu'un accessoire sans photo garde l'allure qu'il
/// avait. Le ClipRRect qui l'entoure vit chez l'appelant : il sert a la
/// galerie, pas au repli, dont les coins sont deja arrondis.
class _AccessoryCover extends StatelessWidget {
  const _AccessoryCover({required this.iconeDeRepli, required this.cs});

  final IconData iconeDeRepli;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(iconeDeRepli, size: 72, color: cs.primary.withAlpha(180)),
  );
}
