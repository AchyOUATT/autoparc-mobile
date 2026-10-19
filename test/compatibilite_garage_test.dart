import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/catalog/presentation/pages/part_detail_page.dart';
import 'package:auto/features/garage/data/models/garage_compatibility.dart';
import 'package:auto/l10n/app_localizations.dart';

import 'support/langues.dart';

/// Ce que l'application dit au client sur la compatibilité d'une pièce.
///
/// Le défaut corrigé ici se voyait à l'écran mais passait pour une évidence :
///
/// ```dart
/// item.compatible
///     ? (check_circle, green, 'Compatible')   // compatibilityReady ignoré
///     : item.compatibilityReady ? ... : ...
/// ```
///
/// `compatible` court-circuitait le test. Le drapeau qui dit « on ne connaît
/// pas la motorisation de ce véhicule » n'était consulté que sur la branche
/// négative — donc jamais quand la réponse était oui.
///
/// Ce n'est pas un détail d'affichage. Une génération reçoit plusieurs moteurs
/// et plusieurs filtres : un Hilux AN10 existe en diesel 1KD et en V6 essence
/// 1GR, avec deux références différentes. Côté serveur, le filtre par code
/// moteur ne s'applique que si le véhicule du client en a un — sinon la
/// recherche renvoie les deux. L'écran les annonçait tous les deux en vert, et
/// l'un des deux ne se visse pas.
///
/// Les quatre combinaisons sont donc verrouillées une par une.
void main() {
  GarageCompatibility item({
    required bool compatible,
    required bool pret,
  }) =>
      GarageCompatibility(
        vehicleId: 1,
        displayName: 'Hilux',
        year: 2010,
        compatible: compatible,
        compatibilityReady: pret,
      );

  /// [locale] décide de la langue du VERDICT, et c'est la vague 2 qui l'a rendu
  /// nécessaire : les quatre verdicts viennent des `.arb` depuis qu'elle a
  /// traduit la fiche d'une pièce, et `AppLocalizations.of` LÈVE sur une coque
  /// qui ne pose pas les délégués — « Null check operator used on a null
  /// value », ce qui est exactement ainsi que les cinq tests de ce fichier sont
  /// tombés.
  ///
  /// La locale est NOMMÉE même pour le français : voir
  /// test/support/langues.dart — un banc qui l'omet résout `[en_US]` contre une
  /// liste de locales qui commence par `en`, donc mesure l'anglais.
  Future<void> afficher(
    WidgetTester tester,
    GarageCompatibility i, {
    Locale locale = localeFr,
  }) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ListView(children: [CompatibilityTile(item: i)])),
    ));
    await tester.pump();
  }

  // ── LES QUATRE VERDICTS, DANS LES DEUX LANGUES ────────────────────────────
  //
  // Les quatre libellés étaient recopiés ici en français. La vague 2 les a
  // sortis dans les `.arb`, et ce groupe les y LIT désormais : une assertion
  // qui réécrirait « À confirmer » à la main resterait verte le jour où
  // l'`.arb` dirait autre chose, et ne dirait rien du tout de l'anglais.
  //
  // La boucle sur les deux langues n'est pas décorative : elle est la
  // NON-VACUITÉ de la colonne anglaise. Les quatre verdicts doivent se
  // distinguer deux à deux dans CHAQUE langue — « Compatible » et
  // « À confirmer » ne doivent jamais être la même chaîne —, et l'anglais
  // (« Fits » / « To be confirmed » / « Does not fit » / « Undetermined »)
  // n'avait aucun banc avant celui-ci.
  group('Verdict de compatibilité', () {
    for (final langue in langues.entries) {
      testWidgets('${langue.key} : compatible et motorisation connue, '
          'une affirmation', (tester) async {
        final t = await chargerTextes(langue.value);
        await afficher(
          tester,
          item(compatible: true, pret: true),
          locale: langue.value,
        );

        expect(find.text(t.catalogFitmentYes), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text(t.catalogFitmentUnsureDetail), findsNothing);
      });

      /// Le cas qui manquait, et le seul qui fait acheter la mauvaise pièce.
      testWidgets('${langue.key} : compatible mais motorisation inconnue, '
          'une réserve', (tester) async {
        final t = await chargerTextes(langue.value);
        await afficher(
          tester,
          item(compatible: true, pret: false),
          locale: langue.value,
        );

        expect(find.text(t.catalogFitmentYes), findsNothing,
            reason: 'Sans le moteur, l\'application ne peut pas l\'affirmer.');
        expect(find.text(t.catalogFitmentUnsure), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.text(t.catalogFitmentUnsureDetail), findsOneWidget,
            reason: 'Il faut dire ce qui manque, et comment le combler.');
      });

      testWidgets('${langue.key} : incompatible et motorisation connue, '
          'un refus net', (tester) async {
        final t = await chargerTextes(langue.value);
        await afficher(
          tester,
          item(compatible: false, pret: true),
          locale: langue.value,
        );

        expect(find.text(t.catalogFitmentNo), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
      });

      testWidgets('${langue.key} : incompatible et motorisation inconnue, '
          'aucune réponse', (tester) async {
        final t = await chargerTextes(langue.value);
        await afficher(
          tester,
          item(compatible: false, pret: false),
          locale: langue.value,
        );

        expect(find.text(t.catalogFitmentUnknown), findsOneWidget);
        expect(find.text(t.catalogFitmentNo), findsNothing,
            reason: 'Annoncer une incompatibilité qu\'on n\'a pas établie '
                'ferait renoncer le client à une pièce qui lui convenait '
                'peut-être.');
      });

      /// LES QUATRE VERDICTS SE DISTINGUENT, et c'est la garde que la
      /// traduction rend nécessaire : quatre états rendus par deux chaînes
      /// identiques effaceraient en anglais la distinction que le français
      /// fait — exactement le défaut que ce fichier existe pour empêcher, mais
      /// arrivé par le `.arb` au lieu du `switch`.
      testWidgets('${langue.key} : les quatre verdicts sont quatre chaînes '
          'distinctes', (tester) async {
        final t = await chargerTextes(langue.value);
        final verdicts = <String>[
          t.catalogFitmentYes,
          t.catalogFitmentUnsure,
          t.catalogFitmentNo,
          t.catalogFitmentUnknown,
        ];

        expect(
          verdicts.toSet(),
          hasLength(4),
          reason:
              'Deux des quatre verdicts s\'écrivent pareil en ${langue.key} : '
              '${verdicts.join(" / ")}. Le client ne pourrait plus distinguer '
              'une certitude d\'une réserve.',
        );
      });
    }

    /// Le vert est réservé à la certitude.
    testWidgets('seule la certitude s\'affiche en vert', (tester) async {
      for (final pret in [true, false]) {
        await afficher(tester, item(compatible: true, pret: pret));

        final icone = tester.widget<Icon>(find.byType(Icon).first);

        if (pret) {
          expect(icone.color, Colors.green);
        } else {
          expect(icone.color, isNot(Colors.green),
              reason: 'Un vert sur une réponse incertaine se lit comme une '
                  'garantie.');
        }
      }
    });
  });
}
