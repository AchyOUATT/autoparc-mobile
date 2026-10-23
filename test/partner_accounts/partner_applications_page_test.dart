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
}
