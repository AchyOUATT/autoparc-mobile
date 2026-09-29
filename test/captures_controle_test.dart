import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/features/garage/data/garage_repository.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/data/models/vehicle_check.dart';
import 'package:auto/features/garage/presentation/pages/vehicle_check_page.dart';

/// Captures d'écran du contrôle avant voyage.
///
/// Ce fichier rend les trois étapes de l'écran et les écrit en PNG. Il sert à
/// regarder la fonction sans lancer l'application, sans serveur et sans
/// connexion — ce qui est utile, puisque l'écran vit derrière le garage, donc
/// derrière une authentification.
///
/// Les données ne sont pas inventées : la liste ci-dessous est la sortie réelle
/// du serveur pour un Land Cruiser Prado 2015 de 345 900 km, trajet de 360 km,
/// telle que `ControleAvantVoyage::liste()` l'a composée. Une capture faite sur
/// des données de fantaisie ne montrerait pas ce que la fonction fait.
///
/// Pourquoi les PNG ne sont PAS comparés :
/// un golden est exact au pixel et dépend de la plateforme de rendu. La CI de ce
/// dépôt lance `flutter test` sur Ubuntu, la machine de développement est sous
/// Windows : une comparaison committée échouerait sur la différence
/// d'anticrénelage des polices, sans qu'aucune régression n'ait eu lieu. Les
/// captures ne s'écrivent donc que sur demande explicite :
///
///   CAPTURES=1 flutter test test/captures_controle_test.dart --update-goldens
///
/// Hors de ce mode, le test reste un vrai test : il rend les mêmes écrans et
/// vérifie ce qu'ils portent. Il tourne donc en CI sans risque.
void main() {
  final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';

  setUpAll(() async {
    await _chargerPolices();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Une taille de téléphone, remise à zéro dans la portée du test.
  ///
  /// `setSurfaceSize` exige d'être appelée pendant un test : dans un `tearDown`
  /// de groupe, elle échoue sur `inTest is not true`.
  Future<void> taillePhone(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 940));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  /// Écrit la capture, ou ne fait rien hors du mode capture.
  Future<void> capturer(WidgetTester tester, String nom) async {
    if (!ecrireCaptures) return;
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/captures/$nom.png'),
    );
  }

  Widget ecran(_DepotPrado depot) => ProviderScope(
        overrides: [garageRepositoryProvider.overrideWithValue(depot)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8AAFC8)),
            useMaterial3: true,
          ),
          home: const VehicleCheckPage(ownedVehicleId: 5, vehicle: _prado),
        ),
      );

  testWidgets('les trois étapes du contrôle', (tester) async {
    await taillePhone(tester);

    final depot = _DepotPrado();
    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();

    // ── 1. Le départ : le trajet et le compteur ─────────────────
    expect(find.text('Où vas-tu ?'), findsOneWidget);
    expect(find.text('345900'), findsOneWidget,
        reason: 'Le compteur connu est proposé, pas à retaper.');
    await capturer(tester, '01-depart');

    await tester.tap(find.text('Une autre région · 400 km'));
    await tester.pumpAndSettle();
    await capturer(tester, '02-depart-trajet-choisi');

    // ── 2. La liste composée ────────────────────────────────────
    await tester.tap(find.text("Voir ce qu'il faut vérifier"));
    await tester.pumpAndSettle();

    expect(find.text('0/17'), findsOneWidget);
    expect(find.text('PAPIERS'), findsOneWidget,
        reason: 'Les papiers passent en tête : à un contrôle, ils ne se discutent pas.');
    await capturer(tester, '03-liste-tete');

    // Les points conditionnels et leurs raisons vivent plus bas : c'est la
    // partie qui distingue une liste composée d'une liste générique.
    await tester.dragUntilVisible(
      find.text('345 900 km au compteur'),
      find.byType(ListView).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    // Le même chiffre justifie deux points distincts — la courroie et le
    // refroidissement — et chacun le porte, plutôt que de renvoyer à l'autre.
    expect(find.text('345 900 km au compteur'), findsNWidgets(2));
    expect(find.text('Véhicule de 11 ans'), findsWidgets);
    await capturer(tester, '04-liste-raisons');

    // ── 3. Le verdict ───────────────────────────────────────────
    await tester.tap(find.text('Défaut').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    expect(find.text('À régler avant de partir'), findsOneWidget);
    expect(find.text('À RÉGLER'), findsOneWidget);
    expect(find.text('PEUT ATTENDRE'), findsOneWidget);
    await capturer(tester, '05-verdict-bloque');
  });

  testWidgets("le contrôle d'hivernage", (tester) async {
    await taillePhone(tester);

    final depot = _DepotPrado(saison: true);
    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();

    // Le choix du type de contrôle : un seul point d'entrée, et c'est ici qu'on
    // dit ce qu'on vient faire.
    expect(find.text("Contrôle d'hivernage"), findsOneWidget);
    await capturer(tester, '07-choix-du-controle');

    await tester.tap(find.text("Contrôle d'hivernage"));
    await tester.pumpAndSettle();

    // Un contrôle de saison ne va nulle part : pas de distance à choisir.
    expect(find.text('Où vas-tu ?'), findsNothing);

    await tester.tap(find.text("Voir ce qu'il faut vérifier"));
    await tester.pumpAndSettle();

    expect(find.text('Profondeur des rainures'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget,
        reason: "Cinq points : un contrôle de saison n'a aucun déclencheur "
            'extérieur, il ne tient que s\'il se fait en trois minutes.');
    await capturer(tester, '08-hivernage-liste');
  });

  testWidgets('un contrôle sans défaut ne certifie rien', (tester) async {
    await taillePhone(tester);

    final depot = _DepotPrado(verdictClair: true);
    await tester.pumpWidget(ecran(depot));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Une autre région · 400 km'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Voir ce qu'il faut vérifier"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Correct').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer le contrôle'));
    await tester.pumpAndSettle();

    expect(find.text('sur le point vérifié'), findsOneWidget);
    expect(find.textContaining("16 points n'ont pas été vérifiés"), findsOneWidget,
        reason: 'Le verdict ne porte que sur ce qui a été regardé.');
    await capturer(tester, '06-verdict-sans-defaut');
  });
}

/// Charge de vraies polices, sans quoi les captures ne montreraient que des
/// rectangles : le moteur de test n'embarque aucune fonte.
///
/// Elles sont lues dans le cache du SDK plutôt que copiées dans le dépôt — deux
/// fichiers binaires de plus dans l'historique pour une image de documentation
/// ne se justifient pas. Si le chemin n'existe pas, les captures sortent sans
/// texte lisible mais le test passe : il ne vérifie pas des pixels.
Future<void> _chargerPolices() async {
  final racine = Platform.environment['FLUTTER_ROOT'];
  if (racine == null) return;

  final dossier = Directory('$racine/bin/cache/artifacts/material_fonts');
  if (!dossier.existsSync()) return;

  const fontes = {
    'Roboto': ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf'],
    'MaterialIcons': ['materialicons-regular.otf'],
  };

  for (final entree in fontes.entries) {
    final chargeur = FontLoader(entree.key);
    var trouvee = false;

    for (final nom in entree.value) {
      final fichier = File('${dossier.path}/$nom');
      if (!fichier.existsSync()) continue;
      chargeur.addFont(Future.value(fichier.readAsBytesSync().buffer.asByteData()));
      trouvee = true;
    }

    if (trouvee) await chargeur.load();
  }
}

// ── Le véhicule et sa liste, tels qu'ils existent vraiment ──────────

const _prado = OwnedVehicle(
  id: 5,
  designation: 'Toyota Land Cruiser Prado 2015',
  brandId: 1,
  vehicleModelId: 1,
  year: 2015,
  mileageKm: 345900,
  identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Land Cruiser Prado'),
  compatibilityReady: true,
);

/// Dépôt qui rend la liste réelle du serveur pour ce véhicule et ce trajet.
class _DepotPrado extends GarageRepository {
  _DepotPrado({this.verdictClair = false, this.saison = false}) : super(ApiClient());

  final bool verdictClair;
  final bool saison;

  /// Ce que le serveur propose un 10 juillet : l'hivernage est la saison en
  /// cours, et c'est lui qui nomme le contrôle.
  static const _types = [
    {
      'value': 'trip',
      'label': 'Avant un voyage',
      'hint': "La liste dépend de la distance : un aller-retour en ville et une descente de quatre cents kilomètres ne demandent pas la même chose.",
      'season': null,
    },
    {
      'value': 'seasonal',
      'label': "Contrôle d'hivernage",
      'hint': "L'eau et la boue : ce qui compte est de voir, d'être vu et de tenir la route.",
      'season': 'pluies',
    },
  ];

  @override
  Future<CheckTemplate> checkTemplate(
    int ownedVehicleId, {
    int? tripDistanceKm,
    String reason = 'trip',
  }) async =>
      CheckTemplate.fromJson({
        'reason': reason,
        'title': reason == 'seasonal' ? "Contrôle d'hivernage" : 'Avant de partir',
        'trip_distance_km': tripDistanceKm,
        'mileage_km': 345900,
        'available_reasons': saison ? _types : const [],
        'items': reason == 'seasonal' ? _pointsHivernage : _points,
      });

  @override
  Future<VehicleCheck> submitCheck(int ownedVehicleId, Map<String, dynamic> payload) async =>
      VehicleCheck.fromJson({
        'id': 1,
        'owned_vehicle_id': 5,
        'trip_distance_km': 400,
        'mileage_km': 345900,
        'performed_at': '2026-09-28T21:00:00+00:00',
        'verdict': verdictClair
            ? {
                'value': 'clear',
                'label': 'Rien à signaler',
                'detail': 'sur le point vérifié',
              }
            : {
                'value': 'blocked',
                'label': 'À régler avant de partir',
                'detail': '1 point bloquant, 1 à surveiller',
              },
        'counts': {
          'blocking': verdictClair ? 0 : 1,
          'watch': verdictClair ? 0 : 1,
          'checked': 1,
        },
        'to_fix': verdictClair
            ? []
            : [
                {
                  'item_code': 'papiers-assurance',
                  'title': "Attestation d'assurance valide",
                  'category': 'papiers',
                  'category_label': 'Papiers',
                  'severity': 'blocking',
                  'status': 'bad',
                  'blocking': true,
                  'help': "Sur le pare-brise et dans la boîte à gants. À un contrôle, une attestation périmée ne se discute pas : amende, et le véhicule reste sur place.",
                  'part_category_id': null,
                },
                {
                  'item_code': 'visibilite',
                  'title': 'Pare-brise, balais et rétroviseurs',
                  'category': 'eclairage',
                  'category_label': 'Éclairage et visibilité',
                  'severity': 'watch',
                  'status': 'watch',
                  'blocking': false,
                  'help': "Un impact dans l'axe du regard s'agrandit avec la chaleur, et fait refuser la visite technique.",
                  'part_category_id': 47,
                },
              ],
      });

  @override
  Future<List<OwnedVehicle>> getVehicles() async => const [];
}

/// Le contrôle d'hivernage, tel que le serveur le compose un 10 juillet.
///
/// Cinq points, et aucun ne porte de « raison » : la saison est annoncée par le
/// titre du contrôle, et la répéter sur chaque carte serait du bruit.
const List<Map<String, dynamic>> _pointsHivernage = [
  {'code': 'pluies-pneus', 'category': 'pneus', 'category_label': 'Pneus', 'title': 'Profondeur des rainures', 'help': "Sur route mouillée, un pneu à moitié usé n'évacue plus l'eau : la voiture flotte et ne dirige plus. C'est le seul point de cette liste qui tue.", 'severity': 'blocking', 'reasons': <String>[], 'part_category_id': 31},
  {'code': 'pluies-essuie-glaces', 'category': 'eclairage', 'category_label': 'Éclairage et visibilité', 'title': 'Balais et lave-glace', 'help': "Un balai durci transforme une averse en écran opaque. Ils se remplacent avant la première pluie, pas après — au milieu de la saison, tout le monde en cherche en même temps.", 'severity': 'blocking', 'reasons': <String>[]},
  {'code': 'pluies-eclairage', 'category': 'eclairage', 'category_label': 'Éclairage et visibilité', 'title': 'Feux avant, arrière et antibrouillards', 'help': "Une averse ramène la visibilité à cinquante mètres en plein jour. Les feux arrière comptent autant que les phares : ce sont eux qui te font voir de celui qui arrive derrière.", 'severity': 'blocking', 'reasons': <String>[], 'part_category_id': 52},
  {'code': 'pluies-etancheite', 'category': 'niveaux', 'category_label': 'Niveaux et fuites', 'title': 'Écoulements et joints de portes', 'help': "Les écoulements du pare-brise et du toit se bouchent de poussière et de feuilles pendant la saison sèche. L'eau passe alors dans l'habitacle, pourrit les tapis et finit dans le faisceau électrique — une panne qui coûte cher et qu'on ne relie jamais à la pluie.", 'severity': 'watch', 'reasons': <String>[]},
  {'code': 'pluies-desembuage', 'category': 'confort', 'category_label': 'Climatisation', 'title': 'Désembuage du pare-brise', 'help': "Par temps de pluie, c'est la climatisation qui assèche l'air et désembue, pas la ventilation seule. Si elle ne fonctionne pas, tu roules à l'aveugle au premier orage.", 'severity': 'watch', 'reasons': <String>[], 'part_category_id': 60},
];

/// La sortie de `ControleAvantVoyage::liste()` pour le Prado, recopiée telle
/// quelle : dix-sept points, onze du noyau et six déclenchés par une condition.
const List<Map<String, dynamic>> _points = [
  {'code': 'papiers-assurance', 'category': 'papiers', 'category_label': 'Papiers', 'title': "Attestation d'assurance valide", 'help': "Sur le pare-brise et dans la boîte à gants. À un contrôle, une attestation périmée ne se discute pas : amende, et le véhicule reste sur place.", 'severity': 'blocking', 'reasons': <String>[]},
  {'code': 'papiers-visite', 'category': 'papiers', 'category_label': 'Papiers', 'title': 'Visite technique valide', 'help': "La vignette sur le pare-brise et le procès-verbal. Sa date ne se devine pas : regarde-la avant de partir, pas au poste de contrôle.", 'severity': 'blocking', 'reasons': <String>[]},
  {'code': 'papiers-bord', 'category': 'papiers', 'category_label': 'Papiers', 'title': 'Carte grise et permis à bord', 'help': "Les originaux. Un permis oublié à la maison arrête le voyage au premier contrôle, quelle que soit la bonne foi.", 'severity': 'blocking', 'reasons': <String>[]},
  {'code': 'pneus-etat', 'category': 'pneus', 'category_label': 'Pneus', 'title': 'Pression et usure des quatre pneus', 'help': "À froid, avant de rouler : la pression conseillée est sur l'étiquette du montant de la porte conducteur. Cherche le témoin d'usure au fond des rainures, et regarde les flancs — une boursouflure annonce un éclatement, pas une crevaison.", 'severity': 'blocking', 'reasons': <String>[], 'part_category_id': 31},
  {'code': 'pneus-secours', 'category': 'pneus', 'category_label': 'Pneus', 'title': 'Roue de secours, cric et clé', 'help': "Une roue de secours se dégonfle sans qu'on s'en aperçoive, et un cric absent la rend inutile. Entre deux villes, une crevaison sans secours, c'est la nuit sur place.", 'severity': 'blocking', 'reasons': <String>[], 'part_category_id': 31},
  {'code': 'niveaux-capot', 'category': 'niveaux', 'category_label': 'Niveaux et fuites', 'title': 'Niveaux sous le capot', 'help': "Moteur froid, terrain plat : l'huile entre les deux repères de la jauge, le liquide de refroidissement au vase d'expansion, le liquide de frein au bocal. Par 40 degrés, un niveau de refroidissement bas devient une surchauffe en une heure de route.", 'severity': 'blocking', 'reasons': <String>[], 'part_category_id': 12},
  {'code': 'niveaux-fuite', 'category': 'niveaux', 'category_label': 'Niveaux et fuites', 'title': 'Trace de fuite sous le véhicule', 'help': "Regarde le sol à l'endroit où la voiture était garée. Une tache fraîche d'huile, de liquide coloré ou de liquide de frein se traite avant le départ — sur la route, elle se traite à l'arrêt forcé.", 'severity': 'blocking', 'reasons': <String>[]},
  {'code': 'freins', 'category': 'freins', 'category_label': 'Freins', 'title': 'Freins : pédale, bruit, vibration', 'help': "Moteur tournant, appuie fort : la pédale doit rester ferme. Si elle s'enfonce lentement, ne prends pas la route. Puis un freinage à basse vitesse : un grincement métallique, c'est une plaquette finie ; une vibration dans le volant, un disque voilé.", 'severity': 'blocking', 'reasons': <String>[], 'part_category_id': 20},
  {'code': 'eclairage-feux', 'category': 'eclairage', 'category_label': 'Éclairage et visibilité', 'title': 'Feux, stop et clignotants', 'help': "À deux, ou en reculant contre un mur : croisement, route, stop, clignotants, warning. Un feu stop mort, c'est le camion derrière qui ne sait pas que tu ralentis.", 'severity': 'blocking', 'reasons': <String>[], 'part_category_id': 52},
  {'code': 'visibilite', 'category': 'eclairage', 'category_label': 'Éclairage et visibilité', 'title': 'Pare-brise, balais et rétroviseurs', 'help': "Un impact dans l'axe du regard s'agrandit avec la chaleur, et fait refuser la visite technique. Un balai durci transforme une averse en écran opaque — vérifie aussi que le lave-glace a de l'eau.", 'severity': 'watch', 'reasons': <String>[], 'part_category_id': 47},
  {'code': 'moteur-courroie', 'category': 'moteur', 'category_label': 'Moteur', 'title': "État de la courroie d'accessoires", 'help': "Craquelures, effilochage, jeu au doigt. Cette courroie entraîne l'alternateur et souvent la pompe à eau : si elle casse en route, tu t'arrêtes là où elle a cassé.", 'severity': 'blocking', 'reasons': ['345 900 km au compteur']},
  {'code': 'moteur-distribution', 'category': 'moteur', 'category_label': 'Moteur', 'title': 'Courroie de distribution : dernier remplacement', 'help': "Si personne ne sait quand elle a été changée, un long trajet n'est pas le moment de le découvrir : sa rupture casse le moteur, pas seulement la courroie.", 'severity': 'watch', 'reasons': ['Trajet de 360 km', 'Véhicule de 11 ans'], 'part_category_id': 8},
  {'code': 'moteur-batterie', 'category': 'moteur', 'category_label': 'Moteur', 'title': 'Cosses et fixation de la batterie', 'help': "Cosses propres et serrées, batterie bien bridée. La chaleur raccourcit sa vie : passé huit ans, elle lâche sans prévenir — souvent au démarrage du retour.", 'severity': 'watch', 'reasons': ['Véhicule de 11 ans'], 'part_category_id': 55},
  {'code': 'moteur-refroidissement', 'category': 'moteur', 'category_label': 'Moteur', 'title': 'Ventilateur et durites de refroidissement', 'help': "Le ventilateur doit se déclencher moteur chaud. Durites souples sans craquelure, colliers serrés : c'est la panne la plus fréquente sur une longue nationale en pleine chaleur.", 'severity': 'watch', 'reasons': ['Trajet de 360 km', '345 900 km au compteur'], 'part_category_id': 15},
  {'code': 'confort-clim', 'category': 'confort', 'category_label': 'Climatisation', 'title': 'Climatisation', 'help': "Trois cents kilomètres à 40 degrés sans climatisation, ce n'est pas une question de confort : c'est la vigilance du conducteur qui baisse.", 'severity': 'watch', 'reasons': ['Trajet de 360 km'], 'part_category_id': 60},
  {'code': 'securite-equipement', 'category': 'securite', 'category_label': 'Sécurité', 'title': 'Triangle, extincteur et gilet', 'help': "Exigés à la visite technique et demandés aux contrôles. L'extincteur porte une date de péremption : regarde-la. Le gilet sert la nuit, quand descendre sans être vu est le vrai danger d'une panne.", 'severity': 'blocking', 'reasons': <String>[]},
  {'code': 'voyage-provisions', 'category': 'voyage', 'category_label': 'Avant de démarrer', 'title': 'Plein, eau et téléphone chargé', 'help': "Repère où tu feras le plein : entre deux villes, une station fermée coûte cher. De l'eau à bord, un téléphone chargé et du crédit dessus.", 'severity': 'watch', 'reasons': ['Trajet de 360 km']},
];
