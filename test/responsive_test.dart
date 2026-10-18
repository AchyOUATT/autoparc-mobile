import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/update/ecran_mise_a_jour.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/add_accessory_page.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/cart/presentation/pages/cart_page.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_detail_page.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/add_part_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/garage/data/models/fuel_fill.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/pages/fuel_fills_page.dart';
import 'package:auto/features/garage/presentation/pages/garage_page.dart';
import 'package:auto/features/garage/presentation/providers/fuel_fills_provider.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/home/presentation/pages/home_page.dart';
import 'package:auto/features/home/presentation/providers/home_providers.dart';
import 'package:auto/features/needs/presentation/pages/client_needs_page.dart';
import 'package:auto/features/needs/presentation/pages/needs_list_page.dart';
import 'package:auto/features/needs/presentation/pages/submit_need_page.dart';
import 'package:auto/features/notifications/presentation/pages/notifications_page.dart';
import 'package:auto/features/partners/presentation/pages/partner_form_page.dart';
import 'package:auto/features/partners/presentation/pages/partner_list_page.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_detail_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/garage/presentation/pages/add_vehicle_to_garage_page.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/data/media_repository.dart';
import 'package:auto/shared/presentation/pages/media_upload_page.dart';
import 'package:auto/l10n/app_localizations.dart';

import 'support/echelles.dart';
import 'support/langues.dart';

