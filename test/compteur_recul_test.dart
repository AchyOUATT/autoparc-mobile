import 'package:auto/core/api/api_client.dart';
import 'package:auto/features/garage/data/garage_repository.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/widgets/mileage_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le kilométrage qui reculait sans rien dire.
///
/// « Sauvegarder » rendait `int.tryParse(texte) ?? ancienne valeur`. Les deux
/// moitiés de cette ligne étaient fausses, et la seconde coûtait cher.
///
/// Un texte illisible retombait sur l'ancienne valeur : la boîte se refermait
/// sur un succès apparent, sans rien avoir changé.
///
/// Surtout, un compteur plus PETIT se parse très bien — 9 600 tapé pour
/// 96 000 — et partait tel quel. Le serveur ne l'arrêtait pas non plus :
/// `mileage_km` n'était validé que `min:0`, et UpdateOwnedVehicleRequest
/// hérite de cette règle.
///
/// Le dégât n'est pas cosmétique. `kilometresAvantVidange()` calcule
/// `intervalle − (kilométrage − kilométrage de la dernière vidange)`. Avec
/// 9 600 contre 90 000 de dernière vidange, il rend 80 400 km de plus que
/// l'intervalle : le rappel de vidange est repoussé si loin qu'il ne part
/// jamais. Aucune erreur, aucune trace — le moteur de récurrence de
/// l'application s'éteint en silence pour ce véhicule.
///
/// Le recul reste possible : un compteur remplacé existe sur un parc importé,
/// et une saisie trop haute doit pouvoir être corrigée. Ce que ces tests
/// protègent, c'est qu'il soit désormais DÉLIBÉRÉ.
void main() {
  OwnedVehicle vehicule({int? km = 96000}) => OwnedVehicle(
        id: 1,
        designation: 'Toyota Corolla 2016',
        brandId: 1,
        vehicleModelId: 2,
        year: 2016,
        mileageKm: km,
        identity: const OwnedVehicleIdentity(brand: 'Toyota', model: 'Corolla'),
        compatibilityReady: true,
      );

  /// Monte un écran dont le bouton ouvre la boîte de saisie.
  ///
  /// Le dépôt est remplacé : la confirmation déclenche un envoi réseau, et
  /// c'est la boîte qu'on mesure ici, pas le serveur. Le faux retient ce qui
  /// lui a été transmis — c'est la seule façon de distinguer « la boîte a
  /// refusé » de « la boîte a envoyé l'ancienne valeur ».
  Future<_FauxDepot> ouvrir(WidgetTester tester, {int? km = 96000}) async {
    final depot = _FauxDepot(vehicule(km: km));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [garageRepositoryProvider.overrideWithValue(depot)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => showMileageDialog(context, ref, vehicule(km: km)),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    return depot;
  }

  testWidgets('un compteur en recul demande confirmation au lieu de partir',
      (tester) async {
    final depot = await ouvrir(tester);

    await tester.enterText(find.byType(TextField), '9600');
    await tester.tap(find.text('Sauvegarder'));
    await tester.pump();

    // Le séparateur de milliers du français est une espace fine insécable
    // (U+202F), pas une espace ordinaire : chercher « 96 000 » tapé au clavier
    // ne trouve rien. On tolère donc n'importe quelle espace — ce que ce test
    // protège est le garde-fou, pas la typographie.
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').contains(RegExp(r'96\s?000')),
      ),
      findsOneWidget,
      reason: "L'avertissement doit nommer le chiffre précédent : c'est lui "
          'qui révèle la faute de frappe.',
    );
    expect(find.text('Confirmer'), findsOneWidget);
    expect(
      depot.envoye,
      isEmpty,
      reason: 'Rien ne doit partir tant que le recul n\'est pas confirmé.',
    );
  });

  testWidgets('le second appui confirme et enregistre bien le recul',
      (tester) async {
    final depot = await ouvrir(tester);

    await tester.enterText(find.byType(TextField), '9600');
    await tester.tap(find.text('Sauvegarder'));
    await tester.pump();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    expect(
      depot.envoye,
      [
        {'mileage_km': 9600}
      ],
      reason: 'Un compteur remplacé, ou une saisie trop haute corrigée, doit '
          'rester possible. On ne bloque pas, on rend délibéré.',
    );
  });

  testWidgets('modifier la saisie annule la confirmation en cours',
      (tester) async {
    final depot = await ouvrir(tester);

    await tester.enterText(find.byType(TextField), '9600');
    await tester.tap(find.text('Sauvegarder'));
    await tester.pump();

    // Le propriétaire voit son erreur et corrige : le prochain appui ne doit
    // pas valider par inadvertance le recul qu'il vient d'abandonner.
    await tester.enterText(find.byType(TextField), '96500');
    await tester.pump();

    expect(find.text('Sauvegarder'), findsOneWidget);
    expect(find.text('Confirmer'), findsNothing);

    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();

    expect(depot.envoye, [
      {'mileage_km': 96500}
    ]);
  });

  testWidgets('un texte illisible ne se referme plus sur un faux succès',
      (tester) async {
    final depot = await ouvrir(tester);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('Sauvegarder'));
    await tester.pump();

    expect(find.text('Entrez un nombre de kilomètres.'), findsOneWidget);
    expect(
      depot.envoye,
      isEmpty,
      reason: 'La boîte se refermait sur l\'ancienne valeur, donc sur rien.',
    );
  });

  testWidgets('les espaces de séparation des milliers sont acceptés',
      (tester) async {
    final depot = await ouvrir(tester);

    // « 96 500 » est ce qu'on tape naturellement, et int.tryParse le refuse.
    // Le rejeter ferait passer une saisie correcte pour une faute.
    await tester.enterText(find.byType(TextField), '96 500');
    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();

    expect(depot.envoye, [
      {'mileage_km': 96500}
    ]);
  });

  testWidgets('un kilométrage hors de portée est refusé', (tester) async {
    final depot = await ouvrir(tester);

    // Le zéro de trop : 960 000 devient 9 600 000.
    await tester.enterText(find.byType(TextField), '9600000');
    await tester.tap(find.text('Sauvegarder'));
    await tester.pump();

    expect(find.text('Ce kilométrage est hors de portée.'), findsOneWidget);
    expect(depot.envoye, isEmpty);
  });

  testWidgets('un véhicule sans kilométrage connu accepte la première saisie',
      (tester) async {
    // Sans valeur précédente, il n'y a aucun recul possible : la première
    // saisie ne doit pas demander de confirmation.
    final depot = await ouvrir(tester, km: null);

    await tester.enterText(find.byType(TextField), '42000');
    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();

    expect(depot.envoye, [
      {'mileage_km': 42000}
    ]);
  });
}

/// Dépôt qui retient ce qu'on lui envoie, sans réseau.
class _FauxDepot extends GarageRepository {
  _FauxDepot(this.vehicule) : super(ApiClient());

  final OwnedVehicle vehicule;
  final List<Map<String, dynamic>> envoye = [];

  @override
  Future<List<OwnedVehicle>> getVehicles() async => [vehicule];

  @override
  Future<OwnedVehicle> updateVehicle(int id, Map<String, dynamic> payload) async {
    envoye.add(payload);
    return vehicule;
  }
}
