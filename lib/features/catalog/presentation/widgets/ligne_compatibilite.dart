import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/compatibility_summary.dart';

/// Les modèles compatibles, sur une carte du catalogue : deux lignes, le reste
/// compté à côté.
///
/// ── CE QUE LE PROPRIÉTAIRE A DEMANDÉ ───────────────────────────────────────
///
/// Savoir à quoi une pièce ou un accessoire se destine SANS ouvrir la fiche.
/// Deux lignes au plus, la suite tronquée, police très petite, couleur sobre :
///
///   Corolla · Tucson · Rio  +9
///
/// LE MODÈLE SEUL, SANS LA MARQUE, et c'est une décision du propriétaire prise
/// sur la première mesure. La ligne a porté « Toyota Corolla · Hyundai Tucson
/// · Kia Rio » : les trois noms ne tenaient alors que dans 3 cases sur 12, et
/// la carte annonçait surtout un « +N ». Le serveur compose désormais
/// `vehicleModel?->name` seul, et les trois tiennent dans 10 cases sur 12. Le
/// risque assumé est écrit côté serveur, dans `PartResource` : deux marques
/// pourraient nommer un modèle pareillement, et la déduplication les
/// confondrait — le référentiel actuel n'a pas ce cas.
///
/// ── LE COMPTE EST UN ÉLÉMENT SÉPARÉ, ET C'EST LA DÉCISION CENTRALE ─────────
///
/// « +9 » n'est PAS collé au bout du texte tronqué. S'il l'était, la troncature
/// le mangerait en PREMIER — l'ellipse tombe à la fin de la dernière ligne,
/// c'est-à-dire exactement là où serait le compte —, et il disparaîtrait
/// précisément dans le cas où il est le plus utile : celui où les noms ne
/// tiennent pas. Il est donc le second enfant d'un `Row` dont le premier est
/// l'`Expanded` des noms : les noms se coupent, le compte reste.
///
/// ── ET IL EST CALCULÉ SUR CE QUI EST PEINT, PAS SUR CE QUI EST REÇU ────────
///
/// Le serveur plafonne `vehicles` à TROIS noms pour le poids de la réponse,
/// mais `count` est le total réel. Un « +N » calculé sur `count - 3` serait
/// donc FAUX dès que la carte n'affiche pas les trois. Mesuré par
/// `bandes_filtres_test.dart`, sur « Corolla · Tucson · Rio » :
///
///   320 pt d'écran   x1,0 → 3 noms   x1,3 → 3   x1,5 → 3   x2,0 → 2
///   360 pt           x1,0 → 3        x1,3 → 3   x1,5 → 3   x2,0 → 2
///   411 pt           x1,0 → 3        x1,3 → 3   x1,5 → 3   x2,0 → 3
///
/// Soit DEUX cases sur douze où le compte doit retrancher deux noms et non
/// trois. C'est moins qu'avant le passage au modèle seul — neuf cases sur
/// douze, dont quatre à deux noms d'écart —, et ce n'est pas une raison de
/// retirer le mécanisme : un écart d'une unité que personne ne vérifie est
/// exactement ce que ce dépôt passe ses semaines à corriger, et il ne tient
/// ici qu'à la longueur de trois chaînes que le référentiel du serveur peut
/// changer sans prévenir.
///
/// D'où le `LayoutBuilder` et la boucle `combienTiennent` : on remet le texte
/// en page soi-même, du plus long au plus court, et on retient le premier
/// préfixe qui ne déborde pas de deux lignes. Le compte se déduit de CE
/// nombre-là. `Text` garde quand même son `maxLines: 2` et son ellipse : si la
/// mesure se trompait, l'écran ellipserait au lieu de déborder.
///
/// Le plancher de la boucle est UN nom. Un seul nom trop long s'ellipse alors,
/// et c'est admis : un nom de modèle est une valeur du référentiel du serveur,
/// dont personne ici ne contrôle la longueur — « Grand Cherokee Trackhawk »
/// est le plus long qu'il porte. Afficher zéro nom et un compte nu
/// n'apprendrait rien.
///
/// ── POURQUOI LE `LayoutBuilder` NE COÛTE RIEN ICI ──────────────────────────
///
/// `vehicle_list_page.dart` raconte ce qu'un `LayoutBuilder` a coûté sur la
/// carte des véhicules : `_RenderLayoutBuilder` ne sait répondre à aucune
/// question de taille intrinsèque, ce qui a interdit `IntrinsicHeight` sur la
/// grille. Les deux colonnes des cartes de pièces et d'accessoires sont deux
/// `Column` dans les deux `Expanded` d'un `Row` en `CrossAxisAlignment.start` :
/// personne n'y demande de hauteur intrinsèque, et la contrainte de largeur
/// descend sans détour. Vérifié par les bancs de géométrie, qui montent la page
/// entière.
class LigneCompatibilite extends StatelessWidget {
  const LigneCompatibilite({super.key, required this.resume});

