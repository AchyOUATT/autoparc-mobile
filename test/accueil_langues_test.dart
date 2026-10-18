import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/core/widgets/navigation_bar_theme.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/garage/presentation/widgets/engine_prompt.dart';
import 'package:auto/features/home/presentation/pages/home_page.dart';
import 'package:auto/features/home/presentation/providers/home_providers.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/langues.dart';
import 'support/mesures.dart';
import 'support/polices.dart';

/// LES ÉCRANS TRADUITS PAR CE LOT NE TRONQUENT PAS EN ANGLAIS.
///
/// ── CE QUE CE FICHIER EXISTE POUR EMPÊCHER ──────────────────────────────────
///
/// Le lot précédent a passé une journée entière sur des troncatures invisibles :
/// un titre coupé dans 24 cases, une ville rognée sans ellipse. La traduction
/// est précisément le genre de changement qui les rouvre, parce qu'elle change
/// la largeur de chaque chaîne sans toucher à une seule mise en page.
///
/// ET L'ANGLAIS N'EST PAS UNIFORMÉMENT PLUS COURT. Mesuré sur ce lot :
///
///   « Accessoires »                  77,93 pt → « Accessories »      78,06 pt
///   « Mettre à jour le kilométrage »          → « Update mileage »    plus court
///   « Visite technique, assurance, … »        → « Roadworthiness … »  plus long
///
/// L'intuition « l'anglais est plus concis » est donc fausse au cas par cas, et
/// c'est le cas par cas qui casse une mise en page.
///
/// ── LES ÉCRANS COUVERTS, ET CEUX QUI NE LE SONT PAS ─────────────────────────
///
/// Couverts ici : l'accueil ENTIER — carte du véhicule, échéances, bande des
/// pièces compatibles, vitrine, tuiles « Parcourir », invitation au besoin — et
/// les barres de titre des trois pages du catalogue, qui sont les quatre
/// chaînes de coque que ce lot traduit.
///
/// La barre de navigation du bas est mesurée par `bandes_filtres_test.dart`,
/// dans les deux langues, avec le détail de la marge qui reste. Les cartes du
/// catalogue le sont par `carte_geometrie_test.dart`, également dans les deux
/// langues.
///
/// NON COUVERTS, et c'est volontaire : les écrans que ce lot ne traduit pas.
/// Leur texte français ne change pas de largeur, et les mesurer en anglais
/// mesurerait du français.
///
/// ── LA MÉTHODE ──────────────────────────────────────────────────────────────
///
/// Les mêmes configurations que le français, et dans la même exécution : trois
/// largeurs d'écran, quatre échelles de texte, les deux langues. On mesure sur
/// les GLYPHES PEINTS — voir `support/mesures.dart` — et la page est montée
/// DANS SA COQUE, avec la barre de navigation qui lui prend ses 112 points,
/// parce qu'une page mesurée sans son chrome mesure un téléphone qui n'existe
/// pas.
void main() {
  setUpAll(() => chargerPolices());

  tearDown(() => definirLocaleMontants(localeFr));

  /// 320 × 640 : le plus petit format encore courant. 360 × 720 : la médiane du
  /// parc Android. 411 × 923 : le Pixel de l'émulateur, donc l'écran sur lequel
  /// un défaut ne se voit pas.
  const ecrans = <String, Size>{
    '320x640': Size(320, 640),
    '360x720': Size(360, 720),
    '411x923': Size(411, 923),
  };

  /// 1,0 est le réglage par défaut, 1,3 le deuxième cran d'Android (« Grande
  /// police »), 1,5 le troisième, 2,0 le dernier.
  const echelles = <double>[1.0, 1.3, 1.5, 2.0];

  // ── Le pire contenu que l'accueil puisse recevoir ─────────────────────────

  /// Un véhicule de la vitrine, au pire cas : nom long, ville, prix à huit
  /// chiffres. Le prix est la seule ligne de la tuile dont la LARGEUR change
  /// avec la langue — « 99 999 999 FCFA » contre « 99,999,999 FCFA ».
  Vehicle affaire() => Vehicle.fromJson({
    'id': 1,
    'reference': 'VH-0001',
    'designation': 'Toyota Land Cruiser Prado 2016',
    'registration_status': 'registered',
    'identity': {
      'brand': 'Toyota',
      'brand_slug': 'toyota',
      'model': 'Land Cruiser Prado',
      'year': 2016,
    },
    'commercial': {
      'condition': 'used',
      'status': 'in_stock',
      'availability': 'sale',
      'sale_price': '99999999.00',
      'currency': 'XOF',
      'price_negotiable': true,
      'deal_type': 'good_deal',
      'deal_label': 'Bonne affaire',
      'location': {
        'id': 1,
        'name': 'Showroom Paspanga',
        'city': 'Bobo-Dioulasso',
      },
    },
  });

  Part pieceCompatible() => Part.fromJson({
    'id': 1,
    'name': 'Filtre à huile moteur cartouche 04152-YZZA1',
    'sku': '04152-YZZA1',
    'type': 'aftermarket',
    'condition': 'new',
    'pricing': {
      'selling_price': 3000,
      'currency': 'XOF',
      'vat_rate': 0,
      'price_including_vat': 3000,
    },
    'stock': {
      'is_available': true,
      'quantity': 15,
      'alert_threshold': 0,
      'is_low': false,
    },
  });

  /// Les trois valeurs de la fixture dont PERSONNE ne contrôle la longueur.
  ///
  /// Le surnom est tapé par le propriétaire ; le nom de modèle et le nom de
  /// pièce viennent du référentiel du serveur. Les textes qui les portent
  /// s'ellipsent par construction, et c'est le seul droit à l'ellipse de cet
  /// écran — voir [aucuneTroncature].
  const valeursSansBorne = <String>{
    'Le Prado du chantier de Bobo',
    'Land Cruiser Prado',
    'Filtre à huile moteur cartouche 04152-YZZA1',
  };

  /// LES DEUX PARAGRAPHES DU BANDEAU DE MOTORISATION QUI DÉBORDENT, nommés un
  /// par un — et c'est la correction d'une exclusion trop large.
  ///
  /// Le tableau écartait `find.byType(MissingEngineBanner)`, donc le sous-arbre
  /// entier : quatre paragraphes, dont DEUX débordent et DEUX n'ont jamais eu
  /// de raison d'être écartés. Le test dédié ci-dessous ne mesurait que le
  /// premier, et le second a vécu non chiffré jusqu'à ce qu'un relecteur ouvre
  /// le sous-arbre.
  ///
  /// Les chaînes sont RECOPIÉES, et c'est volontaire : `engine_prompt.dart` les
  /// écrit en dur parce que ce bandeau n'est pas traduit par ce lot — il est
  /// partagé avec `garage_page.dart`. Les mesures le confirment, elles sont
  /// identiques au centième dans les deux langues. Le jour où le bandeau
  /// passera aux `.arb`, ces deux chaînes devront être lues dans
  /// `AppLocalizations` comme le reste du fichier.
  const bandeauDeborde = <String>{
    'Motorisation non renseignée',
    'Sans elle, impossible de savoir quelles pièces vont sur ce véhicule.',
  };

  // ── La coque ──────────────────────────────────────────────────────────────

  /// Monte [page] DANS LA COQUE DE L'APPLICATION, à la taille, à l'échelle et
  /// dans la langue demandées.
  ///
  /// La barre de navigation est celle de l'application —
  /// `BarreNavigationPrincipale` —, avec ses intitulés LUS dans les traductions
  /// et non recopiés. Les creux du système sont posés comme ailleurs : 24 en
  /// haut, 48 en bas pour la barre à trois boutons, qui est le cas le plus
  /// contraignant. Sans eux on mesure un appareil sans barre d'état.
  Future<Object?> poser(
    WidgetTester tester, {
    required Widget page,
    required int ongletActif,
    required Size ecran,
    required double echelle,
    required Locale locale,

    /// La session montée. Le client par défaut, parce que c'est lui qui voit
    /// l'accueil ENTIER — le personnel n'a pas de garage, et `_MyVehicleSection`
    /// disparaît pour lui.
    ///
    /// Le groupe des barres de titre monte le PERSONNEL, pour deux raisons.
    /// D'abord parce que c'est le rôle dont les barres de titre sont les plus
    /// chargées : il y gagne un bouton « Ajouter ». Ensuite pour éviter une
    /// fragilité de cycle de vie qui n'a rien à voir avec la traduction :
    /// `part_list_page.dart` insère `_GarageFilterBanner` sous `if (!isStaff)`,
    /// et cet état lit ses notifiers dans `deactivate()` pour écrire APRÈS la
    /// trame — le commentaire sur place explique pourquoi les deux autres
    /// emplacements ne marchaient pas. Quand un banc démonte tout le
    /// `ProviderScope`, le rappel écrit dans un conteneur déjà jeté et lève
    /// « Tried to use StateController after dispose ».
    ///
    /// CE N'EST PAS UN DÉFAUT DE PRODUCTION CONTOURNÉ : dans l'application, le
    /// `ProviderScope` est la racine et vit aussi longtemps que le processus,
    /// donc le conteneur ne peut pas disparaître entre `deactivate()` et la
    /// trame suivante. La fragilité est réelle et sans porteur ; elle est
    /// signalée ici plutôt que tue, et hors du champ d'un lot de traduction.
    AuthState session = const AuthState(type: AuthType.client),
  }) async {
    // Le format des montants est un réglage de module, posé par
    // `AutoParcApp.build` dans l'application. Sans cette ligne, le banc
    // mesurerait une page anglaise avec des prix français.
    definirLocaleMontants(locale);

    tester.view.physicalSize = ecran;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(ecran);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        // Une clé neuve à chaque pose : sans elle, Flutter réutilise l'élément
        // du `ProviderScope`, donc son conteneur, donc l'état déjà chargé des
        // providers — et deux poses dans le même test mesureraient deux fois la
        // première.
        key: UniqueKey(),
        overrides: [
          authProvider.overrideWith((_) => _FauxAuth(session)),
          garageProvider.overrideWith(_GarageDuPrado.new),
          homeDealsProvider.overrideWith((_) async => [affaire()]),
          homeCompatiblePartsProvider.overrideWith(
            (_, __) async => [pieceCompatible(), pieceCompatible()],
          ),
          catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
          catalogRefsProvider.overrideWith(
            (_) async => const CatalogRefs(
              brands: [],
              vehicleModels: [],
              trims: [],
              engineTypes: [],
              drivetrains: [],
              colors: [],
              features: [],
              locations: [],
            ),
          ),
        ],
        child: MaterialApp(
          theme: themeAutoParc(Brightness.light),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: ecran,
              textScaler: TextScaler.linear(echelle),
              padding: const EdgeInsets.only(top: 24, bottom: 48),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
            ),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Scaffold(
                  body: page,
                  bottomNavigationBar: BarreNavigationPrincipale(
                    selectedIndex: ongletActif,
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        label: l10n.commonHome,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.directions_car_outlined),
                        label: l10n.commonVehicles,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.tune_outlined),
                        label: l10n.commonAccessories,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.settings_outlined),
                        label: l10n.commonParts,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Les dépôts répondent sur des microtâches ; six pompes laissent la page
    // passer de ses indicateurs de chargement à son contenu.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return tester.takeException();
  }

  /// Tous les paragraphes peints sous [racine], chacun contrôlé sur les deux
  /// troncatures : celle que le `TextPainter` déclare, et celle qu'il ne déclare
  /// pas.
  ///
  /// ── LA RÈGLE, ET SON UNIQUE EXCEPTION ──────────────────────────────────────
  ///
  /// UNE CHAÎNE DE L'APPLICATION NE DOIT JAMAIS SE COUPER. C'est nous qui
  /// l'écrivons, nous qui la traduisons, et sa longueur est donc notre
  /// responsabilité : « Mettre à jour le kilométrage » tronqué en « Mettre à
  /// jour le kilo… » est un défaut, pas un compromis.
  ///
  /// UNE VALEUR SANS BORNE, elle, a le droit de s'ellipser, et plusieurs le
  /// font par construction (`maxLines: 1, overflow: ellipsis` écrit dans
  /// `_SectionTitle`, `_VehicleCard`, `_PartTile`, `_DealTile`) : le surnom
  /// qu'un propriétaire tape, un nom de modèle ou de pièce que le serveur
  /// envoie. Aucune largeur d'écran ne peut les garantir, et les refuser
  /// voudrait dire replier des cartes sur quatre lignes pour un nom de
  /// fantaisie.
  ///
  /// [valeursSansBorne] porte donc ces valeurs, nommément, telles que la
  /// fixture les pose. Un texte qui en CONTIENT une est exempté ; tous les
  /// autres sont tenus à la règle. C'est volontairement une liste à tenir à
  /// jour plutôt qu'un assouplissement général : le jour où une chaîne de
  /// l'application se coupe, il faut qu'elle tombe, et non qu'elle glisse dans
  /// une exception écrite pour quelqu'un d'autre.
  void aucuneTroncature(
    WidgetTester tester, {
    required Finder racine,
    required String ou,
    Set<String> valeursSansBorne = const {},
    List<Finder> horsChamp = const [],

    /// Les textes dont la troncature est un DÉFAUT MESURÉ, antérieur à ce lot,
    /// verrouillé par un test qui lui est propre.
    ///
    /// Distinct de [valeursSansBorne], et la distinction compte : une valeur
    /// sans borne a le DROIT de s'ellipser, un défaut connu ne l'a pas — il est
    /// seulement déjà chiffré ailleurs, pour ne pas faire tomber le tableau sur
    /// quelque chose que ce lot n'a ni causé ni le mandat de corriger. Chaque
    /// entrée doit avoir son test nommé, sinon c'est une assertion relâchée
    /// déguisée.
    Set<String> defautsConnus = const {},
  }) {
    // Les paragraphes exclus sont écartés PAR IDENTITÉ de leur objet de rendu,
    // et non par leur texte : un `Finder` de paragraphe est plus étroit qu'une
    // chaîne, qui pourrait réapparaître ailleurs dans la page.
    //
    // MAIS IL DOIT DÉSIGNER DES PARAGRAPHES, ET JAMAIS UN SOUS-ARBRE, et c'est
    // la correction du relecteur. Ce paramètre recevait
    // `find.byType(MissingEngineBanner)` : tout le bandeau, c'est-à-dire
    // QUATRE paragraphes dont DEUX débordent, quand le test censé les
    // verrouiller n'en mesurait qu'un. Le second — la phrase explicative, dont
    // le mot « impossible » réclame 120,59 points à l'échelle 2,0 — n'était
    // chiffré nulle part et sortait du champ sans que rien ne le dise. Les
    // deux autres, le libellé du bouton et le glyphe de l'icône, étaient
    // écartés sans raison : ils passent la règle générale et y sont revenus.
    final exclus = <RenderParagraph>{
      for (final f in horsChamp)
        ...tester.renderObjectList<RenderParagraph>(
          find.descendant(of: f, matching: find.byType(RichText)),
        ),
    };

    final paragraphes = tester
        .renderObjectList<RenderParagraph>(
          find.descendant(of: racine, matching: find.byType(RichText)),
        )
        .where((p) => !exclus.contains(p))
        .toList();

    expect(
      paragraphes,
      isNotEmpty,
      reason:
          'Aucun paragraphe peint sous $ou : la page est restée sur son '
          'indicateur de chargement, et ce test ne mesure rien.',
    );

    for (final p in paragraphes) {
      final texte = texteDe(p);
      if (valeursSansBorne.any(texte.contains)) continue;
      if (defautsConnus.contains(texte)) continue;

      expect(
        p.didExceedMaxLines,
        isFalse,
        reason:
            '$ou : « $texte » est COUPÉ — '
            '${voulue(p).toStringAsFixed(1)} points voulus pour '
            '${recue(p).toStringAsFixed(1)} reçus, et il n\'en reste peint '
            'que « ${peint(p, recue(p))} ».',
      );

      expect(
        motLePlusLarge(p),
        lessThanOrEqualTo(recue(p) + 0.01),
        reason:
            '$ou : un mot de « $texte » fait '
            '${motLePlusLarge(p).toStringAsFixed(1)} points pour '
            '${recue(p).toStringAsFixed(1)} reçus. Il sera rogné sans ellipse, '
            'donc en silence : `didExceedMaxLines` ne voit pas ce cas.',
      );
    }
  }

  // ── L'accueil ─────────────────────────────────────────────────────────────

  group('L\'accueil', () {
    /// « Bonnes affaires » / « Good deals », lus dans les `.arb` plutôt que
    /// recopiés : le tableau les écarte nommément, et une copie en dur
    /// cesserait de les écarter — donc ferait tomber le tableau — le jour où la
    /// traduction change.
    final titreVitrine = <String, String>{};

    setUpAll(() async {
      for (final langue in langues.entries) {
        titreVitrine[langue.key] =
            (await chargerTextes(langue.value)).homeDealsSection;
      }
    });
    for (final ecran in ecrans.entries) {
      for (final echelle in echelles) {
        for (final langue in langues.entries) {
          testWidgets(
            '${ecran.key}, texte x$echelle, ${langue.key} : rien n\'est coupé',
            (tester) async {
              final exception = await poser(
                tester,
                page: const HomePage(),
                ongletActif: 0,
                ecran: ecran.value,
                echelle: echelle,
                locale: langue.value,
              );

              expect(
                exception,
                isNull,
                reason:
                    'Débordement de l\'accueil en ${ecran.key} à l\'échelle '
                    '$echelle, en ${langue.key} : Flutter peint sa bande '
                    'rayée par-dessus le contenu.',
              );

              // ON DÉFILE, et ce n'est pas une précaution : l'accueil est un
              // `ListView`, qui ne CONSTRUIT que ce qui est visible. Mesuré
              // sans défilement, « Vous ne trouvez pas ? Dites-nous ce que
              // vous cherchez » — la ligne la plus longue de la page — n'avait
              // tout simplement pas d'objet de rendu, et le tableau passait au
              // vert sans l'avoir regardée une seule fois. Le défaut a été vu
              // parce que le test de non-vacuité, lui, la cherchait par son
              // texte et ne la trouvait pas.
              for (var pas = 0; pas < 10; pas++) {
                aucuneTroncature(
                  tester,
                  racine: find.byType(HomePage),
                  ou:
                      'Accueil ${ecran.key} x$echelle ${langue.key}, '
                      'défilement $pas',
                  valeursSansBorne: valeursSansBorne,
                  // `MissingEngineBanner` porte DEUX défauts ANTÉRIEURS à ce
                  // lot, indépendants de la langue, et son propre test
                  // ci-dessous en verrouille les deux chiffres. On écarte les
                  // DEUX PARAGRAPHES nommément, et non le bandeau : écarter le
                  // sous-arbre entier cachait le second, et c'est exactement le
                  // reproche qui a valu cette correction.
                  horsChamp: [
                    for (final texte in bandeauDeborde)
                      find.descendant(
                        of: find.byType(MissingEngineBanner),
                        matching: find.text(texte),
                      ),
                  ],
                  // Le titre de la vitrine. Voir « le titre de section se
                  // coupe déjà » ci-dessous, qui en porte les chiffres dans
                  // les deux langues.
                  defautsConnus: {titreVitrine[langue.key]!},
                );

                final defilable = find.descendant(
                  of: find.byType(HomePage),
                  matching: find.byType(Scrollable),
                );
                if (defilable.evaluate().isEmpty) break;

                await tester.drag(defilable.first, const Offset(0, -240));
                for (var i = 0; i < 3; i++) {
                  await tester.pump(const Duration(milliseconds: 50));
                }
                expect(
                  tester.takeException(),
                  isNull,
                  reason:
                      'Débordement apparu au défilement $pas en '
                      '${ecran.key} à l\'échelle $echelle, en '
                      '${langue.key}.',
                );
              }
            },
          );
        }
      }
    }

    testWidgets('les textes mesurés sont bien ceux de la langue montée', (
      tester,
    ) async {
      // NON-VACUITÉ DU TABLEAU CI-DESSUS. Sans ce test, une coque dont les
      // délégués seraient mal câblés mesurerait du français dans les deux
      // colonnes, et les douze cases anglaises passeraient au vert en
      // n'éprouvant rien. C'est le défaut exact de la police de repli, raconté
      // dans support/polices.dart : faux et vert.
      for (final langue in langues.entries) {
        await poser(
          tester,
          page: const HomePage(),
          ongletActif: 0,
          ecran: const Size(411, 923),
          echelle: 1.0,
          locale: langue.value,
        );

        final textes = await chargerTextes(langue.value);

        // On descend jusqu'au bas de la page : l'invitation au besoin est le
        // dernier enfant du `ListView` et n'est pas construite tant qu'elle est
        // hors champ.
        for (var i = 0; i < 6; i++) {
          await tester.drag(
            find
                .descendant(
                  of: find.byType(HomePage),
                  matching: find.byType(Scrollable),
                )
                .first,
            const Offset(0, -240),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          find.text(textes.homeDealsSection),
          findsOneWidget,
          reason:
              'Le titre de la vitrine n\'est pas en ${langue.key} : la coque '
              'ne sert pas la langue qu\'elle annonce. Ou bien il a quitté le '
              'champ au défilement, et ce sont les glissements ci-dessus '
              'qu\'il faut revoir.',
        );
        expect(
          find.text(textes.homeNeedPrompt),
          findsOneWidget,
          reason: 'L\'invitation au besoin n\'est pas en ${langue.key}.',
        );
      }
    });

    testWidgets('le titre de section se coupe déjà, et la traduction '
        'n\'aggrave rien', (tester) async {
      // CE TEST NE PRÉTEND PAS QUE LE DÉFAUT A DISPARU. Même forme que celui
      // du bandeau de motorisation, et que « il recouvrait la deuxième carte,
      // et c'est mesuré » dans bandes_filtres_test.dart : on verrouille le
      // chiffre pour que personne ne croie le contraire sur la foi du lot.
      //
      // LE DÉFAUT. `_SectionTitle` pose son libellé dans un `Expanded` qui
      // partage sa rangée avec le lien « Tout voir », et le borne à UNE ligne
      // avec ellipse. À 320 points d'écran et à l'échelle 2,0 il ne reçoit que
      // 103,0 points. « Bonnes affaires » en réclame 200,1 ; même replié sur
      // deux lignes, le seul mot « affaires » en demanderait environ 106. La
      // correction n'est donc pas un `maxLines: 2` : il faut décider où va
      // « Tout voir » quand la place manque, et c'est une décision de mise en
      // page sur un widget partagé par toutes les sections de l'accueil — pas
      // une décision de lot de traduction.
      //
      // CE QUE CE LOT DOIT GARANTIR, EN REVANCHE, C'EST DE NE PAS L'AGGRAVER,
      // et c'est ce que ce test mesure. Le résultat va à l'encontre de
      // l'intuition : c'est le FRANÇAIS le plus large. À 320 × 2,0,
      // « Bonnes affaires » demande 200,1 points et « Good deals » 142,2 —
      // l'anglais en réclame 57,9 de MOINS. La traduction améliore donc cette
      // case au lieu de la dégrader, et la seule chose à surveiller est qu'un
      // futur libellé anglais ne repasse pas devant.
      final demandes = <String, double>{};

      for (final langue in langues.entries) {
        await poser(
          tester,
          page: const HomePage(),
          ongletActif: 0,
          ecran: const Size(320, 640),
          echelle: 2.0,
          locale: langue.value,
        );

        // La vitrine est sous le pli : on descend jusqu'à elle.
        for (var i = 0; i < 6; i++) {
          await tester.drag(
            find
                .descendant(
                  of: find.byType(HomePage),
                  matching: find.byType(Scrollable),
                )
                .first,
            const Offset(0, -240),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }

        final titre = tester.renderObject<RenderParagraph>(
          find.text(titreVitrine[langue.key]!),
        );

        demandes[langue.key] = voulue(titre);

        expect(
          titre.didExceedMaxLines,
          isTrue,
          reason:
              'Le titre de la vitrine ne se coupe plus en ${langue.key} à '
              '320 points et à l\'échelle 2,0 : '
              '${voulue(titre).toStringAsFixed(1)} points voulus pour '
              '${recue(titre).toStringAsFixed(1)} reçus. S\'il a été corrigé, '
              'retirez ce test ET l\'entrée `defautsConnus` du tableau, pour '
              'que le titre repasse sous la règle générale.',
        );
      }

      expect(
        demandes['en'],
        lessThanOrEqualTo(demandes['fr']! + 0.01),
        reason:
            'Le titre de la vitrine est devenu PLUS large en anglais '
            '(${demandes['en']!.toStringAsFixed(1)} points) qu\'en français '
            '(${demandes['fr']!.toStringAsFixed(1)}) : la traduction aggrave '
            'une troncature qu\'elle ne causait pas. C\'est précisément ce que '
            'ce lot avait pour consigne de ne pas faire.',
      );
    });

    testWidgets('le bandeau de motorisation déborde déjà, par DEUX '
        'paragraphes, et les deux chiffres sont verrouillés', (tester) async {
      // CE TEST NE PRÉTEND PAS QUE LE DÉFAUT A DISPARU. Il n'a pas disparu, et
      // c'est écrit ici plutôt que caché derrière une assertion relâchée —
      // même forme que « il recouvrait la deuxième carte, et c'est mesuré »
      // dans bandes_filtres_test.dart.
      //
      // LE DÉFAUT, ET SA FORME. Dans `engine_prompt.dart`, le bandeau pose une
      // icône, un `Expanded` de deux paragraphes et un bouton « Compléter »
      // dans la même rangée. L'`Expanded` reçoit ce que l'icône et le bouton
      // laissent : 101,07 points à l'échelle 1,5 sur un écran de 320, et 72,40
      // à l'échelle 2,0. Un mot plus large que sa ligne est posé seul et
      // déborde HORIZONTALEMENT, sans que le paragraphe se déclare tronqué —
      // `didExceedMaxLines` reste faux, et les glyphes passent sous le bouton.
      //
      // LES DEUX PARAGRAPHES, ET C'EST LA CORRECTION DU RELECTEUR. Ce test
      // n'en mesurait qu'un, pendant que l'exclusion du tableau écartait le
      // sous-arbre entier : le second a donc vécu sans chiffre.
      //
      //   « Motorisation non renseignée »   mot « Motorisation »
      //       123,51 pt à l'échelle 1,5, 163,69 à 2,0
      //       → déborde en 320×1,5 (101,07 reçus), puis aux TROIS largeurs à
      //         2,0 : 72,40 reçus à 320, 112,40 à 360, 163,40 à 411 — cette
      //         dernière case ne manque que de 0,29 point.
      //       → QUATRE cases sur douze.
      //
      //   « Sans elle, impossible de … »    mot « impossible »
      //       91,44 pt à l'échelle 1,5, 120,59 à 2,0
      //       → tient en 320×1,5 (91,44 pour 101,07) ; déborde à 2,0 en 320
      //         (72,40 reçus) et en 360 (112,40), pas en 411 (163,40).
      //       → DEUX cases sur douze.
      //
      // IL EST ANTÉRIEUR À LA TRADUCTION ET INDÉPENDANT D'ELLE : les mêmes
      // chiffres au centième dans les deux langues, parce que le bandeau n'est
      // pas traduit par ce lot — c'est un widget du garage, employé aussi par
      // `garage_page.dart`. Les deux paragraphes ont la MÊME cause et donc la
      // même correction : décider où va le bouton quand la place manque. Ce
      // n'est pas une décision de lot de traduction, et un `maxLines` posé sur
      // la phrase ne corrigerait rien — il couperait une chaîne de
      // l'application, ce que ce dépôt refuse.
      //
      // Le jour où le bandeau sera corrigé, ce test tombera — et c'est voulu :
      // il faudra alors le retirer et rendre les deux paragraphes à la règle
      // générale, en vidant `bandeauDeborde` au-dessus.

      /// Le paragraphe de [texte] du bandeau, sur l'écran monté.
      RenderParagraph duBandeau(String texte) =>
          tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(MissingEngineBanner),
              matching: find.text(texte),
            ),
          );

      /// Les deux lectures que ce défaut demande, sur un paragraphe donné.
      ///
      /// La seconde n'est pas décorative : si le paragraphe se déclarait
      /// tronqué, le texte se perdrait d'une AUTRE façon et la mesure du
      /// segment insécable n'en rendrait plus compte.
      void deborde(RenderParagraph p, String ou) {
        expect(
          motLePlusLarge(p),
          greaterThan(recue(p)),
          reason:
              'Le bandeau de motorisation ne déborde plus en $ou, sur '
              '« ${texteDe(p)} » : ${motLePlusLarge(p).toStringAsFixed(2)} '
              'points de segment insécable pour '
              '${recue(p).toStringAsFixed(2)} reçus. S\'il a été corrigé, '
              'retirez ce test ET l\'entrée de `bandeauDeborde` ci-dessus, '
              'pour que le paragraphe repasse sous la règle générale.',
        );

        expect(
          p.didExceedMaxLines,
          isFalse,
          reason:
              '$ou : « ${texteDe(p)} » se déclare maintenant tronqué. C\'est '
              'une AUTRE façon de perdre le texte, et la mesure du segment '
              'insécable n\'en rend plus compte. Remesurez.',
        );
      }

      // 320 × 1,5 : le titre déborde, la phrase NON. C'est la case qui montre
      // que les deux paragraphes ne tombent pas ensemble, donc qu'un seul
      // chiffre ne pouvait pas décrire le bandeau.
      await poser(
        tester,
        page: const HomePage(),
        ongletActif: 0,
        ecran: const Size(320, 640),
        echelle: 1.5,
        locale: localeFr,
      );

      deborde(duBandeau('Motorisation non renseignée'), '320×1,5');

      final phraseA15 = duBandeau(
        'Sans elle, impossible de savoir quelles pièces vont sur ce véhicule.',
      );
      expect(
        motLePlusLarge(phraseA15),
        lessThanOrEqualTo(recue(phraseA15) + 0.01),
        reason:
            'La phrase du bandeau déborde maintenant dès l\'échelle 1,5 : '
            '${motLePlusLarge(phraseA15).toStringAsFixed(2)} points pour '
            '${recue(phraseA15).toStringAsFixed(2)} reçus. Le défaut s\'est '
            'AGGRAVÉ — il ne touchait que l\'échelle 2,0 — et le compte de '
            'cases du commentaire ci-dessus est devenu faux.',
      );

      // 320 × 2,0 : les DEUX débordent. C'est la case du second chiffre, celle
      // que l'exclusion par sous-arbre dissimulait.
      await poser(
        tester,
        page: const HomePage(),
        ongletActif: 0,
        ecran: const Size(320, 640),
        echelle: 2.0,
        locale: localeFr,
      );

      for (final texte in bandeauDeborde) {
        deborde(duBandeau(texte), '320×2,0');
      }
    });

    testWidgets('le libellé d\'échéance mélange la phrase traduite et le '
        'libellé du serveur', (tester) async {
      // CE TEST DIT UN ÉTAT, PAS UN IDÉAL. Les libellés d'échéance — « Visite
      // technique », « Assurance », « Vidange » — et leurs détails sont
      // composés par l'API, et la vague serveur ne fait pas partie de ce lot.
      // En anglais, l'accueil affiche donc « Visite technique overdue by 11
      // days ». C'est volontaire et c'est écrit ici, pour que personne ne le
      // découvre sur une capture d'écran en croyant à un oubli.
      await poser(
        tester,
        page: const HomePage(),
        ongletActif: 0,
        ecran: const Size(411, 923),
        echelle: 1.0,
        locale: localeEn,
      );

      expect(
        find.text('Visite technique overdue by 11 days'),
        findsOneWidget,
        reason:
            'Soit la phrase n\'est plus traduite, soit le serveur est passé à '
            'l\'anglais — et dans ce second cas, c\'est ce test qu\'il faut '
            'mettre à jour, avec la vague serveur.',
      );
    });
  });

  // ── Les barres de titre du catalogue ──────────────────────────────────────

  /// Les trois autres pages de la coque ne sont traduites que par leur BARRE DE
  /// TITRE dans ce lot : leur corps — filtres, badges, cartes — reste français.
  /// On ne mesure donc ici que ce qui a changé, et on le dit : mesurer leur
  /// corps « en anglais » mesurerait du français et donnerait une couverture
  /// imaginaire.
  group('Les barres de titre du catalogue', () {
    final pages = <String, (Widget, int, String Function(AppLocalizations))>{
      'Véhicules': (const VehicleListPage(), 1, (l) => l.commonVehicles),
      'Accessoires': (const AccessoryListPage(), 2, (l) => l.commonAccessories),
      'Pièces': (const PartListPage(), 3, (l) => l.catalogPartListTitle),
    };

    for (final page in pages.entries) {
      for (final ecran in ecrans.entries) {
        for (final echelle in echelles) {
          for (final langue in langues.entries) {
            testWidgets(
              '${page.key} en ${ecran.key}, texte x$echelle, ${langue.key}',
              (tester) async {
                await poser(
                  tester,
                  page: page.value.$1,
                  ongletActif: page.value.$2,
                  ecran: ecran.value,
                  echelle: echelle,
                  locale: langue.value,
                  session: const AuthState(
                    type: AuthType.staff,
                    staffUser: StaffUser(
                      id: 1,
                      name: 'Administrateur',
                      email: 'admin@autoparc.bf',
                      role: 'admin',
                    ),
                  ),
                );

                final attendu = page.value.$3(
                  await chargerTextes(langue.value),
                );

                final titre = tester.renderObject<RenderParagraph>(
                  find.descendant(
                    of: find.byType(AppBar),
                    matching: find.text(attendu),
                  ),
                );

                expect(
                  titre.didExceedMaxLines,
                  isFalse,
                  reason:
                      '« $attendu » est COUPÉ dans la barre de titre en '
                      '${ecran.key} à l\'échelle $echelle : '
                      '${voulue(titre).toStringAsFixed(1)} points voulus pour '
                      '${recue(titre).toStringAsFixed(1)} reçus, il n\'en '
                      'reste que « ${peint(titre, recue(titre))} ».',
                );

                expect(
                  motLePlusLarge(titre),
                  lessThanOrEqualTo(recue(titre) + 0.01),
                  reason:
                      'Un mot de « $attendu » fait '
                      '${motLePlusLarge(titre).toStringAsFixed(1)} points pour '
                      '${recue(titre).toStringAsFixed(1)} reçus : il sera '
                      'rogné sans ellipse.',
                );
              },
            );
          }
        }
      }
    }
  });
}