/// Les écrans tiennent-ils sur un petit téléphone, et avec de gros caractères ?
///
/// Deux conditions que rien ne vérifiait, et qui ne se voient pas sur
/// l'émulateur par défaut — un Pixel fait 411 points de large, et le texte y
/// est à l'échelle 1.
///
/// Le parc visé est tout autre : des téléphones d'entrée de gamme à 320 points,
/// et des gens qui grossissent les caractères du système parce qu'ils lisent
/// mal. Un débordement n'y est pas cosmétique — Flutter peint une bande
/// rayée jaune et noir par-dessus le contenu, et ce qui est dessous devient
/// illisible, parfois intouchable.
///
/// La vérification est mécanique : `RenderFlex overflowed` est une exception
/// levée pendant la peinture, et `tester.takeException()` la rend. Ces tests
/// échouent donc d'eux-mêmes à la première ligne qui ne rentre plus — c'est
/// tout l'intérêt de les poser maintenant plutôt que de relire les écrans.
///
/// Un mot sur la marge que ces tests prennent. Le banc d'essai de Flutter ne
/// charge pas Roboto : il utilise une police de test dont chaque caractère est
/// un carré de la taille du corps. Un titre de 28 signes en 16 points y mesure
/// 448 points, contre environ 240 à l'écran — près du double. C'est donc un
/// pire cas, et volontairement : une mise en page qui tient sous cette police
/// tient avec n'importe quel corps de caractères, n'importe quelle traduction
/// plus bavarde, et le grossissement système poussé plus loin que 1,3.
///
/// C'est ainsi que le débordement du bloc VIN a été trouvé : un `Text` posé
/// brut dans un `Row` réclame toute sa largeur naturelle, et rien ne l'en
/// empêche. Le défaut existait depuis le début ; seule la largeur du texte
/// décidait s'il se voyait.
void main() {
  // ── Référentiel minimal ──────────────────────────────────────────────────

  const marque  = BrandRef(id: 3, name: 'Toyota', isActive: true);
  const corolla = ModelRef(id: 11, brandId: 3, name: 'Corolla');

  const refs = CatalogRefs(
    brands: [marque],
    vehicleModels: [corolla],
    trims: [],
    engineTypes: [],
    drivetrains: [],
    colors: [],
    features: [],
    locations: [],
  );

  /// Les tailles d'écran et d'échelle de texte a tenir.
  ///
  /// 320 points : le plus petit format encore courant (Galaxy A01, iPhone SE
  /// premiere generation). 360 : la mediane du parc Android.
  const formats = <String, Size>{
    '320x640': Size(320, 640),
    '360x720': Size(360, 720),
  };

  /// Les échelles de texte du système. 1,3 correspond au deuxième cran des
  /// réglages Android ; au-delà, Flutter autorise jusqu'à 2.
  ///
  /// ── POURQUOI CETTE LISTE S'ARRÊTE AVANT LES AUTRES BANCS ────────────────
  ///
  /// `support/echelles.dart` asserte jusqu'à 1,5. Ce banc s'arrête à 1,3, et ce
  /// n'est ni un oubli ni un relâchement : il ne charge PAS Roboto. Le banc
  /// d'essai de Flutter peint alors chaque caractère comme un carré du corps du
  /// texte — « 95 000 km • Essence » y mesure 228,0 points contre 117,1 avec
  /// Roboto, presque le DOUBLE. L'échelle 1,3 sous cette police vaut donc à peu
  /// près 2,6 sous Roboto, soit bien au-delà de la frontière que ces échelles
  /// nomment. Monter à 1,5 ici n'éprouverait aucun téléphone réel ; ce serait
  /// exiger qu'un écran tienne à l'échelle 3.
  ///
  /// CE QUI EST VÉRIFIÉ, EN REVANCHE, c'est que cette liste reste DANS le
  /// domaine asserté — le test de cohérence ci-dessous. Si le propriétaire
  /// déplaçait la frontière sous 1,3, ce banc exigerait plus que la règle, et il
  /// faut qu'il le dise au lieu de le faire en silence.
  const echelles = <double>[1.0, 1.3];

  test('les échelles de ce banc sont dans le domaine ASSERTÉ', () {
    // Non-vacuité de la règle partagée, vue d'ici. Ce banc porte la police de
    // repli et sa propre liste ; il doit au moins garantir qu'il n'exige pas
    // au-delà de ce que `support/echelles.dart` autorise à exiger.
    for (final echelle in echelles) {
      expect(
        tenue(echelle),
        isTrue,
        reason:
            'Ce banc exige l\'absence de débordement à l\'échelle $echelle, '
            'alors que la règle partagée ne garantit que jusqu\'à '
            '$echelleTenue. Soit la frontière a bougé — et il faut retirer '
            'cette échelle d\'ici —, soit cette liste a grandi sans qu\'on '
            'relise `support/echelles.dart`.',
      );
    }
  });

  Future<void> poser(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Pompe un écran à une taille donnée et rend l'exception de mise en page,
  /// s'il y en a une.
  ///
  /// `marqueur` n'est pas une politesse : un écran resté sur son indicateur de
  /// chargement ne déborde jamais, et le test passerait sans avoir rien
  /// mesuré. Chaque cas nomme donc un texte qui n'apparaît qu'une fois la page
  /// réellement dessinée.
  Future<Object?> deborde(
    WidgetTester tester,
    Widget ecran, {
    required Size taille,
    required double echelle,
    required String marqueur,
  }) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: taille,
          textScaler: TextScaler.linear(echelle),
          // Les creux du systeme, que ce banc ignorait.
          //
          // Sans eux, MediaQueryData les laisse a zero : on mesurait un
          // appareil sans barre d'etat ni barre de navigation, c'est-a-dire
          // aucun appareil reel. Environ 72 points de hauteur etaient offerts
          // gratuitement a chaque ecran, et un debordement qui se voit sur un
          // telephone passait ici au vert.
          //
          // 48 en bas : la barre a trois boutons — retour, accueil, applis
          // ouvertes. C'est le cas le plus contraignant, et donc le bon a
          // tenir : un ecran qui passe avec elle passe aussi en navigation
          // gestuelle, ou le creux n'est que d'une vingtaine de points.
          padding: const EdgeInsets.only(top: 24, bottom: 48),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
        ),
        child: ecran,
      ),
    );
    await poser(tester);

    final erreur = tester.takeException();
    if (erreur != null) return erreur;

    expect(
      find.textContaining(marqueur, findRichText: true),
      findsWidgets,
      reason: 'L\'écran ne s\'est pas dessiné : rien n\'a été mesuré.',
    );

    return null;
  }

  /// Déroule un écran de haut en bas : un débordement peut n'apparaître que
  /// sur une ligne encore hors champ au premier rendu.
  Future<Object?> debordeEnDefilant(
    WidgetTester tester,
    Widget ecran, {
    required Size taille,
    required double echelle,
    required String marqueur,
  }) async {
    final immediat = await deborde(
      tester,
      ecran,
      taille: taille,
      echelle: echelle,
      marqueur: marqueur,
    );
    if (immediat != null) return immediat;

    final defilable = find.byType(Scrollable);
    if (defilable.evaluate().isEmpty) return null;

    for (var i = 0; i < 12; i++) {
      await tester.drag(defilable.first, const Offset(0, -260));
      await poser(tester);
      final erreur = tester.takeException();
      if (erreur != null) return erreur;
    }

    return null;
  }

  // ── Le garage : le formulaire d'ajout ────────────────────────────────────

  Widget formulaireGarage() => ProviderScope(
        overrides: [catalogRefsProvider.overrideWith((_) async => refs)],
        child: const MaterialApp(home: AddVehicleToGaragePage()),
      );

  group('Ajouter un véhicule au garage', () {
    for (final format in formats.entries) {
      for (final echelle in echelles) {
        testWidgets('tient en ${format.key}, texte x$echelle', (tester) async {
          expect(
            await debordeEnDefilant(
              tester,
              formulaireGarage(),
              taille: format.value,
              echelle: echelle,
              marqueur: "Décodage automatique par VIN",
            ),
            isNull,
          );
        });
      }
    }
  });

  // ── La fiche d'un article, côté administration ───────────────────────────

  /// La barre de titre de l'écran de modification porte desormais trois
  /// éléments : le titre, le bouton Photos et le bouton Enregistrer. C'est la
  /// barre la plus chargée de l'application, et celle qui déborde en premier.
  group('Modifier une pièce', () {
    Widget ecranModification() => ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
            catalogRefsProvider.overrideWith((_) async => refs),
          ],
          child: MaterialApp(home: AddPartPage(existing: _piece())),
        );

    for (final format in formats.entries) {
      for (final echelle in echelles) {
        testWidgets('tient en ${format.key}, texte x$echelle', (tester) async {
          expect(
            await debordeEnDefilant(
              tester,
              ecranModification(),
              taille: format.value,
              echelle: echelle,
              marqueur: "Identification",
            ),
            isNull,
          );
        });
      }
    }
  });

  group('Modifier un accessoire', () {
    Widget ecranModification() => ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
            catalogRefsProvider.overrideWith((_) async => refs),
          ],
          child: MaterialApp(home: AddAccessoryPage(existing: _accessoire())),
        );

    for (final format in formats.entries) {
      for (final echelle in echelles) {
        testWidgets('tient en ${format.key}, texte x$echelle', (tester) async {
          expect(
            await debordeEnDefilant(
              tester,
              ecranModification(),
              taille: format.value,
              echelle: echelle,
              marqueur: "Identification",
            ),
            isNull,
          );
        });
      }
    }
  });

  // ── La fiche d'une pièce, vue par un administrateur ──────────────────────

  /// Sa barre de titre porte maintenant trois commandes — Photos, Modifier,
  /// Supprimer — en plus du nom de la pièce, qui peut être long.
  group('Fiche d\'une pièce (admin)', () {
    Widget fiche() => ProviderScope(
          overrides: [
            authProvider.overrideWith((_) => _FauxAuth(_admin())),
            catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
          ],
          child: MaterialApp(
            home: PartDetailPage(partId: 1, initialPart: _piece()),
          ),
        );

    for (final format in formats.entries) {
      for (final echelle in echelles) {
        testWidgets('tient en ${format.key}, texte x$echelle', (tester) async {
          expect(
            await debordeEnDefilant(
              tester,
              fiche(),
              taille: format.value,
              echelle: echelle,
              marqueur: 'Filtre à huile',
            ),
            isNull,
          );
        });
      }
    }
  });

  // ── La fiche d'un accessoire, vue par un administrateur ──────────────────

  /// Cet écran manquait, et c'est la seule raison pour laquelle un débordement
  /// mesuré à la main n'avait pas été vu ici : sa barre de titre portait une
  /// puce de catégorie en plus des quatre commandes — Partager, Photos,
  /// Modifier, Supprimer — et débordait de 9,0 points à 320 × 1,0 et de
  /// 40 points à 320 × 1,3. À 360, elle tenait.
  ///
  /// Le libellé de catégorie compte autant que le format, et c'est pourquoi
  /// `_accessoire()` porte « Multimédia » : avec « Confort », sept signes, la
  /// barre tenait à 320 et le banc serait resté vert sur un écran cassé.
  group('Fiche d\'un accessoire (admin)', () {
    Widget fiche() => ProviderScope(
          overrides: [
            authProvider.overrideWith((_) => _FauxAuth(_admin())),
            catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
          ],
          child: MaterialApp(
            home: AccessoryDetailPage(
              accessoryId: 1,
              initialAccessory: _accessoire(),
            ),
          ),
        );

    for (final format in formats.entries) {
      for (final echelle in echelles) {
        testWidgets('tient en ${format.key}, texte x$echelle', (tester) async {
          expect(
            await debordeEnDefilant(
              tester,
              fiche(),
              taille: format.value,
              echelle: echelle,
              // Un texte du corps, et non le nom de l'article : celui-ci
              // s'affiche dans la barre de titre même sans corps dessiné.
              marqueur: 'Informations',
            ),
            isNull,
          );
        });
      }
    }
  });

  // ── Les autres écrans, en bloc ───────────────────────────────────────────

  /// Chacun est ouvert avec la session qui le concerne — administrateur pour
  /// les écrans de gestion, client pour ceux du garage — et des dépôts muets.
  /// Le rôle compte : il décide des commandes affichées, donc du contenu des
  /// barres de titre, et l'administrateur est celui qui en voit le plus.
  ///
  /// Ce que ce bloc vérifie exactement : la structure de chaque écran, son
  /// état de chargement et son état vide, tous déroulés jusqu'en bas. Pas ses
  /// listes remplies, qui demanderaient le jeu de données de chaque écran.
  /// C'est pourtant là que les débordements se trouvent, parce qu'ils viennent
  /// de la mise en page et non du contenu : les cinq trouvés ici — le titre du
  /// bloc VIN, la ligne de prix, l'en-tête des partenaires, l'en-tête d'un
  /// critère de besoin, les deux boutons d'un panier vide — étaient tous dans
  /// du texte fixe, plus deux menus déroulants sans `isExpanded`.
  final ecrans = <String, (Widget, String, AuthState)>{
    'Accueil':            (const HomePage(),            'Accueil',          _admin()),
    'Pièces':             (const PartListPage(),        'Pièces détachées', _admin()),
    'Accessoires':        (const AccessoryListPage(),   'Accessoires',      _admin()),
    'Véhicules':          (const VehicleListPage(),     'Véhicules',        _admin()),
    'Mon garage':         (const GaragePage(),          'Mon garage',       _client()),
    'Profil du personnel': (const GaragePage(),         'Mon profil',       _admin()),
    'Panier':             (const CartPage(),            'Panier',           _client()),
    'Besoins clients':    (const NeedsListPage(),       'Besoins clients',  _admin()),
    'Mes besoins':        (const ClientNeedsPage(),     'Mes besoins',      _client()),
    'Exprimer un besoin': (const SubmitNeedPage(),      'besoin',           _client()),
    'Notifications':      (const NotificationsPage(),   'Notifications',    _admin()),
    'Partenaires':        (const PartnerListPage(),     'Partenaires',      _admin()),
    'Nouveau partenaire': (const PartnerFormPage(),     'partenaire',       _admin()),
    'Mettre en vente':    (const VehicleRegisterPage(), 'véhicule',         _admin()),
  };

  /// Les surcharges propres à un écran, en plus des trois communes.
  ///
  /// **« Accueil » MESURAIT UN ÉCRAN VIDE.** Les trois surcharges communes
  /// posent un dépôt muet ; `homeDealsProvider` ne résolvait donc jamais, et
  /// `_DealsSection` rend `SizedBox.shrink()` sur tout ce qui n'est pas
  /// `data` : la vitrine n'existait pas au rendu. Le carrousel débordait de
  /// 26 points à l'échelle 1,0 et de 65 à 1,3 — dès le premier rendu, aux
  /// trois largeurs, avec ou sans photo — et ce groupe restait vert.
  ///
  /// C'est le défaut de méthode que corrige cette carte : un écran dont les
  /// sections dépendent d'un `FutureProvider` ne se mesure pas avec un dépôt
  /// muet. Le marqueur « Accueil » ne protégeait pas de ça — il n'est que le
  /// titre de la barre, et il s'affiche même quand le corps est vide.
  ///
  /// Un seul véhicule suffit, et c'est volontaire : le carrousel défile
  /// horizontalement, donc c'est la HAUTEUR d'une tuile qui déborde, jamais
  /// leur nombre.
  final surcharges = <String, List<Override>>{
    'Accueil': [homeDealsProvider.overrideWith((_) async => [_affaire()])],
  };

  for (final entree in ecrans.entries) {
    group(entree.key, () {
      for (final format in formats.entries) {
        for (final echelle in echelles) {
          testWidgets('tient en ${format.key}, texte x$echelle',
              (tester) async {
            expect(
              await debordeEnDefilant(
                tester,
                ProviderScope(
                  overrides: [
                    authProvider
                        .overrideWith((_) => _FauxAuth(entree.value.$3)),
                    catalogRepositoryProvider
                        .overrideWithValue(_DepotMuet()),
                    catalogRefsProvider.overrideWith((_) async => refs),
                    ...?surcharges[entree.key],
                  ],
                  // Les quatorze écrans du tableau passent par ici. Voir
                  // test/support/langues.dart : sans `locale:`, ceux qui sont
                  // traduits auraient été mesurés en anglais, et le marqueur
                  // français de la barre de titre les aurait fait tomber.
                  child: MaterialApp(
                    locale: localeFr,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: entree.value.$1,
                  ),
                ),
                taille: format.value,
                echelle: echelle,
                marqueur: entree.value.$2,
              ),
              isNull,
            );
          });
        }
      }
    });
  }

  // ── L'écran des photos ───────────────────────────────────────────────────

  /// Il n'était atteignable que dans la seconde suivant la création d'un
  /// article, et plus jamais ensuite : personne ne l'avait donc jamais vu avec
  /// des photos déjà en place, ni sur un petit écran.
  group('Photos d\'un article', () {
    Widget ecranPhotos(List<MediaItem> deja) => ProviderScope(
          overrides: [
            mediaRepositoryProvider.overrideWithValue(_DepotMedia(deja)),
          ],
          child: const MaterialApp(
            home: MediaUploadPage(
              config: MediaUploadConfig(
                type: MediaOwnerType.part,
                id: 1,
                title: 'Filtre à huile moteur cartouche 04152-YZZA1',
              ),
            ),
          ),
        );

    for (final format in formats.entries) {
      for (final echelle in echelles) {
        testWidgets('vide, en ${format.key}, texte x$echelle', (tester) async {
          expect(
            await debordeEnDefilant(
              tester,
              ecranPhotos(const []),
              taille: format.value,
              echelle: echelle,
              marqueur: "Aucune photo",
            ),
            isNull,
          );
        });

        testWidgets('avec photos, en ${format.key}, texte x$echelle',
            (tester) async {
          expect(
            await debordeEnDefilant(
              tester,
              ecranPhotos(_photos()),
              taille: format.value,
              echelle: echelle,
              marqueur: "Cover",
            ),
            isNull,
          );
        });
      }
    }
  });

  // ── Les passages à la pompe ──────────────────────────────────────────────

  /// L'écran le plus dense du garage : chaque ligne empile le compteur, les
  /// litres et le montant sur un titre, puis la nature du passage, sa date, la
  /// consommation de son intervalle et le motif de son écart sur trois
  /// sous-titres — le tout entre une icône et un bouton de suppression. Il est
  /// aussi le seul à porter un bouton flottant étendu, qui mange la largeur
  /// restante en bas.
  ///
  /// Les deux états sont mesurés comme pour les photos d'un article : vide, il
  /// n'a qu'un bloc d'explication centré ; rempli, il a tout le reste. Une
  /// mise en page ne déborde pas de la même façon dans les deux.
  group('Passages à la pompe', () {
    Widget ecranCarburant(List<FuelFill> passages) => ProviderScope(
          overrides: [
            fuelFillsProvider.overrideWith(() => _Passages(passages)),
            garageProvider.overrideWith(_GarageAvecCamry.new),
          ],
          child: const MaterialApp(home: FuelFillsPage(ownedVehicleId: 1)),
        );

    for (final format in formats.entries) {
      for (final echelle in echelles) {
        testWidgets('vide, en ${format.key}, texte x$echelle', (tester) async {
          expect(
            await debordeEnDefilant(
              tester,
              ecranCarburant(const []),
              taille: format.value,
              echelle: echelle,
              marqueur: 'Aucun passage enregistré',
            ),
            isNull,
          );
        });

        testWidgets('avec des passages, en ${format.key}, texte x$echelle',
            (tester) async {
          expect(
            await debordeEnDefilant(
              tester,
              ecranCarburant(_passages()),
              taille: format.value,
              echelle: echelle,
              // « Demi-plein » ne s'écrit que sur une ligne dessinée : le
              // titre de la barre, lui, s'affiche même pendant le chargement
              // et ne prouverait rien.
              marqueur: 'Demi-plein',
            ),
            isNull,
          );
        });
      }
    }
  });

  // ── L'écran de mise à jour obligatoire ───────────────────────────────────

  /// Celui-ci mérite le banc plus que les autres. Un débordement ailleurs se
  /// contourne : on quitte l'écran. Ici il n'y a pas de sortie — c'est tout
  /// l'objet de l'écran —, et la bande rayée se peindrait par-dessus la seule
  /// commande disponible. L'application deviendrait un mur.
  ///
  /// Le message vient du serveur, donc sa longueur n'est pas un paramètre que
  /// l'application maîtrise : on mesure avec une phrase longue, puisque c'est
  /// elle qui décide si ça tient.
  group('Mise à jour obligatoire', () {
    Widget ecranBloquant() => const MaterialApp(
          // Le bouton de cet écran est traduit depuis le lot de langue. Voir
          // test/support/langues.dart : sans `locale:`, la coque mesurerait
          // l'anglais.
          locale: localeFr,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EcranMiseAJour(
            message: "Cette version de l'application ne peut plus lire les "
                'prix du catalogue depuis le serveur. Installez la dernière '
                'version pour continuer à consulter vos véhicules.',
            urlStore:
                'https://play.google.com/store/apps/details?id=bf.autoparc',
          ),
        );

    for (final format in formats.entries) {
      for (final echelle in echelles) {
        testWidgets('tient en ${format.key}, texte x$echelle', (tester) async {
          expect(
            await debordeEnDefilant(
              tester,
              ecranBloquant(),
              taille: format.value,
              echelle: echelle,
              marqueur: 'Mettre à jour',
            ),
            isNull,
          );
        });
      }
    }
  });
}

