import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository extends PartnerRepository {
  PartnerProfile? savedProfile;
  Map<String, dynamic>? registration;
  bool loggedOut = false;
  @override
  Future<PartnerProfile?> restore() async => savedProfile;
  @override
  Future<PartnerProfile> register(Map<String, dynamic> fields) async {
    registration = fields;
    return savedProfile = _profile('pending');
  }
  @override
  Future<PartnerProfile> getMe() async => savedProfile!;
  @override
  Future<void> logout() async { loggedOut = true; savedProfile = null; }
}

PartnerProfile _profile(String status) => PartnerProfile(user: const {'role': 'partner'}, account: {
  'company_name': 'Garage Exemple', 'status': status,
  if (status == 'rejected') 'review_reason': 'Téléphone à vérifier',
});

Future<void> _open(WidgetTester tester, _Repository repository) async {
  await tester.pumpWidget(ProviderScope(overrides: [partnerRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: PartnerAccountPage())));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('une inscription réelle du formulaire aboutit à une attente sans gestion', (tester) async {
    final repository = _Repository();
    await _open(tester, repository);
    await tester.tap(find.text('Inscription'));
    await tester.pumpAndSettle();
    for (final entry in {
      'partner-company': 'Garage Exemple', 'partner-contact': 'Awa Exemple',
      'partner-phone': '+22670000000', 'partner-email': 'awa@example.test',
      'partner-password': 'Partenaire12345', 'partner-confirmation': 'Partenaire12345',
    }.entries) {
      final field = find.byKey(Key(entry.key));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    await tester.ensureVisible(find.byKey(const Key('partner-submit')));
    await tester.tap(find.byKey(const Key('partner-submit')));
    await tester.pumpAndSettle();

    expect(repository.registration!['company_name'], 'Garage Exemple');
    expect(repository.registration!['password_confirmation'], 'Partenaire12345');
    expect(find.text('Inscription reçue'), findsOneWidget);
    expect(find.text('Vérifier mon statut'), findsOneWidget);
    expect(find.text('Créer une annonce'), findsNothing);
  });

  testWidgets('le motif du refus reste visible et la déconnexion est disponible', (tester) async {
    final repository = _Repository()..savedProfile = _profile('rejected');
    await _open(tester, repository);

    expect(find.text('Demande refusée'), findsOneWidget);
    expect(find.text('Motif : Téléphone à vérifier'), findsOneWidget);
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(repository.loggedOut, isTrue);
    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets('un compte approuvé accède aux trois inventaires sans rôle personnel', (tester) async {
    final repository = _Repository()..savedProfile = _profile('approved');
    await _open(tester, repository);

    expect(find.text('Compte approuvé'), findsOneWidget);
    expect(find.text('Véhicules'), findsOneWidget);
    expect(find.text('Pièces détachées'), findsOneWidget);
    expect(find.text('Accessoires'), findsOneWidget);
    expect(find.text('Personnel'), findsNothing);
  });
}
