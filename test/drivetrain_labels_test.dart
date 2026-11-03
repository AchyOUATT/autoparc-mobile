import 'package:auto/core/l10n/reference_labels.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/features/private_sales/presentation/private_listing_detail.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/models/vehicle_classification_selection.dart';
import 'package:auto/features/vehicles/presentation/widgets/vehicle_identity_fields.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'private_sales/private_sales_test.dart' as fixture;

const _drives = [
  DrivetrainRef(id: 1, code: 'FWD', label: 'Traction avant'),
  DrivetrainRef(id: 2, code: 'RWD', label: 'Propulsion'),
  DrivetrainRef(id: 3, code: 'AWD', label: 'Intégrale permanente'),
  DrivetrainRef(id: 4, code: '4WD', label: '4x4 enclenchable'),
];

const _refs = CatalogRefs(
  brands: [],
  vehicleModels: [],
  trims: [],
  engineTypes: [],
  drivetrains: _drives,
  colors: [],
  features: [],
  locations: [],
);

const _legacy = {
  'FWD': 'FWD',
  'RWD': 'RWD',
  'AWD': 'AWD',
  '4WD': '4WD',
  'Traction avant': 'FWD',
  'Propulsion': 'RWD',
  'Propulsion arrière': 'RWD',
  'Intégrale permanente': 'AWD',
  'Transmission intégrale permanente': 'AWD',
  '4x4 enclenchable': '4WD',
  '4x4 débrayable': '4WD',
  'Intégrale (AWD)': 'AWD',
  '4×4 (4WD)': '4WD',
  'Front-wheel drive': 'FWD',
  'Rear-wheel drive': 'RWD',
  'All-wheel drive': 'AWD',
  'Selectable four-wheel drive': '4WD',
  'All-wheel drive (AWD)': 'AWD',
  'Four-wheel drive (4WD)': '4WD',
};

Map<String, String> _labels(String language) => language == 'fr'
    ? {
        'FWD': 'Traction avant',
        'RWD': 'Propulsion arrière',
        'AWD': 'Intégrale (AWD)',
        '4WD': '4×4 (4WD)',
      }
    : {
        'FWD': 'Front-wheel drive',
        'RWD': 'Rear-wheel drive',
        'AWD': 'All-wheel drive (AWD)',
        '4WD': 'Four-wheel drive (4WD)',
      };

void main() {
  for (final language in ['fr', 'en']) {
    test(
      'wheel drive codes correct stale or conflicting labels in $language',
      () async {
        final l10n = await AppLocalizations.delegate.load(Locale(language));
        final labels = _labels(language);
        for (final drive in _drives) {
          expect(
            referenceDrivetrainLabel(drive.code, drive.label, l10n),
            labels[drive.code],
          );
          expect(
            referenceDrivetrainLabel(
              ' ${drive.code.toLowerCase()} ',
              'Conflicting cached label',
              l10n,
            ),
            labels[drive.code],
          );
        }
        expect(
          referenceDrivetrainLabel('AWD', 'Traction avant', l10n),
          labels['AWD'],
        );
        expect(
          referenceDrivetrainLabel('4WD', 'Intégrale permanente', l10n),
          labels['4WD'],
        );
      },
    );

    test('old label-only snapshots remain readable in $language', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      final labels = _labels(language);
      for (final entry in _legacy.entries) {
        expect(
          referenceDrivetrainLabel(null, entry.key, l10n),
          labels[entry.value],
        );
      }
      expect(
        referenceDrivetrainLabel('', '4x4 débrayable', l10n),
        labels['4WD'],
      );
    });

    test(
      'unknown wheel references keep their exact text in $language',
      () async {
        final l10n = await AppLocalizations.delegate.load(Locale(language));
        expect(
          referenceDrivetrainLabel('custom', 'Traction avant', l10n),
          'Traction avant',
        );
        for (final label in [
          '6x4',
          '4x2',
          'AWD de mon atelier',
          ' Motricité libre ',
        ]) {
          expect(referenceDrivetrainLabel(null, label, l10n), label);
          expect(referenceDrivetrainLabel('custom', label, l10n), label);
        }
      },
    );

    testWidgets(
      'four wheel drive choices preserve reference ids in $language',
      (tester) async {
        final year = TextEditingController();
        final mileage = TextEditingController();
        final model = TextEditingController();
        addTearDown(year.dispose);
        addTearDown(mileage.dispose);
        addTearDown(model.dispose);
        final selection = VehicleClassificationSelection.fromIds(
          _refs,
          drivetrainId: 3,
        );
        final l10n = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) => VehicleIdentityFields(
                    refs: _refs,
                    selection: selection,
                    yearController: year,
                    mileageController: mileage,
                    freeModelController: model,
                    freeModel: false,
                    onFreeModelChanged: (_) {},
                    onChanged: () => setState(() {}),
                    onModelChanged: () {},
                    color: null,
                    onColorChanged: (_) {},
                    transmission: null,
                    onTransmissionChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = find.byType(DropdownButtonFormField<DrivetrainRef>);
        final button = tester.widget<DropdownButton<DrivetrainRef>>(
          find.byType(DropdownButton<DrivetrainRef>),
        );
        expect(button.items!.map((item) => item.value!.id), [1, 2, 3, 4]);
        expect(
          button.items!.map((item) => (item.child as Text).data),
          _labels(language).values,
        );
        expect(selection.toPayload(editing: true)['drivetrain_id'], 3);
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text(_labels(language)['4WD']!).last);
        await tester.pumpAndSettle();
        expect(selection.toPayload(editing: true)['drivetrain_id'], 4);
        final clear = find.widgetWithText(
          TextButton,
          l10n.privateSalesClearDrivetrain,
        );
        await tester.ensureVisible(clear);
        await tester.pumpAndSettle();
        await tester.tap(clear);
        await tester.pumpAndSettle();
        expect(selection.toPayload(editing: true)['drivetrain_id'], isNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'private details prefer an explicit drivetrain code in $language',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (_) => fixture.TestAuth(const AuthState()),
              ),
            ],
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const PrivateListingDetail(
                publicListing: false,
                listing: PrivateListing({
                  'title': 'Toyota',
                  'year': 2020,
                  'mileage_km': 20000,
                  'price': 4500000,
                  'city': 'Ouagadougou',
                  'vehicle_identity': {
                    'drivetrain': 'Traction avant',
                    'drivetrain_code': 'AWD',
                  },
                }),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining(_labels(language)['AWD']!), findsOneWidget);
        expect(find.textContaining('Traction avant'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
