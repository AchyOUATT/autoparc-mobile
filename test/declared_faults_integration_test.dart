import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/catalog_repository.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/inspections/presentation/staff_inspection_widgets.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/features/private_sales/presentation/private_listing_detail.dart';
import 'package:auto/features/private_sales/presentation/private_listing_form.dart';
import 'package:auto/features/vehicles/presentation/widgets/declared_faults_section.dart';
import 'package:auto/l10n/app_localizations_fr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'private_sales/private_sales_test.dart' as fixture;

Map<String, dynamic> declaration(String state, {String status = 'declared'}) =>
    {
      'state': state,
      'declared_at': state == 'unknown' ? null : '2026-11-03T10:00:00Z',
      'faults': state == 'has_faults'
          ? [
              {
                'id': 7,
                'category': 'braking',
                'title': 'Freinage à contrôler',
                'description': 'Vibration au freinage',
                'severity': 'moderate',
                'status': status,
                'affects_drivability': true,
                'is_safety_critical': true,
                'disclosed_to_buyer': true,
              },
            ]
          : <Map<String, dynamic>>[],
      'unresolved_count': state == 'has_faults' && status != 'repaired' ? 1 : 0,
    };

class _DeclarationApi extends fixture.FakeSalesApi {
  _DeclarationApi(String state, {String status = 'declared'})
    : stored = {
        ...fixture.listingFields(status: 'draft'),
        'fault_declaration': declaration(state, status: status),
        'photos': [
          {'id': 1, 'url': 'https://example.invalid/condition-photo.jpg'},
        ],
      };

  Map<String, dynamic> stored;

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    commands.add((path: path, data: data));
    stored = {
      ...stored,
      ...?data,
      if (data?.containsKey('fault_declaration_state') == true)
        'fault_declaration': {
          'state': data!['fault_declaration_state'],
          'declared_at': '2026-11-03T10:00:00Z',
          'faults': data['faults'],
          'unresolved_count': (data['faults'] as List)
              .where((f) => f['status'] != 'repaired')
              .length,
        },
    };
    return {'data': stored};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    commands.add((path: path, data: data));
    if (path.endsWith('/submit')) {
      if (!PrivateListing(stored).faultDeclaration.canSubmit) {
        throw const ApiException(
          message: 'Declaration required',
          statusCode: 422,
        );
      }
      stored = {...stored, 'status': 'pending'};
    }
    return {'data': stored};
  }
}

class _FilterApi extends ApiClient {
  final calls = <({String path, Map<String, dynamic>? params})>[];
  bool missingUnified = false;
  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    calls.add((path: path, params: params));
    if (missingUnified) {
      throw const ApiException(message: 'Not found', statusCode: 404);
    }
    return {
      'data': <Map<String, dynamic>>[],
      'meta': {'current_page': 1, 'last_page': 1, 'total': 0, 'per_page': 20},
      'links': {'next': null, 'prev': null},
    };
  }
}