  /// `null` quand la réponse ne porte pas la clé — voir `Part.compatibility`.
  /// La ligne disparaît alors, comme pour un article sans compatibilité.
  final CompatibilitySummary? resume;

  /// Deux lignes, et c'est la demande du propriétaire. Trois mangeraient la
  /// hauteur que la carte rend au nom de l'article.
  static const int _lignes = 2;

  /// 10,0 points : un cran SOUS le `labelSmall` du nom de l'article, lui-même
  /// un cran sous le `bodySmall` que la carte employait avant — le commentaire
  /// du nom, dans `part_list_page.dart`, raconte cette descente. La ligne doit
  /// se lire comme une mention et non comme un second titre.
  static const double _corps = 10.0;

  /// Interligne serré : deux lignes de mention ne doivent pas coûter la
  /// hauteur de deux lignes de contenu. 10,0 × 1,2 fait 12,0 points par ligne,
  /// plus les 3,0 de [_ecartAvantLaLigne] : la carte grandit de 15,0 points
  /// quand la mention tient sur une ligne et de 27,0 quand il lui en faut
  /// deux. Au réglage par défaut, et depuis que le serveur n'envoie que le
  /// modèle, c'est UNE ligne aux trois largeurs — donc 15,0.
  static const double _interligne = 1.2;

  /// L'écart entre les noms et le compte. Quatre points, soit l'équivalent
  /// visuel des deux espaces de la maquette, sans dépendre de la chasse d'une
  /// espace qui change avec l'échelle de texte.
  static const double _ecartAvantCompte = 4.0;

  /// L'écart qui détache la ligne du nom de l'article, PORTÉ PAR CE WIDGET.
  ///
  /// Il est ici et non dans la carte pour une raison de tenue : un
  /// `SizedBox(height: 3)` écrit dans la carte resterait là quand la ligne
  /// disparaît, et un article sans compatibilité porterait trois points de
  /// vide que personne n'aurait demandés. C'est la même famille de défaut que
  /// le séparateur orphelin.
  static const double _ecartAvantLaLigne = 3.0;

