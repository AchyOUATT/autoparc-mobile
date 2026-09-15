import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/widgets/engine_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le bandeau qui réclame la motorisation manquante.
///
/// Il se décide sur `compatibility_ready`, calculé par le serveur — jamais sur
/// la présence d'un libellé de motorisation dans l'affichage. Les deux peuvent
/// diverger : un véhicule dont la finition porte la motorisation par défaut
/// n'affiche aucun libellé, et pourtant le serveur sait calculer.

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
}
