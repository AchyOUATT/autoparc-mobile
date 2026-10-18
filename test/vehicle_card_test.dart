import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/echelles.dart';

/// Tenue des fiches du catalogue, à la largeur près.
///
/// CE FICHIER A CHANGÉ DE PRÉMISSE AVEC CE LOT, et il faut le dire en face. Il
/// était écrit pour une grille qui IMPOSAIT la hauteur des cartes —
/// `childAspectRatio: 0.82` — et chacun de ses tests posait la carte dans une
/// case de hauteur fixe pour vérifier qu'elle n'en débordait pas. C'est ce
/// budget vertical qui coupait le titre dans les douze configurations mesurées,
/// et il a été supprimé : les rangées ont désormais une hauteur INTRINSÈQUE.
///
/// Une case de hauteur fixe n'existe donc plus nulle part, et continuer à y
/// poser la carte mesurerait une grille qui n'existe pas — c'est exactement le
/// défaut de méthode que ce dépôt a payé trois fois. Ce qui reste contraint est
/// la LARGEUR, et elle seule : ces tests posent la carte à la largeur que la
/// rangée lui donne et laissent la hauteur libre.
///
/// CE GROUPE NE MESURE QUE LA COMPOSITION, pas ce qui est peint. `find.text`
/// lit le champ `data` du `Text` : le texte VOULU. Un texte ellipsé le passe
/// sans broncher, et c'est ainsi que la ligne à trois valeurs a été déclarée
/// affichée alors qu'elle était tronquée sur toutes les cartes du catalogue. La
/// géométrie réelle — largeur voulue contre largeur reçue, segment insécable,
/// état de dépassement du `TextPainter`, avec la vraie police, sur la page
/// montée dans sa coque — est mesurée dans `carte_geometrie_test.dart`. Les deux
/// sont nécessaires : celui-ci dit ce que la carte VEUT dire, l'autre dit ce
/// qu'elle MONTRE.
void main() {
  final page = PaginatedResponse.fromJson(
    jsonDecode(File('test/fixtures/vehicles_list.json').readAsStringSync())
        as Map<String, dynamic>,
    Vehicle.fromJson,
  );

  /// Les largeurs de carte que la rangée produit réellement.
  ///
  /// Arithmétique de la rangée, pas une estimation : la grille vit dans un
  /// `SliverPadding.all(12)`, deux cartes séparées de 10 points y mesurent donc
  /// `(écran − 34) / 2`. À 320 points d'écran — le plus petit du parc — cela
  /// fait 143,0 ; à 360, 163,0 ; à 411, l'émulateur de référence, 188,5.
  const largeurs = <String, double>{
    '320 pt': 143.0,
    '360 pt': 163.0,
    '411 pt': 188.5,
  };

  /// La plus serrée des trois, et donc celle des tests qui n'en éprouvent qu'une.
  const largeur = 143.0;

  Widget carte(
    Vehicle vehicule, {
    double echelleTexte = 1.0,
    double? boite,
  }) =>
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(echelleTexte)),
            child: Scaffold(
              // `SingleChildScrollView` ET NON `Center` SEUL : il donne à la carte
              // une hauteur ILLIMITÉE, comme le `SliverList` de la vraie
              // rangée. Sans lui, la carte dépasse les 600 points de la surface
              // du banc à l'échelle 2,0 sous la police à glyphes carrés, et le
              // banc signalerait un débordement que la liste ne produit pas.
              body: SingleChildScrollView(
                child: Center(
                  // LARGEUR SEULE, hauteur libre. Un `SizedBox` à hauteur fixe
                  // ferait déborder une carte qui, dans la vraie rangée, se
                  // contente de grandir — et le banc signalerait un défaut qui
                  // n'existe plus.
                  child: SizedBox(
                    width: boite ?? largeur,
                    child: VehicleCard(vehicle: vehicule),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  group('Fiche de la grille', () {
    testWidgets('aucune fiche du catalogue ne déborde, aux trois largeurs',
        (tester) async {
      // LA BOUCLE A CHANGÉ D'AXE : elle parcourait deux HAUTEURS de case —
      // l'ancien ratio 0,92 et le ratio 0,82 du jour — parce que c'était la
      // hauteur qui débordait. Elle parcourt maintenant les trois LARGEURS que
      // la rangée produit, parce que c'est la seule dimension que la rangée
      // impose encore.
      for (final entree in largeurs.entries) {
        for (final vehicule in page.data) {
          await tester.pumpWidget(carte(vehicule, boite: entree.value));
          await tester.pump();

          expect(tester.takeException(), isNull,
              reason: 'La fiche ${vehicule.reference} déborde à '
                  '${entree.key} d\'écran.');
        }
      }
    });

    testWidgets('elle tient aussi quand le texte du téléphone est agrandi',
        (tester) async {
      // Les quatre crans d'Android, et non le seul 1,3 : c'est à 2,0 que le
      // titre se replie sur six lignes, et une borne de repli trop basse y
      // ellipserait au lieu de grandir.
      //
      // ET 2,0 RESTE ASSERTÉE ICI, bien que la règle de `support/echelles.dart`
      // autorise à la relâcher : ce test ne mesure aucune troncature, il vérifie
      // que RIEN NE JETTE. C'est le deuxième des quatre points non négociables,
      // et il ne connaît pas de frontière — une bande rayée de `RenderFlex`
      // rend le contenu illisible et parfois intouchable, à 2,0 comme à 1,0.
      for (final echelle in echellesMesurees) {
        await tester.pumpWidget(
            carte(page.data.first, echelleTexte: echelle));
        await tester.pump();

        expect(tester.takeException(), isNull,
            reason: 'La fiche déborde à l\'échelle de texte $echelle.');
      }
    });
  });

  // ── La ligne de caractéristiques ───────────────────────────────────────

  /// Le gabarit du catalogue, remoulé champ par champ.
  ///
  /// Les cas à éprouver ne sont pas dans le jeu de données — il ne contient
  /// qu'un véhicule —, et ils ne sont pas rares : un véhicule neuf n'a pas de
  /// kilométrage relevé, un véhicule dont la motorisation n'a pas été saisie
  /// n'a pas de carburant. C'est là que les séparateurs orphelins se voient.
  final gabarit = (jsonDecode(
    File('test/fixtures/vehicles_list.json').readAsStringSync(),
  ) as Map<String, dynamic>)['data'][0] as Map<String, dynamic>;

  Vehicle vehicule({
    int? kilometrage = 95000,
    String? boite = 'automatic',
    String? motorisation = 'Essence',
    String? affaire = 'Bonne affaire',
    int photos = 3,
    String nomModele = 'Tucson',
  }) {
    final json = jsonDecode(jsonEncode(gabarit)) as Map<String, dynamic>;
    final technique = json['technical'] as Map<String, dynamic>;
    final identite  = json['identity'] as Map<String, dynamic>;
    final commerce  = json['commercial'] as Map<String, dynamic>;

    technique['mileage_km']   = kilometrage;
    technique['transmission'] = boite;
    identite['engine_type']   = motorisation;
    identite['model']         = nomModele;
    commerce['deal_label']    = affaire;
    commerce['deal_type']     = affaire == null ? null : 'good_deal';
    // `<dynamic>` et non le type déduit : `Vehicle.fromJson` lit la liste
    // telle que `jsonDecode` la rend, et son `firstWhere` refuse une liste
    // plus étroitement typée.
    json['media'] = <dynamic>[
      for (var i = 0; i < photos; i++)
        <String, dynamic>{
          'id': i,
          'url': 'https://media.autoparc.test/vehicles/1/$i.jpg',
          'collection': 'gallery',
          'is_cover': i == 0,
        },
    ];
    return Vehicle.fromJson(json);
  }

  /// Le séparateur de milliers de `NumberFormat.decimalPattern('fr_FR')` est
  /// une espace fine insécable, pas une espace ordinaire. L'écrire en clair
  /// ici plutôt que de le recalculer : un test qui reformate avec l'outil
  /// qu'il mesure passerait aussi le jour où l'outil changerait de locale.
  const km = '95 000 km';

  /// CE GROUPE NE MESURE QUE LA COMPOSITION DE LA CHAÎNE, et non ce qui est
  /// peint. `find.text` lit le champ `data` du `Text` : le texte VOULU. Un
  /// texte ellipsé le passe sans broncher, et c'est ainsi que la ligne à trois
  /// valeurs a été déclarée affichée alors qu'elle était tronquée sur toutes
  /// les cartes du catalogue. La géométrie réelle — largeur voulue contre
  /// largeur disponible, état de dépassement du `TextPainter`, avec la vraie
  /// police — est mesurée dans `carte_geometrie_test.dart`. Les deux sont
  /// nécessaires : celui-ci dit ce que la carte VEUT dire, l'autre dit ce
  /// qu'elle MONTRE.
  group('Ligne de caractéristiques', () {
    testWidgets('deux valeurs, et la boîte de vitesses n\'en est plus',
        (tester) async {
      // La boîte coûtait sept signes même abrégée en « Auto », et ces sept
      // signes poussaient le carburant hors de l'ellipse. Elle reste sur la
      // fiche de détail, où `_libelleTransmission` l'écrit en entier.
      await tester.pumpWidget(carte(vehicule()));
      await tester.pump();

      expect(find.text('$km • Essence'), findsOneWidget);
      expect(find.textContaining('Auto'), findsNothing);
    });

    testWidgets('une valeur absente disparaît avec son séparateur',
        (tester) async {
      // Un véhicule neuf : aucun kilométrage relevé.
      await tester.pumpWidget(carte(vehicule(kilometrage: null)));
      await tester.pump();

      expect(find.text('Essence'), findsOneWidget);
      expect(find.textContaining('• •'), findsNothing);
    });

    testWidgets('la valeur restante reste seule, sans séparateur orphelin',
        (tester) async {
      // La boîte est passée à `null` par acquit de conscience : elle n'est plus
      // lue par la ligne, et ce test échouerait si elle y revenait.
      await tester.pumpWidget(
        carte(vehicule(boite: null, motorisation: null)),
      );
      await tester.pump();

      expect(find.text(km), findsOneWidget);
      expect(find.textContaining('•'), findsNothing);
    });

    testWidgets('toutes absentes : pas de ligne, pas de tiret, pas de null',
        (tester) async {
      await tester.pumpWidget(
        carte(vehicule(kilometrage: null, boite: null, motorisation: null)),
      );
      await tester.pump();

      expect(find.textContaining('•'),    findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(find.textContaining('km'),   findsNothing);
      expect(find.text('—'),              findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('une ligne trop longue SE REPLIE, et s\'ellipse seulement en '
        'dernier recours', (tester) async {
      // CE TEST A CHANGÉ DE RÈGLE, et c'est la règle du lot. Il vérifiait
      // `maxLines: 1` et appelait l'ellipse une réussite ; l'ellipse était
      // justement le défaut — une ligne de caractéristiques coupée perd le
      // carburant, qui est sa dernière valeur. La carte se replie maintenant, et
      // l'ellipse n'est plus que la borne contre un libellé aberrant venu du
      // serveur.
      //
      // 1 234 567 km et une motorisation à rallonge : la ligne dépasse de loin
      // les 119 points de texte d'une carte à 320 points d'écran, et elle doit
      // grandir sans peindre la bande rayée.
      await tester.pumpWidget(carte(
        vehicule(
          kilometrage: 1234567,
          boite: 'manual',
          motorisation: 'Essence sans plomb 95 bicarburation GPL',
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);

      // « bicarburation » et non « 1 234 » : le séparateur de milliers est une
      // espace fine insécable (U+202F), et le chercher avec une espace
      // ordinaire ne trouve rien — le test échouerait pour la mauvaise raison.
      final ligne =
          tester.widget<Text>(find.textContaining('bicarburation'));
      expect(ligne.maxLines, greaterThan(1),
          reason: 'La ligne est revenue à une seule ligne : elle s\'ellipsera '
              'au lieu de se replier, et le carburant disparaîtra.');
      expect(ligne.overflow, TextOverflow.ellipsis,
          reason: 'Sans ellipse, un libellé aberrant déborderait au lieu de se '
              'borner.');
    });
  });

  // ── Le compteur de photos et le badge unique ───────────────────────────

  group('Compteur de photos', () {
    testWidgets('trois photos s\'annoncent', (tester) async {
      await tester.pumpWidget(carte(vehicule(photos: 3)));
      await tester.pump();

      expect(find.text('3 photos'), findsOneWidget);
    });

    testWidgets('une seule photo ne s\'annonce pas', (tester) async {
      // « 1 photos » est faux, et « 1 photo » n'annoncerait rien de plus que
      // la vignette elle-même.
      await tester.pumpWidget(carte(vehicule(photos: 1)));
      await tester.pump();

      expect(find.textContaining('photo'), findsNothing);
    });

    testWidgets('aucune photo ne s\'annonce pas', (tester) async {
      await tester.pumpWidget(carte(vehicule(photos: 0)));
      await tester.pump();

      expect(find.textContaining('photo'), findsNothing);
    });
  });

  /// `_AvailabilityBadge` dit si le prix affiché est un prix de vente ou un
  /// loyer ; c'est le seul badge qui reste sur la photo. L'étiquette d'affaire
  /// était peinte de l'ocre exact du « À louer » — deux badges de même teinte
  /// sur une location en promotion — et elle est descendue qualifier le prix.
  group('Étiquette d\'affaire', () {
    testWidgets('elle est descendue sous la photo, à côté du prix',
        (tester) async {
      await tester.pumpWidget(carte(vehicule(affaire: 'Bonne affaire')));
      await tester.pump();

      expect(find.text('Bonne affaire'), findsOneWidget);

      // Le titre marque le haut du bloc de texte : tout ce qui est au-dessus
      // est posé sur la photo. L'étiquette est en dessous, le badge de
      // disponibilité au-dessus, et il y est seul.
      final titre = tester.getTopLeft(find.textContaining('Tucson')).dy;
      expect(tester.getTopLeft(find.text('Bonne affaire')).dy,
          greaterThan(titre));
      expect(tester.getTopLeft(find.text('À vendre')).dy, lessThan(titre));
    });

    testWidgets('elle ne reprend pas l\'ocre du « À louer »', (tester) async {
      await tester.pumpWidget(carte(vehicule(affaire: 'Bonne affaire')));
      await tester.pump();

      // La collision qui a motivé le déplacement : 0xFFB26A00 est la teinte
      // du « À louer » de `_AvailabilityBadge`.
      final etiquette = tester.widget<Text>(find.text('Bonne affaire'));
      expect(etiquette.style?.color, isNot(const Color(0xFFB26A00)));
    });

    testWidgets('elle se tait quand le véhicule n\'est pas en affaire',
        (tester) async {
      await tester.pumpWidget(carte(vehicule(affaire: null)));
      await tester.pump();

      expect(find.text('Bonne affaire'), findsNothing);
    });
  });

  // ── Les deux couleurs ajoutées, dans les deux modes ────────────────────

  /// Le thème de cette application a un mode sombre, et les deux couleurs que
  /// la carte gagne ici doivent y tenir.
  ///
  /// L'étiquette d'affaire est écrite en `tertiary` justement parce que son
  /// ancien ocre en dur ne se vérifiait nulle part. La pastille de photos, au
  /// contraire, assume un voile noir : elle est posée sur une photo. Son pire
  /// cas est le repli — le logo de marque sur `surfaceContainerHighest` —, et
  /// c'est celui qu'on mesure.
  ///
  /// Les mathématiques sont celles de `navigation_bar_contraste_test.dart`.
  group('Contraste des couleurs ajoutées', () {
    double luminance(Color c) {
      double canal(double v) => v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
    }

    Color aplatir(Color dessus, Color fond) => Color.from(
          alpha: 1.0,
          red: dessus.r * dessus.a + fond.r * (1 - dessus.a),
          green: dessus.g * dessus.a + fond.g * (1 - dessus.a),
          blue: dessus.b * dessus.a + fond.b * (1 - dessus.a),
        );

    double contraste(Color dessus, Color fond) {
      final a = luminance(aplatir(dessus, fond));
      final b = luminance(fond);
      return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
    }

    /// Seuil WCAG AA pour un texte de moins de 18 points.
    const seuil = 4.5;

    for (final brightness in Brightness.values) {
      test('thème ${brightness.name}', () {
        final cs = ColorScheme.fromSeed(
          seedColor: const Color(0xFF8AAFC8),
          brightness: brightness,
        );

        // Le `Card` de Material 3 se peint en `surfaceContainerLow`.
        expect(contraste(cs.tertiary, cs.surfaceContainerLow),
            greaterThanOrEqualTo(seuil),
            reason: 'L\'étiquette d\'affaire est illisible sur la carte.');

        expect(
            contraste(
                Colors.white, aplatir(Colors.black54, cs.surfaceContainerHighest)),
            greaterThanOrEqualTo(seuil),
            reason: 'Le compteur de photos est illisible sur le repli.');
      });
    }
  });

  // ── Le retour au toucher ───────────────────────────────────────────────

  group('Retour au toucher', () {
    testWidgets('la carte se réduit à l\'appui et revient ensuite',
        (tester) async {
      await tester.pumpWidget(carte(vehicule()));
      await tester.pump();

      double echelle() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
      double? elevation() => tester.widget<Card>(find.byType(Card)).elevation;

      expect(echelle(), 1.0);
      expect(elevation(), isNull, reason: 'Au repos, l\'élévation du thème.');

      final doigt =
          await tester.startGesture(tester.getCenter(find.byType(VehicleCard)));
      await tester.pump();
      expect(echelle(), lessThan(1.0));
      expect(elevation(), greaterThan(1.0));

      // On annule au lieu de relâcher : un relâchement déclenche `onTap`,
      // donc `context.push`, et ce banc n'a pas de routeur. Les deux chemins
      // appellent le même `_appui(false)`.
      await doigt.cancel();
      await tester.pump();
      expect(echelle(), 1.0);
      expect(elevation(), isNull);
    });

    testWidgets('l\'ondulation Material est conservée', (tester) async {
      await tester.pumpWidget(carte(vehicule()));
      await tester.pump();

      expect(find.descendant(
        of: find.byType(VehicleCard),
        matching: find.byType(InkWell),
      ), findsOneWidget);
    });
  });

  // ── La largeur réelle de la carte, aux douze configurations ────────────

  /// LA CASE N'A PLUS DE HAUTEUR, et ce groupe en est la preuve par l'exemple.
  /// Il posait la carte dans des cases de 143,0 × 174,4 et 163,0 × 198,8 — la
  /// largeur ET la hauteur que le délégué calculait — et il cherchait le
  /// débordement vertical. La hauteur est maintenant celle du contenu : seule la
  /// largeur reste imposée par la rangée, et c'est elle que ce groupe parcourt,
  /// aux quatre échelles de texte plutôt qu'aux deux premières.
  ///
  /// Ces cas sont mesurés sous la police du banc d'essai, qui peint chaque
  /// caractère comme un carré du corps du texte : c'est un PIRE CAS de largeur,
  /// et il convient pour chercher un débordement de mise en page. Il ne convient
  /// pas pour décider si un texte est tronqué — ses métriques ne sont celles
  /// d'aucun téléphone. Les chiffres de troncature sont dans
  /// `carte_geometrie_test.dart`, qui charge Roboto et monte la page entière.
  group('La largeur réelle de la carte', () {
    for (final cas in largeurs.entries) {
      // Les quatre échelles, 2,0 comprise et assertée : voir le groupe du
      // dessus — ce qu'on exige ici est « rien ne jette », qui n'a pas de
      // frontière.
      for (final echelle in echellesMesurees) {
        testWidgets('${cas.key}, texte x$echelle', (tester) async {
          for (final v in <Vehicle>[
            vehicule(),
            vehicule(kilometrage: null, boite: null, motorisation: null),
            vehicule(
              nomModele: 'Tucson Highlander Executive',
              kilometrage: 1234567,
              motorisation: 'Essence sans plomb 95 bicarburation GPL',
            ),
          ]) {
            await tester.pumpWidget(ProviderScope(
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    textScaler: TextScaler.linear(echelle),
                  ),
                  child: Scaffold(
                    // Hauteur ILLIMITÉE, comme dans la vraie rangée : voir le
                    // commentaire de `carte` plus haut.
                    body: SingleChildScrollView(
                      child: Center(
                        child: SizedBox(
                          width: cas.value,
                          child: VehicleCard(vehicle: v),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ));
            await tester.pump();

            expect(tester.takeException(), isNull,
                reason: 'La fiche ${v.identity.fullName} déborde à '
                    '${cas.key} d\'écran, à l\'échelle $echelle.');
          }
        });
      }
    }
  });
}
