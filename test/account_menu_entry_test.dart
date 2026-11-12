import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/auth/presentation/widgets/client_account_sheet.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/pages/garage_page.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/faux_depot_partenaire.dart';

class _FauxClient extends Fake implements User {
  @override
  String get uid => 'client-1';
  @override
  String get email => 'client@example.test';
  @override
  String get displayName => 'Awa Client';
}

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);

  var deleteCalled = false;
  String? deleteResult;

  @override
  Future<String?> deleteAccount() async {
    deleteCalled = true;
    if (deleteResult == null && state.isClient) {
      state = const AuthState();
    }
    return deleteResult;
  }

  @override
  Future<void> signOut() async {
    state = const AuthState();
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _EmptyGarage extends GarageNotifier {
  @override
  Future<List<OwnedVehicle>> build() async => [];
}

AuthState _client() =>
    AuthState(type: AuthType.client, firebaseUser: _FauxClient());

const _employe = StaffUser(
  id: 1,
  name: 'Awa Traoré',
  email: 'awa@autoparc.bf',
  role: 'admin',
);

Future<AppLocalizations> _l10n(Locale locale) =>
    AppLocalizations.delegate.load(locale);

Future<_Auth> _poserTiroir(
  WidgetTester tester, {
  required AuthState session,
  Locale locale = const Locale('fr'),
  PartnerRepository? depotPartenaire,
}) async {
  final auth = _Auth(session);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => auth),
        if (depotPartenaire != null)
          partnerRepositoryProvider.overrideWithValue(depotPartenaire),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(drawer: AppDrawer(), body: SizedBox.shrink()),
      ),
    ),
  );
  tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
  await tester.pumpAndSettle();
  return auth;
}

FilledButton _boutonSupprimer(WidgetTester tester, String libelle) {
  return tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, libelle),
  );
}

void main() {
  for (final locale in [const Locale('fr'), const Locale('en')]) {
    testWidgets('le menu client ouvre la feuille de compte ($locale)', (
      tester,
    ) async {
      final l10n = await _l10n(locale);
      await _poserTiroir(tester, session: _client(), locale: locale);

      expect(find.text(l10n.garageAccountTitle), findsOneWidget);
      await tester.tap(find.text(l10n.garageAccountTitle));
      await tester.pumpAndSettle();

      expect(find.byType(ClientAccountSheet), findsOneWidget);
      expect(find.text('Awa Client'), findsOneWidget);
      expect(find.text('client@example.test'), findsOneWidget);
      expect(find.text(l10n.garageDeleteAccountTitle), findsOneWidget);

      final titre = tester.widget<Text>(
        find.descendant(
          of: find.widgetWithText(ListTile, l10n.garageDeleteAccountTitle),
          matching: find.text(l10n.garageDeleteAccountTitle),
        ),
      );
      expect(titre.style?.color, Colors.red);
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });
  }

  testWidgets('le personnel ne voit pas Mon compte dans le menu', (
    tester,
  ) async {
    final l10n = await _l10n(const Locale('fr'));
    await _poserTiroir(
      tester,
      session: const AuthState(type: AuthType.staff, staffUser: _employe),
    );

    expect(find.text(l10n.garageAccountTitle), findsNothing);
    expect(find.text(l10n.garageDeleteAccountTitle), findsNothing);
  });

  testWidgets('un partenaire sans session client ne voit pas Mon compte', (
    tester,
  ) async {
    final l10n = await _l10n(const Locale('fr'));
    await _poserTiroir(
      tester,
      session: const AuthState(),
      depotPartenaire: FauxDepotPartenaire()..profilAuCoffre = profilDeBanc(),
    );

    expect(find.text(l10n.garageAccountTitle), findsNothing);
    expect(find.text(l10n.garageDeleteAccountTitle), findsNothing);
  });

  testWidgets('un visiteur ne voit pas Mon compte', (tester) async {
    final l10n = await _l10n(const Locale('fr'));
    await _poserTiroir(tester, session: const AuthState());

    expect(find.text(l10n.garageAccountTitle), findsNothing);
    expect(find.text(l10n.garageDeleteAccountTitle), findsNothing);
  });

  testWidgets('la confirmation exige l\'adresse et n\'est pas relâchée', (
    tester,
  ) async {
    final l10n = await _l10n(const Locale('fr'));
    final auth = await _poserTiroir(tester, session: _client());

    await tester.tap(find.text(l10n.garageAccountTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.garageDeleteAccountTitle));
    await tester.pumpAndSettle();

    expect(find.byType(ClientAccountDeletionDialog), findsOneWidget);
    expect(find.text(l10n.garageAccountDeletionListTitle), findsOneWidget);
    expect(
      _boutonSupprimer(tester, l10n.garageDeletePermanently).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), 'autre@example.test');
    await tester.pump();
    expect(
      _boutonSupprimer(tester, l10n.garageDeletePermanently).onPressed,
      isNull,
    );
    expect(auth.deleteCalled, isFalse);

    await tester.enterText(find.byType(TextField), 'CLIENT@example.test');
    await tester.pump();
    expect(
      _boutonSupprimer(tester, l10n.garageDeletePermanently).onPressed,
      isNotNull,
    );

    await tester.tap(find.text(l10n.garageDeletePermanently));
    await tester.pumpAndSettle();

    expect(auth.deleteCalled, isTrue);
    expect(find.byType(ClientAccountDeletionDialog), findsNothing);
  });

  testWidgets('la pastille du garage ouvre la même feuille', (tester) async {
    final l10n = await _l10n(const Locale('fr'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((_) => _Auth(_client())),
          garageProvider.overrideWith(_EmptyGarage.new),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GaragePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GaragePage), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.garageAccountTitle));
    await tester.pumpAndSettle();

    expect(find.byType(ClientAccountSheet), findsOneWidget);
    expect(find.text(l10n.garageDeleteAccountTitle), findsOneWidget);
    expect(find.text('Awa Client'), findsOneWidget);
  });
}
