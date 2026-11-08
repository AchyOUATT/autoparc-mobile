import 'dart:async';

import 'package:auto/features/partner_accounts/data/notice_tableau_de_bord.dart';
import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/faux_depot_partenaire.dart';

/// Ce que `main()` lit au coffre avant la première trame.
///
/// ── CE QUE CE BANC FERME ──────────────────────────────────────────────────
///
/// `sessionPartenaireAuDemarrage` décide de la PREMIÈRE trame : tableau de
/// bord ou accueil acheteur. Elle ne doit ni retarder le démarrage d'un coffre
/// lent au-delà de son délai, ni l'empêcher sur un coffre cassé, ni inventer
/// une session — et ce qu'elle rend doit être exactement ce que `restore()`
/// aurait posé, puisque c'est la MÊME définition (`sessionInitialeDepuis`).
///
/// Un coffre qui ne répond pas est modélisé par un `Completer` jamais
/// complété ; le délai est réel, donc court.
class _Coffre extends PartnerTokenStore {
  _Coffre(this._reponse);

  final Future<PartnerSessionStockee?> Function() _reponse;

  @override
  Future<PartnerSessionStockee?> readSession() => _reponse();

  @override
  Future<void> writeSession(String token, [Map<String, dynamic>? profile]) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  group('sessionInitialeDepuis', () {
    test('un coffre vide : aucune session, et plus rien à attendre', () {
      final session = sessionInitialeDepuis(null);

      expect(session.profile, isNull);
      expect(session.loading, isFalse);
      expect(session.verified, isTrue);
    });

    test('un profil au coffre : la session, NON confirmée', () {
      final profil = profilDeBanc(company: 'Garage Kossodo');
      final session = sessionInitialeDepuis(
        PartnerSessionStockee(token: 'jeton', profile: profil.toJson()),
      );

      expect(session.profile?.displayName, 'Garage Kossodo');
      expect(session.verified, isFalse,
          reason: 'Le coffre est une hypothèse tant que le serveur n\'a pas '
              'répondu : le tiroir doit lire « Session à confirmer… ».');
      expect(session.loading, isFalse);
    });

    test('un jeton sans profil : rien à montrer, donc en attente', () {
      final session = sessionInitialeDepuis(const PartnerSessionStockee(token: 'jeton-d-avant'));

      expect(session.profile, isNull);
      expect(session.loading, isTrue);
    });

    test('un profil illisible vaut un jeton sans profil', () {
      final session = sessionInitialeDepuis(
        const PartnerSessionStockee(token: 'jeton', profile: {'rien': 'de lisible'}),
      );

      expect(session.profile, isNull);
      expect(session.loading, isTrue);
    });
  });

  /// La ligne « votre accueil est maintenant votre tableau de bord » ne
  /// s'adresse qu'aux sessions restaurées d'un coffre antérieur : une session
  /// qui NAÎT dans cette version — connexion ou inscription — la marque vue.
  group('La ligne de bienvenue et les sessions qui naissent', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('une inscription la marque vue', () async {
      final conteneur = ProviderContainer(
        overrides: [partnerRepositoryProvider.overrideWithValue(FauxDepotPartenaire())],
      );
      addTearDown(conteneur.dispose);

      await conteneur.read(partnerSessionProvider.notifier).register({'contact_name': 'Awa'});
      // L'écriture ne retient pas la connexion : on laisse la file se vider.
      await pumpEventQueue();

      expect(await NoticeTableauDeBord.estVue(), isTrue,
          reason: 'Qui vient de s\'inscrire n\'a jamais eu d\'autre accueil : '
              '« maintenant » lui annoncerait un changement qui n\'a pas eu lieu.');
    });

    test('une connexion aussi', () async {
      final depot = FauxDepotPartenaire()..reponseLogin = () async => profilDeBanc();
      final conteneur = ProviderContainer(
        overrides: [partnerRepositoryProvider.overrideWithValue(depot)],
      );
      addTearDown(conteneur.dispose);

      await conteneur.read(partnerSessionProvider.notifier).login('+22670000000', 'Partenaire12345');
      await pumpEventQueue();

      expect(await NoticeTableauDeBord.estVue(), isTrue);
    });

    test('une restauration ne la marque pas : c\'est à elle que la ligne s\'adresse', () async {
      final conteneur = ProviderContainer(
        overrides: [
          partnerRepositoryProvider.overrideWithValue(FauxDepotPartenaire()..profilAuCoffre = profilDeBanc()),
        ],
      );
      addTearDown(conteneur.dispose);

      await conteneur.read(partnerSessionProvider.notifier).restore();

      expect(await NoticeTableauDeBord.estVue(), isFalse);
    });
  });

  group('sessionPartenaireAuDemarrage', () {
    test('rend ce que le coffre dit', () async {
      final profil = profilDeBanc();
      final session = await sessionPartenaireAuDemarrage(
        _Coffre(() async => PartnerSessionStockee(token: 'jeton', profile: profil.toJson())),
      );

      expect(session.profile?.displayName, 'Garage Exemple');
      expect(session.verified, isFalse);
    });

    test('un coffre vide : aucune session', () async {
      final session = await sessionPartenaireAuDemarrage(_Coffre(() async => null));

      expect(session.profile, isNull);
      expect(session.loading, isFalse);
    });

    test('un coffre qui ne répond pas dans le délai : on démarre sans savoir', () async {
      final jamais = Completer<PartnerSessionStockee?>();
      final chrono = Stopwatch()..start();

      final session = await sessionPartenaireAuDemarrage(
        _Coffre(() => jamais.future),
        delai: const Duration(milliseconds: 100),
      );

      expect(chrono.elapsed, lessThan(const Duration(seconds: 2)),
          reason: 'Le délai borne le démarrage : un coffre lent ne doit pas '
              'le retenir plus longtemps.');
      expect(session.profile, isNull);
      expect(session.loading, isTrue,
          reason: '« On ne sait pas encore » : l\'état de départ historique du '
              'notifier, qui relira le coffre et décidera. Ni une session '
              'inventée, ni une absence affirmée.');
    });

    test('un coffre qui lève : on démarre sans savoir', () async {
      final session = await sessionPartenaireAuDemarrage(
        _Coffre(() async => throw StateError('canal de plateforme absent')),
      );

      expect(session.profile, isNull);
      expect(session.loading, isTrue);
    });
  });
}
