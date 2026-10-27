import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/partner_accounts/data/partner_repository.dart';
import 'package:auto/features/partner_accounts/presentation/partner_account_page.dart';
import 'package:auto/features/partner_accounts/presentation/partner_notifications_page.dart';
import 'package:auto/features/partner_accounts/presentation/partner_session.dart';

import 'support/polices.dart';

/// Captures de la diffusion : ce que le partenaire reçoit.
///
/// Même convention que les autres fichiers de capture : rien n'est écrit sans
/// `CAPTURES=1`, et chaque banc vérifie d'abord que la capture ne serait pas
/// vide — un `matchesGoldenFile` sur un écran qui n'a rien rendu produit une
/// image grise sans que rien ne s'en plaigne.

class _Session extends StateNotifier<PartnerSession>
    implements PartnerSessionNotifier {
  _Session()
      : super(PartnerSession(
          profile: PartnerProfile(
            user: const {'role': 'partner'},
            account: const {
              'status': 'approved',
              'company_name': 'Garage Ouaga 2000',
              'contact_name': 'Salif Kaboré',
            },
          ),
        ));

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Depot extends PartnerRepository {
  @override
  Future<List<Map<String, dynamic>>> notifications() async => [
        _ligne(
          id: 1,
          titre: 'Demande client à pourvoir',
          corps: 'Pièce détachée — budget 25 000 FCFA — Cherche un filtre à '
              'huile pour Corolla E180.',
          besoin: const {
            'brand_name': 'Toyota',
            'part_category_name': 'Filtres à huile',
            'oem_number': '90915-YZZD2',
          },
        ),
        _ligne(
          id: 2,
          titre: 'Demande client à pourvoir',
          corps: 'Véhicule — budget 4 500 000 FCFA — Cherche une berline diesel, '
              'boîte automatique.',
          besoin: const {'brand_name': 'Hyundai', 'vehicle_model_name': 'Elantra'},
          lue: true,
        ),
      ];

  @override
  Future<int> notificationsNonLues() async => 1;

  static Map<String, dynamic> _ligne({
    required int id,
    required String titre,
    required String corps,
    required Map<String, dynamic> besoin,
    bool lue = false,
  }) => {
        'id': id,
        'type': 'need_broadcast',
        'title': titre,
        'body': corps,
        'data': {'type': 'need_broadcast', 'need_id': '$id', 'besoin': besoin},
        'read_at': lue ? '2026-10-27T10:00:00+00:00' : null,
        'created_at': '2026-10-27T09:00:00+00:00',
      };
}

void main() {
  final bool ecrireCaptures = Platform.environment['CAPTURES'] == '1';

  setUpAll(chargerPolices);

  Future<void> poser(WidgetTester tester, Widget ecran) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        partnerRepositoryProvider.overrideWithValue(_Depot()),
        partnerSessionProvider.overrideWith((_) => _Session()),
      ],
      child: MaterialApp(home: ecran),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> capturer(WidgetTester tester, String nom, Finder temoin) async {
    expect(temoin, findsWidgets,
        reason: 'La capture serait vide : $nom n a rien rendu.');
    if (!ecrireCaptures) return;

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/captures/$nom.png'),
    );
  }

  testWidgets('les demandes reçues par le partenaire', (tester) async {
    await poser(tester, const PartnerNotificationsPage());

    await capturer(tester, 'diffusion-demandes-partenaire',
        find.textContaining('90915-YZZD2'));
  });

  testWidgets('la tuile et sa pastille dans l’espace partenaire',
      (tester) async {
    await poser(tester, const PartnerAccountPage());

    await tester.scrollUntilVisible(
      find.byKey(const Key('partner-tuile-demandes')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await capturer(tester, 'diffusion-tuile-partenaire',
        find.byKey(const Key('partner-demandes-pastille')));
  });
}