/// Trois passages, dont le pire cas de ligne : un plein dont l'intervalle a
/// été écarté, qui porte donc à la fois sa consommation, sa distance, la
/// mention « écarté » et le motif rédigé. Le motif retenu est
/// `anormalement_bas`, le plus long des trois libellés — c'est lui qui pousse
/// le sous-titre, et la mesure de débordement ne vaut que sur le pire texte.
///
/// Dans l'ordre du serveur, compteur DÉCROISSANT : la page n'inverse plus la
/// liste, et un jeu posé à l'envers la ferait mesurer sur une mise en page que
/// personne ne voit.
List<FuelFill> _passages() => const [
      FuelFill(
        id: 3,
        isFull: true,
        mileageKm: 197400,
        litres: 41.2,
        amountFcfa: 130000,
        l100km: 4.0,
        distanceKm: 1000,
        retenu: false,
        motifEcart: 'anormalement_bas',
      ),
      FuelFill(
          id: 2,
          isFull: false,
          mileageKm: 95600,
          litres: 13.7,
          amountFcfa: 10000),
      FuelFill(
          id: 1,
          isFull: true,
          mileageKm: 95000,
          litres: 40.0,
          amountFcfa: 29000),
    ];

class _Passages extends FuelFillsNotifier {
  _Passages(this.liste);

