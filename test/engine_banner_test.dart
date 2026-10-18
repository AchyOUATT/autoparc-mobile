import 'dart:io';

import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/widgets/engine_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/echelles.dart';
import 'support/polices.dart';

/// Le bandeau qui réclame la motorisation manquante.
///
/// Il se décide sur `compatibility_ready`, calculé par le serveur — jamais sur
/// la présence d'un libellé de motorisation dans l'affichage. Les deux peuvent
/// diverger : un véhicule dont la finition porte la motorisation par défaut
/// n'affiche aucun libellé, et pourtant le serveur sait calculer.
///
/// ── ET IL CHANGE DE FORME, CE QUI SE JUGE À L'ŒIL ──────────────────────────
///
/// Le bouton « Compléter » descend sous le texte quand les mots ne tiennent
/// plus à côté de lui. `accueil_langues_test.dart` en porte les douze mesures
/// et vérifie qu'il n'y a plus de débordement ; il ne dit pas si la forme
/// empilée se lit comme un bandeau ou comme deux morceaux. D'où les captures
/// ci-dessous, et la règle que `captures_catalogue_test.dart` écrit en tête :
/// une décision de mise en page se juge à l'œil ET se vérifie au chiffre, les
/// deux ne se remplacent pas.
///
/// Comme les autres bancs de captures, les PNG ne sont pas comparés — un golden
/// est exact au pixel, la CI tourne sous Ubuntu et le poste sous Windows. Ils ne
/// s'écrivent que sur demande :
///
///   CAPTURES=1 flutter test test/engine_banner_test.dart --update-goldens

OwnedVehicle _vehicule({required bool pret, String? engineType}) => OwnedVehicle(
      id: 1,
      designation: 'Toyota Corolla 2017',
      brandId: 1,
      vehicleModelId: 2,
      year: 2017,
      identity: OwnedVehicleIdentity(
        brand: 'Toyota',
        model: 'Corolla',
        engineType: engineType,
      ),
      compatibilityReady: pret,
    );

Future<void> _afficher(WidgetTester tester, OwnedVehicle vehicule) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: MissingEngineBanner(vehicle: vehicule)),
      ),
    ),
  );
}

void main() {
  testWidgets('le bandeau se tait quand le serveur sait calculer',
      (tester) async {
    await _afficher(tester, _vehicule(pret: true));

    expect(find.textContaining('Motorisation'), findsNothing);
    expect(find.text('Compléter'), findsNothing);
  });

  testWidgets('le bandeau nomme le manque et sa conséquence', (tester) async {
    await _afficher(tester, _vehicule(pret: false));

    expect(find.text('Motorisation non renseignée'), findsOneWidget);
    // Dire « information incomplète » n'apprendrait rien : ce qui compte est
    // ce qu'on perd, c'est-à-dire la liste des pièces qui vont sur la voiture.
    expect(find.textContaining('quelles pièces'), findsOneWidget);
    expect(find.text('Compléter'), findsOneWidget);
  });

  /// Le piège inverse de celui du formulaire : une motorisation affichée ne
  /// garantit pas que le serveur sache calculer, et son absence ne prouve pas
  /// le contraire. Seul `compatibility_ready` tranche.
  testWidgets('le bandeau ignore le libellé affiché, il suit le serveur',
      (tester) async {
    await _afficher(tester, _vehicule(pret: true, engineType: null));
    expect(find.text('Compléter'), findsNothing,
        reason: 'Prêt sans libellé : la finition a suffi.');

    await _afficher(tester, _vehicule(pret: false, engineType: 'Essence'));
    expect(find.text('Compléter'), findsOneWidget,
        reason: 'Un libellé affiché ne remplace pas compatibility_ready.');
  });

  // ── LES DEUX FORMES, EN IMAGE ────────────────────────────────────────────

  group('Les captures des deux formes', () {
    final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';

    setUpAll(() => chargerPolices(exigerRoboto: false));

    /// 268 POINTS, ET CE N'EST PAS UN NOMBRE DE FANTAISIE : c'est la largeur
    /// que la carte de l'accueil donne au bandeau ENTIER sur un écran de 320,
    /// reconstituée depuis la mesure. À l'échelle 1,0 l'`Expanded` y reçoit
    /// 129,75 points et le bouton 90,25, soit 220,0 ; plus 28 pour l'icône et
    /// son écart, cela fait 248,0 de contenu ; plus les 12 et 8 points de
    /// remplissage du `Container`, 268,0 au total.
    ///
    /// LA PREMIÈRE VERSION POSAIT 248, et la capture l'a dénoncée tout de
    /// suite : le bandeau s'y empilait dès l'échelle 1,3, là où l'accueil le
    /// garde côte à côte. Vingt points de remplissage comptés deux fois, et une
    /// capture qui montrait une forme que l'application ne produit pas — ce qui
    /// est exactement ce que l'en-tête de `captures_catalogue_test.dart`
    /// reproche aux captures généreuses.
    ///
    /// Cette largeur est posée ici plutôt que l'accueil entier monté : ce banc
    /// n'a ni garage, ni authentification, ni réseau, et le monter pour voir un
    /// bandeau coûterait cent cinquante lignes de fixture. Ce que la capture
    /// doit montrer — où va le bouton, comment le bloc respire — ne dépend que
    /// de cette largeur-là. Les CHIFFRES, eux, sont mesurés dans la vraie coque
    /// par `accueil_langues_test.dart`, et c'est là qu'il faut les lire.
    const largeurBandeau = 268.0;

    Future<void> capturer(
      WidgetTester tester, {
      required double echelle,
      required String nom,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeAutoParc(Brightness.light),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(echelle)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: largeurBandeau,
                    child: MissingEngineBanner(
                      vehicle: _vehicule(pret: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Le test reste un vrai test hors du mode capture : le bandeau doit
      // rendre ses trois chaînes à chaque échelle, et rien ne doit jeter.
      expect(find.text('Motorisation non renseignée'), findsOneWidget);
      expect(find.text('Compléter'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Le bandeau déborde à l\'échelle $echelle.',
      );

      if (!ecrireCaptures) return;
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../build/captures/$nom.png'),
      );
    }

    for (final echelle in echellesMesurees) {
      testWidgets('à l\'échelle $echelle', (tester) async {
        await capturer(
          tester,
          echelle: echelle,
          nom: 'bandeau-motorisation-x${echelle.toStringAsFixed(1).replaceAll('.', '')}',
        );
      });
    }
  });
}