  @override
  Widget build(BuildContext context) {
    final r = resume;

    // UN ARTICLE SANS COMPATIBILITÉ N'AFFICHE RIEN : ni ligne vide, ni
    // séparateur orphelin, ni « +0 ». `estVide` tient les deux cas — aucun nom,
    // ou un compte nul — parce que les deux arrivent : le serveur rend
    // `{count: 0, vehicles: []}` pour une pièce sans fitment, et c'est la
    // fixture `parts_list.json` du dépôt.
    if (r == null || r.estVide) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final sens = Directionality.of(context);
    final echelle = MediaQuery.textScalerOf(context);

    // `outline`, le gris d'habillage. C'est l'inverse du choix fait pour le NOM
    // de l'article juste au-dessus, qui est passé de `outline` à `onSurface`
    // parce qu'il est le contenu principal : ici la mention secondaire est
    // exactement ce qu'on veut.
    //
    // LE STYLE EST FUSIONNÉ AVEC CELUI DE L'ARBRE, ET CE N'EST PAS DÉCORATIF.
    // Un `Text` fusionne toujours son `style` avec le `DefaultTextStyle`
    // ambiant, dont vient la FAMILLE DE POLICE — ces trois propriétés-ci n'en
    // portent aucune. Le `TextPainter` de [combienTiennent], lui, ne fusionne
    // rien : construit sur le style nu, il mesurait la police de REPLI, bien
    // plus large que Roboto.
    //
    // CE QUE ÇA DONNAIT À L'ÉCRAN, mesuré avant la correction : la carte
    // n'affichait qu'UN nom et annonçait « +11 » dans les quarante-huit cases
    // du banc, y compris à 411 points de large au réglage par défaut, où les
    // trois tiennent largement — « Corolla » y demande 33,24 points à Roboto
    // pour 158,80 reçus sur deux lignes. Exactement le défaut que
    // `test/support/polices.dart` raconte pour les bancs, mais dans le code de
    // production : une mesure fausse, et rien pour s'en plaindre.
    final style = DefaultTextStyle.of(context).style.merge(
      TextStyle(fontSize: _corps, height: _interligne, color: cs.outline),
    );

    final separateur = l10n.catalogCompatibilitySeparator;

    double largeurDe(String texte) => (TextPainter(
      text: TextSpan(text: texte, style: style),
      textDirection: sens,
      textScaler: echelle,
      maxLines: 1,
    )..layout()).width;

    /// Combien des noms REÇUS tiennent dans [dispo] sur [_lignes] lignes.
    ///
    /// Du plus long au plus court, et jamais moins d'un : un nom seul plus
    /// large que sa case s'ellipse — c'est une valeur du référentiel du
    /// serveur, dont personne ici ne contrôle la longueur —, mais afficher zéro
    /// nom et un compte nu n'apprendrait rien.
    int combienTiennent(double dispo) {
      for (var n = r.vehicles.length; n > 1; n--) {
        final tp = TextPainter(
          text: TextSpan(
            text: r.vehicles.take(n).join(separateur),
            style: style,
          ),
          textDirection: sens,
          textScaler: echelle,
          maxLines: _lignes,
          // La MÊME ellipse que le `Text` ci-dessous : sans elle, le
          // `TextPainter` mesurerait une mise en page que l'écran ne produit
          // pas, et `didExceedMaxLines` ne répondrait pas à la même question.
          ellipsis: '…',
        )..layout(maxWidth: dispo);
        if (!tp.didExceedMaxLines) return n;
      }
      return 1;
    }

    return LayoutBuilder(
      builder: (context, contraintes) {
        // LA PLACE DU COMPTE EST RÉSERVÉE SUR SON PIRE CAS, et il faut dire
        // pourquoi : la largeur du compte dépend de sa valeur, sa valeur dépend
        // du nombre de noms peints, et le nombre de noms peints dépend de la
        // place qui reste. C'est circulaire. On tranche par le haut — le plus
        // grand compte possible est `count - 1`, celui d'un seul nom peint, et
        // c'est aussi le plus large en chiffres. Réserver pour lui donne aux
        // noms un peu moins de place qu'ils n'en auront, jamais plus : l'erreur
        // ne peut pas produire de troncature surprise.
        final resteMax = r.count - 1;
        final reserve = resteMax >= 1
            ? largeurDe(l10n.catalogCompatibilityMore(resteMax)) +
                  _ecartAvantCompte
            : 0.0;

        final peints = combienTiennent(contraintes.maxWidth - reserve);
        final reste = r.count - peints;

        return Padding(
          padding: const EdgeInsets.only(top: _ecartAvantLaLigne),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  r.vehicles.take(peints).join(separateur),
                  maxLines: _lignes,
                  // Le filet. La boucle ci-dessus garantit que ce texte tient ;
                  // l'ellipse est là pour le jour où elle se tromperait, parce
                  // qu'un texte ellipsé reste lisible quand un texte débordant
                  // se fait rogner par le `clipBehavior` de la `Card` SANS
                  // ellipse — c'est la troncature invisible qui a coûté une
                  // journée entière à ce dépôt.
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              if (reste > 0)
                Padding(
                  padding: const EdgeInsets.only(left: _ecartAvantCompte),
                  child: Text(
                    l10n.catalogCompatibilityMore(reste),
                    // Même corps et même encre que les noms : la seule
                    // distinction est la graisse. Une seconde couleur sur une
                    // ligne de mention de 10 points ferait du bruit pour une
                    // information qui tient en deux caractères.
                    style: style.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
