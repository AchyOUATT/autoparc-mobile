import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/needs/data/needs_repository.dart';
import 'package:auto/features/needs/presentation/pages/submit_need_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';

/// Captures du formulaire de besoin, avec ses champs téléphone.
///
/// Même convention que `captures_catalogue_test.dart` : rien n'est écrit sans
/// `CAPTURES=1`, et les images vont dans `build/captures/`. Hors de ce mode, ce
/// fichier se contente de vérifier que la capture ne serait pas vide — un
/// `matchesGoldenFile` sur un écran qui n'a rien rendu produit une image grise
/// sans que rien ne s'en plaigne.
///
/// Ce que la capture montre : l'écran exige une connexion, et c'est en
/// PERSONNEL qu'on se place — le chemin où aucun contact ne partait. Un client
/// envoie au moins son `firebase_uid` ; un membre du personnel qui saisit la
/// demande de quelqu'un au comptoir n'envoyait rien du tout.
class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth()
      : super(const AuthState(
          type: AuthType.staff,
          staffUser: StaffUser(
            id: 1,
            name: 'Awa Traoré',
            email: 'awa@autoparc.bf',
            role: 'manager',
          ),
        ));

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Le PENDANT client, pour que la capture montre les deux versants du
/// bandeau : c'est la seule difference que le correctif introduit.
class _FauxClient extends Fake implements User {
  @override
  String? get displayName => 'Issa Ouedraogo';
  @override
  String get uid => 'uid-client';
}