  final List<FuelFill> liste;

  @override
  Future<List<FuelFill>> build(int ownedVehicleId) async => liste;
}

/// Le véhicule que la page retrouve dans le garage : sans lui, ni titre
/// complet ni bouton flottant, et c'est précisément ce qui charge l'écran.
/// Le surnom est long à dessein — c'est lui qui pousse la barre de titre.
class _GarageAvecCamry extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => const [
        OwnedVehicle(
          id: 1,
          designation: 'Toyota Camry 2013 2,5 l boîte automatique',
          nickname: 'La Camry de la famille',
          brandId: 1,
          vehicleModelId: 7,
          year: 2013,
          mileageKm: 197400,
          identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Camry'),
          compatibilityReady: true,
        ),
      ];
}

Accessory _accessoire() => Accessory.fromJson({
      'id': 1,
      'name': 'Tapis de sol caoutchouc toutes saisons, jeu de quatre',
      'sku': 'TAP-4S-001',
      // « Multimédia » et non « Confort » : dix signes contre sept, à égalité
      // avec « Esthétique » et « Utilitaire » pour le plus long des cinq
      // libellés. C'est lui qui décidait si la barre de la fiche débordait —
      // 129,0 points de puce contre 95,7 —, donc le seul qui mesure quelque
      // chose. Le libellé le plus court aurait rendu le banc complaisant.
      'category': {'value': 'multimedia', 'label': 'Multimédia'},
      'pricing': {
        'selling_price': 12000,
        'currency': 'XOF',
        'vat_rate': 0,
        'price_including_vat': 12000,
      },
      'stock': {
        'is_available': true,
        'quantity': 15,
        'alert_threshold': 0,
        'is_low': false,
      },
      'is_active': true,
    });

