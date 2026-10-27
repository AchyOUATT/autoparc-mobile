import 'package:flutter/material.dart';

import '../../../core/utils/currency_format.dart';
import '../data/models/promotion.dart';

/// Ce qui signale une promotion : la remise, et le prix qu'elle remplace.
///
/// ── POURQUOI DEUX WIDGETS ET NON UN ───────────────────────────────────────
///
/// Une carte de liste n'a pas la place d'une fiche. La pastille seule suffit à
/// faire remarquer l'offre dans une grille ; le prix barré n'a de sens que là
/// où il y a de la place pour le lire sans rogner le prix réel.
///
/// Les deux refusent de s'afficher sur une promotion `finie` : une page ouverte
/// traverse minuit, et mieux vaut cesser d'annoncer une remise que la laisser
/// vieillir à l'écran. Le serveur, lui, a déjà cessé de l'envoyer.

/// « -20 % », assez petit pour tenir dans une carte.
class PastillePromotion extends StatelessWidget {
  const PastillePromotion({super.key, required this.promotion});

  final Promotion? promotion;

  @override
  Widget build(BuildContext context) {
    final promo = promotion;
    if (promo == null || promo.finie || promo.discountPercent <= 0) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    return Container(
      key: const Key('promotion-pastille'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '-${formaterPourcentage(promo.discountPercent)} %',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
        maxLines: 1,
      ),
    );
  }
}

/// Le prix habituel, barré, à côté du prix du jour.
///
/// ── POURQUOI IL N'AFFICHE PAS LUI-MÊME LE PRIX DU JOUR ────────────────────
///
/// Parce que celui-ci est déjà rendu, partout, par le champ de prix habituel :
/// sur une fiche publique, `commercial.sale_price` et `pricing.selling_price`
/// portent le prix promotionnel. Le redessiner ici ferait deux sources pour un
/// même nombre, et elles divergeraient le jour où l'une changerait.
///
/// Ce widget ajoute ce qui MANQUE : ce que le prix remplace.
class PrixNormalBarre extends StatelessWidget {
  const PrixNormalBarre({super.key, required this.promotion, this.style});

  final Promotion? promotion;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final promo = promotion;
    if (promo == null || promo.finie) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Text(
      formatXofShort(promo.normalPrice),
      key: const Key('promotion-prix-barre'),
      style: (style ?? Theme.of(context).textTheme.bodySmall)?.copyWith(
        decoration: TextDecoration.lineThrough,
        color: cs.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// « 40 » et non « 40.0 » ; « 7.5 » quand la virgule compte.
///
/// Le serveur arrondit déjà au dixième : on ne recalcule rien, on met en forme.
String formaterPourcentage(double valeur) =>
    valeur == valeur.roundToDouble() ? '${valeur.round()}' : '$valeur';
