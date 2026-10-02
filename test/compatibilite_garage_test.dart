import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/catalog/presentation/pages/part_detail_page.dart';
import 'package:auto/features/garage/data/models/garage_compatibility.dart';

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

  Future<void> afficher(WidgetTester tester, GarageCompatibility i) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ListView(children: [CompatibilityTile(item: i)])),
    ));
    await tester.pump();
  }

  group('Verdict de compatibilité', () {
    testWidgets('compatible et motorisation connue : une affirmation',
        (tester) async {
      await afficher(tester, item(compatible: true, pret: true));

      expect(find.text('Compatible'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.textContaining('n\'est pas renseignée'), findsNothing);
    });

    /// Le cas qui manquait, et le seul qui fait acheter la mauvaise pièce.
    testWidgets('compatible mais motorisation inconnue : une réserve',
        (tester) async {
      await afficher(tester, item(compatible: true, pret: false));

      expect(find.text('Compatible'), findsNothing,
          reason: 'Sans le moteur, l\'application ne peut pas l\'affirmer.');
      expect(find.text('À confirmer'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.textContaining('motorisation'), findsOneWidget,
          reason: 'Il faut dire ce qui manque, et comment le combler.');
    });

    testWidgets('incompatible et motorisation connue : un refus net',
        (tester) async {
      await afficher(tester, item(compatible: false, pret: true));

      expect(find.text('Non compatible'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('incompatible et motorisation inconnue : aucune réponse',
        (tester) async {
      await afficher(tester, item(compatible: false, pret: false));

      expect(find.text('Non déterminé'), findsOneWidget);
      expect(find.text('Non compatible'), findsNothing,
          reason: 'Annoncer une incompatibilité qu\'on n\'a pas établie ferait '
              'renoncer le client à une pièce qui lui convenait peut-être.');
    });

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
