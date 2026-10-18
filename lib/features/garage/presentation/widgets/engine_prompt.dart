import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vehicles/data/models/catalog_refs.dart';
import '../../../vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';

/// Réclamer la motorisation manquante, là où le manque se voit.
///
/// La compatibilité d'une pièce se décide côté serveur sur
/// `effective_engine_type_id` ou `effective_engine_code` : sans l'un des deux,
/// aucune pièce ne peut être déclarée compatible, et la liste reste vide sans
/// que rien n'explique pourquoi. Le serveur résume cet état dans
/// `compatibility_ready`, et c'est lui qu'on lit — surtout pas « le menu
/// déroulant était vide » : la motorisation peut venir de la finition sans
/// avoir été saisie.
///
/// Le moment choisi n'est pas l'enregistrement. Quelqu'un qui vient de remplir
/// dix champs a gagné son écran de succès ; l'arrêter avec un reproche qu'il ne
/// peut souvent pas satisfaire — beaucoup ignorent leur motorisation de tête —
/// n'apprend qu'à fermer les boîtes de dialogue sans les lire. Le bandeau, lui,
/// attend sur la carte du véhicule : il se représente quand la personne a le
/// temps, éventuellement sa carte grise sous les yeux, et disparaît de lui-même
/// une fois la réponse donnée.

/// Bandeau affiché sur une carte véhicule tant que la motorisation manque.
///
/// ── LE BOUTON DESCEND QUAND IL NE RESTE PLUS DE PLACE POUR LES MOTS ────────
///
/// Le bandeau a longtemps posé l'icône, les deux phrases et « Compléter » dans
/// une seule rangée. Le bouton n'est pas repliable — « Compléter » est un mot
/// —, donc il gardait sa largeur et l'`Expanded` des phrases encaissait tout
/// le grossissement du texte. Mesuré sur l'accueil, dans sa coque, à 320
/// points d'écran :
///
///   échelle 1,0   l'`Expanded` reçoit 129,75 points
///   échelle 1,3                       112,54
///   échelle 1,5                       101,07   ← « Motorisation » en veut 123,51
///   échelle 2,0                        72,40   ← et 163,69
///
/// Un mot plus large que sa ligne est posé seul et déborde HORIZONTALEMENT :
/// `didExceedMaxLines` reste FAUX, aucune ellipse n'apparaît, et les glyphes
/// passent sous le bouton où le rognage de la carte les mange. C'est la
/// troncature que personne ne voit, et elle touchait QUATRE cases sur douze
/// pour « Motorisation » — 320×1,5 puis les trois largeurs à 2,0, la dernière
/// à 0,29 point près — et DEUX pour « impossible », à 320 et 360 × 2,0.
///
/// LE SEUIL EST MESURÉ, PAS DEVINÉ, et il ne regarde pas l'échelle de texte :
/// il compare ce que les mots réclament, et le nombre de lignes qu'ils posent
/// réellement, à ce que la rangée peut leur laisser. Une borne d'échelle aurait
/// passé outre le réglage d'accessibilité ; un seuil sur l'échelle aurait figé
/// une décision que la largeur d'écran change aussi.
///
/// Empilé, le bloc de texte reçoit 220,0 points à 320, 260,0 à 360 et 311,0 à
/// 411 : le plus large des deux mots en réclame 163,69 au dernier cran
/// d'Android, donc plus rien ne déborde, à aucune des douze cases.
///
/// ── IL Y A DEUX SEUILS, ET LE SECOND EST VENU D'UNE CAPTURE ────────────────
///
/// Le premier répond à « les mots tiennent-ils ? ». Le second à « est-ce
/// lisible ? », et il a été ajouté après coup : la forme côte à côte à 320
/// points et à l'échelle 1,3 ne rognait RIEN — c'était mesuré — mais elle
/// brisait « Motorisation non renseignée » sur TROIS lignes étroites à côté
/// d'une colonne vide sur toute la hauteur. Le propriétaire a tranché sur la
/// capture : la forme empilée y est meilleure à l'œil, et la mesure dit qu'elle
/// est aussi plus COURTE. Quand les deux plans s'accordent il n'y a pas
/// d'arbitrage à rendre. Voir [_lignesTitreCoteACote].
///
/// ── LA FORME DE CHACUNE DES DOUZE CASES, ET CE QU'ELLE A COÛTÉ ─────────────
///
/// Relevé sur l'accueil monté dans sa coque, hauteur du bandeau avant et après
/// ce second seuil :
///
///              forme            hauteur
///   320 x1,0   côte à côte      126,0  (inchangée)
///       x1,3   EMPILÉE          205,0 → 185,0   ← a basculé
///       x1,5   empilée          202,0  (inchangée)
///       x2,0   empilée          310,0  (inchangée)
///   360 x1,0   côte à côte      110,0  (inchangée)
///       x1,3   côte à côte      158,0  (inchangée)
///       x1,5   EMPILÉE          232,0 → 202,0   ← a basculé
///       x2,0   empilée          278,0  (inchangée)
///   411 x1,0   côte à côte       74,0  (inchangée)
///       x1,3   côte à côte      137,0  (inchangée)
///       x1,5   côte à côte      178,0  (inchangée)
///       x2,0   empilée          246,0  (inchangée)
///
/// DEUX CASES BASCULENT, et les deux RACCOURCISSENT — de 20,0 et de 30,0
/// points. Aucune ne grandit. Les dix autres ne bougent pas : le bandeau ne
/// coûte toujours AUCUNE hauteur au réglage par défaut, qui est ce que presque
/// tout le monde voit.
///
/// 360 × 1,5 N'ÉTAIT PAS DEMANDÉE, et c'est le seuil qui l'a trouvée : le titre
/// y recevait 141,07 points et s'y brisait sur trois lignes, exactement le
/// défaut relevé à 320 × 1,3. Un seuil mesuré attrape les cas qui se
/// ressemblent, c'est tout l'intérêt de ne pas nommer les cases une par une.
class MissingEngineBanner extends ConsumerWidget {
  const MissingEngineBanner({super.key, required this.vehicle});

