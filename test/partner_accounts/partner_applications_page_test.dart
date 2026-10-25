import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/partner_accounts/presentation/partner_applications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Api implements ApiClient {
  bool failNext = false;

  /// Une charge utile imposee, pour eprouver ce que fait l'ecran d'une reponse
  /// mal formee. Laissee nulle, la reponse nominale est servie.
  Map<String, dynamic>? reponseImposee;

  final queries = <Map<String, dynamic>>[];
  final decisions = <({String path, Map<String, dynamic>? data})>[];
  final reviewed = <int>{};

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async {
    expect(path, '/partner-applications');
    queries.add({...?params});
    if (failNext) {
      failNext = false;
      throw const ApiException(message: 'Indisponible', statusCode: 503);
    }
    if (reponseImposee != null) return reponseImposee!;
    final page = params?['page'] as int? ?? 1;
    final id = page == 1 ? 1 : 2;
    return {
      'data': reviewed.contains(id) ? [] : [{
        'id': id, 'company_name': 'Garage $id', 'contact_name': 'Responsable $id',
        'phone': '+2267000000$id', 'status': params?['status'] ?? 'pending',
        'user': {'email': 'garage$id@example.test'},
      }],
      'meta': {'current_page': page, 'last_page': 2, 'total': 26 - reviewed.length},
    };
  }

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    decisions.add((path: path, data: data));
    reviewed.add(int.parse(path.split('/')[2]));
    return {'data': {}};
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

Future<void> _open(WidgetTester tester, _Api api, {String role = 'manager'}) async {
  await tester.pumpWidget(ProviderScope(overrides: [
    apiClientProvider.overrideWithValue(api),
    authProvider.overrideWith((_) => _Auth(AuthState(type: AuthType.staff,
      staffUser: StaffUser(id: 1, name: 'Responsable', email: 'staff@example.test', role: role)))),
  ], child: const MaterialApp(home: PartnerApplicationsPage())));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('un personnel sans capacité ne charge ni ne valide les demandes', (tester) async {
    final api = _Api();
    await _open(tester, api, role: 'viewer');

    expect(find.text('Accès réservé aux responsables.'), findsOneWidget);
    expect(find.text('Approuver'), findsNothing);
    expect(api.queries, isEmpty);
    expect(api.decisions, isEmpty);
  });

  testWidgets('réessai, page suivante et approbation utilisent les routes du personnel', (tester) async {
    final api = _Api()..failNext = true;
    await _open(tester, api);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Garage 1'), findsOneWidget);
    expect(api.queries.last, {'status': 'pending', 'page': 1, 'per_page': 25});

    await tester.tap(find.byKey(const Key('partner-applications-next')));
    await tester.pumpAndSettle();
    expect(find.text('Garage 2'), findsOneWidget);
    expect(find.text('Page 2 / 2 · 26 demande(s)'), findsOneWidget);
    expect(api.queries.last['page'], 2);

    await tester.tap(find.text('Approuver'));
    await tester.pumpAndSettle();
    expect(api.decisions.single.path, '/partner-applications/2/approve');
    expect(api.decisions.single.data, isEmpty);
    expect(find.text('Garage 1'), findsOneWidget);
    expect(api.queries.last['page'], 1);
  });

  testWidgets('le refus exige un motif puis transmet la valeur nettoyée', (tester) async {
    final api = _Api();
    await _open(tester, api, role: 'admin');
    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(find.text('Précisez le motif de cette décision.'), findsOneWidget);
    expect(api.decisions, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Motif communiqué au partenaire'), '  Coordonnées incomplètes  ');
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    expect(api.decisions.single.path, '/partner-applications/1/reject');
    expect(api.decisions.single.data, {'review_reason': 'Coordonnées incomplètes'});
    expect(find.text('Aucune demande dans cette catégorie.'), findsOneWidget);
  });

  // ── Une reponse mal formee ne doit pas donner un ecran rouge ──────────────
  //
  // Cet ecran lisait ses champs en casts NUS — `account['id'] as int`,
  // `account['phone'] as String`, `(response['data'] as List)`. Un champ nul,
  // absent, ou serialise dans un autre type ne donne alors pas un message mais
  // un `TypeError` leve DANS le `build()`, donc un ecran rouge que
  // `messageFor()` ne rattrape pas : il ne traite que les erreurs reseau.
  //
  // Ce n'est pas theorique. Le depot documente la meme faute comme ayant deja
  // fait tomber le catalogue entier — « 2450000.00 » lu comme un `num?` —
  // dans `lib/core/update/version_minimale.dart`. Et c'est l'ecran sur lequel
  // quelqu'un approuve une entreprise.

  testWidgets('un identifiant serialise en TEXTE est lu, et l\'approbation vise la bonne route', (tester) async {
    // PHP rend volontiers un entier en chaine. `as int` levait ici.
    final api = _Api()
      ..reponseImposee = {
        'data': [
          {'id': '7', 'company_name': 'Garage Kossodo', 'contact_name': 'Awa', 'phone': '+22670000000'},
        ],
        'meta': {'current_page': '1', 'last_page': '1', 'total': '1'},
      };
    await _open(tester, api);

    expect(tester.takeException(), isNull, reason: 'La carte a leve pendant sa construction.');
    expect(find.text('Garage Kossodo'), findsOneWidget);
    // Les compteurs sont lus tolerants eux aussi : « 1 / 1 » et non « 1 / 1 »
    // par defaut de requete.
    expect(find.text('Page 1 / 1 · 1 demande(s)'), findsOneWidget);

    await tester.tap(find.text('Approuver'));
    await tester.pumpAndSettle();

    expect(api.decisions.single.path, '/partner-applications/7/approve');
  });

  testWidgets('des champs nuls ou absents sont nommes, et non affiches en blanc', (tester) async {
    final api = _Api()
      ..reponseImposee = {
        'data': [
          {'id': 3, 'phone': null},
        ],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
      };
    await _open(tester, api);

    expect(tester.takeException(), isNull);
    // Le repli NOMME ce qui manque : une ligne blanche laisserait croire que le
    // champ est vide alors qu'il est illisible, sur l'ecran ou l'on decide.
    expect(find.text('Entreprise sans nom'), findsOneWidget);
    expect(find.text('Contact non renseigné'), findsOneWidget);
    expect(find.text('Téléphone non renseigné'), findsOneWidget);
    // Et l'action reste possible : l'identifiant, lui, est lisible.
    expect(find.text('Approuver'), findsOneWidget);
  });

  testWidgets('un `data` absent rend une page vide, pas une exception', (tester) async {
    final api = _Api()..reponseImposee = {'meta': {'current_page': 1}};
    await _open(tester, api);

    expect(tester.takeException(), isNull);
    expect(find.text('Aucune demande dans cette catégorie.'), findsOneWidget);
  });

  testWidgets('un element mal forme se perd seul, sans emporter la page', (tester) async {
    // Mieux vaut une candidature manquante qu'un ecran rouge : les elements qui
    // ne sont pas des maps sont ecartes un par un.
    final api = _Api()
      ..reponseImposee = {
        'data': [
          'ceci n\'est pas une map',
          {'id': 9, 'company_name': 'Garage Tanghin', 'contact_name': 'Salif', 'phone': '+22671000000'},
        ],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 2},
      };
    await _open(tester, api);

    expect(tester.takeException(), isNull);
    expect(find.text('Garage Tanghin'), findsOneWidget);
  });

  testWidgets('une erreur reseau passe par messageFor, et jamais le texte Dart brut', (tester) async {
    // Le garde-fou que la fiche de republication demandait et qui n'avait
    // jamais ete pose : verifier que le texte RENDU ne porte pas le nom de
    // l'exception. Corriger la couche des messages sans tester son emploi est
    // precisement l'ecart qui a produit la panne d'origine.
    final api = _Api()..failNext = true;
    await _open(tester, api);

    expect(find.textContaining('ApiException'), findsNothing);
    expect(find.textContaining('DioException'), findsNothing);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
