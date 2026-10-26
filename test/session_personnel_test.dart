import 'dart:async';
import 'dart:convert';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// La session du personnel, du coffre à l'écran.
///
/// ── CE QUE CE BANC COUVRE, ET QUI N'ETAIT COUVERT PAR RIEN ────────────────
///
/// `auth_session_restore_test.dart` n'éprouve que le chemin Firebase : son
/// coffre faussé rend `null` pour tout, donc `_init()` prend l'autre branche.
/// La restauration d'une session du PERSONNEL n'avait aucun banc.
///
/// Ici le coffre est faux mais le code du coffre est VRAI : le canal de
/// plateforme est intercepté, et `ApiClient.readSession` / `saveSession` /
/// `deleteSession` s'exécutent réellement par-dessus. C'est ce qui permet
/// d'éprouver la migration de l'ancienne clé, qu'un faux coffre en mémoire
/// aurait court-circuitée.
class _Coffre {
  final Map<String, String> valeurs = {};

  /// Appelé UNE fois, juste après une écriture.
  ///
  /// Sert à ouvrir la fenêtre que `_verifier` traverse entre son premier garde
  /// de génération et l'écriture de l'état : elle contient deux accès au
  /// coffre, pendant lesquels l'utilisateur peut se déconnecter.
  Future<void> Function()? auMomentDEcrire;

  void installer() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = (call.arguments as Map?) ?? const {};
        final cle = args['key'] as String?;

        switch (call.method) {
          case 'read':
            return valeurs[cle];
          case 'write':
            valeurs[cle!] = args['value'] as String;
            final prevenir = auMomentDEcrire;
            if (prevenir != null) {
              auMomentDEcrire = null;
              await prevenir();
            }

            return null;
          case 'delete':
            valeurs.remove(cle);

            return null;
          case 'readAll':
            return valeurs;
          case 'deleteAll':
            valeurs.clear();

            return null;
        }

        return null;
      },
    );
  }
}

class _Depot extends AuthRepository {
  _Depot() : super(ApiClient());

  final List<String> appels = [];

  /// Ce que `getMe()` fera. Une `Future` non résolue permet d'observer l'état
  /// PENDANT la vérification, ce qui est tout l'objet du démarrage optimiste.
  Future<StaffUser> Function()? reponse;

  @override
  Future<StaffUser> getMe() {
    appels.add('getMe');

    return reponse!();
  }

  /// La vraie version appelle le serveur avant d'effacer. On garde l'effacement
  /// — c'est lui qu'on mesure — et on se passe du réseau.
  @override
  Future<void> logoutStaff() async {
    appels.add('logoutStaff');
    await ApiClient.deleteSession();
  }

  @override
  User? get utilisateurCourant => null;

  @override
  Stream<User?> get firebaseAuthStream => const Stream<User?>.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Coffre coffre;
  late _Depot depot;

  setUp(() {
    coffre = _Coffre()..installer();
    depot = _Depot();
  });

  Map<String, dynamic> profilJson({String role = 'admin'}) => {
        'id': 7,
        'name': 'Awa Traoré',
        'email': 'awa@autoparc.bf',
        'role': role,
      };

  void semerSession({String jeton = 'jeton-personnel', Map<String, dynamic>? profil}) {
    coffre.valeurs['sanctum_session'] =
        jsonEncode({'token': jeton, if (profil != null) 'user': profil});
  }

  /// Le coffre d'une version ANTERIEURE : le jeton seul, sous l'ancienne clé.
  void semerAncienneCle({String jeton = 'jeton-d-avant'}) {
    coffre.valeurs['sanctum_token'] = jeton;
  }

  AuthNotifier demarrer() {
    final auth = AuthNotifier(depot, delaiAvantSecondeTentative: Duration.zero);
    addTearDown(auth.dispose);

    return auth;
  }

