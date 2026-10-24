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

  for (final code in [401, 403]) {
    test('un refus $code sur le profil efface la session partenaire', () async {
      tokens.token = 'expired';
      dio.httpClientAdapter = _Adapter((_) => (code, {'message': 'Session refusée'}));

      await expectLater(repository.getMe(), throwsA(isA<PartnerApiException>().having((error) => error.statusCode, 'status', code)));
      expect(tokens.token, isNull);
    });
  }

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
}