  final OwnedVehicle vehicle;

  /// Les trois chaînes, nommées une fois : la mesure et le rendu doivent
  /// porter sur LES MÊMES. Une copie dans le calcul de seuil et une autre dans
  /// le `Text` divergeraient au premier changement de libellé, et le seuil
  /// deviendrait faux sans que rien ne le dise — c'est exactement le défaut que
  /// `test/support/polices.dart` raconte : une mesure fausse et verte.
  static const String _titre = 'Motorisation non renseignée';
  static const String _phrase =
      'Sans elle, impossible de savoir quelles pièces vont sur ce véhicule.';
  static const String _action = 'Compléter';

  static const double _icone = 18.0;
  static const double _ecartIcone = 10.0;

  /// Le remplissage horizontal d'un `TextButton`, MAJORÉ.
  ///
  /// `TextButton` interpole le sien de 12 points par côté au réglage par
  /// défaut à 4 au-delà de l'échelle 3,0 — voir `_scaledPadding` dans
  /// `text_button.dart`. On réserve donc 24, qui est son maximum, et jamais
  /// moins : surestimer le bouton fait descendre le bandeau un cran trop tôt,
  /// ce qui ne coûte que de la hauteur, là où le sous-estimer rognerait un mot
  /// en silence. C'est le sens dans lequel se tromper.
  static const double _remplissageBouton = 24.0;

  /// La largeur minimale d'un `TextButton` (`minimumSize`), qui domine le
  /// calcul quand le libellé est court.
  static const double _largeurMiniBouton = 64.0;

