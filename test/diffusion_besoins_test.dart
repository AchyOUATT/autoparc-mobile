import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/notifications/data/models/app_notification.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart';
import 'package:auto/features/partner_accounts/presentation/partner_account_page.dart';
import 'package:auto/features/partner_accounts/presentation/partner_notifications_page.dart';
import 'package:auto/features/partner_accounts/presentation/partner_session.dart';

/// La boîte aux lettres du partenaire, où arrivent les demandes clients.
///
/// ── CE QUE CE BANC TIENT ───────────────────────────────────────────────────
///
/// Que la demande se lise d'un coup d'œil — le type, le budget, les critères —
/// et que la pastille de non-lue disparaisse une fois ouverte.
///
/// Et, surtout, que l'écran ne CHERCHE nulle part le contact du client. Le
/// serveur ne l'envoie pas, et c'est délibéré : ce client s'est adressé à la
/// boutique, pas à quinze vendeurs. Un écran qui le lirait aujourd'hui n'aurait
/// rien à afficher, mais il attendrait un champ — et quelqu'un finirait par le
/// faire envoyer pour « réparer » l'affichage.

class _Depot extends PartnerRepository {
  _Depot(this.lignes);

  final List<Map<String, dynamic>> lignes;
  final List<int> luesUneAUne = [];
  bool toutLu = false;

  @override
  Future<List<Map<String, dynamic>>> notifications() async => lignes;

  @override
  Future<int> notificationsNonLues() async =>
      lignes.where((l) => l['read_at'] == null).length;

  @override
  Future<void> marquerLu(int id) async => luesUneAUne.add(id);

  @override
  Future<void> marquerToutLu() async => toutLu = true;
}

Map<String, dynamic> _diffusion({
  int id = 1,
  bool lue = false,
  Map<String, dynamic>? besoin,
}) => {
      'id': id,
      'type': 'need_broadcast',
      'title': 'Demande client a pourvoir',
      'body': 'Piece detachee — budget 25000 FCFA — Cherche un filtre a huile.',
      'data': {
        'type': 'need_broadcast',
        'need_id': '$id',
        'besoin': besoin ??
            const {
              'id': 1,
              'type': 'part',
              'description': 'Cherche un filtre a huile pour Corolla E180.',
              'budget_max': 25000,
              'brand_name': 'Toyota',
              'part_category_name': 'Filtres à huile',
              'oem_number': '90915-YZZD2',
            },
      },
      'read_at': lue ? '2026-10-27T10:00:00+00:00' : null,
      'created_at': '2026-10-27T09:00:00+00:00',
    };

