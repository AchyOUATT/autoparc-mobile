import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/catalog/presentation/vehicle_price.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as partner;
import 'package:auto/features/partner_accounts/presentation/partner_listings_page.dart';
import 'package:auto/features/partner_accounts/presentation/partner_session.dart'
    as partner;
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';

VehicleCommercial _offer({
  String availability = 'rent',
  double? sale,
  double? daily,
  double? weekly,
  double? monthly,
}) => VehicleCommercial(
  condition: 'used',
  status: 'in_stock',
  availability: availability,
  salePrice: sale,
  rentalDailyRate: daily,
  rentalWeeklyRate: weekly,
  rentalMonthlyRate: monthly,
  currency: 'XOF',
  priceNegotiable: false,
);

class _Guest extends StateNotifier<AuthState> implements AuthNotifier {
  _Guest() : super(const AuthState());

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Session extends StateNotifier<partner.PartnerSession>
    implements partner.PartnerSessionNotifier {
  _Session()
    : super(
        partner.PartnerSession(
          profile: partner.PartnerProfile(
            user: const {'role': 'partner'},
            account: const {'status': 'approved', 'contact_name': 'Vendeur'},
          ),
        ),
      );

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Inventory extends partner.PartnerRepository {
  _Inventory(this.commercial);

  final Map<String, dynamic> commercial;

  @override
  Future<partner.PartnerListingPage> listListings(
    partner.PartnerListingKind kind, {
    int page = 1,
    String? query,
  }) async => partner.PartnerListingPage(
    items: [
      {'id': 1, 'name': 'Toyota Corolla', 'commercial': commercial},
    ],
    page: 1,
    lastPage: 1,
    total: 1,
  );
}

Widget _app(Widget page, {String language = 'fr', double scale = 1}) =>
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: page,
    );

void main() {
  setUpAll(chargerPolices);
  setUp(() => definirLocaleMontants(const Locale('fr')));
  tearDown(() => definirLocaleMontants(const Locale('fr')));

  for (final language in ['fr', 'en']) {
    test('a weekly-only headline preserves its period in $language', () async {
      definirLocaleMontants(Locale(language));
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      final suffix = language == 'fr' ? '/semaine' : '/week';
      final offer = _offer(weekly: 130000, sale: 8000000);
      expect(
        vehicleHeadlinePrice(offer, l10n),
        '${formatXofShort(130000)}$suffix',
      );
      expect(vehicleRentalPriceLabels(offer, l10n), [
        '${formatXofShort(130000)}$suffix',
      ]);
    });
  }

  test(
    'daily weekly and monthly rates remain independent and ordered',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final offer = _offer(daily: 25000, weekly: 130000, monthly: 500000);
      expect(vehicleRentalPriceLabels(offer, l10n), [
        '${formatXofShort(25000)}/j',
        '${formatXofShort(130000)}/semaine',
        '${formatXofShort(500000)}/mois',
      ]);
      expect(vehicleHeadlinePrice(offer, l10n), '${formatXofShort(25000)}/j');
    },
  );

  test('a mixed offer retains its sale headline and its weekly rate', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    final offer = _offer(availability: 'both', sale: 8000000, weekly: 130000);
    expect(vehicleHeadlinePrice(offer, l10n), formatXofShort(8000000));
    expect(vehicleRentalPriceLabels(offer, l10n), [
      '${formatXofShort(130000)}/semaine',
    ]);
  });

  test('an inactive weekly rate is hidden on a sale-only offer', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    final offer = _offer(availability: 'sale', weekly: 130000);
    expect(vehicleRentalPriceLabels(offer, l10n), isEmpty);
    expect(vehicleHeadlinePrice(offer, l10n), isNull);
  });

  test(
    'an explicit zero weekly rate remains visible without conversion',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(vehicleRentalPriceLabels(_offer(weekly: 0), l10n), [
        '${formatXofShort(0)}/semaine',
      ]);
    },
  );

  for (final language in ['fr', 'en']) {
    testWidgets('vehicle detail shows a weekly-only rental in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vehicle = Vehicle.fromJson({
        'id': 71,
        'reference': 'VH-RENT',
        'designation': 'Toyota Corolla',
        'vehicle_type': 'passenger',
        'registration_status': 'registered',
        'identity': {'brand': 'Toyota', 'model': 'Corolla', 'year': 2020},
        'commercial': {
          'condition': 'used',
          'status': 'in_stock',
          'availability': 'rent',
          'sale_price': 8000000,
          'rental_weekly_rate': '130000.00',
        },
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((_) => _Guest()),
            vehicleDetailProvider(71).overrideWith((_) async => vehicle),
          ],
          child: _app(
            const VehicleDetailPage(vehicleId: 71),
            language: language,
            scale: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final suffix = language == 'fr' ? '/semaine' : '/week';
      expect(find.textContaining(suffix), findsOneWidget);
      expect(find.textContaining('/mois'), findsNothing);
      expect(find.textContaining('/month'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('partner inventory shows weekly-only without an invented month', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partner.partnerRepositoryProvider.overrideWithValue(
            _Inventory({
              'availability': 'rent',
              'sale_price': '8000000.00',
              'rental_weekly_rate': '130000.00',
              'currency': 'XOF',
            }),
          ),
          partner.partnerSessionProvider.overrideWith((_) => _Session()),
        ],
        child: _app(
          const PartnerListingsPage(kind: partner.PartnerListingKind.vehicles),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Location : 130 000 / semaine'), findsOneWidget);
    expect(find.textContaining('/ mois'), findsNothing);
    expect(find.textContaining('8 000 000'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('partner inventory shows all three supplied rental rates', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partner.partnerRepositoryProvider.overrideWithValue(
            _Inventory({
              'availability': 'rent',
              'rental_daily_rate': 25000,
              'rental_weekly_rate': 130000,
              'rental_monthly_rate': 500000,
            }),
          ),
          partner.partnerSessionProvider.overrideWith((_) => _Session()),
        ],
        child: _app(
          const PartnerListingsPage(kind: partner.PartnerListingKind.vehicles),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Location : 25 000 / jour'), findsOneWidget);
    expect(find.textContaining('Location : 130 000 / semaine'), findsOneWidget);
    expect(find.textContaining('Location : 500 000 / mois'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