class _AuthClient extends StateNotifier<AuthState> implements AuthNotifier {
  _AuthClient()
      : super(AuthState(type: AuthType.client, firebaseUser: _FauxClient()));

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Depot extends NeedsRepository {
  _Depot() : super(ApiClient());

  @override
  Future<void> submitNeed(Map<String, dynamic> payload) async {}
}

void main() {
  final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';

  // Sans les vraies polices, une capture rend tout le texte en rectangles :
  // la police de banc par defaut dessine des boites pleines. Le depot a son
  // chargeur, et `captures_catalogue_test.dart` l'emploie de la meme facon.
  setUpAll(chargerPolices);

  Future<void> ouvrir(WidgetTester tester, {bool client = false}) async {
    // 360x720 : la plus petite taille que `responsive_test.dart` eprouve, donc
    // celle ou un champ de trop se verrait le plus vite.
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        needsRepositoryProvider.overrideWithValue(_Depot()),
        authProvider.overrideWith((_) => client ? _AuthClient() : _Auth()),

        // ── POURQUOI OUTREPASSER LES REFERENTIELS ─────────────────────────
        //
        // Deux raisons, et la seconde est la vraie. D'abord l'image : laisses
        // en attente, ces `FutureProvider` rendent des indicateurs de
        // chargement, et la capture montrerait des roues qui tournent au lieu
        // des listes. Ensuite le banc : une requete reseau jamais resolue
        // laisse un MINUTEUR en attente, et le demontage de l'arbre leve
        // alors « A Timer is still pending even after the widget tree was
        // disposed » — la capture etait bien ecrite, mais le test echouait
        // apres coup.
        publicBrandsProvider.overrideWith((_) async => const [
              (id: 1, name: 'Toyota'),
              (id: 2, name: 'Hyundai'),
              (id: 3, name: 'Lexus'),
            ]),
        publicPartCategoriesProvider.overrideWith((_) async => const [
              (id: 10, name: 'Filtres à huile'),
              (id: 11, name: 'Freins'),
            ]),
        publicManufacturersProvider.overrideWith((_) async => const [
              (id: 20, name: 'Bosch'),
              (id: 21, name: 'Denso'),
            ]),
      ],
      child: const MaterialApp(home: SubmitNeedPage()),
    ));

    // On pompe par duree : les referentiels de la page restent en attente en
    // banc, donc leurs indicateurs de chargement tournent indefiniment et
    // `pumpAndSettle` expirerait.
    await tester.pump(const Duration(milliseconds: 250));
  }

  Future<Finder> atteindre(WidgetTester tester, Finder cible) async {
    await tester.scrollUntilVisible(
      cible,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 200));

    return cible;
  }

  /// Le bandeau se lit sous les champs telephone : on en remplit un, sans
  /// quoi la capture montrerait un formulaire vierge.
  Future<void> saisirUnNumero(WidgetTester tester) async {
    await tester.enterText(
      await atteindre(tester, find.byKey(const ValueKey('besoin-telephone-0'))),
      '+226 70 00 00 01',
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> capturer(WidgetTester tester, String nom) async {
    expect(
      find.byKey(const ValueKey('besoin-telephone-0')),
      findsOneWidget,
      reason: 'La capture serait vide : le champ telephone n a pas ete rendu.',
    );
    if (!ecrireCaptures) return;

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/captures/$nom.png'),
    );
  }

  testWidgets('un numéro demandé, un second proposé', (tester) async {
    await ouvrir(tester);

    final champ = await atteindre(
      tester,
      find.byKey(const ValueKey('besoin-telephone-0')),
    );
    await tester.enterText(champ, '+226 70 00 00 01');
    await tester.pump(const Duration(milliseconds: 100));

    await capturer(tester, 'besoin-telephone-un-numero');
  });

  testWidgets('trois numéros, et le bouton d’ajout disparaît', (tester) async {
    await ouvrir(tester);

    await tester.enterText(
      await atteindre(tester, find.byKey(const ValueKey('besoin-telephone-0'))),
      '+226 70 00 00 01',
    );

    for (var pose = 0; pose < 2; pose++) {
      final ajouter = await atteindre(
        tester,
        find.byKey(const Key('besoin-ajouter-telephone')),
      );
      await tester.tap(ajouter);
      await tester.pump(const Duration(milliseconds: 150));
    }

    await tester.enterText(
      await atteindre(tester, find.byKey(const ValueKey('besoin-telephone-1'))),
      '+226 75 00 00 02',
    );
    await tester.enterText(
      await atteindre(tester, find.byKey(const ValueKey('besoin-telephone-2'))),
      '+226 76 00 00 03',
    );
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byKey(const Key('besoin-ajouter-telephone')), findsNothing);

    await capturer(tester, 'besoin-telephone-trois-numeros');
  });

  /// Le refus, qui est le coeur du lot : sans numero, rien ne part.
  testWidgets('le refus quand aucun numéro n’est donné', (tester) async {
    await ouvrir(tester);

    await tester.enterText(
      await atteindre(tester, find.byKey(const Key('besoin-description'))),
      'Cherche une berline diesel, boîte automatique, moins de 150 000 km.',
    );

    final soumettre = await atteindre(
      tester,
      find.byKey(const Key('besoin-soumettre')),
    );
    await tester.tap(soumettre);
    await tester.pump(const Duration(milliseconds: 200));

    await atteindre(tester, find.text('Indiquez un numéro.'));

    await capturer(tester, 'besoin-telephone-refus');
  });

  /// ── LES DEUX VERSANTS DU BANDEAU ────────────────────────────────────────
  ///
  /// Le bandeau annoncait « votre demande sera liee a votre compte » a
  /// QUICONQUE etait connecte. Or le `firebase_uid` ne part que
  /// `if (auth.isClient)` : la demande saisie au comptoir par un membre du
  /// personnel n'est rattachee a aucun compte, et surtout pas a celui du
  /// client qu'il a devant lui. Les deux captures montrent ce que chacun
  /// lit desormais.
  testWidgets('le bandeau, côté personnel', (tester) async {
    await ouvrir(tester);
    await saisirUnNumero(tester);
    await atteindre(tester, find.textContaining('Saisie par'));

    expect(find.textContaining('ne sera rattachée à aucun compte'),
        findsOneWidget,
        reason: 'La capture ne montrerait pas ce que le correctif change.');

    await capturer(tester, 'besoin-bandeau-personnel');
  });

  testWidgets('le bandeau, côté client', (tester) async {
    await ouvrir(tester, client: true);
    await saisirUnNumero(tester);
    await atteindre(tester, find.textContaining('Connecté en tant que'));

    expect(find.textContaining('liée à votre compte'), findsOneWidget);

    await capturer(tester, 'besoin-bandeau-client');
  });
}