import 'package:auto/core/l10n/langue.dart';
import 'package:auto/core/l10n/tuile_langue.dart';
import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/langues.dart';

/// LA TUILE DU TIROIR, TOUCHÉE POUR DE VRAI.
///
/// `langue_test.dart` prouve que le provider change ce qui est peint et que le
/// choix survit au redémarrage. Il ne prouve pas que LE GESTE de
/// l'utilisateur — ouvrir le tiroir, toucher « Langue », choisir « English » —
/// atteigne ce provider. C'est ce chaînon, et lui seul, que ce fichier mesure :
/// trois lignes de code, et exactement le genre de trois lignes qui manquent
/// sans que rien ne le dise.
///
/// La tuile est montée dans un `Drawer`, comme dans l'application, parce que
/// c'est la contrainte qui a décidé de sa forme : une boîte de dialogue plutôt
/// que deux boutons radio à même le tiroir, le tiroir se refermant au premier
/// appui.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => definirLocaleMontants(localeFr));

  Future<ProviderContainer> poserTiroir(WidgetTester tester) async {
    final conteneur = ProviderContainer();
    addTearDown(conteneur.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: conteneur,
        child: const _CoqueTiroir(),
      ),
    );
    await tester.pump();

    // Le tiroir est ouvert par son bouton, et non par la clé du `Scaffold` :
    // c'est le geste de l'utilisateur. L'icône plutôt que l'infobulle —
    // celle-ci vient de `MaterialLocalizations` et change donc avec la langue,
    // ce qui est précisément ce que ce banc fait varier.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    return conteneur;
  }

  testWidgets('la tuile annonce la langue courante', (tester) async {
    await poserTiroir(tester);

    expect(find.text('Langue'), findsOneWidget);
    expect(
      find.text('Français'),
      findsOneWidget,
      reason:
          'Le sous-titre de la tuile n\'annonce pas la langue active : un '
          'anglophone ne peut pas savoir ce qu\'il va changer.',
    );
  });

  testWidgets('choisir « English » bascule l\'affichage ET le provider', (
    tester,
  ) async {
    final conteneur = await poserTiroir(tester);

    await tester.tap(find.text('Langue'));
    await tester.pumpAndSettle();

    // LES DEUX NOMS SONT DANS LEUR PROPRE LANGUE, et c'est la décision que
    // cette assertion verrouille : un anglophone devant une interface encore
    // française doit reconnaître « English » sans rien lire d'autre. Traduire
    // les intitulés lui donnerait « Anglais ».
    expect(find.text('Français'), findsWidgets);
    expect(
      find.text('English'),
      findsOneWidget,
      reason:
          'La boîte ne propose pas « English » écrit en anglais : un '
          'utilisateur qui ne lit pas le français ne trouve pas sa langue.',
    );

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(
      conteneur.read(langueProvider),
      localeAnglais,
      reason:
          'La tuile n\'appelle pas `definir` : le choix est perdu entre le '
          'doigt et le provider.',
    );
    expect(
      find.text('Language'),
      findsOneWidget,
      reason:
          'Le tiroir n\'a pas suivi : la tuile montre encore « Langue » après '
          'la bascule.',
    );
    expect(
      find.text('Accueil'),
      findsNothing,
      reason: 'Le corps de la page est resté en français.',
    );
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('le choix fait depuis le tiroir est écrit sur le disque', (
    tester,
  ) async {
    await poserTiroir(tester);

    await tester.tap(find.text('Langue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // Le redémarrage, comme dans premiere_utilisation_test.dart.
    SharedPreferences.resetStatic();

    expect(
      await LangueService.lire(),
      localeAnglais,
      reason:
          'Le geste change l\'écran et rien d\'autre : au lancement suivant, '
          'le client anglophone retrouve le français.',
    );
  });

  testWidgets('fermer la boîte sans choisir ne change rien', (tester) async {
    final conteneur = await poserTiroir(tester);

    await tester.tap(find.text('Langue'));
    await tester.pumpAndSettle();

    // Un appui hors de la boîte : `showDialog` rend null, et `definir` ne doit
    // pas être appelé. Sans la garde `if (choix == null) return`, ce serait un
    // plantage sur un geste banal.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(conteneur.read(langueProvider), localeFrancais);
    expect(find.text('Langue'), findsOneWidget);
  });
}

/// Le tiroir de l'application, réduit à la tuile de langue et à un repère.
///
/// Reproduit le câblage de `AutoParcApp` — `locale:` pris dans `langueProvider`
/// et les délégués — parce que c'est lui qui fait que la bascule se VOIT. Le
/// repère dans le corps est `commonHome`, la clé que porte aussi l'onglet
/// d'accueil.
class _CoqueTiroir extends ConsumerWidget {
  const _CoqueTiroir();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langue = ref.watch(langueProvider);
    definirLocaleMontants(langue);

    return MaterialApp(
      locale: langue,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(AppLocalizations.of(context).commonHome)),
          drawer: Drawer(
            child: ListView(children: const [TuileLangue()]),
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