List<MediaItem> _photos() => List.generate(
      5,
      (i) => MediaItem.fromJson({
        'id': i + 1,
        'url': 'https://exemple.test/photo-$i.jpg',
        'collection': 'gallery',
        'is_cover': i == 0,
      }),
    );

Part _piece() => Part.fromJson({
      'id': 1,
      // Un nom long à dessein : c'est lui qui pousse la barre de titre.
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

/// Un véhicule de la vitrine de l'accueil, au pire cas de hauteur.
///
/// La tuile du carrousel empile le nom, la ville quand elle est connue, et le
/// prix. Les trois sont donc renseignés : une tuile sans ville est plus courte,
/// et c'est exactement ce qu'« ajusté au contenu réel » avait mesuré avant de
/// figer 152 points.
///
/// La pastille de promotion vit dans la photo et ne pousse rien ; elle est là
/// parce que `homeDealsProvider` ne sert que des `deal_type` non nuls, et que
/// la fixture doit ressembler à ce que l'écran reçoit.
Vehicle _affaire() => Vehicle.fromJson({
      'id': 1,
      'reference': 'VH-0001',
      'designation': 'Toyota Corolla Base 2015',
      'registration_status': 'registered',
      'identity': {
        'brand': 'Toyota',
        'brand_slug': 'toyota',
        'model': 'Corolla',
        'year': 2015,
      },
      'commercial': {
        'condition': 'used',
        'status': 'in_stock',
        'availability': 'sale',
        'sale_price': '4500000.00',
        'currency': 'XOF',
        'price_negotiable': true,
        'deal_type': 'good_deal',
        'deal_label': 'Bonne affaire',
        'location': {
          'id': 1,
          'name': 'Showroom Paspanga',
          'city': 'Ouagadougou',
        },
      },
      'media': const [],
      'published_at': '2026-09-30T18:42:43+00:00',
    });

/// Un dépôt qui ne répond jamais : l'écran doit se dessiner sans attendre le
/// réseau, et c'est bien sa mise en page qu'on mesure ici.
class _DepotMuet implements CatalogRepository {
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Une session figée, sans Firebase.
///
/// Le vrai `AuthNotifier` s'abonne à Firebase dès son constructeur, ce qu'un
/// test ne peut pas satisfaire. Celui-ci se contente de porter l'état, ce qui
/// suffit : les écrans ne lisent de l'authentification que les capacités.
class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Un administrateur : c'est le rôle qui voit le plus de commandes à l'écran,
/// donc celui dont les barres de titre sont les plus chargées.
AuthState _admin() => const AuthState(
      type: AuthType.staff,
      staffUser: StaffUser(
        id: 1,
        name: 'Administrateur',
        email: 'admin@autoparc.bf',
        role: 'admin',
      ),
    );

/// Un client connecté. Le garage, le panier et « mes besoins » n'existent que
/// pour lui : les ouvrir en administrateur montrerait une autre page.
AuthState _client() => const AuthState(type: AuthType.client);

/// Rend une liste de médias fixée, sans réseau.
class _DepotMedia implements MediaRepository {
  _DepotMedia(this.deja);

  final List<MediaItem> deja;

  @override
  Future<List<MediaItem>> getMedia(MediaOwnerType type, int id) async => deja;

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}