  /// Le nombre de lignes au-delà duquel le titre ne vaut plus la forme côte à
  /// côte.
  ///
  /// ── CE CHIFFRE EST UN RELEVÉ, PAS UN CHOIX ────────────────────────────────
  ///
  /// C'est le nombre de lignes que la forme côte à côte donne au titre AU
  /// RÉGLAGE PAR DÉFAUT SUR LE PLUS PETIT ÉCRAN — 320 points, échelle 1,0, le
  /// titre reçoit 129,75 points et s'y pose sur deux lignes. C'est la forme que
  /// presque tout le monde voit, et celle que personne n'a reprochée. La règle
  /// est donc : la forme côte à côte est gardée tant qu'elle ne fait pas au
  /// titre PIRE qu'à ce réglage-là.
  ///
  /// POURQUOI UN SEUIL DE PLUS, puisque le premier suffisait à ne rien rogner.
  /// Parce que ne rien rogner n'est pas la même chose qu'être lisible. Relevé
  /// sur `bandeau-motorisation-x13.png`, à 320 points et à l'échelle 1,3 : le
  /// titre reçoit 112,54 points pour 241,71 demandés et se brise sur TROIS
  /// lignes étroites, pendant que la colonne du bouton reste vide sur toute la
  /// hauteur du bandeau. Rien n'est coupé, et pourtant la forme empilée y est
  /// meilleure des DEUX côtés : le titre y tient sur deux lignes, et le bandeau
  /// y est plus COURT. Quand les deux plans s'accordent, il n'y a plus
  /// d'arbitrage à rendre.
  ///
  /// IL NE S'AGIT PAS D'UN SEUIL SUR L'ÉCHELLE DE TEXTE ni sur la largeur
  /// d'écran : on compte les lignes que le `TextPainter` pose réellement à la
  /// largeur réellement disponible. Le seuil suit donc la langue, la longueur du
  /// libellé du bouton et la police, qu'aucun nombre écrit à la main ne suivrait.
  static const int _lignesTitreCoteACote = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (vehicle.compatibilityReady) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        // Le même ambre que les échéances proches : un manque à combler,
        // pas une erreur. Le rouge est réservé à ce qui est déjà dépassé.
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, contraintes) {
          // LES STYLES SONT FUSIONNÉS AVEC CELUI DE L'ARBRE, et ce n'est pas
          // décoratif : un `Text` fusionne toujours son style avec le
          // `DefaultTextStyle` ambiant, dont viennent la FAMILLE DE POLICE et —
          // pour le titre, qui ne nomme pas de corps — la TAILLE. Un
          // `TextPainter` construit sur le style nu mesurerait la police de
          // repli, presque deux fois plus large, et le seuil se déclencherait
          // au mauvais endroit. `ligne_compatibilite.dart` porte le même
          // avertissement, pour le même piège déjà payé.
          final ambiant = DefaultTextStyle.of(context).style;
          final styleTitre = ambiant.merge(
            const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A5A00),
            ),
          );
          final stylePhrase = ambiant.merge(
            Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8A5A00),
            ),
          );
          final styleAction = ambiant.merge(
            Theme.of(context).textTheme.labelLarge,
          );

          final sens = Directionality.of(context);
          final echelle = MediaQuery.textScalerOf(context);

          /// [texte] remis en page à [largeur], ou sans borne quand elle est
          /// omise.
          TextPainter poser(String texte, TextStyle style, [double? largeur]) =>
              TextPainter(
                text: TextSpan(text: texte, style: style),
                textDirection: sens,
                textScaler: echelle,
              )..layout(maxWidth: largeur ?? double.infinity);

          /// Le plus long segment INSÉCABLE de [texte], remis en page sans
          /// borne.
          ///
          /// Sans borne, et c'est le point : borné à la largeur reçue, le
          /// moteur finit par couper DANS le mot, et `minIntrinsicWidth`
          /// retombe alors à la largeur d'un caractère — le prix d'une carte de
          /// pièce en rend 17,74 dans ce cas, et le banc qui s'y fiait passait
          /// au vert sur un prix cassé en deux.
          double motLePlusLarge(String texte, TextStyle style) =>
              poser(texte, style).minIntrinsicWidth;

          final besoinTexte = [
            motLePlusLarge(_titre, styleTitre),
            motLePlusLarge(_phrase, stylePhrase),
          ].reduce((a, b) => a > b ? a : b);

          final libelle = motLePlusLarge(_action, styleAction);
          final besoinBouton =
              libelle + _remplissageBouton > _largeurMiniBouton
              ? libelle + _remplissageBouton
              : _largeurMiniBouton;

          final dispo = contraintes.maxWidth - _icone - _ecartIcone;
          final resteAuTexte = dispo - besoinBouton;

          // LES DEUX CONDITIONS NE DISENT PAS LA MÊME CHOSE, et l'ordre compte.
          //
          // La PREMIÈRE est la non négociable : aucun mot ne doit être plus
          // large que la ligne qu'on lui laisse, sans quoi il est rogné sans
          // ellipse et en silence. C'est elle qui corrigeait le défaut mesuré à
          // 320 × 1,5.
          //
          // La SECONDE est la lisibilité : même sans rien rogner, un titre
          // brisé sur trois lignes étroites à côté d'une colonne vide se lit
          // plus mal qu'un titre empilé sur deux. Voir [_lignesTitreCoteACote],
          // qui porte le relevé.
          //
          // L'ÉVALUATION PARESSEUSE DU `&&` N'EST PAS UNE COMMODITÉ : quand le
          // bouton est plus large que la place, `resteAuTexte` devient NÉGATIF,
          // et `TextPainter.layout` sur une largeur négative lève. La première
          // condition est fausse dans ce cas — `besoinTexte` est positif — donc
          // la seconde n'est jamais évaluée.
          final coteACote =
              besoinTexte <= resteAuTexte &&
              poser(_titre, styleTitre, resteAuTexte)
                      .computeLineMetrics()
                      .length <=
                  _lignesTitreCoteACote;

          // `MainAxisSize.min`, ET C'EST UNE CORRECTION VUE SUR UNE CAPTURE.
          // Un `Column` prend TOUTE la hauteur disponible par défaut. Les deux
          // emplacements de production — la carte de l'accueil et la fiche du
          // garage — bornent la hauteur du bandeau, si bien que le défaut n'y
          // paraissait pas : 126,0 points mesurés à 320 × 1,0, c'est-à-dire la
          // hauteur du contenu. Posé dans un parent qui NE la borne pas, le
          // même bandeau s'étirait sur les 600 points de l'écran, un aplat
          // ambre et trois lignes en haut. La capture l'a montré du premier
          // coup, et aucun chiffre ne l'avait dit.
          final textes = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_titre, style: styleTitre),
              const SizedBox(height: 2),
              Text(_phrase, style: stylePhrase),
            ],
          );

          final bouton = TextButton(
            onPressed: () => showEngineTypeDialog(context, ref, vehicle),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
            child: const Text(_action),
          );

          if (coteACote) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_gas_station_outlined,
                  size: _icone,
                  color: Color(0xFF8A5A00),
                ),
                const SizedBox(width: _ecartIcone),
                Expanded(child: textes),
                bouton,
              ],
            );
          }

          // EMPILÉ, le bouton reste du côté de la fin de ligne : c'est là que
          // Material pose les actions d'un bandeau, et le déplacer au début
          // ferait lire l'action avant le manque qu'elle répare.
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.local_gas_station_outlined,
                    size: _icone,
                    color: Color(0xFF8A5A00),
                  ),
                  const SizedBox(width: _ecartIcone),
                  Expanded(child: textes),
                ],
              ),
              Align(alignment: AlignmentDirectional.centerEnd, child: bouton),
            ],
          );
        },
      ),
    );
  }
}

