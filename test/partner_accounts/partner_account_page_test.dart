import 'dart:async';

import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository extends PartnerRepository {
  PartnerProfile? savedProfile;
  Map<String, dynamic>? registration;
  bool loggedOut = false;
  /// La couture a change : le notifier lit le COFFRE, puis verifie. Un faux
  /// qui ne modelise que `getMe()` laisserait la lecture du coffre tomber sur
  /// le vrai magasin securise, dont le canal de plateforme n'existe pas en
  /// banc — et la page resterait sur son indicateur de chargement.
  @override
  Future<PartnerSessionStockee?> sessionStockee() async => savedProfile == null
      ? null
      : PartnerSessionStockee(token: 'jeton-de-banc', profile: savedProfile!.toJson());
  @override
  Future<PartnerProfile> register(Map<String, dynamic> fields) async {
    registration = fields;
    return savedProfile = _profile('pending');
  }
  /// Quand elle est posée, `getMe()` attend : c'est ce qui rend la fenêtre
  /// du démarrage optimiste observable.
  Completer<PartnerProfile>? porte;

  @override
  Future<PartnerProfile> getMe() async => porte == null ? savedProfile! : porte!.future;
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
  /// LA FENETRE DU DEMARRAGE OPTIMISTE, VUE DE LA PAGE.
  ///
  /// La page s'ouvre désormais sur le profil enregistré au coffre, sans
  /// attendre le réseau — ce qui supprime l'indicateur bloquant que le
  /// partenaire regardait tourner jusqu'à 60 s sur une instance Render
  /// endormie. Mais le statut affiché vient alors du coffre, et il peut être
  /// périmé : la puce le dit, au lieu d'annoncer « Compte approuvé » sur la
  /// foi d'un enregistrement que rien n'a confirmé.
  testWidgets('pendant la vérification, la puce annonce un statut à confirmer', (tester) async {
    final repository = _Repository()
      ..savedProfile = _profile('approved')
      ..porte = Completer<PartnerProfile>();

    await _open(tester, repository);

    expect(find.text('Statut à confirmer…'), findsOneWidget);
    expect(find.text('Compte approuvé'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: "C'est tout l'objet du démarrage optimiste : plus d'attente "
            'bloquante.');

    // Le serveur répond enfin.
    repository.porte!.complete(_profile('approved'));
    await tester.pumpAndSettle();

    expect(find.text('Compte approuvé'), findsOneWidget);
    expect(find.text('Statut à confirmer…'), findsNothing);
  });

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
    // Laisser le clavier et le défilement se stabiliser avant le clic.
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('partner-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('partner-submit')));
    await tester.pumpAndSettle();

    expect(repository.registration, isNotNull);
    expect(repository.registration!['company_name'], 'Garage Exemple');
    expect(repository.registration!['password_confirmation'], 'Partenaire12345');
    expect(find.text('Inscription reçue'), findsOneWidget);
    expect(find.text('Vérifier mon statut'), findsOneWidget);
    expect(find.text('Créer une annonce'), findsNothing);
  });

  /// ── L'ENTREPRISE N'EST PLUS EXIGEE ──────────────────────────────────────
  ///
  /// Le vendeur type ici est un particulier ou un petit revendeur sans raison
  /// sociale. L'exiger lui faisait inventer un nom, ou abandonner
  /// l'inscription — et la seconde perte est muette.
  testWidgets('une inscription sans nom d’entreprise part quand même',
      (tester) async {
    final repository = _Repository();
    await _open(tester, repository);
    await tester.tap(find.text('Inscription'));
    await tester.pumpAndSettle();
    for (final entry in {
      'partner-contact': 'Salif Kaboré', 'partner-phone': '+22670000001',
      'partner-email': 'salif@example.test',
      'partner-password': 'Partenaire12345', 'partner-confirmation': 'Partenaire12345',
    }.entries) {
      final field = find.byKey(Key(entry.key));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('partner-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('partner-submit')));
    await tester.pumpAndSettle();

    expect(repository.registration, isNotNull,
        reason: 'Le formulaire a refusé une inscription que le serveur accepte.');
    expect(repository.registration!.containsKey('company_name'), isFalse,
        reason: '« Absent » et « vide » doivent arriver distinctement : une '
            'chaîne vide s’enregistrerait comme un nom.');
    expect(repository.registration!['contact_name'], 'Salif Kaboré');
  });

  /// Le titre de l'espace ne peut pas rester vide.
  ///
  /// Le profil PRIVE rend bien `null` — à dessein, pour que le titulaire voie
  /// que le champ est vide plutôt que son propre nom recopié. C'est
  /// l'affichage qui se replie.
  testWidgets('sans entreprise, l’espace porte le nom du responsable',
      (tester) async {
    final repository = _Repository()
      ..savedProfile = PartnerProfile(user: const {'role': 'partner'}, account: const {
        'company_name': null, 'contact_name': 'Salif Kaboré', 'status': 'approved',
      });

    await _open(tester, repository);

    expect(find.text('Salif Kaboré'), findsWidgets);
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
