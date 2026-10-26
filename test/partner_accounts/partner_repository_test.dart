import 'dart:convert';
import 'dart:typed_data';

import 'package:auto/features/partner_accounts/data/partner_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tokens implements PartnerTokenStore {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async { token = value; }
  @override
  Future<void> clear() async { token = null; }
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);
  final (int, dynamic) Function(RequestOptions) reply;
  final List<RequestOptions> requests = [];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final (status, body) = reply(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {'content-type': ['application/json']});
  }
  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _profile({String status = 'pending'}) => {
  'user': {'id': 1, 'role': 'partner', 'email': 'garage@example.test'},
  'partner_account': {'id': 2, 'company_name': 'Garage Exemple', 'status': status},
};

void main() {
  late _Tokens tokens;
  late Dio dio;
  late PartnerRepository repository;
  setUp(() {
    tokens = _Tokens();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api'));
    repository = PartnerRepository(dio: dio, tokenStore: tokens);
  });

  test('la connexion utilise la route partenaire et son coffre distinct', () async {
    final adapter = _Adapter((_) => (200, {..._profile(), 'token': 'partner-test-token'}));
    dio.httpClientAdapter = adapter;

    final profile = await repository.login(' garage@example.test ', 'password12345');

    expect(profile.status, 'pending');
    expect(profile.approved, isFalse);
    expect(tokens.token, 'partner-test-token');
    expect(SecurePartnerTokenStore.tokenKey, 'partner_sanctum_token');
    expect(adapter.requests.single.path, '/partner/login');
    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    expect(adapter.requests.single.data['email'], 'garage@example.test');
  });

  test('restaurer une session envoie seulement son jeton partenaire', () async {
    tokens.token = 'partner-test-token';
    final adapter = _Adapter((_) => (200, _profile(status: 'approved')));
    dio.httpClientAdapter = adapter;

    expect((await repository.restore())!.approved, isTrue);
    expect(adapter.requests.single.path, '/partner/me');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer partner-test-token');
  });

  /// CE BANC BOUCLAIT SUR [401, 403] ET NE GARDE QUE 401 : changement voulu,
  /// pas régression.
  ///
  /// Un 403 nu ne dit pas que la session est morte, il dit que CETTE action
  /// est refusée. Effacer le jeton dessus déconnectait un partenaire qui
  /// touchait une annonce n'étant pas la sienne — « cette annonce n'est pas
  /// la vôtre » fermait sa session. Le 403 qui ferme légitimement la session
  /// est celui qui porte `code: account_disabled`, et il est éprouvé dans le
  /// groupe « Ce qui vide le coffre partenaire » en bas de ce fichier.
  test('un refus 401 sur le profil efface la session partenaire', () async {
    tokens.token = 'expired';
    dio.httpClientAdapter = _Adapter((_) => (401, {'message': 'Session refusée'}));

    await expectLater(repository.getMe(), throwsA(isA<PartnerApiException>().having((error) => error.statusCode, 'status', 401)));
    expect(tokens.token, isNull);
  });

  test('un refus 403 NU conserve la session partenaire', () async {
    tokens.token = 'encore-valable';
    dio.httpClientAdapter = _Adapter((_) => (403, {'message': "Cette annonce n'est pas la vôtre."}));

    await expectLater(repository.getMe(), throwsA(isA<PartnerApiException>().having((error) => error.statusCode, 'status', 403)));
    expect(tokens.token, 'encore-valable',
        reason: "C'est la panne d'origine : n'importe quel 403 effaçait le jeton.");
  });

  test('une panne serveur conserve le jeton pour une prochaine tentative', () async {
    tokens.token = 'still-valid';
    dio.httpClientAdapter = _Adapter((_) => (503, {'message': 'Indisponible'}));

    await expectLater(repository.getMe(), throwsA(isA<PartnerApiException>()));
    expect(tokens.token, 'still-valid');
  });

  test('un refus de connexion expose le statut et le motif sans jeton', () async {
    dio.httpClientAdapter = _Adapter((_) => (403, {'message': 'Compte refusé', 'status': 'rejected', 'review_reason': 'Coordonnées à vérifier'}));

    await expectLater(repository.login('garage@example.test', 'password12345'), throwsA(isA<PartnerApiException>()
      .having((error) => error.accountStatus, 'statut', 'rejected')
      .having((error) => error.reviewReason, 'motif', 'Coordonnées à vérifier')));
    expect(tokens.token, isNull);
  });

  test('une réponse du personnel ne devient jamais une session partenaire', () async {
    dio.httpClientAdapter = _Adapter((_) => (200, {..._profile(), 'user': {'role': 'admin'}, 'token': 'staff-token'}));
    await expectLater(repository.login('staff@example.test', 'password12345'), throwsA(isA<PartnerApiException>()));
    expect(tokens.token, isNull);
  });

  test('liste paginée et mutation restent sur les routes du propriétaire', () async {
    tokens.token = 'owner-token';
    final adapter = _Adapter((request) => request.method == 'GET'
      ? (200, {'data': [{'id': 7, 'name': 'Filtre'}], 'meta': {'current_page': 2, 'last_page': 3, 'total': 42}})
      : (200, {'data': {'id': 7, 'name': 'Filtre modifié'}}));
    dio.httpClientAdapter = adapter;

    final page = await repository.listListings(PartnerListingKind.parts, page: 2, query: ' filtre ');
    await repository.saveListing(PartnerListingKind.parts, {'name': 'Filtre modifié'}, id: 7);

    expect(page.page, 2); expect(page.lastPage, 3); expect(page.total, 42);
    expect(page.items.single['id'], 7);
    expect(adapter.requests.first.queryParameters, {'page': 2, 'per_page': 20, 'q': 'filtre'});
    expect(adapter.requests.last.path, '/partner/parts/7');
    expect(adapter.requests.last.method, 'PATCH');
    expect(adapter.requests.every((request) => request.headers['Authorization'] == 'Bearer owner-token'), isTrue);
  });

  test('la déconnexion efface le jeton local même si le serveur est indisponible', () async {
    tokens.token = 'owner-token';
    dio.httpClientAdapter = _Adapter((_) => (503, {'message': 'Indisponible'}));

    await expectLater(repository.logout(), throwsA(isA<PartnerApiException>()));
    expect(tokens.token, isNull);
  });

  test('les références acceptent les listes JSON nues du catalogue public', () async {
    tokens.token = 'owner-token';
    final adapter = _Adapter((request) => switch (request.path) {
      '/catalog/sync' => (200, {
        'brands': [{'id': 1, 'name': 'Marque'}],
        'vehicle_models': [{'id': 2, 'brand_id': 1, 'name': 'Modèle'}],
        'engine_types': [{'id': 3, 'label': 'Essence'}],
      }),
      '/catalog/part-categories' => (200, [{'id': 4, 'name': 'Filtres'}]),
      '/catalog/manufacturers' => (200, [{'id': 5, 'name': 'Fabricant'}]),
      _ => (404, {'message': 'Route inattendue'}),
    });
    dio.httpClientAdapter = adapter;

    final references = await repository.references();

    expect(references.brands.single['id'], 1);
    expect(references.models.single['id'], 2);
    expect(references.engineTypes.single['id'], 3);
    expect(references.partCategories.single['id'], 4);
    expect(references.manufacturers.single['id'], 5);
    expect(adapter.requests.every((request) => !request.headers.containsKey('Authorization')), isTrue);
  });

  /// Le jeton partenaire part-il au bon moment, et SEULEMENT au bon moment ?
  ///
  /// `getMe()` est le seul endroit du dépôt qui efface le coffre sur un refus
  /// du serveur, et il s'en remet à `sessionRejected`. Les bancs de
  /// `test/session_rejetee_test.dart` éprouvent la règle ; celui-ci éprouve
  /// son EFFET, sur le vrai chemin, coffre compris.
  ///
  /// `restore()` passe par `getMe()` : c'est donc aussi le comportement au
  /// démarrage de l'application qui se joue ici.
  group('Ce qui vide le coffre partenaire, et ce qui n\'y touche pas', () {
    Future<PartnerApiException> refus(int statut, {String? code}) async {
      tokens.token = 'partner-test-token';
      dio.httpClientAdapter = _Adapter((_) => (statut, {
        'message': 'Refus du serveur.',
        'code': ?code,
      }));

      try {
        await repository.getMe();
        fail('getMe() devait lever sur un $statut.');
      } on PartnerApiException catch (erreur) {
        return erreur;
      }
    }

    test('un compte désactivé vide le coffre', () async {
      final erreur = await refus(403, code: 'account_disabled');

      expect(erreur.isAccountDisabled, isTrue);
      expect(tokens.token, isNull, reason: 'Le jeton devait partir.');
    });

    /// LE BANC QUI PROTEGE LE PARTENAIRE DE LUI-MEME.
    ///
    /// C'est ce refus-là que l'ancienne règle traitait comme un rejet de
    /// session : « cette annonce n'est pas la vôtre » déconnectait.
    test('un refus de permission laisse le jeton intact', () async {
      final erreur = await refus(403, code: 'permission_denied');

      expect(erreur.isPermissionDenied, isTrue);
      expect(tokens.token, 'partner-test-token',
          reason: 'Un refus d\'autorisation a vidé le coffre.');
    });

    test('un 403 sans code laisse le jeton intact', () async {
      await refus(403);

      expect(tokens.token, 'partner-test-token');
    });

    test('un 401 vide le coffre', () async {
      await refus(401);

      expect(tokens.token, isNull);
    });

    /// Render s'endort sur le plan gratuit : un 500 ou un délai dépassé ne
    /// dit rien de la session, et ne doit donc rien fermer.
    test('une erreur serveur laisse le jeton intact', () async {
      await refus(500);

      expect(tokens.token, 'partner-test-token');
    });
  });
}
