import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/widgets/mileage_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le plantage intermittent, enfin reproduit.
///
/// Le journal d'erreurs embarqué l'a attrapé sur l'appareil, en trois lignes
/// qui se suivent :
///
///   A TextEditingController was used after being disposed.
///   '_dependents.isEmpty': is not true.
///   Tried to build dirty widget in the wrong build scope.
///
/// Le contrôleur du champ était créé avant `showDialog` et détruit à la ligne
/// suivante. Or `showDialog` rend la main dès le `Navigator.pop` : la boîte
/// s'anime encore, son champ est toujours monté. Il suffit alors que quelque
/// chose reconstruise l'overlay — le clavier qui se referme et modifie les
/// `MediaQuery` — pour que le champ se réabonne à un contrôleur détruit.
///
/// D'où l'intermittence : il fallait que le clavier soit ouvert et que sa
/// fermeture tombe pendant les quelques dixièmes de seconde de l'animation de
/// sortie. Ce test force exactement cette coïncidence.
void main() {
  final vehicule = OwnedVehicle(
    id: 1,
    designation: 'Toyota Corolla 2016',
    brandId: 1,
    vehicleModelId: 2,
    year: 2016,
    mileageKm: 120000,
    identity: const OwnedVehicleIdentity(brand: 'Toyota', model: 'Corolla'),
    compatibilityReady: true,
  );

  testWidgets('fermer la boîte pendant que le clavier se referme ne plante pas',
      (tester) async {
    // Le clavier occupe le bas de l'écran : c'est l'état réel au moment où
    // l'on touche « Sauvegarder », le champ ayant le focus.
    var insets = const EdgeInsets.only(bottom: 320);

    late StateSetter rebatir;

    await tester.pumpWidget(
      ProviderScope(
        child: StatefulBuilder(
          builder: (context, setState) {
            rebatir = setState;

            return MediaQuery(
              data: MediaQueryData(viewInsets: insets),
              child: MaterialApp(
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) => ElevatedButton(
                      onPressed: () => showMileageDialog(context, ref, vehicule),
                      child: const Text('Ouvrir'),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '125000');
    await tester.tap(find.text('Sauvegarder'));

    // Une seule image : la boîte est fermée mais son animation de sortie n'est
    // pas terminée, et son champ de saisie est toujours monté.
    await tester.pump();

    // Le clavier se referme, les MediaQuery changent, l'overlay se
    // reconstruit. C'est là que l'ancien code touchait un contrôleur détruit.
    rebatir(() => insets = EdgeInsets.zero);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.takeException(),
      isNull,
      reason: 'Le contrôleur doit vivre aussi longtemps que le champ qui '
          "s'en sert.",
    );
  });
}
