import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/part_category.dart';
import 'package:auto/features/catalog/presentation/pages/accessory_list_page.dart';
import 'package:auto/features/catalog/presentation/pages/part_list_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';

/// Les pastilles de filtre à l'écran, et le filtre qu'on ne pourrait plus
/// retirer.
///
/// Les tests de `niveau_categories_test.dart` verrouillent le choix du niveau ;
/// ceux-ci vérifient que l'écran le respecte, et surtout la garde qui évite
/// une impasse : la désélection d'une catégorie passe par sa propre pastille.
/// Si une pastille sélectionnée disparaît — la dernière pièce de sa catégorie
/// vient d'être vendue —, le filtre reste posé et plus aucun geste ne peut le
/// retirer. La liste resterait vide pour le reste de la session.
void main() {
  const marque = BrandRef(id: 3, name: 'Toyota', isActive: true);

  const refs = CatalogRefs(
    brands: [marque],
    vehicleModels: [ModelRef(id: 11, brandId: 3, name: 'Corolla')],
    trims: [],
    engineTypes: [],
    drivetrains: [],
    colors: [],
    features: [],
    locations: [],
  );

  PartCategory cat(int id, String nom, {int? parent, bool propres = false}) =>
      PartCategory(id: id, name: nom, parentId: parent, hasOwnParts: propres);

  /// L'arbre élagué du catalogue de production : une seule branche peuplée.
  final brancheUnique = [
    cat(1, 'Moteur'),
    cat(2, 'Filtres', parent: 1),
    cat(3, 'Filtre à huile', parent: 2, propres: true),
  ];

  /// Deux branches peuplées : les racines se partagent le catalogue.
  final deuxBranches = [
    ...brancheUnique,
    cat(24, 'Freinage'),
    cat(26, 'Plaquettes avant', parent: 24, propres: true),
  ];

  Future<ProviderContainer> ouvrirPieces(
    WidgetTester tester, {
    required List<PartCategory> elague,
    PartFilter filtreInitial = const PartFilter(),
  }) async {
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith((_) => _FauxAuth(_admin())),
      catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
      catalogRefsProvider.overrideWith((_) async => refs),
      partCategoriesProvider.overrideWith((_) async => elague),
      categoriesAvecPiecesProvider.overrideWith((_) async => elague),
      partFilterProvider.overrideWith((_) => filtreInitial),
    ]);
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PartListPage()),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    return container;
  }

  // ── Les pièces ───────────────────────────────────────────────────────────

  /// Le défaut signalé : neuf pastilles, une seule qui menait quelque part.
  testWidgets('aucune pastille quand une seule branche est peuplée',
      (tester) async {
    await ouvrirPieces(tester, elague: brancheUnique);

    expect(find.widgetWithText(FilterChip, 'Moteur'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Filtres'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Filtre à huile'), findsNothing);
  });

  testWidgets('les racines deviennent des pastilles dès qu\'elles se partagent le catalogue',
      (tester) async {
    await ouvrirPieces(tester, elague: deuxBranches);

    expect(find.widgetWithText(FilterChip, 'Moteur'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Freinage'), findsOneWidget);
  });

  /// Les catégories vides ne doivent plus apparaître, même si le référentiel
  /// les connaît : c'est tout l'objet de la correction.
  testWidgets('une catégorie vide n\'a pas de pastille', (tester) async {
    await ouvrirPieces(tester, elague: deuxBranches);

    // Absentes de l'arbre élagué, donc jamais proposées.
    expect(find.widgetWithText(FilterChip, 'Climatisation'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Transmission'), findsNothing);
  });

  // ── La garde contre l'impasse ────────────────────────────────────────────

  /// Le test central de ce fichier.
  testWidgets('un filtre posé sur une catégorie plus proposée est retiré',
      (tester) async {
    final container = await ouvrirPieces(
      tester,
      elague: brancheUnique, // aucune pastille : rien ne peut plus être tapé
      filtreInitial: const PartFilter(categoryId: 24), // « Freinage », vidée
    );
    await tester.pump();

    expect(
      container.read(partFilterProvider).categoryId,
      isNull,
      reason: 'Sans cela, la liste resterait vide sans aucun geste pour la rouvrir.',
    );
  });

  /// L'inverse : un filtre sur une catégorie encore proposée doit survivre.
  /// Un effacement trop large réinitialiserait le filtre à chaque ouverture.
  testWidgets('un filtre sur une catégorie encore proposée est conservé',
      (tester) async {
    final container = await ouvrirPieces(
      tester,
      elague: deuxBranches,
      filtreInitial: const PartFilter(categoryId: 24),
    );
    await tester.pump();

    expect(container.read(partFilterProvider).categoryId, 24);
  });

  // ── Les accessoires ──────────────────────────────────────────────────────

  Future<ProviderContainer> ouvrirAccessoires(
    WidgetTester tester, {
    required Set<String> occupees,
    AccessoryFilter filtreInitial = const AccessoryFilter(),
  }) async {
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith((_) => _FauxAuth(_admin())),
      catalogRepositoryProvider.overrideWithValue(_DepotMuet()),
      catalogRefsProvider.overrideWith((_) async => refs),
      categoriesAccessoiresOccupeesProvider.overrideWith((_) async => occupees),
      accessoryFilterProvider.overrideWith((_) => filtreInitial),
    ]);
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AccessoryListPage()),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    return container;
  }

  testWidgets('seules les catégories d\'accessoires occupées ont une pastille',
      (tester) async {
    await ouvrirAccessoires(tester, occupees: {'confort', 'securite'});

    expect(find.widgetWithText(FilterChip, 'Confort'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Sécurité'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Esthétique'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Multimédia'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Utilitaire'), findsNothing);
  });

  /// Le catalogue d'accessoires de production est vide : les cinq pastilles
  /// menaient toutes nulle part, et la rangée s'affichait quand même.
  testWidgets('un catalogue d\'accessoires vide n\'affiche aucune pastille',
      (tester) async {
    await ouvrirAccessoires(tester, occupees: const {});

    for (final libelle in ['Esthétique', 'Confort', 'Sécurité', 'Multimédia', 'Utilitaire']) {
      expect(find.widgetWithText(FilterChip, libelle), findsNothing);
    }
  });

  testWidgets('un filtre accessoire sur une catégorie vidée est retiré',
      (tester) async {
    final container = await ouvrirAccessoires(
      tester,
      occupees: {'confort'},
      filtreInitial: const AccessoryFilter(category: 'securite'),
    );
    await tester.pump();

    expect(container.read(accessoryFilterProvider).category, isNull);
  });
}

/// Une session figée, sans Firebase : le vrai AuthNotifier s'y abonne dès son
/// constructeur.
class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

AuthState _admin() => const AuthState(
      type: AuthType.staff,
      staffUser: StaffUser(
        id: 1,
        name: 'Administrateur',
        email: 'admin@autoparc.bf',
        role: 'admin',
      ),
    );

/// Un dépôt qui ne répond jamais : seules les pastilles sont mesurées ici.
class _DepotMuet implements CatalogRepository {
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}
