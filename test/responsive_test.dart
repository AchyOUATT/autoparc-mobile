import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/accessory.dart';
import 'package:auto/features/catalog/data/models/part.dart';
import 'package:auto/features/catalog/presentation/pages/add_accessory_page.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/cart/presentation/pages/cart_page.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/add_part_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/features/garage/presentation/pages/garage_page.dart';
import 'package:auto/features/home/presentation/pages/home_page.dart';
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
  const echelles = <double>[1.0, 1.3];

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
                  ],
                  child: MaterialApp(home: entree.value.$1),
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
}

Accessory _accessoire() => Accessory.fromJson({
      'id': 1,
      'name': 'Tapis de sol caoutchouc toutes saisons, jeu de quatre',
      'sku': 'TAP-4S-001',
      'category': {'value': 'confort', 'label': 'Confort'},
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
