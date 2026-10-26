import 'dart:async';

import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// La session partenaire, du coffre à l'écran.
///
/// ── CE QUE CE BANC FERME ──────────────────────────────────────────────────
///
/// `restore()` attendait `/api/partner/me` avant de publier quoi que ce soit,
/// et `partner_account_page.dart:63` montre un indicateur BLOQUANT tant que
/// `loading && profile == null`. Sur une instance Render endormie, le
/// partenaire regardait donc tourner cet indicateur : 34,8 s mesurées sur
/// `/up` à froid le 2026-10-15, et jusqu'à 60 s de `receiveTimeout`.
///
/// Le chemin du personnel a le même banc, pour la même mécanique
/// (`test/session_personnel_test.dart`). Les deux notifiers sont indépendants :
/// rien dans le langage ne garantit qu'ils restent d'accord, et c'est pour
/// cela que les deux sont éprouvés séparément.
class _Depot extends PartnerRepository {
  PartnerSessionStockee? coffre;
  final List<String> appels = [];

  /// Ce que `getMe()` fera. Une `Future` non résolue permet d'observer l'état
  /// PENDANT la vérification, ce qui est tout l'objet du démarrage optimiste.
  Future<PartnerProfile> Function()? reponse;

  @override
  Future<PartnerSessionStockee?> sessionStockee() async {
    appels.add('coffre');

    return coffre;
  }

  /// Le VRAI dépôt vide le coffre sur un rejet définitif
  /// (`partner_repository.dart`, branche `if (error.sessionRejected) await
  /// _tokens.clear()`). Un faux qui ne le ferait pas MENTIRAIT sur le
  /// contrat : la reprise au premier plan retrouverait un coffre garni et
  /// reconstituerait la notice, alors qu'en production elle la perd. Une
  /// mutation a survécu exactement pour cette raison.
  @override
  Future<PartnerProfile> getMe() async {
    appels.add('getMe');

    try {
      return await reponse!();
    } on PartnerApiException catch (error) {
      if (error.sessionRejected) coffre = null;

      rethrow;
    }
  }

  /// Quand elle est posée, `logout()` attend après avoir vidé le coffre : la
  /// fenêtre de l'appel serveur devient observable.
  Completer<void>? porteDeconnexion;

  @override
  Future<void> logout() async {
    appels.add('logout');
    coffre = null;
    if (porteDeconnexion != null) await porteDeconnexion!.future;
  }
}

