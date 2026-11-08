import 'dart:async';

import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto/l10n/app_localizations.dart';

import '../support/faux_depot_partenaire.dart';

/// Le faux est partagé — `test/support/faux_depot_partenaire.dart` dit ce
/// qu'il modélise, et pourquoi un faux qui ne modéliserait que `getMe()`
/// laisserait ce banc VERT sur l'état anonyme : le notifier lit le coffre
/// avant de vérifier, et `restore()` attrape l'exception du vrai magasin
/// sécurisé au lieu de rester sur son indicateur.
Future<void> _open(WidgetTester tester, FauxDepotPartenaire repository) async {
  await tester.pumpWidget(ProviderScope(overrides: [partnerRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PartnerAccountPage())));
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
    final repository = FauxDepotPartenaire()
      ..profilAuCoffre = profilDeBanc()
      ..porteGetMe = Completer<PartnerProfile>();

    await _open(tester, repository);

    expect(find.text('Statut à confirmer…'), findsOneWidget);
    expect(find.text('Compte approuvé'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: "C'est tout l'objet du démarrage optimiste : plus d'attente "
            'bloquante.');

    // Le serveur répond enfin.
    repository.porteGetMe!.complete(profilDeBanc());
    await tester.pumpAndSettle();

    expect(find.text('Compte approuvé'), findsOneWidget);
    expect(find.text('Statut à confirmer…'), findsNothing);
  });

  testWidgets('une inscription réelle du formulaire aboutit à une attente sans gestion', (tester) async {
    final repository = FauxDepotPartenaire();
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

    expect(repository.inscription, isNotNull);
    expect(repository.inscription!['company_name'], 'Garage Exemple');
    expect(repository.inscription!['password_confirmation'], 'Partenaire12345');
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
    final repository = FauxDepotPartenaire();
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

    expect(repository.inscription, isNotNull,
        reason: 'Le formulaire a refusé une inscription que le serveur accepte.');
    expect(repository.inscription!.containsKey('company_name'), isFalse,
        reason: '« Absent » et « vide » doivent arriver distinctement : une '
            'chaîne vide s’enregistrerait comme un nom.');
    expect(repository.inscription!['contact_name'], 'Salif Kaboré');
  });

  /// ── L'ADRESSE N'EST PLUS EXIGEE NON PLUS ────────────────────────────────
  ///
  /// Mesure faite côté serveur : aucun courriel n'est envoyé nulle part, toutes
  /// les notifications passent par `AppNotification`. L'adresse ne servait donc
  /// qu'à se connecter, et c'est le numéro qui le fait désormais.
  testWidgets('une inscription sans courriel part quand même', (tester) async {
    final repository = FauxDepotPartenaire();
    await _open(tester, repository);
    await tester.tap(find.text('Inscription'));
    await tester.pumpAndSettle();
    for (final entry in {
      'partner-contact': 'Salif Kaboré', 'partner-phone': '+22670000001',
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

    expect(repository.inscription, isNotNull,
        reason: 'Le formulaire a refusé une inscription que le serveur accepte.');
    expect(repository.inscription!.containsKey('email'), isFalse);
    expect(repository.inscription!['phone'], '+22670000001');
  });

  /// Le champ de connexion accepte les deux : les partenaires inscrits avant
  /// ce changement ont une adresse et s'en servent.
  testWidgets('la connexion accepte un numéro comme une adresse', (tester) async {
    for (final identifiant in ['+226 70 00 00 01', 'salif@example.test']) {
      final repository = FauxDepotPartenaire();
      await _open(tester, repository);

      await tester.enterText(find.byKey(const Key('partner-email')), identifiant);
      await tester.enterText(find.byKey(const Key('partner-password')), 'Partenaire12345');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Indiquez une adresse email valide.'), findsNothing,
          reason: '« $identifiant » a été refusé avant même de partir.');
      expect(find.text('Indiquez un numéro de téléphone ou une adresse email.'),
          findsNothing);
    }
  });

  testWidgets('la connexion refuse un identifiant qui n’est ni l’un ni l’autre',
      (tester) async {
    final repository = FauxDepotPartenaire();
    await _open(tester, repository);

    await tester.enterText(find.byKey(const Key('partner-email')), 'salif');
    await tester.enterText(find.byKey(const Key('partner-password')), 'Partenaire12345');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('partner-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Indiquez un numéro de téléphone ou une adresse email.'),
        findsOneWidget);
  });

  /// Le titre de l'espace ne peut pas rester vide.
  ///
  /// Le profil PRIVE rend bien `null` — à dessein, pour que le titulaire voie
  /// que le champ est vide plutôt que son propre nom recopié. C'est
  /// l'affichage qui se replie.
  testWidgets('sans entreprise, l’espace porte le nom du responsable',
      (tester) async {
    final repository = FauxDepotPartenaire()
      ..profilAuCoffre = profilDeBanc(company: null, contact: 'Salif Kaboré');

    await _open(tester, repository);

    expect(find.text('Salif Kaboré'), findsWidgets);
  });

  testWidgets('le motif du refus reste visible et la déconnexion est disponible', (tester) async {
    final repository = FauxDepotPartenaire()
      ..profilAuCoffre = profilDeBanc(
        status: 'rejected',
        reviewReason: 'Téléphone à vérifier',
      );
    await _open(tester, repository);

    expect(find.text('Demande refusée'), findsOneWidget);
    expect(find.text('Motif : Téléphone à vérifier'), findsOneWidget);
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(repository.appels, contains('logout'));
    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets('un compte approuvé accède aux trois inventaires sans rôle personnel', (tester) async {
    final repository = FauxDepotPartenaire()..profilAuCoffre = profilDeBanc();
    await _open(tester, repository);

    expect(find.text('Compte approuvé'), findsOneWidget);
    expect(find.text('Véhicules'), findsOneWidget);
    expect(find.text('Pièces détachées'), findsOneWidget);
    expect(find.text('Accessoires'), findsOneWidget);
    expect(find.text('Personnel'), findsNothing);
  });
}