void main() {
  test(
    'old stock and private payloads remain unknown rather than claiming no faults',
    () {
      final listing = fixture.listingFields()..remove('fault_declaration');
      expect(PrivateListing(listing).faultDeclaration.state, 'unknown');
      expect(PrivateListing(listing).faultDeclaration.canSubmit, isFalse);
      final vehicle = Vehicle.fromJson({
        'id': 1,
        'designation': 'Toyota Corolla',
        'registration_status': 'registered',
        'identity': {'brand': 'Toyota', 'model': 'Corolla'},
        'commercial': {
          'condition': 'used',
          'status': 'in_stock',
          'availability': 'sale',
        },
        'faults': <Map<String, dynamic>>[],
      });
      expect(vehicle.faultDeclaration.state, 'unknown');
    },
  );

  test(
    'filter forwards strict condition to both catalogue APIs and can be cleared',
    () async {
      final api = _FilterApi();
      final repo = CatalogRepository(api, CatalogLocalCache());
      final filter = const VehicleFilter().copyWith(withoutFaults: true);
      await repo.getVehicleListings(withoutFaults: filter.withoutFaults);
      await repo.getVehicles(withoutFaults: true);
      expect(api.calls.map((call) => call.params!['without_faults']), [
        '1',
        '1',
      ]);
      expect(filter.copyWith(clearWithoutFaults: true).withoutFaults, isNull);
      await repo.getVehicleListings(withoutFaults: false);
      expect(api.calls.last.params!.containsKey('without_faults'), isFalse);
    },
  );

  test(
    'strict condition cannot fall back to an older catalogue with unknown declarations',
    () async {
      final api = _FilterApi()..missingUnified = true;
      final repo = CatalogRepository(api, CatalogLocalCache());
      await expectLater(
        repo.getVehicleListings(withoutFaults: true),
        throwsA(isA<ApiException>()),
      );
      expect(api.calls, hasLength(1));
    },
  );

  testWidgets('private submission requires an explicit persisted declaration', (
    tester,
  ) async {
    fixture.saleViewport(tester);
    final api = _DeclarationApi('unknown');
    final l10n = AppLocalizationsFr();
    await fixture.open(
      tester,
      api,
      PrivateListingForm(existing: PrivateListing(api.stored)),
    );
    final submit = find.widgetWithText(FilledButton, l10n.privateSalesSubmit);
    await tester.scrollUntilVisible(
      submit,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(
      find.text(l10n.faultDeclarationPrivateSubmitRequired),
      findsOneWidget,
    );
    expect(api.commands, isEmpty);

    final none = find.byKey(const ValueKey('fault-declaration-state-none'));
    await tester.scrollUntilVisible(
      none,
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(none);
    await tester.pumpAndSettle();
    await fixture.saveSaleDraft(tester);
    expect(api.commands.single.data!['fault_declaration_state'], 'none');
    expect(api.commands.single.data!['faults'], isEmpty);

    for (final text in [
      l10n.privateSalesOwnerConfirmation,
      l10n.privateSalesContactConsent,
    ]) {
      final checkbox = find.widgetWithText(CheckboxListTile, text);
      await tester.scrollUntilVisible(
        checkbox,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(submit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(api.commands.last.path, '/my/private-listings/1/submit');
  });

  testWidgets(
    'price-only edits preserve the existing declaration and unrepaired history',
    (tester) async {
      fixture.saleViewport(tester);
      final api = _DeclarationApi('has_faults', status: 'wont_fix');
      await fixture.open(
        tester,
        api,
        PrivateListingForm(existing: PrivateListing(api.stored)),
      );
      final price = fixture.saleTextField(
        AppLocalizationsFr().privateSalesPriceLabel,
      );
      await tester.ensureVisible(price);
      await tester.enterText(price, '7000000');
      await fixture.saveSaleDraft(tester);
      expect(api.commands.single.data!.containsKey('faults'), isFalse);
      expect(
        api.commands.single.data!.containsKey('fault_declaration_state'),
        isFalse,
      );
      final retained = PrivateListing(api.stored).faultDeclaration;
      expect(retained.faults.single.id, 7);
      expect(retained.faults.single.status, 'wont_fix');
      expect(retained.unresolvedCount, 1);
    },
  );

  testWidgets(
    'public details show declared faults independently of staff inspection',
    (tester) async {
      fixture.saleViewport(tester);
      final api = _DeclarationApi('has_faults', status: 'wont_fix');
      await fixture.open(
        tester,
        api,
        PrivateListingDetail(listing: PrivateListing(api.stored)),
      );
      await tester.ensureVisible(find.byType(DeclaredFaultsSection));
      expect(find.text('Freinage à contrôler'), findsOneWidget);
      expect(find.text('Vibration au freinage'), findsOneWidget);
      expect(find.byType(StaffInspectionBadge), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