PartnerProfile _profil({String statut = 'approved'}) => PartnerProfile(
      user: const {'role': 'partner'},
      account: {'company_name': 'Garage Kossodo', 'status': statut},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Depot depot;

  setUp(() => depot = _Depot());

  PartnerSessionNotifier demarrer() {
    final notifier = PartnerSessionNotifier(depot);
    addTearDown(notifier.dispose);

    return notifier;
  }

  Future<void> souffler([int ms = 20]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  void semerCoffre({Map<String, dynamic>? profil}) {
    depot.coffre = PartnerSessionStockee(token: 'jeton-partenaire', profile: profil);
  }

  /// Le contrat du getter, éprouvé directement.
  ///
  /// `sessionAConfirmer` vaut `profile != null && !verified`, et le premier
  /// terme n'est observable par aucun scénario d'interface : la puce qui le lit
  /// ne s'affiche que dans la branche d'un compte approuvé, où le profil n'est
  /// jamais nul. Sans ce banc, retirer ce terme ne ferait rien tomber — et un
  /// écran ajouté demain annoncerait « statut à confirmer » à quelqu'un qui n'a
  /// aucune session.
  group('Le contrat de sessionAConfirmer', () {
    test('il exige un profil, pas seulement une non-confirmation', () {
      expect(const PartnerSession(verified: false).sessionAConfirmer, isFalse,
          reason: 'Sans profil, il n’y a rien à confirmer.');
      expect(
        PartnerSession(profile: _profil(), verified: false).sessionAConfirmer,
        isTrue,
      );
      expect(PartnerSession(profile: _profil()).sessionAConfirmer, isFalse,
          reason: 'Le défaut est « confirmé ».');
      expect(const PartnerSession().sessionAConfirmer, isFalse);
    });
  });

  group('Démarrage optimiste', () {
    test("l'espace s'ouvre sans attendre le réseau", () async {
      semerCoffre(profil: _profil().toJson());
      final porte = Completer<PartnerProfile>();
      depot.reponse = () => porte.future;

      final session = demarrer();
      await souffler();

      expect(session.state.profile?.companyName, 'Garage Kossodo');
      expect(session.state.profile?.approved, isTrue);
      expect(session.state.loading, isFalse,
          reason: "L'indicateur bloquant de la page ne doit plus s'afficher.");
      expect(session.state.verified, isFalse);
      expect(session.state.sessionAConfirmer, isTrue);

      expect(depot.appels, ['coffre', 'getMe']);
      expect(porte.isCompleted, isFalse,
          reason: "L'état ci-dessus a été lu AVANT la réponse du serveur.");

      porte.complete(_profil());
      await souffler();
    });

    test('aucun coffre : rien à restaurer, et le serveur reste tranquille',
        () async {
      depot.reponse = () => throw StateError('ne doit pas être appelé');

      final session = demarrer();
      await souffler();

      expect(session.state.profile, isNull);
      expect(session.state.loading, isFalse);
      expect(depot.appels, ['coffre'],
          reason: "La garantie « pas de jeton, pas d'appel » vivait dans "
              "`PartnerRepository.restore()`, retiré ; elle vit ici.");
    });

    /// Une session d'avant cette version n'a que le jeton. Il n'y a alors rien
    /// à montrer, donc l'indicateur reste — mais pour une seule exécution : la
    /// vérification écrit le profil au coffre en passant.
    test('un coffre sans profil garde l’indicateur, puis se complète', () async {
      depot.coffre = const PartnerSessionStockee(token: 'jeton-d-avant');
      final porte = Completer<PartnerProfile>();
      depot.reponse = () => porte.future;

      final session = demarrer();
      await souffler();

      expect(session.state.profile, isNull);
      expect(session.state.loading, isTrue);

      porte.complete(_profil());
      await souffler();

      expect(session.state.profile?.companyName, 'Garage Kossodo');
      expect(session.state.verified, isTrue);
      expect(session.state.loading, isFalse);
    });
  });

  group('Ce que la vérification décide', () {
    test('elle confirme, et le profil frais remplace celui du coffre', () async {
      semerCoffre(profil: _profil(statut: 'pending').toJson());
      depot.reponse = () async => _profil(statut: 'approved');

      final session = demarrer();
      await souffler();

      expect(session.state.verified, isTrue);
      expect(session.state.sessionAConfirmer, isFalse);
      expect(session.state.profile?.approved, isTrue,
          reason: 'Le statut du serveur prime sur celui qui dormait au coffre.');
    });

    test('un compte désactivé ferme la session', () async {
      semerCoffre(profil: _profil().toJson());
      depot.reponse = () => throw const PartnerApiException(
            'Votre compte partenaire a été désactivé.',
            statusCode: 403,
            code: 'account_disabled',
          );

      final session = demarrer();
      await souffler();

      expect(session.state.profile, isNull);
      expect(session.state.error, 'Votre compte partenaire a été désactivé.');
      expect(session.state.restoreFailed, isFalse,
          reason: 'Réessayer ne servirait à rien : le compte est désactivé.');
    });

    /// LE BANC QUI PROTEGE LE PARTENAIRE DE LUI-MEME.
    ///
    /// C'est ce refus-là que l'ancienne règle `401 || 403` traitait comme un
    /// rejet de session.
    test('un refus de permission garde le profil et propose de réessayer',
        () async {
      semerCoffre(profil: _profil().toJson());
      depot.reponse = () => throw const PartnerApiException(
            'Cette annonce n’est pas la vôtre.',
            statusCode: 403,
            code: 'permission_denied',
          );

      final session = demarrer();
      await souffler();

      expect(session.state.profile?.companyName, 'Garage Kossodo');
      expect(session.state.verified, isFalse);
      expect(session.state.restoreFailed, isTrue);
    });

    test('une lenteur du serveur garde le profil', () async {
      semerCoffre(profil: _profil().toJson());
      depot.reponse = () => throw const PartnerApiException(
            'Service indisponible.',
            statusCode: 503,
          );

      final session = demarrer();
      await souffler();

      expect(session.state.profile, isNotNull);
      expect(session.state.restoreFailed, isTrue);
      expect(depot.appels.where((a) => a == 'getMe').length, 1,
          reason: 'Pas de seconde tentative automatique ici, contrairement au '
              'personnel : `restoreFailed` allume un bouton « Réessayer », et '
              "une tentative que l'utilisateur déclenche vaut mieux qu'une "
              "tentative qu'il ne voit pas.");
    });
  });

  /// Une réponse périmée ne doit pas rouvrir une session fermée. `mounted` ne
  /// l'empêche pas : il ne dit que la mort du notifier.
  group('Une réponse périmée n’écrase pas un état plus récent', () {
    test('une déconnexion pendant la vérification gagne', () async {
      semerCoffre(profil: _profil().toJson());
      final porte = Completer<PartnerProfile>();
      depot.reponse = () => porte.future;

      final session = demarrer();
      await souffler();
      expect(session.state.profile, isNotNull);

      await session.logout();
      expect(session.state.profile, isNull);

      porte.complete(_profil());
      await souffler();

      expect(session.state.profile, isNull,
          reason: 'La réponse périmée a rouvert une session fermée.');
    });

    test('effacer la notice périme aussi la vérification', () async {
      semerCoffre(profil: _profil().toJson());
      final porte = Completer<PartnerProfile>();
      depot.reponse = () => porte.future;

      final session = demarrer();
      await souffler();

      session.clearNotice();
      porte.complete(_profil());
      await souffler();

      expect(session.state.profile, isNull);
    });
  });

  /// La même porte que du côté personnel, et la revue l'avait écartée.
  ///
  /// `logout()` gardait le profil dans l'état pendant l'appel serveur — jusqu'à
  /// 60 s sur une instance endormie. Or `didChangeAppLifecycleState` exige
  /// précisément `state.profile != null` pour réactualiser : une reprise au
  /// premier plan dans cet intervalle reposait la session.
  group('Déconnexion pendant que le serveur ne répond pas', () {
    test('une reprise au premier plan ne rouvre pas la session', () async {
      semerCoffre(profil: _profil().toJson());
      depot.reponse = () async => _profil();

      final session = demarrer();
      await souffler();
      expect(session.state.profile, isNotNull);

      depot.porteDeconnexion = Completer<void>();
      final deconnexion = session.logout();
      await souffler();

      expect(session.state.profile, isNull,
          reason: "La déconnexion doit être immédiate à l'écran.");

      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await souffler();

      expect(session.state.profile, isNull,
          reason: 'Une reprise au premier plan a rouvert une session fermée.');

      depot.porteDeconnexion!.complete();
      await deconnexion;
      await souffler();

      expect(session.state.profile, isNull);
    });
  });

  group('Reprise au premier plan', () {
    test('un retour au premier plan réactualise la session', () async {
      semerCoffre(profil: _profil().toJson());
      depot.reponse = () async => _profil();

      final session = demarrer();
      await souffler();
      final avant = depot.appels.where((a) => a == 'getMe').length;

      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await souffler();

      expect(depot.appels.where((a) => a == 'getMe').length, avant + 1,
          reason: 'Un téléphone reste des jours sans redémarrer : sans cela, '
              'une suspension décidée pendant la nuit resterait invisible.');
    });

    test('sans session, un retour au premier plan ne réveille personne',
        () async {
      depot.reponse = () => throw StateError('ne doit pas être appelé');

      final session = demarrer();
      await souffler();

      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await souffler();

      expect(depot.appels.where((a) => a == 'getMe'), isEmpty);
    });

    /// LE GARDE `profile == null` DU CYCLE DE VIE, ET CE QU'IL PROTEGE.
    ///
    /// Sans lui, une reprise appelle `refresh()`, qui n'ayant pas de profil
    /// retombe sur `restore()` — lequel REMET L'ETAT A ZERO. La notice
    /// affichée disparaît alors : le partenaire lit « Compte refusé —
    /// téléphone à vérifier », change d'application, revient, et le message
    /// n'est plus là. Aucun appel réseau ne le trahit, seul l'état le dit.
    test('une reprise n’efface pas la notice affichée', () async {
      semerCoffre(profil: _profil().toJson());
      depot.reponse = () => throw const PartnerApiException(
            'Compte refusé.',
            statusCode: 403,
            code: 'account_disabled',
            accountStatus: 'rejected',
            reviewReason: 'Téléphone à vérifier',
          );

      final session = demarrer();
      await souffler();

      expect(session.state.profile, isNull);
      expect(session.state.error, 'Compte refusé.');
      expect(session.state.reviewReason, 'Téléphone à vérifier');

      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await souffler();

      expect(session.state.error, 'Compte refusé.',
          reason: 'La reprise au premier plan a effacé le motif du refus.');
      expect(session.state.reviewReason, 'Téléphone à vérifier');
    });

    test('les autres états du cycle de vie ne déclenchent rien', () async {
      semerCoffre(profil: _profil().toJson());
      depot.reponse = () async => _profil();

      final session = demarrer();
      await souffler();
      final avant = depot.appels.where((a) => a == 'getMe').length;

      for (final etat in [
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
        AppLifecycleState.hidden,
      ]) {
        session.didChangeAppLifecycleState(etat);
      }
      await souffler();

      expect(depot.appels.where((a) => a == 'getMe').length, avant);
    });
  });
}