class _SessionApprouvee extends StateNotifier<PartnerSession>
    implements PartnerSessionNotifier {
  _SessionApprouvee()
      : super(PartnerSession(
          profile: PartnerProfile(
            user: const {'role': 'partner'},
            account: const {'status': 'approved', 'contact_name': 'Salif'},
          ),
        ));

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// L'espace partenaire vit dans un `ListView` : la tuile des demandes est
/// sous la ligne de flottaison, donc PAS CONSTRUITE tant qu'on n'a pas
/// fait défiler. `find` ne la voit pas, et un banc qui l'ignorerait
/// conclurait qu'elle n'existe pas.
Future<void> _jusquALaTuile(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('partner-tuile-demandes')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _ouvrir(WidgetTester tester, _Depot depot) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [partnerRepositoryProvider.overrideWithValue(depot)],
    child: const MaterialApp(home: PartnerNotificationsPage()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la demande se lit d’un coup d’œil', (tester) async {
    await _ouvrir(tester, _Depot([_diffusion()]));

    expect(find.text('Demande client a pourvoir'), findsOneWidget);
    expect(find.textContaining('budget 25000'), findsOneWidget);
    expect(find.textContaining('Toyota'), findsOneWidget);
    expect(find.textContaining('90915-YZZD2'), findsOneWidget);
  });

  /// Un critère absent ne laisse pas de séparateur orphelin : c'est le défaut
  /// que la ligne à trois valeurs des fiches véhicule avait payé.
  testWidgets('les critères absents ne laissent pas de séparateur',
      (tester) async {
    await _ouvrir(tester, _Depot([
      _diffusion(besoin: const {
        'id': 1,
        'type': 'accessory',
        'description': 'Cherche un tapis de sol.',
        'accessory_category': 'confort',
      }),
    ]));

    expect(find.text('confort'), findsOneWidget);
    expect(find.textContaining(' ·  · '), findsNothing);
  });

  testWidgets('une non-lue porte sa pastille, une lue non', (tester) async {
    await _ouvrir(tester, _Depot([
      _diffusion(id: 1),
      _diffusion(id: 2, lue: true),
    ]));

    expect(find.byKey(const Key('partner-notif-pastille')), findsOneWidget);
  });

  testWidgets('ouvrir une non-lue la marque lue', (tester) async {
    final depot = _Depot([_diffusion(id: 7)]);
    await _ouvrir(tester, depot);

    await tester.tap(find.byKey(const ValueKey('partner-notif-7')));
    await tester.pumpAndSettle();

    expect(depot.luesUneAUne, [7]);
  });

  testWidgets('« Tout lire » n’apparaît que s’il reste des non-lues',
      (tester) async {
    await _ouvrir(tester, _Depot([_diffusion(lue: true)]));

    expect(find.byKey(const Key('partner-notifs-tout-lire')), findsNothing);
  });

  testWidgets('« Tout lire » marque tout lu', (tester) async {
    final depot = _Depot([_diffusion()]);
    await _ouvrir(tester, depot);

    await tester.tap(find.byKey(const Key('partner-notifs-tout-lire')));
    await tester.pumpAndSettle();

    expect(depot.toutLu, isTrue);
  });

  testWidgets('une boîte vide le dit, et dit pourquoi', (tester) async {
    await _ouvrir(tester, _Depot([]));

    expect(find.textContaining('Aucune demande'), findsOneWidget);
    expect(find.textContaining('dès que la boutique les transmet'), findsOneWidget);
  });

  /// LE BANC QUI COMPTE : rien ne cherche le contact du client.
  ///
  /// Le serveur ne l'envoie pas. Un écran qui le lirait n'aurait rien à
  /// afficher aujourd'hui, mais il attendrait un champ — et quelqu'un finirait
  /// par le faire envoyer pour « réparer » l'affichage.
  testWidgets('l’écran n’affiche aucun contact, même si le serveur en envoyait',
      (tester) async {
    await _ouvrir(tester, _Depot([
      _diffusion(besoin: const {
        'id': 1,
        'type': 'part',
        'description': 'Cherche un filtre.',
        // Ce que le serveur NE DOIT PAS envoyer. S'il le faisait un jour, par
        // regression, l'écran ne doit toujours rien en montrer.
        'contact_name': 'Awa Traore',
        'contact_phone': '+22670000001',
        'contact_email': 'awa@example.test',
      }),
    ]));

    for (final prive in ['Awa Traore', '+22670000001', 'awa@example.test']) {
      expect(find.textContaining(prive), findsNothing,
          reason: '« $prive » s affiche : le client sera appele par tous les '
              'partenaires.');
    }
  });

  // ── LA PASTILLE DE L'ESPACE PARTENAIRE ──────────────────────────────
  //
  // Une tuile muette ne se visite pas : sans le compteur, le partenaire
  // n'a aucune raison d'ouvrir cet ecran, et la demande attend.

  testWidgets('la tuile porte le nombre de demandes non lues', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        partnerRepositoryProvider.overrideWithValue(_Depot([
          _diffusion(id: 1),
          _diffusion(id: 2),
          _diffusion(id: 3, lue: true),
        ])),
        partnerSessionProvider.overrideWith((_) => _SessionApprouvee()),
      ],
      child: const MaterialApp(home: PartnerAccountPage()),
    ));
    await tester.pumpAndSettle();

    await _jusquALaTuile(tester);

    expect(find.byKey(const Key('partner-demandes-pastille')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  /// Rien plutot qu'un « 0 » : une pastille a zero attire l'oeil sur une
  /// absence, et apprend a ne plus la regarder.
  testWidgets('sans non-lue, aucune pastille', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        partnerRepositoryProvider.overrideWithValue(_Depot([_diffusion(lue: true)])),
        partnerSessionProvider.overrideWith((_) => _SessionApprouvee()),
      ],
      child: const MaterialApp(home: PartnerAccountPage()),
    ));
    await tester.pumpAndSettle();

    await _jusquALaTuile(tester);

    expect(find.byKey(const Key('partner-demandes-pastille')), findsNothing);
  });

  /// Le type `need_broadcast` doit être connu du modèle, sans quoi il tombe
  /// sur l'icône et la couleur par défaut — indistinguable du reste.
  test('le type de diffusion a son icône et sa couleur', () {
    final notif = AppNotification.fromJson(_diffusion());

    expect(notif.iconData, Icons.campaign_outlined);
    expect(notif.iconColor, 0xFF00695C);
  });
}
