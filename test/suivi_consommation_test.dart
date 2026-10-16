import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/garage/data/models/fuel_fill.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/pages/fuel_fills_page.dart';
import 'package:auto/features/garage/presentation/providers/fuel_fills_provider.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/garage/presentation/widgets/consumption_tile.dart';
import 'package:auto/features/garage/presentation/widgets/fuel_fill_dialog.dart';
import 'package:auto/features/notifications/data/models/app_notification.dart';
import 'package:auto/features/notifications/presentation/pages/notifications_page.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Le suivi carburant : ce que le serveur envoie, et ce que l'écran en fait.
///
/// Deux couches, et l'ordre compte. La première est la lecture de la charge
/// utile, parce qu'une tuile juste posée sur un modèle qui ne sait pas lire la
/// réponse réelle ne prouve rien : Laravel sérialise les colonnes `decimal` en
/// CHAÎNES — « 8.40 », pas 8.4 — et c'est l'incident cité en tête de
/// `api_contract_test.dart`, qui avait fait remonter
/// `type 'String' is not a subtype of type 'num?'` sur le catalogue entier.
/// Les mêmes champs arrivent en nombres dès qu'un agrégat est arrondi par PHP,
/// d'où les deux formes vérifiées côte à côte.
///
/// Tout le reste est monté en 320 points de large, aux échelles de texte 1,0 et 1,3, et
/// sous la police du banc d'essai dont chaque caractère est un carré du corps
/// — près du double de la largeur réelle. C'est le pire cas que
/// `responsive_test.dart` a posé pour le reste de l'application, et il a déjà
/// servi ici : la rangée « Passage à la pompe / Historique » de la tuile
/// débordait en `Row`, bande rayée par-dessus le bouton. Elle est en `Wrap`
/// depuis.
///
/// Les tests vérifient ensuite les deux décisions qui rendent le chiffre juste
/// ou faux :
///   — le formulaire part sur DEMI-PLEIN, jamais sur plein. Un demi-plein
///     déclaré plein ferme un intervalle sur un niveau de réservoir inconnu,
///     et la consommation affichée devient fausse sans que rien ne le signale ;
///   — les litres se déduisent du montant et du prix, parce qu'ici on achète
///     pour un montant et que personne ne relève des litres à la pompe.
void main() {
  // ── La charge utile, telle que le serveur l'envoie ───────────────────────

  group('Lecture d\'un passage', () {
    /// La forme réelle : `litres` et `price_per_litre` sont des colonnes
    /// `decimal`, et Laravel les rend entre guillemets. Un `as num?` ici
    /// faisait tomber l'écran entier, pas la ligne fautive.
    test('les décimaux en chaînes sont lus', () {
      final passage = FuelFill.fromJson(const {
        'id': 4,
        'is_full': true,
        'filled_at': '2026-10-12',
        'mileage_km': 97400,
        'litres': '41.20',
        'amount_fcfa': 30000,
        'price_per_litre': '728.95',
        'note': null,
        'created_at': '2026-10-16T17:42:31+00:00',
        'l_100km': '8.40',
        'distance_km': '2400',
        'retenu': true,
        'motif_ecart': null,
      });

      expect(passage.litres, closeTo(41.2, 0.001));
      expect(passage.pricePerLitre, closeTo(728.95, 0.001));
      expect(passage.l100km, closeTo(8.4, 0.001));
      expect(passage.distanceKm, closeTo(2400, 0.001));
      expect(passage.isFull, isTrue);
      expect(passage.retenu, isTrue);
      expect(passage.filledAt, DateTime(2026, 10, 12));
    });

    test('les mêmes champs en nombres sont lus pareillement', () {
      final passage = FuelFill.fromJson(const {
        'id': 4,
        'is_full': true,
        'mileage_km': 97400,
        'litres': 41.2,
        'amount_fcfa': 30000,
        'price_per_litre': 728.95,
        'l_100km': 8.4,
        'distance_km': 2400,
        'retenu': true,
      });

      expect(passage.litres, closeTo(41.2, 0.001));
      expect(passage.pricePerLitre, closeTo(728.95, 0.001));
      expect(passage.l100km, closeTo(8.4, 0.001));
      expect(passage.distanceKm, closeTo(2400, 0.001));
    });

    /// Un `tinyint(1)` non casté remonte en 0/1. Un faux `false` ferait passer
    /// un plein pour un demi-plein : l'intervalle serait perdu, le chiffre
    /// affiché reposerait sur moins de mesures, et rien ne le dirait.
    test('is_full tient le 0/1 d\'un tinyint non casté', () {
      bool lu(Object? brut) => FuelFill.fromJson({
            'id': 1,
            'is_full': brut,
            'mileage_km': 95000,
            'litres': '40.00',
          }).isFull;

      expect(lu(1), isTrue);
      expect(lu(0), isFalse);
      expect(lu('true'), isTrue);
      expect(lu(true), isTrue);
      expect(lu(false), isFalse);
    });

    /// Un demi-plein ne ferme pas d'intervalle : les quatre champs de mesure
    /// arrivent nuls, et le modèle doit s'en accommoder sans les inventer.
    test('un demi-plein arrive sans mesure et n\'en invente pas', () {
      final passage = FuelFill.fromJson(const {
        'id': 2,
        'is_full': false,
        'mileage_km': 95100,
        'litres': '10.00',
        'l_100km': null,
        'distance_km': null,
        'retenu': false,
        'motif_ecart': null,
      });

      expect(passage.l100km, isNull);
      expect(passage.porteUneMesure, isFalse);
      expect(passage.motifLibelle, isNull);
      expect(passage.bornesIntervalles, 0);
    });

    /// Ce que la suppression détruira, et la confirmation l'annonce. Un plein
    /// au milieu de la série borne DEUX intervalles retenus : il ferme celui
    /// d'avant et ouvre celui d'après.
    test('le nombre d\'intervalles bornés se lit', () {
      int bornees(Map<String, dynamic> extra) => FuelFill.fromJson({
            'id': 3,
            'is_full': true,
            'mileage_km': 90600,
            'litres': '48.00',
            ...extra,
          }).bornesIntervalles;

      expect(bornees({'bornes_intervalles': 2, 'retenu': true}), 2);
      expect(bornees({'bornes_intervalles': 1, 'retenu': true}), 1);
      expect(bornees({'bornes_intervalles': 0, 'retenu': false}), 0);
      // Un agrégat peut remonter en chaîne, comme partout ailleurs dans cette
      // réponse.
      expect(bornees({'bornes_intervalles': '2', 'retenu': true}), 2);
    });

    /// Serveur d'avant le déploiement : la clé manque. On retombe sur ce que
    /// la ligne sait d'elle-même, et ce repli SOUS-estime toujours — il
    /// n'annonce jamais une destruction qui n'aura pas lieu.
    test('sans la clé, les intervalles bornés se replient sur « retenu »', () {
      int bornees(bool retenu) => FuelFill.fromJson({
            'id': 3,
            'is_full': true,
            'mileage_km': 90600,
            'litres': '48.00',
            'retenu': retenu,
          }).bornesIntervalles;

      expect(bornees(true), 1);
      expect(bornees(false), 0);
    });

    test('chaque motif d\'écart a sa phrase', () {
      String? phrase(String? motif) => FuelFill.fromJson({
            'id': 1,
            'is_full': true,
            'mileage_km': 95000,
            'litres': '40.00',
            'motif_ecart': motif,
          }).motifLibelle;

      expect(phrase('trop_long'), isNotNull);
      expect(phrase('invraisemblable'), isNotNull);
      // Le motif de la seconde passe du serveur : un intervalle sous 60 % de
      // la médiane du véhicule. Sa phrase doit dire la cause — un passage non
      // saisi — et non le chiffre, parce que 4,0 l/100 km sur une voiture qui
      // en fait 8,0 se lit comme une bonne nouvelle.
      expect(phrase('anormalement_bas'), isNotNull);
      expect(phrase('anormalement_bas'),
          contains('n\'a pas été enregistré'));
      // Disparu du serveur : en dessous de 50 km l'intervalle se prolonge au
      // lieu d'être écarté, donc plus aucun passage ne peut porter ce motif.
      // Un libellé laissé derrière finirait par être cité dans une revue comme
      // une règle encore appliquée.
      expect(phrase('trop_court'), isNull);
      expect(phrase(null), isNull);
      // Un motif que cette version de l'application ne connaît pas encore ne
      // doit pas faire tomber la ligne : elle se tait.
      expect(phrase('motif_a_venir'), isNull);
    });
  });

  group('Lecture du suivi', () {
    test('les décimaux en chaînes sont lus', () {
      final suivi = FuelTracking.fromJson(const {
        'l_100km': '8.40',
        'fcfa_100km': '6800.00',
        'based_on_fills': 5,
        'total_fills': 11,
        'full_fills': 6,
        'excluded_intervals': 1,
        'last_filled_at': '2026-10-12',
        'last_mileage_km': 97400,
        'baseline_l_100km': '7.10',
        'abnormal': false,
        'totals': {
          'litres': '182.40',
          'amount_fcfa': '133000',
          'distance_km': '2310',
        },
      });

      expect(suivi.l100km, closeTo(8.4, 0.001));
      expect(suivi.fcfa100km, closeTo(6800, 0.001));
      expect(suivi.baselineL100km, closeTo(7.1, 0.001));
      expect(suivi.totals.litres, closeTo(182.4, 0.001));
      expect(suivi.totals.amountFcfa, 133000);
      expect(suivi.totals.distanceKm, 2310);
      expect(suivi.aUnChiffre, isTrue);
      expect(suivi.vide, isFalse);
    });

    test('les mêmes champs en nombres sont lus pareillement', () {
      final suivi = FuelTracking.fromJson(const {
        'l_100km': 8.4,
        'fcfa_100km': 6800,
        'based_on_fills': 5,
        'total_fills': 11,
        'full_fills': 6,
        'excluded_intervals': 1,
        'baseline_l_100km': 7.1,
        'abnormal': true,
        'totals': {'litres': 182.4, 'amount_fcfa': 133000, 'distance_km': 2310},
      });

      expect(suivi.l100km, closeTo(8.4, 0.001));
      expect(suivi.fcfa100km, closeTo(6800, 0.001));
      expect(suivi.baselineL100km, closeTo(7.1, 0.001));
      expect(suivi.totals.litres, closeTo(182.4, 0.001));
      expect(suivi.abnormal, isTrue);
    });

    /// Aucun passage saisi : les compteurs sont à zéro et les chiffres nuls,
    /// mais la clé est là. C'est ce qui sépare « aucun passage » de « pas
    /// demandé », et les deux ne mènent pas au même écran.
    test('un suivi vide se distingue d\'une clé absente', () {
      final vide = FuelTracking.fromJson(const {
        'l_100km': null,
        'fcfa_100km': null,
        'based_on_fills': 0,
        'total_fills': 0,
        'full_fills': 0,
        'excluded_intervals': 0,
        'last_filled_at': null,
        'last_mileage_km': null,
        'baseline_l_100km': null,
        'abnormal': false,
        'totals': {'litres': 0, 'amount_fcfa': 0, 'distance_km': 0},
      });

      expect(vide.vide, isTrue);
      expect(vide.aUnChiffre, isFalse);
      expect(vide.totals.distanceKm, 0);
      expect(vide.alerteL100km, isNull);
      expect(vide.seriesRompue, isFalse);
    });

    /// Les deux grandeurs ne sont pas la même et le modèle doit les tenir
    /// séparées : `l_100km` porte les cinq derniers intervalles, le verdict se
    /// prend sur les DEUX derniers. Série 8 8 8 8 3,1 3,1 11 11 — référence
    /// 8,0, verdict vrai, moyenne publiée 7,2, verdict 11,0.
    test('le taux du verdict se lit à part de celui qui s\'affiche', () {
      final suivi = FuelTracking.fromJson(const {
        'l_100km': '7.20',
        'based_on_fills': 5,
        'total_fills': 9,
        'full_fills': 9,
        'baseline_l_100km': '8.00',
        'abnormal': true,
        'alerte_l_100km': '11.00',
        'series_rompue': false,
      });

      expect(suivi.l100km, closeTo(7.2, 0.001));
      expect(suivi.alerteL100km, closeTo(11.0, 0.001));
      expect(suivi.seriesRompue, isFalse);
    });

    /// `series_rompue` arrive en booléen JSON, mais rien n'interdit à une
    /// couche intermédiaire de le rendre en 0/1 : un faux `false` tairait la
    /// seule explication de la chute du nombre d'intervalles.
    test('la série rompue se lit, booléen comme tinyint', () {
      bool lu(Object? brut) => FuelTracking.fromJson({
            'total_fills': 11,
            'series_rompue': brut,
          }).seriesRompue;

      expect(lu(true), isTrue);
      expect(lu(1), isTrue);
      expect(lu(false), isFalse);
      expect(lu(0), isFalse);
      expect(lu(null), isFalse);
    });
  });

  group('Lecture d\'un véhicule du garage', () {
    Map<String, dynamic> brut() => {
          'id': 1,
          'designation': 'Toyota Camry 2013',
          'nickname': null,
          'brand_id': 1,
          'vehicle_model_id': 7,
          'year': 2013,
          'mileage_km': 97400,
          'identity': {'brand': 'Toyota', 'model': 'Camry'},
          'compatibility_ready': true,
          'deadlines': <dynamic>[],
        };

    /// Le serveur d'avant le déploiement ne connaît pas la clé. L'application
    /// est publiée sur les téléphones avant que l'API ne soit en ligne : si
    /// son absence levait, le garage entier deviendrait illisible le temps du
    /// déploiement.
    test('sans clé fuel_tracking, le véhicule se lit quand même', () {
      final v = OwnedVehicle.fromJson(brut());

      expect(v.fuelTracking, isNull);
      expect(v.mileageKm, 97400);
    });

    test('avec la clé, le suivi est rattaché au véhicule', () {
      final v = OwnedVehicle.fromJson({
        ...brut(),
        'fuel_tracking': {
          'l_100km': '8.40',
          'based_on_fills': 5,
          'total_fills': 11,
          'full_fills': 6,
          'excluded_intervals': 1,
          'abnormal': false,
          'totals': {
            'litres': '182.40',
            'amount_fcfa': 133000,
            'distance_km': 2310,
          },
        },
      });

      expect(v.fuelTracking, isNotNull);
      expect(v.fuelTracking!.l100km, closeTo(8.4, 0.001));
      expect(v.fuelTracking!.totals.litres, closeTo(182.4, 0.001));
    });
  });

  // ── Jeu d'essai ──────────────────────────────────────────────────────────

  final vehicule = OwnedVehicle(
    id: 1,
    designation: 'Toyota Camry 2013',
    brandId: 1,
    vehicleModelId: 7,
    year: 2013,
    mileageKm: 97400,
    identity: const OwnedVehicleIdentity(brand: 'Toyota', model: 'Camry'),
    compatibilityReady: true,
    consumption: const VehicleConsumption(
      label: '2,5 l 4 cyl. boîte auto. 6',
      combinedL100km: 8.2,
      source: 'Ressources naturelles Canada',
      cycle: 'essai canadien, cinq cycles',
    ),
  );

  OwnedVehicle avecSuivi(FuelTracking? suivi) => OwnedVehicle(
        id: vehicule.id,
        designation: vehicule.designation,
        brandId: vehicule.brandId,
        vehicleModelId: vehicule.vehicleModelId,
        year: vehicule.year,
        mileageKm: vehicule.mileageKm,
        identity: vehicule.identity,
        compatibilityReady: true,
        consumption: vehicule.consumption,
        fuelTracking: suivi,
      );

  const tailles = [1.0, 1.3];

  Future<void> monter(WidgetTester t, Widget enfant, double echelle,
      {List<Override> overrides = const []}) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(echelle)),
          child: enfant,
        ),
      ),
    ));
  }

  // ── La tuile, ses quatre états ───────────────────────────────────────────

  group('Tuile de consommation', () {
    for (final echelle in tailles) {
      testWidgets('le chiffre mesuré passe devant la cote, x$echelle',
          (tester) async {
        await monter(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: ConsumptionTile(
                vehicle: avecSuivi(const FuelTracking(
                  l100km: 8.4,
                  fcfa100km: 6800,
                  basedOnFills: 5,
                  totalFills: 11,
                  fullFills: 6,
                  totals: FuelTotals(
                      litres: 182.4, amountFcfa: 133000, distanceKm: 2310),
                )),
              ),
            ),
          ),
          echelle,
        );

        expect(find.textContaining('8,4 l/100 km'), findsOneWidget);
        expect(find.textContaining('6 800 FCFA/100 km'), findsOneWidget);
        // La cote d'homologation reste, mais comme repère.
        expect(find.textContaining('Cote constructeur 8,2'), findsOneWidget);
      });

      testWidgets('sans intervalle retenu, des faits bruts et non une moyenne, '
          'x$echelle', (tester) async {
        await monter(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: ConsumptionTile(
                vehicle: avecSuivi(const FuelTracking(
                  totalFills: 4,
                  totals: FuelTotals(
                      litres: 82.4, amountFcfa: 60000, distanceKm: 910),
                )),
              ),
            ),
          ),
          echelle,
        );

        expect(find.textContaining('82,4 l'), findsOneWidget);
        expect(find.textContaining('910 km'), findsOneWidget);
        // Aucun taux tiré de ces totaux : l'écart de niveau entre le premier
        // et le dernier passage le fausserait d'une capacité de réservoir que
        // nous ne connaissons pas.
        expect(find.textContaining('82,4 l/100'), findsNothing);
        expect(find.textContaining('moyenne'), findsNothing);
        expect(find.textContaining('Deux pleins'), findsOneWidget);
      });

      testWidgets('aucun passage : l\'invitation, x$echelle', (tester) async {
        await monter(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: ConsumptionTile(vehicle: avecSuivi(const FuelTracking())),
            ),
          ),
          echelle,
        );

        expect(find.text('Suivre ma consommation'), findsOneWidget);
        expect(find.textContaining('Historique'), findsNothing);
      });

      testWidgets('anomalie : dite, et suivie de quoi faire, x$echelle',
          (tester) async {
        await monter(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: ConsumptionTile(
                vehicle: avecSuivi(const FuelTracking(
                  l100km: 10.9,
                  basedOnFills: 5,
                  totalFills: 14,
                  fullFills: 9,
                  baselineL100km: 7.1,
                  abnormal: true,
                  alerteL100km: 10.9,
                )),
              ),
            ),
          ),
          echelle,
        );

        expect(find.textContaining('10,9 l/100 km contre 7,1'), findsOneWidget);
        expect(find.textContaining('Filtre à air'), findsOneWidget);
        expect(find.text('Voir les pièces'), findsOneWidget);
      });
    }

    /// L'encart opposait `l_100km` à `baseline_l_100km`, deux grandeurs
    /// différentes : la première est la moyenne des CINQ derniers intervalles,
    /// le verdict se prend sur les DEUX derniers. Série mesurée
    /// 8 8 8 8 3,1 3,1 11 11 — référence 8,0, verdict vrai, moyenne publiée
    /// 7,2, taux du verdict 11,0. L'encart écrivait « 7,2 l/100 km contre 8,0
    /// d'habitude » sous le titre « Votre consommation a augmenté » : il
    /// annonçait une BAISSE en criant à la hausse, et le propriétaire ne
    /// pouvait qu'en conclure que l'application se trompe.
    testWidgets('l\'encart cite le chiffre du verdict, pas la moyenne',
        (tester) async {
      await monter(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ConsumptionTile(
              vehicle: avecSuivi(const FuelTracking(
                l100km: 7.2,
                basedOnFills: 5,
                totalFills: 9,
                fullFills: 9,
                baselineL100km: 8.0,
                abnormal: true,
                alerteL100km: 11.0,
              )),
            ),
          ),
        ),
        1.0,
      );

      expect(find.textContaining('11,0 l/100 km contre 8,0'), findsOneWidget);
      expect(find.textContaining('7,2 l/100 km contre'), findsNothing);
      // 7,2 reste le chiffre de la tuile, en gros, au-dessous de l'encart :
      // c'est bien la moyenne des cinq derniers intervalles. Les deux
      // coexistent, ils ne répondent pas à la même question.
      expect(find.text('7,2 l/100 km'), findsOneWidget);
    });

    /// Un serveur qui annonce l'anomalie sans donner le taux du verdict : on
    /// dit la hausse sans l'illustrer, plutôt que de l'illustrer avec la
    /// moyenne — c'est exactement le chiffre qui contredisait le titre.
    testWidgets('sans taux de verdict, l\'encart ne cite aucun chiffre',
        (tester) async {
      await monter(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ConsumptionTile(
              vehicle: avecSuivi(const FuelTracking(
                l100km: 7.2,
                basedOnFills: 5,
                totalFills: 9,
                fullFills: 9,
                baselineL100km: 8.0,
                abnormal: true,
              )),
            ),
          ),
        ),
        1.0,
      );

      expect(find.text('Votre consommation a augmenté.'), findsOneWidget);
      expect(find.textContaining('contre 8,0'), findsNothing);
    });

    /// Compteur remplacé : le serveur ne calcule plus que la série récente.
    /// 7 pleins à 11,0 depuis 200 000 km puis 4 pleins réels à 7,0 depuis
    /// 1 800 — « mesuré sur 3 intervalles » là où la tuile en annonçait 9 la
    /// veille. Sans cette ligne, la chute n'a qu'une lecture possible : des
    /// saisies perdues.
    testWidgets('le compteur remplacé est dit en une ligne', (tester) async {
      await monter(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ConsumptionTile(
              vehicle: avecSuivi(const FuelTracking(
                l100km: 7.0,
                basedOnFills: 3,
                totalFills: 11,
                fullFills: 11,
                seriesRompue: true,
                totals: FuelTotals(
                    litres: 420.0, amountFcfa: 300000, distanceKm: 1800),
              )),
            ),
          ),
        ),
        1.0,
      );

      expect(find.textContaining('Compteur remplacé'), findsOneWidget);
      expect(find.textContaining('n\'entrent plus dans ce calcul'),
          findsOneWidget);
    });

    /// La ligne ne s'invite pas sur un véhicule au compteur continu : elle
    /// inquiéterait sans raison, et elle est le genre de mention qu'on cesse
    /// de lire si elle est toujours là.
    testWidgets('sans compteur remplacé, aucune mention', (tester) async {
      await monter(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ConsumptionTile(
              vehicle: avecSuivi(const FuelTracking(
                l100km: 8.4,
                basedOnFills: 5,
                totalFills: 11,
                fullFills: 6,
              )),
            ),
          ),
        ),
        1.0,
      );

      expect(find.textContaining('Compteur remplacé'), findsNothing);
    });

    /// Le chemin complet, de la réponse du serveur au texte affiché : une
    /// charge utile où les décimaux sont des chaînes, et un écran qui écrit
    /// « 8,4 ». Le point décimal est la marque d'un chiffre recopié d'un JSON
    /// sans passer par la mise en forme — ici, personne n'écrit « 8.4 ».
    testWidgets('le chiffre s\'écrit à la virgule, depuis une charge réelle',
        (tester) async {
      final v = OwnedVehicle.fromJson({
        'id': 1,
        'designation': 'Toyota Camry 2013',
        'brand_id': 1,
        'vehicle_model_id': 7,
        'year': 2013,
        'mileage_km': 97400,
        'identity': {'brand': 'Toyota', 'model': 'Camry'},
        'compatibility_ready': true,
        'consumption': {
          'label': '2,5 l 4 cyl. boîte auto. 6',
          'combined_l_100km': '8.20',
          'source': 'Ressources naturelles Canada',
          'cycle': 'essai canadien, cinq cycles',
        },
        'fuel_tracking': {
          'l_100km': '8.40',
          'fcfa_100km': '6800.00',
          'based_on_fills': 5,
          'total_fills': 11,
          'full_fills': 6,
          'excluded_intervals': 0,
          'abnormal': false,
          'totals': {
            'litres': '182.40',
            'amount_fcfa': 133000,
            'distance_km': 2310,
          },
        },
        'deadlines': <dynamic>[],
      });

      await monter(
        tester,
        Scaffold(body: SingleChildScrollView(child: ConsumptionTile(vehicle: v))),
        1.0,
      );

      expect(find.textContaining('8,4 l/100 km'), findsOneWidget);
      expect(find.textContaining('Cote constructeur 8,2'), findsOneWidget);
      expect(find.textContaining('8.4'), findsNothing);
      expect(find.textContaining('8.2'), findsNothing);
    });

    testWidgets('serveur sans fuel_tracking : l\'ancienne tuile, intacte',
        (tester) async {
      await monter(tester, Scaffold(body: ConsumptionTile(vehicle: vehicule)),
          1.0);

      // Pas d'invitation à saisir un passage vers une route que ce serveur
      // ne connaît pas.
      expect(find.textContaining('Passage à la pompe'), findsNothing);
      expect(find.textContaining('8,2 l/100 km'), findsOneWidget);
    });
  });

  // ── La saisie ────────────────────────────────────────────────────────────

  group('Saisie d\'un passage', () {
    for (final echelle in tailles) {
      testWidgets('demi-plein par défaut, litres déduits, x$echelle',
          (tester) async {
        await monter(
          tester,
          Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showFuelFillDialog(ctx, vehicule),
                child: const Text('ouvrir'),
              ),
            ),
          ),
          echelle,
          overrides: [fuelFillsProvider.overrideWith(_PassagesFictifs.new)],
        );

        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();

        // Le compteur du véhicule est déjà là : on ne le retape pas debout
        // devant la pompe.
        expect(find.widgetWithText(TextField, '97400'), findsOneWidget);

        await tester.enterText(
            find.widgetWithText(TextField, 'Montant payé'), '10000');
        await tester.enterText(
            find.widgetWithText(TextField, 'Prix au litre'), '730');
        await tester.pumpAndSettle();

        // 10 000 / 730 = 13,70 l, affiché avant de valider.
        expect(find.textContaining('13,7 l'), findsOneWidget);

        final choix = tester
            .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>));
        expect(choix.selected, {false},
            reason: 'Un demi-plein pris pour un plein rend le chiffre FAUX ; '
                'un plein pris pour un demi-plein ne coûte qu\'une mesure.');

        // Les litres restent saisissables, sans être un quatrième champ
        // permanent.
        await tester.tap(find.text('Je connais les litres'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextField, 'Litres pris'), findsOneWidget);
      });
    }
  });

  // ── La charge utile qui part réellement ──────────────────────────────────

  /// Trois défauts de la boîte de saisie ne se voyaient pas à l'écran : ils ne
  /// se voient que dans ce qui part au serveur. D'où ce bloc, qui capte la
  /// charge utile au lieu de lire des libellés.
  group('Charge utile d\'un passage', () {
    setUp(_PassagesCaptes.envois.clear);

    Future<void> ouvrir(WidgetTester tester) async {
      await monter(
        tester,
        Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showFuelFillDialog(ctx, vehicule),
              child: const Text('ouvrir'),
            ),
          ),
        ),
        1.0,
        overrides: [fuelFillsProvider.overrideWith(_PassagesCaptes.new)],
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
    }

    /// Les deux champs du mode « montant » restent garnis quand on bascule :
    /// ils sont masqués, pas vidés. Ils partaient quand même.
    ///
    /// Le scénario : 10 000 FCFA et 730 FCFA/l tapés, puis bascule et 40
    /// litres saisis. La charge partait avec litres=40, amount_fcfa=10000 et
    /// price_per_litre=730 — or 40 l à 730 F font 29 200 F. Le coût aux 100 km
    /// sortait divisé par près de trois, sans aucune alerte, chaque champ
    /// étant individuellement valide.
    testWidgets('basculer de mode n\'emporte pas les chiffres de l\'autre',
        (tester) async {
      await ouvrir(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Montant payé'), '10000');
      await tester.enterText(
          find.widgetWithText(TextField, 'Prix au litre'), '730');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Je connais les litres'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Litres pris'), '40');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final envoi = _PassagesCaptes.envois.single;
      expect(envoi['litres'], 40.0);
      expect(envoi.containsKey('amount_fcfa'), isFalse,
          reason: 'Un montant du mode abandonné rend le coût aux 100 km faux '
              'sans rien déclencher.');
      expect(envoi.containsKey('price_per_litre'), isFalse);
    });

    /// Le téléphone est le seul à connaître le fuseau du propriétaire ; le
    /// serveur tourne en UTC. Sans ce champ la colonne reste NULL et la ligne
    /// de l'historique s'affiche sans date.
    testWidgets('la date du jour part avec la saisie', (tester) async {
      await ouvrir(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Montant payé'), '10000');
      await tester.enterText(
          find.widgetWithText(TextField, 'Prix au litre'), '730');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final jour = DateTime.now();
      expect(
        _PassagesCaptes.envois.single['filled_at'],
        '${jour.year.toString().padLeft(4, '0')}-'
        '${jour.month.toString().padLeft(2, '0')}-'
        '${jour.day.toString().padLeft(2, '0')}',
      );
    });

    /// LE rejeu réellement vécu à la station : faute de réponse, le
    /// propriétaire ferme la boîte, la rouvre et ressaisit. La clé vivait dans
    /// l'état de la boîte et mourait avec elle — la seconde saisie en obtenait
    /// une autre, le serveur n'y voyait pas un rejeu, et deux lignes
    /// identiques entraient en base.
    ///
    /// Ce que cela coûtait : véhicule stable à 8,0 l/100, un demi-plein de
    /// 16 L saisi deux fois sur chacun des deux derniers intervalles — 10,7
    /// l/100 sur ces intervalles, encart rouge et alerte partie, sur une
    /// consommation qui n'avait pas bougé d'un dixième. Le doublon de
    /// demi-plein REMONTE le chiffre : ses litres entrent dans l'intervalle
    /// alors que la distance, elle, ne bouge pas.
    testWidgets('la même saisie rouverte garde la même clé d\'idempotence',
        (tester) async {
      for (var essai = 0; essai < 2; essai++) {
        await ouvrir(tester);
        await tester.enterText(
            find.widgetWithText(TextField, 'Montant payé'), '10000');
        await tester.enterText(
            find.widgetWithText(TextField, 'Prix au litre'), '730');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
      }

      final cles = _PassagesCaptes.envois
          .map((e) => e['client_reference'] as String?)
          .toList();

      expect(cles, hasLength(2));
      expect(cles.first, isNotNull);
      expect(cles.first, isNotEmpty);
      expect(cles.last, cles.first,
          reason: 'Deux clés distinctes pour la même saisie, et le serveur '
              'enregistre deux passages au lieu d\'un.');

      // La largeur de la colonne : au-delà, la clé serait tronquée en base et
      // deux saisies distinctes deviendraient le même passage.
      expect(cles.first!.length, lessThanOrEqualTo(64));
    });

    /// L'autre face de la clé dérivée : elle ne doit pas confondre deux
    /// passages différents. Changer la nature du passage suffit à la changer.
    testWidgets('un demi-plein et un plein ne partagent pas la clé',
        (tester) async {
      for (final plein in [false, true]) {
        await ouvrir(tester);
        await tester.enterText(
            find.widgetWithText(TextField, 'Montant payé'), '10000');
        await tester.enterText(
            find.widgetWithText(TextField, 'Prix au litre'), '730');
        await tester.pumpAndSettle();
        if (plein) {
          await tester.tap(find.text('Plein'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
      }

      expect(
        _PassagesCaptes.envois.first['client_reference'],
        isNot(_PassagesCaptes.envois.last['client_reference']),
      );
    });
  });

  // ── L'alerte de surconsommation, une fois ouverte ────────────────────────

  /// Le cas `fuel_anomaly` existait dans l'aiguillage du push et pas dans
  /// celui de la liste — or c'est la liste qui sert le plus : le push part à
  /// huit heures, le propriétaire ouvre l'application plus tard. La ligne
  /// « Consommation en hausse » se marquait lue et ne menait nulle part, alors
  /// que son corps annonce des pièces au catalogue.
  group('Alerte de surconsommation', () {
    Future<void> toucherLAlerte(
        WidgetTester tester, AppNotification alerte) async {
      final routeur = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/garage/:id/fuel',
            builder: (_, etat) => Scaffold(
              body: Text('pleins du véhicule ${etat.pathParameters['id']}'),
            ),
          ),
          GoRoute(
            path: '/garage',
            builder: (_, _) => const Scaffold(body: Text('garage entier')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider
              .overrideWith((_) => _FauxAuth(const AuthState(type: AuthType.client))),
          notificationsProvider.overrideWith((_) async => [alerte]),
        ],
        child: MaterialApp.router(routerConfig: routeur),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Consommation en hausse'));
      await tester.pumpAndSettle();
    }

    /// Déjà lue : le dépôt n'est donc pas sollicité, et le test ne porte que
    /// sur la destination.
    const dejaLue = AppNotification(
      id: 31,
      type: 'fuel_anomaly',
      title: 'Consommation en hausse',
      body: 'Toyota Camry : 10,7 l/100 km, contre 8,0 habituellement. '
          'Les pièces sont au catalogue.',
      data: {'type': 'fuel_anomaly', 'owned_vehicle_id': 7},
      isRead: true,
    );

    testWidgets('la ligne mène aux pleins du véhicule nommé', (tester) async {
      await toucherLAlerte(tester, dejaLue);

      expect(find.text('pleins du véhicule 7'), findsOneWidget,
          reason: 'C\'est là que le chiffre se vérifie et qu\'une saisie '
              'fautive se supprime — la cause la plus fréquente d\'une '
              'hausse soudaine.');
    });

    /// Une alerte d'une version du serveur qui n'enverrait pas l'identifiant
    /// doit rester cliquable : le garage entier vaut mieux qu'une tuile morte.
    testWidgets('sans identifiant, elle mène au garage', (tester) async {
      await toucherLAlerte(
        tester,
        const AppNotification(
          id: 32,
          type: 'fuel_anomaly',
          title: 'Consommation en hausse',
          body: 'Toyota Camry : 10,7 l/100 km, contre 8,0 habituellement.',
          data: {'type': 'fuel_anomaly'},
          isRead: true,
        ),
      );

      expect(find.text('garage entier'), findsOneWidget);
    });
  });

  // ── L'historique ─────────────────────────────────────────────────────────

  group('Historique des passages', () {
    for (final echelle in tailles) {
      testWidgets('chaque ligne dit sa nature et son intervalle, x$echelle',
          (tester) async {
        await monter(
          tester,
          const FuelFillsPage(ownedVehicleId: 1),
          echelle,
          overrides: [
            fuelFillsProvider.overrideWith(_PassagesFictifs.new),
            garageProvider.overrideWith(_GarageVide.new),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('97 400 km'), findsOneWidget);
        expect(find.text('Demi-plein'), findsOneWidget);
        // Un intervalle écarté le dit en clair : sans motif visible, il passe
        // pour un défaut de l'application et le propriétaire cesse de saisir.
        expect(find.textContaining('Un passage a probablement été oublié'),
            findsOneWidget);
      });
    }

    /// L'ORDRE, sur un jeu posé comme le serveur le rend.
    ///
    /// `FuelFillController::index` fait `reorder()->orderByDesc('mileage_km')
    /// ->orderByDesc('id')` : la réponse arrive du compteur le plus HAUT au
    /// plus bas, et la fixture du contrat le confirme — ids 4, 3, 2, 1 pour
    /// 96 000 à 94 800 km. La page la retournait, croyant l'ordre croissant,
    /// et affichait donc le passage le plus ancien en tête : le propriétaire
    /// qui vient corriger la saisie qu'il vient de faire — la raison d'être de
    /// l'écran — devait défiler jusqu'en bas.
    ///
    /// Aucun test ne l'attrapait parce que les deux jeux qui couvraient
    /// l'écran étaient posés en ordre CROISSANT : l'inversion y produisait par
    /// hasard l'affichage attendu. D'où ce test, et d'où le jeu réordonné.
    ///
    /// L'espace des milliers est INSÉCABLE — c'est celui que `_entier` écrit —
    /// et il s'épelle ici pour qu'une comparaison ne tombe jamais sur une
    /// espace ordinaire invisible à la relecture.
    testWidgets('la première ligne porte le compteur le plus haut',
        (tester) async {
      await monter(
        tester,
        const FuelFillsPage(ownedVehicleId: 1),
        1.0,
        overrides: [
          fuelFillsProvider.overrideWith(_PassagesFictifs.new),
          garageProvider.overrideWith(_GarageVide.new),
        ],
      );
      await tester.pumpAndSettle();

      final haut = tester.getTopLeft(find.textContaining('97 400 km')).dy;
      final milieu =
          tester.getTopLeft(find.textContaining('95 600 km')).dy;
      final bas = tester.getTopLeft(find.textContaining('95 000 km')).dy;

      expect(haut, lessThan(milieu));
      expect(milieu, lessThan(bas));
    });

    /// Le motif de la seconde passe du serveur. Il ne se dit pas comme un
    /// défaut du véhicule : 4,0 l/100 km sur une voiture qui en fait 8,0 n'est
    /// pas une voiture économe, c'est un passage que personne n'a saisi.
    testWidgets('un intervalle anormalement bas nomme sa vraie cause',
        (tester) async {
      await monter(
        tester,
        const FuelFillsPage(ownedVehicleId: 1),
        1.0,
        overrides: [
          fuelFillsProvider.overrideWith(_PassageAnormalementBas.new),
          garageProvider.overrideWith(_GarageVide.new),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('4,0 l/100 km'), findsOneWidget);
      expect(find.textContaining('écarté'), findsOneWidget);
      expect(
        find.textContaining('un passage d\'avant n\'a pas été enregistré'),
        findsOneWidget,
      );
    });

    /// La confirmation doit annoncer ce qu'elle détruit.
    ///
    /// Mesure de la revue : 90 000/40 L, 90 600/48 L, 91 200/50 L affichent
    /// 8,2 l/100 km ; en supprimant le passage du MILIEU — un passage
    /// parfaitement correct — les 98 L restants s'étalent sur 1 200 km et
    /// l'écran passe à 4,2, présenté comme une mesure valide. Le texte
    /// générique d'avant ne laissait rien deviner de cette fusion.
    testWidgets('supprimer un passage central annonce la fusion',
        (tester) async {
      await monter(
        tester,
        const FuelFillsPage(ownedVehicleId: 1),
        1.0,
        overrides: [
          fuelFillsProvider.overrideWith(_PassagesBornes.new),
          garageProvider.overrideWith(_GarageVide.new),
        ],
      );
      await tester.pumpAndSettle();

      // Le passage du milieu, 90 600 km : deuxième ligne de la liste, qui
      // descend des compteurs.
      await tester.tap(find.byIcon(Icons.delete_outline).at(1));
      await tester.pumpAndSettle();

      expect(find.textContaining('ces deux mesures disparaissent'),
          findsOneWidget);
      expect(find.textContaining('n\'en font plus qu\'un'), findsOneWidget);

      // La liste n'a pas bougé : on a seulement lu l'avertissement.
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    /// Le dernier plein de la série n'en borne qu'UNE : la phrase de fusion y
    /// serait fausse, et une alarme fausse se paie en confiance.
    testWidgets('supprimer le dernier plein n\'annonce pas de fusion',
        (tester) async {
      await monter(
        tester,
        const FuelFillsPage(ownedVehicleId: 1),
        1.0,
        overrides: [
          fuelFillsProvider.overrideWith(_PassagesBornes.new),
          garageProvider.overrideWith(_GarageVide.new),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('cette mesure disparaît'), findsOneWidget);
      expect(find.textContaining('n\'en font plus qu\'un'), findsNothing);
    });

    testWidgets('vide, l\'écran dit à quoi il sert', (tester) async {
      await monter(
        tester,
        const FuelFillsPage(ownedVehicleId: 1),
        1.0,
        overrides: [
          fuelFillsProvider.overrideWith(_AucunPassage.new),
          garageProvider.overrideWith(_GarageVide.new),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun passage enregistré'), findsOneWidget);
      expect(find.textContaining('deux pleins'), findsOneWidget);
    });
  });
}

/// Trois passages, DANS L'ORDRE DU SERVEUR : compteur décroissant, le dernier
/// passage en tête — `orderByDesc('mileage_km')`, `orderByDesc('id')`.
///
/// L'ordre n'est pas un détail de présentation du jeu d'essai : posé en ordre
/// croissant, il masquait l'inversion que la page appliquait à la liste, parce
/// que les deux erreurs se compensaient exactement.
///
/// Un plein dont l'intervalle a été écarté pour 2 400 km — au-delà de 2 000,
/// un passage oublié est plus probable qu'un trajet — un demi-plein qui
/// apporte ses litres sans borner quoi que ce soit, et un plein qui ouvre la
/// série.
final _passages = [
  const FuelFill(
    id: 3,
    isFull: true,
    mileageKm: 97400,
    litres: 41.2,
    amountFcfa: 30000,
    l100km: 8.4,
    distanceKm: 2400,
    retenu: false,
    motifEcart: 'trop_long',
  ),
  const FuelFill(
      id: 2, isFull: false, mileageKm: 95600, litres: 13.7, amountFcfa: 10000),
  const FuelFill(
      id: 1, isFull: true, mileageKm: 95000, litres: 40.0, amountFcfa: 29000),
];

/// Les trois passages de la mesure citée par la revue : 90 000/40 L,
/// 90 600/48 L, 91 200/50 L, deux intervalles retenus à 8,0 et 8,3.
///
/// Celui du milieu borne les DEUX : il ferme le premier et ouvre le second.
/// Le supprimer n'enlève pas une mesure, il les fusionne — 98 L sur 1 200 km,
/// soit 4,2 l/100 km affiché comme un chiffre valide.
final _passagesBornes = [
  const FuelFill(
    id: 3,
    isFull: true,
    mileageKm: 91200,
    litres: 50.0,
    amountFcfa: 36000,
    l100km: 8.3,
    distanceKm: 600,
    retenu: true,
    bornesIntervalles: 1,
  ),
  const FuelFill(
    id: 2,
    isFull: true,
    mileageKm: 90600,
    litres: 48.0,
    amountFcfa: 35000,
    l100km: 8.0,
    distanceKm: 600,
    retenu: true,
    bornesIntervalles: 2,
  ),
  const FuelFill(
      id: 1, isFull: true, mileageKm: 90000, litres: 40.0, amountFcfa: 29000),
];

class _PassagesFictifs extends FuelFillsNotifier {
  @override
  Future<List<FuelFill>> build(int ownedVehicleId) async => _passages;
}

class _PassagesBornes extends FuelFillsNotifier {
  @override
  Future<List<FuelFill>> build(int ownedVehicleId) async => _passagesBornes;
}

/// Un intervalle à 4,0 l/100 km sur un véhicule qui en fait 8,0 : 1 000 km
/// pour 40 L, la signature d'un plein sur deux non saisi. Le serveur l'écarte
/// en seconde passe, sous 60 % de la médiane.
class _PassageAnormalementBas extends FuelFillsNotifier {
  @override
  Future<List<FuelFill>> build(int ownedVehicleId) async => const [
        FuelFill(
          id: 2,
          isFull: true,
          mileageKm: 91000,
          litres: 40.0,
          amountFcfa: 29000,
          l100km: 4.0,
          distanceKm: 1000,
          retenu: false,
          motifEcart: 'anormalement_bas',
        ),
        FuelFill(
            id: 1,
            isFull: true,
            mileageKm: 90000,
            litres: 40.0,
            amountFcfa: 29000),
      ];
}

class _AucunPassage extends FuelFillsNotifier {
  @override
  Future<List<FuelFill>> build(int ownedVehicleId) async => const [];
}

/// Retient ce que la boîte de saisie envoie, sans réseau ni rechargement.
///
/// Trois des défauts corrigés ici — les champs du mode abandonné, la date
/// absente, la clé qui ne survit pas à la boîte — ne se voient pas à l'écran :
/// la boîte affichait les bons litres et se fermait proprement. Seule la
/// charge utile les montre.
class _PassagesCaptes extends FuelFillsNotifier {
  static final List<Map<String, dynamic>> envois = [];

  @override
  Future<List<FuelFill>> build(int ownedVehicleId) async => _passages;

  @override
  Future<String?> addFill(Map<String, dynamic> payload) async {
    envois.add(payload);
    return null;
  }
}

class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _GarageVide extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => const [];
}