  /// Laisse tourner les `Future` en attente. Le coffre passe par un canal de
  /// plateforme, donc un seul tour de microtâches ne suffit pas.
  Future<void> souffler([int ms = 20]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  ApiException refus(int statut, String message, {String? code}) =>
      ApiException(statusCode: statut, message: message, code: code);

  group('Démarrage optimiste', () {
    test("l'application s'ouvre sans attendre le réseau", () async {
      semerSession(profil: profilJson());
      final porte = Completer<StaffUser>();
      depot.reponse = () => porte.future;

      final auth = demarrer();
      await souffler();

      expect(auth.state.isStaff, isTrue,
          reason: "Le premier écran ne doit pas attendre `/api/me` : sur une "
              'instance endormie cela durait 34,8 s.');
      expect(auth.state.staffUser?.name, 'Awa Traoré');
      expect(auth.state.staffUser?.role, 'admin');
      expect(auth.state.verified, isFalse);
      expect(auth.state.sessionAConfirmer, isTrue);

      expect(depot.appels, ['getMe'], reason: 'La vérification doit être partie.');
      expect(porte.isCompleted, isFalse,
          reason: "Et l'état ci-dessus a été lu AVANT qu'elle ne réponde.");

      porte.complete(StaffUser.fromJson(profilJson()));
      await souffler();
    });

    test('aucune session au coffre : visiteur, et le serveur reste tranquille',
        () async {
      depot.reponse = () => throw StateError('ne doit pas être appelé');

      final auth = demarrer();
      await souffler();

      expect(auth.state.isAuthenticated, isFalse);
      expect(depot.appels, isEmpty);
    });
  });

  group('Ce que la vérification décide', () {
    test('elle confirme, et le profil frais remplace celui du coffre', () async {
      semerSession(profil: profilJson(role: 'viewer'));
      depot.reponse = () async => StaffUser.fromJson(profilJson(role: 'admin'));

      final auth = demarrer();
      await souffler();

      expect(auth.state.verified, isTrue);
      expect(auth.state.sessionAConfirmer, isFalse);
      expect(auth.state.staffUser?.role, 'admin',
          reason: 'Le rôle du serveur prime sur celui qui dormait au coffre.');

      // Et il est réécrit au coffre, pour le démarrage suivant.
      final enregistre = jsonDecode(coffre.valeurs['sanctum_session']!) as Map;
      expect((enregistre['user'] as Map)['role'], 'admin');
    });

    /// LE BANC DU LOT 1 VU DEPUIS LE CLIENT.
    ///
    /// Avant, ce 403 tombait dans la branche « le serveur est peut-être juste
    /// lent » : le jeton mort restait au coffre et l'employé basculait en mode
    /// visiteur sans un mot.
    test('un compte désactivé ferme la session, et dit pourquoi', () async {
      semerSession(profil: profilJson());
      depot.reponse = () => throw refus(
            403,
            'Votre compte a été désactivé.',
            code: 'account_disabled',
          );

      final auth = demarrer();
      await souffler();

      expect(auth.state.isAuthenticated, isFalse);
      expect(auth.state.error, 'Votre compte a été désactivé.',
          reason: "C'est la seule chose qui explique la déconnexion.");
      expect(coffre.valeurs, isEmpty, reason: 'Les deux clés devaient partir.');
    });

    /// LE BANC QUI PROTEGE L'EMPLOYE DE LUI-MEME.
    test('un refus de permission ne ferme rien', () async {
      semerSession(profil: profilJson());
      depot.reponse =
          () => throw refus(403, 'Accès réservé.', code: 'permission_denied');

      final auth = demarrer();
      await souffler();

      expect(auth.state.isStaff, isTrue);
      expect(coffre.valeurs['sanctum_session'], isNotNull);
    });

    test('une lenteur du serveur ne ferme rien, et la vérification retente une '
        'seule fois', () async {
      semerSession(profil: profilJson());
      depot.reponse = () => throw refus(503, 'Service indisponible.');

      final auth = demarrer();
      await souffler();

      expect(depot.appels, ['getMe', 'getMe'],
          reason: 'Une première tentative réveille souvent l’instance ; la '
              'seconde aboutit. Deux, et pas davantage.');
      expect(auth.state.isStaff, isTrue);
      expect(auth.state.sessionAConfirmer, isTrue,
          reason: "L'indicateur reste, puisque rien n'est confirmé.");
      expect(coffre.valeurs['sanctum_session'], isNotNull);
    });

    test('une coupure réseau ne ferme rien non plus', () async {
      semerSession(profil: profilJson());
      depot.reponse = () =>
          throw const ApiException(message: 'Hors ligne', isNetworkFailure: true);

      final auth = demarrer();
      await souffler();

      expect(auth.state.isStaff, isTrue);
      expect(coffre.valeurs['sanctum_session'], isNotNull);
    });
  });

  /// LE BANC DE LA REPONSE TARDIVE.
  ///
  /// Une vérification peut durer une minute. Si sa réponse écrit sans vérifier
  /// qu'elle est encore d'actualité, elle REOUVRE une session que l'utilisateur
  /// vient de fermer. `mounted` ne suffit pas à l'empêcher : il ne dit que la
  /// mort du notifier, pas qu'un état plus récent a été posé entre-temps.
  group('Une réponse périmée n’écrase pas un état plus récent', () {
    test('une déconnexion pendant la vérification gagne', () async {
      semerSession(profil: profilJson());
      final porte = Completer<StaffUser>();
      depot.reponse = () => porte.future;

      final auth = demarrer();
      await souffler();
      expect(auth.state.isStaff, isTrue);

      await auth.signOut();
      expect(auth.state.isAuthenticated, isFalse);

      // La vérification d'avant répond maintenant, avec un profil valable.
      porte.complete(StaffUser.fromJson(profilJson()));
      await souffler();

      expect(auth.state.isAuthenticated, isFalse,
          reason: 'La réponse périmée a rouvert une session fermée.');
      expect(coffre.valeurs['sanctum_session'], isNull);
    });
  });

  group('Une déconnexion pendant l’écriture au coffre gagne aussi', () {
    /// LA FENETRE QUE LE PREMIER GARDE NE COUVRE PAS.
    ///
    /// `_verifier` vérifie la génération dès que `getMe()` répond, puis écrit
    /// le profil au coffre — deux accès asynchrones — avant de poser l'état.
    /// Une déconnexion survenue dans cet intervalle serait écrasée par un état
    /// « connecté » plus ancien. D'où le SECOND garde, juste avant
    /// l'affectation, que ce banc est le seul à éprouver.
    test('le second garde de génération sert à quelque chose', () async {
      semerSession(profil: profilJson());
      depot.reponse = () async => StaffUser.fromJson(profilJson());

      late AuthNotifier auth;
      coffre.auMomentDEcrire = () => auth.signOut();
      auth = demarrer();
      await souffler();

      expect(auth.state.isAuthenticated, isFalse,
          reason: 'La vérification a rouvert une session fermée pendant '
              "qu'elle écrivait au coffre.");
      expect(coffre.valeurs['sanctum_session'], isNull);
    });
  });

  group('Reprise au premier plan', () {
    test('un retour au premier plan relance une vérification', () async {
      semerSession(profil: profilJson());
      depot.reponse = () async => StaffUser.fromJson(profilJson());

      final auth = demarrer();
      await souffler();
      expect(depot.appels.length, 1);

      auth.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await souffler();

      expect(depot.appels.length, 2,
          reason: 'Un téléphone reste des jours sans redémarrer : sans cela, '
              'une désactivation de la nuit ne serait jamais vue.');
    });

    test('les autres états du cycle de vie ne déclenchent rien', () async {
      semerSession(profil: profilJson());
      depot.reponse = () async => StaffUser.fromJson(profilJson());

      final auth = demarrer();
      await souffler();

      for (final etat in [
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
        AppLifecycleState.hidden,
      ]) {
        auth.didChangeAppLifecycleState(etat);
      }
      await souffler();

      expect(depot.appels.length, 1);
    });

    test("l'observateur est bien enregistré auprès de la liaison", () async {
      semerSession(profil: profilJson());
      depot.reponse = () async => StaffUser.fromJson(profilJson());

      final auth = demarrer();
      await souffler();
      expect(depot.appels.length, 1);
      expect(auth.state.isStaff, isTrue);

      // Le vrai message de plateforme, et non un appel direct : c'est
      // l'enregistrement dans `_observerLeCycleDeVie` qui est éprouvé ici.
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'flutter/lifecycle',
        const StringCodec().encodeMessage('AppLifecycleState.resumed'),
        (_) {},
      );
      await souffler();

      expect(depot.appels.length, greaterThan(1),
          reason: "L'observateur n'a pas été enregistré.");
    });
  });

