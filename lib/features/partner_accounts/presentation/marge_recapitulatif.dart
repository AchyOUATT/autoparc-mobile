import 'package:flutter/material.dart';

/// Ce que le vendeur touchera, ce que la boutique ajoute, et ce que l'acheteur
/// verra.
///
/// ── POURQUOI LES TROIS NOMBRES, ET PAS SEULEMENT LE TOTAL ─────────────────
///
/// Le prix enregistré en base est le prix PUBLIC, marge comprise : c'est lui
/// que le catalogue trie et filtre, et lui que l'acheteur voit. Si le
/// formulaire n'affichait que ce nombre, le vendeur croirait avoir proposé
/// 4 950 000 alors qu'il a tapé 4 500 000 — et il ajusterait son prix à la
/// baisse pour « corriger », en se trompant à chaque fois.
///
/// Les trois nombres lèvent l'ambiguïté d'un coup d'œil, et le taux est dit
/// explicitement parce qu'un écart qu'on ne nomme pas passe pour une erreur.
///
/// ── RIEN NE S'AFFICHE À 0 % ───────────────────────────────────────────────
///
/// Pas de ligne « marge 0 % », qui attirerait l'attention sur un réglage que
/// personne n'a armé. Et rien non plus quand le taux est inconnu — session
/// enregistrée avant cette version, ou serveur pas encore déployé : mieux vaut
/// se taire qu'annoncer un total qu'on ne sait pas calculer.
class MargeRecapitulatif extends StatelessWidget {
  const MargeRecapitulatif({
    super.key,
    required this.prixPropose,
    required this.pourcentage,
    this.libelle = 'Prix affiché à l’acheteur',
  });

  /// Le prix que le vendeur vient de taper, ou null tant qu'il n'a rien tapé.
  final num? prixPropose;

  /// Le taux du jour. Zéro ou négatif : rien ne s'affiche.
  final double pourcentage;

  /// Ce que le total représente, pour distinguer une vente d'une location.
  final String libelle;

  /// Le total, arrondi comme le serveur l'arrondit.
  ///
  /// Le même calcul des deux côtés, sans quoi l'écran annoncerait un franc de
  /// plus ou de moins que ce qui sera enregistré — et c'est exactement le
  /// genre d'écart qu'un vendeur relève.
  static num total(num prixPropose, double pourcentage) =>
      (prixPropose * (1 + pourcentage / 100)).round();

  static String _fmt(num valeur) {
    final chiffres = valeur.round().toString();
    final tampon = StringBuffer();

    for (var i = 0; i < chiffres.length; i++) {
      if (i > 0 && (chiffres.length - i) % 3 == 0) tampon.write(' ');
      tampon.write(chiffres[i]);
    }

    return tampon.toString();
  }

  /// Le taux sans décimale inutile : « 10 % » et non « 10.0 % ».
  static String _taux(double pourcentage) =>
      pourcentage == pourcentage.roundToDouble()
          ? '${pourcentage.round()}'
          : pourcentage.toString();

  @override
  Widget build(BuildContext context) {
    final prix = prixPropose;
    if (pourcentage <= 0 || prix == null || prix <= 0) {
      return const SizedBox.shrink();
    }

    final couleurs = Theme.of(context).colorScheme;
    final textes = Theme.of(context).textTheme;

    return Container(
      key: const Key('marge-recapitulatif'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleurs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ligne(context, 'Votre prix', '${_fmt(prix)} FCFA'),
          const SizedBox(height: 4),
          _ligne(
            context,
            'Marge boutique (${_taux(pourcentage)} %)',
            '+ ${_fmt(total(prix, pourcentage) - prix)} FCFA',
          ),
          const Divider(height: 14),
          _ligne(
            context,
            libelle,
            '${_fmt(total(prix, pourcentage))} FCFA',
            gras: true,
          ),
          const SizedBox(height: 6),
          Text(
            'Ce total est figé au moment où vous enregistrez.',
            style: textes.bodySmall?.copyWith(color: couleurs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Une ligne libellé / montant, qui passe à la ligne plutôt que de déborder.
  ///
  /// `Wrap` et non `Row` : à 320 points et au texte agrandi, « Marge boutique
  /// (7.5 %) » et le montant ne tiennent plus côte à côte, et un `Row` déborde
  /// au lieu de se replier.
  Widget _ligne(BuildContext context, String libelle, String montant,
      {bool gras = false}) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: gras ? FontWeight.w700 : FontWeight.w400,
        );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 2,
      children: [
        Text(libelle, style: style),
        Text(montant, style: style),
      ],
    );
  }
}