/// Le garage du Prado, sans réseau.
class _GarageDuPrado extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => [
    OwnedVehicle.fromJson({
      'id': 1,
      'designation': 'Toyota Land Cruiser Prado 2016 3,0 l boîte automatique',
      'nickname': 'Le Prado du chantier de Bobo',
      'brand_id': 1,
      'vehicle_model_id': 7,
      'year': 2016,
      'mileage_km': 246965,
      'identity': {
        'brand': 'Toyota',
        'brand_slug': 'toyota',
        'model': 'Land Cruiser Prado',
      },
      'compatibility_ready': false,
      'deadlines': [
        {
          'kind': 'technical_inspection',
          'label': 'Visite technique',
          'due_on': null,
          'days_left': -11,
          'overdue': true,
          'detail': null,
        },
        {
          'kind': 'insurance',
          'label': 'Assurance',
          'due_on': null,
          'days_left': 21,
          'overdue': false,
          'detail': null,
        },
        {
          'kind': 'service',
          'label': 'Vidange',
          'due_on': null,
          'days_left': null,
          'overdue': true,
          'detail': 'dépassée de 300 km',
        },
      ],
    }),
  ];
}

/// Un dépôt qui ne répond jamais : les pages du catalogue restent sur leur
/// indicateur, ce qui suffit pour mesurer leur barre de titre.
class _DepotMuet implements CatalogRepository {
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Une session figée, sans Firebase.
///
/// Le vrai `AuthNotifier` s'abonne à Firebase dès son constructeur, ce qu'un
/// banc ne peut pas satisfaire.
class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}