  /// LE BANC QUI EVITE DE DECONNECTER TOUT LE MONDE A LA MISE A JOUR.
  group('Migration depuis l’ancienne clé', () {
    test('une session d’avant cette version continue, et se complète', () async {
      semerAncienneCle();
      depot.reponse = () async => StaffUser.fromJson(profilJson());

      final auth = demarrer();
      await souffler();

      expect(auth.state.isStaff, isTrue,
          reason: 'Ignorer `sanctum_token` déconnecterait tous les employés '
              'déjà connectés, sans message et sans raison.');
      expect(auth.state.verified, isTrue);
      expect(auth.state.staffUser?.name, 'Awa Traoré');

      // Le coffre est désormais au format courant, et l'ancienne clé a disparu
      // — la laisser reviendrait à garder un jeton que plus rien ne lirait ni
      // n'effacerait, valable indéfiniment côté serveur.
      expect(coffre.valeurs.containsKey('sanctum_token'), isFalse);
      final enregistre = jsonDecode(coffre.valeurs['sanctum_session']!) as Map;
      expect(enregistre['token'], 'jeton-d-avant');
      expect((enregistre['user'] as Map)['email'], 'awa@autoparc.bf');
    });

    test('un enregistrement illisible retombe sur l’ancienne clé', () async {
      coffre.valeurs['sanctum_session'] = 'ceci n est pas du JSON';
      semerAncienneCle(jeton: 'le-secours');
      depot.reponse = () async => StaffUser.fromJson(profilJson());

      final auth = demarrer();
      await souffler();

      expect(auth.state.isStaff, isTrue,
          reason: "Une erreur de format ne doit pas déconnecter.");
      final enregistre = jsonDecode(coffre.valeurs['sanctum_session']!) as Map;
      expect(enregistre['token'], 'le-secours');
    });
  });

  group('Déconnexion', () {
    /// La vérification ne doit SURTOUT pas aboutir dans ce banc.
    ///
    /// Si elle aboutit, son `saveSession` retire déjà l'ancienne clé, et
    /// l'oubli de cette même clé par `deleteSession` devient invisible : le
    /// banc passait alors au vert avec un `deleteSession` qui n'effaçait que
    /// la clé courante. D'où la vérification suspendue, qui laisse les deux
    /// clés en place jusqu'à la déconnexion.
    test('elle efface les DEUX clés', () async {
      semerSession(profil: profilJson());
      semerAncienneCle();
      final porte = Completer<StaffUser>();
      depot.reponse = () => porte.future;

      final auth = demarrer();
      await souffler();

      expect(coffre.valeurs.length, 2, reason: 'Les deux clés sont bien là.');

      await auth.signOut();

      expect(auth.state.isAuthenticated, isFalse);
      expect(coffre.valeurs, isEmpty,
          reason: 'Laisser une clé derrière, c’est ne pas déconnecter.');

      porte.complete(StaffUser.fromJson(profilJson()));
      await souffler();
      expect(auth.state.isAuthenticated, isFalse,
          reason: 'Et la réponse tardive ne rouvre rien.');
    });
  });
}