/// Demande la seule information manquante, et rien d'autre.
///
/// Un formulaire d'édition complet obligerait à relire dix champs corrects pour
/// en corriger un. Le geste reste celui du kilométrage : une question, une
/// réponse, la liste se rafraîchit.
Future<void> showEngineTypeDialog(
  BuildContext context,
  WidgetRef ref,
  OwnedVehicle vehicle,
) async {
  final refs = await ref.read(catalogRefsProvider.future).then<CatalogRefs?>(
        (r) => r,
        onError: (_, __) => null,
      );

  if (!context.mounted) return;

  if (refs == null || refs.engineTypes.isEmpty) {
    _dire(context, 'Liste des motorisations indisponible. Réessayez plus tard.',
        erreur: true);
    return;
  }

  final choix = await showDialog<EngineTypeRef>(
    context: context,
    builder: (ctx) => _EngineTypeDialog(
      vehicle: vehicle,
      engineTypes: refs.engineTypes,
    ),
  );

  if (choix == null || !context.mounted) return;

  final erreur = await ref
      .read(garageProvider.notifier)
      .updateVehicle(vehicle.id, {'engine_type_id': choix.id});

  if (!context.mounted) return;

  _dire(
    context,
    erreur ?? 'Motorisation enregistrée : les pièces compatibles sont à jour.',
    erreur: erreur != null,
  );
}

void _dire(BuildContext context, String message, {required bool erreur}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor:
          erreur ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

class _EngineTypeDialog extends StatefulWidget {
  const _EngineTypeDialog({required this.vehicle, required this.engineTypes});

  final OwnedVehicle vehicle;
  final List<EngineTypeRef> engineTypes;

  @override
  State<_EngineTypeDialog> createState() => _EngineTypeDialogState();
}

class _EngineTypeDialogState extends State<_EngineTypeDialog> {
  EngineTypeRef? _choix;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Motorisation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.vehicle.identity.fullName} · ${widget.vehicle.year}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          // Une question qu'on peut se poser sans document sous les yeux :
          // « je fais le plein de quoi ? ». La formuler en jargon reviendrait
          // à demander d'aller chercher la carte grise.
          const Text('Avec quel carburant roule ce véhicule ?'),
          const SizedBox(height: 12),
          DropdownButtonFormField<EngineTypeRef>(
            value: _choix,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text('Sélectionner…'),
            items: widget.engineTypes
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (e) => setState(() => _choix = e),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          // Tant que rien n'est choisi, enregistrer n'aurait rien à écrire.
          onPressed: _choix == null ? null : () => Navigator.pop(context, _choix),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
