import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/garage/data/check_draft_store.dart';
import 'package:auto/features/garage/data/garage_repository.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/data/models/vehicle_check.dart';
import 'package:auto/features/garage/presentation/pages/pre_trip_check_page.dart';

/// Le contrôle avant voyage, côté application.
///
/// Trois choses se défendent mal toutes seules et sont verrouillées ici.
///
/// Le verdict vient du serveur. L'application ne le formule jamais : elle n'a
/// rien constaté, elle a posé des questions. Un test lit le texte affiché mot
/// par mot et refuse toute formulation qui certifierait l'état du véhicule.
///
/// Un contrôle terminé ne se perd pas. Il se remplit dans une cour, capot
/// ouvert, souvent sans réseau. Si l'envoi échoue, il est gardé et rejoué à
/// l'ouverture suivante — et il repart avec LA MÊME clé, sans quoi le rejeu
/// enregistrerait un second passage. C'est le test le plus important du fichier.
///
/// Les raisons s'affichent. « 190 000 km au compteur » est ce qui distingue une
/// liste composée d'une liste générique ; si les raisons disparaissent de
/// l'écran, la fonction perd ce qui la justifie sans qu'aucun autre test ne
/// s'en aperçoive.
///
/// Note sur la technique : ces tests surchargent `garageRepositoryProvider`.
/// Le reste du projet sous-classe la vraie classe et l'injecte par le
/// constructeur, mais aucun test ne surchargeait de provider — et
/// `mileage_dialog_test.dart` laisse de ce fait le vrai dépôt appeler le
/// réseau, ce qui ne protège rien. Ici l'envoi est bel et bien observé.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── Outils ─────────────────────────────────────────────────────

  CheckItem point(
    String code,
    String titre, {
    String severite = 'watch',
    List<String> raisons = const [],
    String? preEtat,
    String? preRaison,
    int? categoriePieces,
  }) =>
      CheckItem(
        code: code,
        category: 'pneus',
        categoryLabel: 'Pneus',
        title: titre,
        help: 'Où regarder pour $titre.',
        severity: severite,
        reasons: raisons,
        prefillStatus: preEtat,
        prefillReason: preRaison,
        partCategoryId: categoriePieces,
      );

  VehicleCheck resultat({
    String verdict = 'clear',
    String libelle = 'Rien à signaler',
    String detail = 'Rien à signaler sur les 2 points vérifiés',
    int bloquants = 0,
    int aSurveiller = 0,
    int verifies = 2,
    List<CheckPointToFix> aReprendre = const [],
  }) =>
      VehicleCheck(
        id: 7,
        ownedVehicleId: 1,
        mileageKm: 182400,
        performedAt: DateTime(2026, 9, 28),
        verdict: CheckVerdict(value: verdict, label: libelle, detail: detail),
        blockingCount: bloquants,
        watchCount: aSurveiller,
        checkedCount: verifies,
        toFix: aReprendre,
      );

  const vehicule = OwnedVehicle(
    id: 1,
    designation: 'Toyota Hilux 2013',
    brandId: 1,
    vehicleModelId: 1,
    year: 2013,
    mileageKm: 182000,
    identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Hilux'),
    compatibilityReady: true,
  );

  Widget ecran(_FauxDepot depot) => ProviderScope(
        overrides: [garageRepositoryProvider.overrideWithValue(depot)],
        child: const MaterialApp(
          home: PreTripCheckPage(ownedVehicleId: 1, vehicle: vehicule),
        ),
      );

  /// Rouvre l'écran comme le ferait une nouvelle navigation.
  ///
  /// Le démontage intermédiaire est indispensable : à type et position
  /// identiques, le framework de test réutilise l'état existant et `initState`
  /// ne repart pas — la reprise d'un envoi en attente ne serait jamais testée.
  Future<void> reouvrir(WidgetTester tester, _FauxDepot depot) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();
  }

  /// Choisit un trajet puis demande la liste.
  Future<void> composer(WidgetTester tester) async {
    await tester.tap(find.text('Une autre région · 400 km'));
    await tester.pump();
    await tester.tap(find.text("Voir ce qu'il faut vérifier"));
    await tester.pumpAndSettle();
  }

  // ── La liste composée ──────────────────────────────────────────

  testWidgets('chaque point dit pourquoi il est là', (tester) async {
    final depot = _FauxDepot(liste: CheckTemplate(items: [
      point('moteur-courroie', "État de la courroie",
          severite: 'blocking', raisons: ['190 000 km au compteur']),
      point('confort-clim', 'Climatisation', raisons: ['Trajet de 400 km']),
    ]));

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();
    await composer(tester);

    expect(find.text('190 000 km au compteur'), findsOneWidget);
    expect(find.text('Trajet de 400 km'), findsOneWidget);
    // Deux appels : celui de l'ouverture, qui demande au serveur quels
    // contrôles ont un sens aujourd'hui, puis la composition avec la distance.
    expect(depot.distancesDemandees, [null, 400]);
  });

  testWidgets("une réponse à un point qui n'est plus demandé ne compte plus",
      (tester) async {
    // On répond, puis on change de trajet : la liste se recompose, et une
    // réponse laissée derrière ferait afficher « 2/1 » et enverrait au serveur
    // un point que l'écran n'a pas montré.
    final depot = _FauxDepot.parDistance({
      400: CheckTemplate(items: [
        point('pneus-etat', 'Pneus'),
        point('confort-clim', 'Climatisation'),
      ]),
      30: CheckTemplate(items: [point('pneus-etat', 'Pneus')]),
    });

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();
    await composer(tester);

    await tester.tap(find.text('Défaut').last); // la climatisation
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);

    // On change d'avis sur le trajet.
    await tester.tap(find.text('Trajet de 400 km · Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('En ville · 30 km'));
    await tester.pump();
    await tester.tap(find.text("Voir ce qu'il faut vérifier"));
    await tester.pumpAndSettle();

    expect(find.text('0/1'), findsOneWidget);
  });

  testWidgets("un point pré-rempli arrive déjà répondu, avec sa raison",
      (tester) async {
    // Pré-remplir n'est pas décider, mais c'est la moitié des taps économisés :
    // l'application porte déjà la date d'assurance.
    final depot = _FauxDepot(liste: CheckTemplate(items: [
      point('papiers-assurance', "Attestation d'assurance valide",
          severite: 'blocking',
          preEtat: 'bad',
          preRaison: 'Expirée depuis 12 jours'),
      point('pneus-etat', 'Pression et usure'),
    ]));

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();
    await composer(tester);

    expect(find.text('Expirée depuis 12 jours'), findsOneWidget);
    // Un point sur deux est déjà répondu : le compteur de l'en-tête le dit.
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets("le kilométrage connu est proposé d'emblée", (tester) async {
    final depot = _FauxDepot(liste: CheckTemplate(items: [point('pneus-etat', 'Pneus')]));

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();

    expect(find.text('182000'), findsOneWidget);
  });

  // ── Le contrôle de saison ──────────────────────────────────────

  testWidgets('le choix du type de contrôle vient du serveur', (tester) async {
    // Le libellé du saisonnier dépend de la saison en cours. Découpé des deux
    // côtés, le calendrier finirait par ne plus tomber au même mois.
    final depot = _FauxDepot(
      liste: CheckTemplate(
        items: [point('pneus-etat', 'Pneus')],
        availableReasons: const [
          CheckReasonOption(value: 'trip', label: 'Avant un voyage', hint: 'La liste dépend de la distance.'),
          CheckReasonOption(
            value: 'seasonal',
            label: "Contrôle d'hivernage",
            hint: "L'eau et la boue : ce qui compte est de voir, d'être vu et de tenir la route.",
            season: 'pluies',
          ),
        ],
      ),
    );

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();

    expect(find.text("Contrôle d'hivernage"), findsOneWidget);
    expect(find.textContaining("L'eau et la boue"), findsOneWidget);
  });

  testWidgets("un contrôle de saison ne demande pas de distance", (tester) async {
    // Il ne va nulle part : lui demander « Où vas-tu ? » n'aurait aucun sens,
    // et le bouton ne doit pas attendre une réponse qui ne viendra pas.
    final depot = _FauxDepot(
      liste: CheckTemplate(
        reason: 'seasonal',
        title: "Contrôle d'hivernage",
        items: [point('pluies-pneus', 'Profondeur des rainures', severite: 'blocking')],
        availableReasons: const [
          CheckReasonOption(value: 'trip', label: 'Avant un voyage', hint: ''),
          CheckReasonOption(value: 'seasonal', label: "Contrôle d'hivernage", hint: '', season: 'pluies'),
        ],
      ),
    );

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Contrôle d'hivernage"));
    await tester.pumpAndSettle();

    expect(find.text('Où vas-tu ?'), findsNothing);

    // Sans avoir choisi de distance, le bouton doit être actif.
    await tester.tap(find.text("Voir ce qu'il faut vérifier"));
    await tester.pumpAndSettle();

    expect(find.text('Profondeur des rainures'), findsOneWidget);
    expect(depot.motifsDemandes.last, 'seasonal');
    expect(depot.distancesDemandees.last, isNull);
  });

  testWidgets("le motif part avec l'envoi, et survit au brouillon", (tester) async {
    // Sans lui, un brouillon d'hivernage repris le lendemain repartirait comme
    // un contrôle avant voyage, avec un verdict qui parlerait de partir.
    final liste = CheckTemplate(
      reason: 'seasonal',
      title: "Contrôle d'hivernage",
      items: [point('pluies-pneus', 'Profondeur des rainures')],
      availableReasons: const [
        CheckReasonOption(value: 'trip', label: 'Avant un voyage', hint: ''),
        CheckReasonOption(value: 'seasonal', label: "Contrôle d'hivernage", hint: '', season: 'pluies'),
      ],
    );

    final depot = _FauxDepot(liste: liste);
    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Contrôle d'hivernage"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Voir ce qu'il faut vérifier"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Correct').first);
    await tester.pumpAndSettle();

    // Réouverture : le brouillon doit rendre le contrôle à sa saison.
    final second = _FauxDepot(liste: liste);
    await reouvrir(tester, second);

    expect(second.motifsDemandes.last, 'seasonal',
        reason: 'Le brouillon doit se rouvrir sur le même type de contrôle.');

    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    expect(second.envois.last['reason'], 'seasonal');
    expect(second.envois.last.containsKey('trip_distance_km'), isFalse,
        reason: "Un contrôle de saison ne porte pas de distance.");
  });

  // ── Le verdict ─────────────────────────────────────────────────

  testWidgets('le verdict est celui du serveur, mot pour mot', (tester) async {
    final depot = _FauxDepot(
      liste: CheckTemplate(items: [point('pneus-etat', 'Pneus')]),
      reponse: resultat(
        verdict: 'attention',
        libelle: 'Points à surveiller',
        detail: '1 point à surveiller, rien qui empêche de partir',
        aSurveiller: 1,
        verifies: 1,
      ),
    );

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();
    await composer(tester);

    await tester.tap(find.text('Correct').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    expect(find.text('Points à surveiller'), findsOneWidget);
    expect(find.text('1 point à surveiller, rien qui empêche de partir'),
        findsOneWidget);
  });

  testWidgets("l'écran ne certifie jamais l'état du véhicule", (tester) async {
    // L'application n'a rien constaté : elle a posé une question et recopié une
    // réponse. Ces formulations lui feraient dire le contraire.
    final depot = _FauxDepot(
      liste: CheckTemplate(items: [point('pneus-etat', 'Pneus')]),
      reponse: resultat(detail: 'Rien à signaler sur le point vérifié', verifies: 1),
    );

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();
    await composer(tester);
    await tester.tap(find.text('Correct').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    for (final interdit in ['bon état', 'prêt à partir', 'en règle', 'conforme']) {
      expect(
        find.textContaining(interdit, findRichText: true),
        findsNothing,
        reason: "L'écran ne doit pas dire « $interdit ».",
      );
    }
  });

  testWidgets('ce qui bloque le départ est séparé de ce qui peut attendre',
      (tester) async {
    final depot = _FauxDepot(
      liste: CheckTemplate(items: [
        point('pneus-etat', 'Pneus', severite: 'blocking'),
        point('visibilite', 'Pare-brise'),
      ]),
      reponse: resultat(
        verdict: 'blocked',
        libelle: 'À régler avant de partir',
        detail: '1 point à régler avant de partir',
        bloquants: 1,
        aSurveiller: 1,
        aReprendre: const [
          CheckPointToFix(
            itemCode: 'pneus-etat',
            title: 'Pression et usure des quatre pneus',
            categoryLabel: 'Pneus',
            blocking: true,
            partCategoryId: 12,
          ),
          CheckPointToFix(
            itemCode: 'visibilite',
            title: 'Pare-brise, balais et rétroviseurs',
            categoryLabel: 'Éclairage et visibilité',
            blocking: false,
          ),
        ],
      ),
    );

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();
    await composer(tester);
    await tester.tap(find.text('Défaut').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    expect(find.text('À RÉGLER'), findsOneWidget);
    expect(find.text('PEUT ATTENDRE'), findsOneWidget);
    expect(find.text('Pression et usure des quatre pneus'), findsOneWidget);

    // Un point qui mène à une catégorie de pièces propose de les ouvrir ;
    // l'autre non, et ne doit donc pas afficher un bouton inerte.
    expect(find.text('Voir les pièces'), findsOneWidget);
  });

  // ── Le réseau qui n'est pas là ─────────────────────────────────

  testWidgets("un envoi qui échoue est gardé, puis rejoué avec la même clé",
      (tester) async {
    // C'est le test le plus important du fichier. Sans la mise en attente, un
    // contrôle terminé disparaît sur une coupure de réseau — et le propriétaire
    // ne le refera pas. Sans la clé stable, le rejeu enregistre un second
    // passage et l'historique du véhicule devient faux.
    final liste = CheckTemplate(items: [point('pneus-etat', 'Pneus')]);
    final premier = _FauxDepot(liste: liste, echoueEnvoi: true);

    await tester.pumpWidget(ecran(premier));
    await tester.pumpAndSettle();
    await composer(tester);
    await tester.tap(find.text('Correct').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    expect(premier.envois, hasLength(1));

    // L'échec doit se voir — et dire que rien n'est perdu. Quelqu'un qui croit
    // avoir perdu un quart d'heure de travail ne recommence pas.
    expect(
      find.textContaining('repartira dès que le réseau revient'),
      findsOneWidget,
      reason: "L'échec doit rassurer, pas seulement signaler.",
    );

    // L'écran est fermé, puis réouvert plus tard : l'envoi doit repartir seul.
    final second = _FauxDepot(liste: liste);
    await reouvrir(tester, second);

    expect(second.envois, hasLength(1), reason: "L'envoi doit être rejoué seul.");
    expect(
      second.envois.first['client_reference'],
      premier.envois.first['client_reference'],
      reason: 'Une clé différente ferait enregistrer deux passages.',
    );
    expect(find.text('Rien à signaler'), findsWidgets);

    // Et il ne doit pas repartir une troisième fois.
    final troisieme = _FauxDepot(liste: liste);
    await reouvrir(tester, troisieme);
    expect(troisieme.envois, isEmpty);
  });

  testWidgets("un refus du serveur n'est pas présenté comme une coupure réseau",
      (tester) async {
    // Un 422 ne passera jamais, quel que soit le réseau. Le garder en attente le
    // faisait rejouer à chaque ouverture de l'écran, en promettant chaque fois
    // qu'il finirait par partir.
    final liste = CheckTemplate(items: [point('pneus-etat', 'Pneus')]);
    final premier = _FauxDepot(
      liste: liste,
      refus: ApiException(
        statusCode: 422,
        message: 'refus',
        errors: const {'mileage_km': ['Le kilométrage ne peut pas dépasser 2000000.']},
      ),
    );

    await tester.pumpWidget(ecran(premier));
    await tester.pumpAndSettle();
    await composer(tester);
    await tester.tap(find.text('Correct').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('repartira dès que le réseau revient'),
      findsNothing,
      reason: 'Un refus ne repartira pas : le promettre est un mensonge.',
    );
    expect(find.textContaining("n'a pas été accepté"), findsOneWidget);
    expect(find.textContaining('Corrige la saisie'), findsOneWidget);

    // Et il ne doit pas rester collé en attente.
    final second = _FauxDepot(liste: liste);
    await reouvrir(tester, second);
    expect(second.envois, isEmpty, reason: 'Une charge refusée ne doit pas être rejouée.');
  });

  testWidgets('la clé survit à une relance, pour ne pas enregistrer deux contrôles',
      (tester) async {
    // Si le premier envoi a atteint le serveur sans que la réponse revienne, le
    // passage existe déjà. Une clé neuve au second essai en créerait un second,
    // et c'est précisément ce que la clé est censée empêcher.
    final liste = CheckTemplate(items: [point('pneus-etat', 'Pneus')]);
    final premier = _FauxDepot(liste: liste, echoueEnvoi: true);

    await tester.pumpWidget(ecran(premier));
    await tester.pumpAndSettle();
    await composer(tester);
    await tester.tap(find.text('Correct').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    // Relance : le rejeu automatique échoue encore, puis l'utilisateur termine
    // lui-même une seconde fois.
    final second = _FauxDepot(liste: liste, echoueEnvoi: true);
    await reouvrir(tester, second);
    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    expect(second.envois, hasLength(2));
    for (final envoi in second.envois) {
      expect(
        envoi['client_reference'],
        premier.envois.first['client_reference'],
        reason: 'La clé du contrôle ne doit jamais être régénérée.',
      );
    }
  });

  testWidgets('un envoi trop ancien pour le serveur est abandonné, pas rejoué',
      (tester) async {
    // Le serveur refuse un performed_at de plus de trente jours. Sans
    // péremption côté téléphone, la charge repartait indéfiniment pour se faire
    // refuser chaque fois.
    SharedPreferences.setMockInitialValues({
      'check_pending_1': jsonEncode({
        'client_reference': '3f1c9a2e-5b7d-4e8a-9c1f-2d6b8e4a7c05',
        'performed_at': DateTime.now().toUtc().subtract(const Duration(days: 40)).toIso8601String(),
        'answers': [{'item_code': 'pneus-etat', 'status': 'ok'}],
      }),
    });

    final depot = _FauxDepot(liste: CheckTemplate(items: [point('pneus-etat', 'Pneus')]));
    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();

    expect(depot.envois, isEmpty);
    expect(await const CheckDraftStore().lireEnAttente(1), isNull);
  });

  testWidgets('un verdict atteint par un renvoi dit autant que les autres',
      (tester) async {
    // Le même contrôle ne doit pas annoncer moins de choses selon le chemin.
    // Atteint par un renvoi, le verdict n'a pas de liste recomposée sous la
    // main : le nombre de points se relit dans le brouillon.
    SharedPreferences.setMockInitialValues({
      'check_draft_1': jsonEncode({
        'trip_distance_km': 400,
        'answers': {'pneus-etat': 'ok'},
        'client_reference': '3f1c9a2e-5b7d-4e8a-9c1f-2d6b8e4a7c05',
        'items_count': 5,
        'saved_at': DateTime.now().toIso8601String(),
      }),
      'check_pending_1': jsonEncode({
        'client_reference': '3f1c9a2e-5b7d-4e8a-9c1f-2d6b8e4a7c05',
        'performed_at': DateTime.now().toUtc().toIso8601String(),
        'answers': [{'item_code': 'pneus-etat', 'status': 'ok'}],
      }),
    });

    final depot = _FauxDepot(
      liste: CheckTemplate(items: [point('pneus-etat', 'Pneus')]),
      reponse: resultat(detail: 'Rien à signaler sur le point vérifié', verifies: 1),
    );

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();

    expect(depot.envois, hasLength(1));
    expect(find.textContaining("4 points n'ont pas été vérifiés"), findsOneWidget);
  });

  testWidgets("l'échec d'envoi se voit en tête de liste, pas après le dernier point",
      (tester) async {
    // Rendu en fin de ListView, le message n'était jamais à l'écran sur une
    // liste de quinze points : l'échec passait inaperçu.
    final depot = _FauxDepot(
      liste: CheckTemplate(items: [
        for (var i = 0; i < 12; i++) point('point-$i', 'Point numéro $i'),
      ]),
      echoueEnvoi: true,
    );

    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();
    await composer(tester);
    await tester.tap(find.text('Correct').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    // Sans défilement : le message doit déjà être rendu.
    expect(find.textContaining('Envoi impossible pour le moment'), findsOneWidget);
  });

  testWidgets('les réponses déjà données survivent à la fermeture de l\'écran',
      (tester) async {
    // On coche quatre points, on va chercher le cric, on revient dix minutes
    // plus tard. Perdre les quatre réponses suffit à ce qu'il n'y ait pas de
    // deuxième contrôle.
    final liste = CheckTemplate(items: [
      point('pneus-etat', 'Pneus'),
      point('freins', 'Freins'),
    ]);

    await tester.pumpWidget(ecran(_FauxDepot(liste: liste)));
    await tester.pumpAndSettle();
    await composer(tester);
    await tester.tap(find.text('Défaut').first);
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);

    await reouvrir(tester, _FauxDepot(liste: liste));

    // La liste est recomposée seule, et la réponse est retrouvée.
    expect(find.text('1/2'), findsOneWidget);
  });

  // ── Le magasin de brouillons ───────────────────────────────────

  group('Brouillon', () {
    test('un brouillon périmé est jeté plutôt que repris', () async {
      // Deux jours plus tard, le kilométrage a bougé et l'assurance a peut-être
      // été renouvelée : reprendre le brouillon enregistrerait un constat
      // périmé comme s'il était d'aujourd'hui.
      const magasin = CheckDraftStore();

      await magasin.enregistrerBrouillon(
        1,
        CheckDraft(
          answers: const {'pneus-etat': 'bad'},
          savedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      );

      expect(await magasin.lireBrouillon(1), isNull);
    });

    test('un brouillon récent est repris', () async {
      const magasin = CheckDraftStore();

      await magasin.enregistrerBrouillon(
        1,
        CheckDraft(
          tripDistanceKm: 400,
          answers: const {'pneus-etat': 'bad'},
          savedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      );

      final repris = await magasin.lireBrouillon(1);
      expect(repris?.answers, {'pneus-etat': 'bad'});
      expect(repris?.tripDistanceKm, 400);
    });

    test('une valeur illisible ne fait pas planter l\'écran', () async {
      // Le format peut changer d'une version de l'application à l'autre. Un
      // brouillon d'une version précédente ferait planter à l'ouverture
      // l'écran censé être le plus robuste de l'application.
      SharedPreferences.setMockInitialValues({
        'check_draft_1': 'ceci n\'est pas du JSON',
        'check_pending_1': '[1, 2, 3]',
      });

      const magasin = CheckDraftStore();

      expect(await magasin.lireBrouillon(1), isNull);
      expect(await magasin.lireEnAttente(1), isNull);
    });

    test('chaque véhicule a son propre brouillon', () async {
      const magasin = CheckDraftStore();

      await magasin.enregistrerBrouillon(
        1,
        CheckDraft(answers: const {'pneus-etat': 'ok'}, savedAt: DateTime.now()),
      );

      expect(await magasin.lireBrouillon(2), isNull);
      expect((await magasin.lireBrouillon(1))?.answers, {'pneus-etat': 'ok'});
    });
  });

  // ── Le résumé porté par la fiche du garage ─────────────────────

  group('Dernier contrôle', () {
    test('la fiche du véhicule porte le résumé du dernier contrôle', () {
      final v = OwnedVehicle.fromJson({
        'id': 1,
        'designation': 'Toyota Hilux 2013',
        'brand_id': 1,
        'vehicle_model_id': 1,
        'year': 2013,
        'identity': <String, dynamic>{},
        'compatibility_ready': true,
        'last_check': {
          'id': 7,
          'performed_at': '2026-09-28T08:00:00+00:00',
          'verdict': 'blocked',
          'verdict_label': 'À régler avant de partir',
          'blocking_count': 1,
          'watch_count': 2,
        },
      });

      expect(v.lastCheck?.bloque, isTrue);
      expect(v.lastCheck?.aReprendre, 3);
    });

    test('un véhicule jamais contrôlé ne promet rien', () {
      final v = OwnedVehicle.fromJson({
        'id': 1,
        'designation': 'Toyota Hilux 2013',
        'brand_id': 1,
        'vehicle_model_id': 1,
        'year': 2013,
        'identity': <String, dynamic>{},
        'compatibility_ready': true,
        'last_check': null,
      });

      expect(v.lastCheck, isNull);
    });
  });
}

/// Dépôt qui répond depuis un scénario en mémoire et retient ce qu'on lui envoie.
class _FauxDepot extends GarageRepository {
  _FauxDepot({
    required this.liste,
    VehicleCheck? reponse,
    this.echoueEnvoi = false,
    this.refus,
  })  : parDistanceKm = const {},
        reponse = reponse ??
            VehicleCheck(
              id: 7,
              ownedVehicleId: 1,
              mileageKm: 182400,
              verdict: const CheckVerdict(
                value: 'clear',
                label: 'Rien à signaler',
                detail: 'Rien à signaler sur le point vérifié',
              ),
              blockingCount: 0,
              watchCount: 0,
              checkedCount: 1,
            ),
        super(ApiClient());

  /// Un dépôt qui compose une liste différente selon la distance demandée.
  _FauxDepot.parDistance(Map<int, CheckTemplate> listes)
      : liste = listes.values.first,
        parDistanceKm = listes,
        reponse = VehicleCheck(
          id: 7,
          ownedVehicleId: 1,
          verdict: const CheckVerdict(value: 'clear', label: 'Rien à signaler', detail: ''),
          blockingCount: 0,
          watchCount: 0,
          checkedCount: 1,
        ),
        echoueEnvoi = false,
        refus = null,
        super(ApiClient());

  final CheckTemplate liste;
  final Map<int, CheckTemplate> parDistanceKm;
  final VehicleCheck reponse;
  final bool echoueEnvoi;

  /// Un refus du serveur, par opposition a une panne de transport.
  final ApiException? refus;

  final List<Map<String, dynamic>> envois = [];
  final List<int?> distancesDemandees = [];
  final List<String> motifsDemandes = [];

  @override
  Future<CheckTemplate> checkTemplate(
    int ownedVehicleId, {
    int? tripDistanceKm,
    String reason = 'trip',
  }) async {
    distancesDemandees.add(tripDistanceKm);
    motifsDemandes.add(reason);
    return parDistanceKm[tripDistanceKm] ?? liste;
  }

  @override
  Future<VehicleCheck> submitCheck(int ownedVehicleId, Map<String, dynamic> payload) async {
    envois.add(payload);
    if (refus != null) throw refus!;
    if (echoueEnvoi) throw Exception('hors ligne');
    return reponse;
  }

  /// Le rafraîchissement du garage suit un envoi réussi : sans cette réponse,
  /// il partirait sur le réseau.
  @override
  Future<List<OwnedVehicle>> getVehicles() async => const [];
}
