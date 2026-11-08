import 'dart:async';
import 'dart:typed_data';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as partner;
import 'package:auto/features/vehicles/data/equipment_documents_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/equipment_documents_page.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/l10n/app_localizations_en.dart';
import 'package:auto/l10n/app_localizations_fr.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';

EquipmentDocument _document({String? expiry = '2000-01-01'}) =>
    EquipmentDocument(
      id: 42,
      type: EquipmentDocumentType.insurance,
      originalName: 'assurance.pdf',
      mimeType: 'application/pdf',
      size: 4,
      status: 'provided',
      expiresOn: expiry,
      uploadedAt: DateTime.utc(2026, 11, 8),
    );

class _Repository extends EquipmentDocumentsRepository {
  _Repository({this.items = const []})
    : super(ApiClient(), partner.PartnerRepository());
  List<EquipmentDocument> items;
  final calls = <(String, int, VehicleFormMode)>[];
  int? deletedId;
  int? downloadedId;
  Map<String, dynamic>? uploaded;
  Object? listError;
  Object? uploadError;
  Completer<EquipmentDocument>? uploadPending;
  Completer<void>? deletePending;
  Completer<List<int>>? downloadPending;

  @override
  Future<List<EquipmentDocument>> documents(
    int vehicleId, {
    required VehicleFormMode mode,
  }) async {
    calls.add(('list', vehicleId, mode));
    if (listError != null) throw listError!;
    return items;
  }

  @override
  Future<EquipmentDocument> upload(
    int vehicleId, {
    required VehicleFormMode mode,
    required String filename,
    required List<int> bytes,
    required EquipmentDocumentType type,
    String? expiresOn,
  }) async {
    calls.add(('upload', vehicleId, mode));
    uploaded = {
      'filename': filename,
      'bytes': bytes,
      'type': type,
      'expiresOn': expiresOn,
    };
    if (uploadError != null) throw uploadError!;
    return uploadPending == null
        ? _document(expiry: expiresOn)
        : uploadPending!.future;
  }

  @override
  Future<List<int>> download(
    int vehicleId,
    int documentId, {
    required VehicleFormMode mode,
  }) async {
    calls.add(('download', vehicleId, mode));
    downloadedId = documentId;
    return downloadPending == null ? [37, 80, 68, 70] : downloadPending!.future;
  }

  @override
  Future<void> delete(
    int vehicleId,
    int documentId, {
    required VehicleFormMode mode,
  }) async {
    calls.add(('delete', vehicleId, mode));
    deletedId = documentId;
    if (deletePending != null) await deletePending!.future;
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _mount(
  WidgetTester tester,
  _Repository repository, {
  VehicleFormMode mode = VehicleFormMode.personnel,
  String language = 'fr',
  double scale = 1,
  EquipmentDocumentPicker? picker,
  EquipmentDocumentExporter? exporter,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        equipmentDocumentsRepositoryProvider.overrideWithValue(repository),
        if (picker != null)
          equipmentDocumentPickerProvider.overrideWithValue(picker),
        if (exporter != null)
          equipmentDocumentExporterProvider.overrideWithValue(exporter),
      ],
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: EquipmentDocumentsPage(vehicleId: 71, mode: mode),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.ensureVisible(_key('equipment-document-add'));
  await tester.tap(_key('equipment-document-add'));
  await tester.pumpAndSettle();
}

Future<void> _pick(WidgetTester tester) async {
  await tester.ensureVisible(_key('equipment-document-select'));
  await tester.tap(_key('equipment-document-select'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(chargerPolices);

  test(
    'oversized metadata is rejected before subscribing to the file stream',
    () async {
      var subscribed = false;
      final stream = Stream<List<int>>.multi((controller) {
        subscribed = true;
        controller.add([1]);
        controller.close();
      });
      await expectLater(
        readEquipmentDocument(
          PlatformFile(
            name: 'large.pdf',
            size: equipmentDocumentMaxBytes + 1,
            readStream: stream,
          ),
        ),
        throwsA(isA<EquipmentDocumentTooLarge>()),
      );
      expect(subscribed, isFalse);
    },
  );

  test('an understated file stops at the first chunk beyond 8 MiB', () async {
    var readThirdChunk = false;
    Stream<List<int>> chunks() async* {
      yield Uint8List(equipmentDocumentMaxBytes);
      yield [1];
      readThirdChunk = true;
      yield [2];
    }

    await expectLater(
      readEquipmentDocument(
        PlatformFile(name: 'large.pdf', size: 1, readStream: chunks()),
      ),
      throwsA(isA<EquipmentDocumentTooLarge>()),
    );
    expect(readThirdChunk, isFalse);
  });

  test('bounded stream and existing bytes are both supported', () async {
    final streamed = await readEquipmentDocument(
      PlatformFile(
        name: 'file.pdf',
        size: 4,
        readStream: Stream.fromIterable([
          [37, 80],
          [68, 70],
        ]),
      ),
    );
    expect(streamed, [37, 80, 68, 70]);
    final existing = Uint8List.fromList([1, 2]);
    expect(
      await readEquipmentDocument(
        PlatformFile(name: 'file.png', size: 2, bytes: existing),
      ),
      [1, 2],
    );
  });

  for (final mode in VehicleFormMode.values) {
    testWidgets('empty documents remain optional for ${mode.name}', (
      tester,
    ) async {
      final repository = _Repository();
      await _mount(tester, repository, mode: mode);
      expect(
        find.text(AppLocalizationsFr().equipmentDocumentEmpty),
        findsOneWidget,
      );
      expect(
        find.text(AppLocalizationsFr().equipmentDocumentsPrivateHint),
        findsOneWidget,
      );
      expect(repository.calls, [('list', 71, mode)]);
      await _open(tester);
      expect(
        tester.widget<FilledButton>(_key('equipment-document-save')).onPressed,
        isNull,
      );
      await tester.tap(find.text(AppLocalizationsFr().commonCancel));
      await tester.pumpAndSettle();
      expect(repository.uploaded, isNull);
    });
  }

  testWidgets(
    'expiry validation allows future dates and save disables during upload',
    (tester) async {
      final repository = _Repository()
        ..uploadPending = Completer<EquipmentDocument>();
      await _mount(
        tester,
        repository,
        mode: VehicleFormMode.partenaire,
        picker: () async => PlatformFile(
          name: 'assurance.pdf',
          size: 4,
          readStream: Stream.value([37, 80, 68, 70]),
        ),
      );
      await _open(tester);
      await _pick(tester);
      tester
          .widget<DropdownButtonFormField<EquipmentDocumentType>>(
            _key('equipment-document-type'),
          )
          .onChanged!(EquipmentDocumentType.insurance);
      await tester.enterText(_key('equipment-document-expiry'), '2027-02-30');
      await tester.tap(_key('equipment-document-save'));
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizationsFr().equipmentDocumentDateInvalid),
        findsOneWidget,
      );
      expect(repository.uploaded, isNull);
      await tester.enterText(_key('equipment-document-expiry'), '2099-12-31');
      await tester.tap(_key('equipment-document-save'));
      await tester.pump();
      expect(repository.uploaded, {
        'filename': 'assurance.pdf',
        'bytes': [37, 80, 68, 70],
        'type': EquipmentDocumentType.insurance,
        'expiresOn': '2099-12-31',
      });
      expect(repository.calls.last, ('upload', 71, VehicleFormMode.partenaire));
      expect(
        tester.widget<FilledButton>(_key('equipment-document-save')).onPressed,
        isNull,
      );
      expect(
        tester.widget<TextFormField>(_key('equipment-document-expiry')).enabled,
        isFalse,
      );
      repository.uploadPending!.complete(_document(expiry: '2099-12-31'));
      await tester.pumpAndSettle();
      expect(_key('equipment-document-42'), findsOneWidget);
      expect(
        find.text(AppLocalizationsFr().equipmentDocumentSaved),
        findsOneWidget,
      );
    },
  );

  testWidgets('a failed upload retries the same single-subscription file', (
    tester,
  ) async {
    final repository = _Repository()
      ..uploadError = const ApiException(
        message: 'Temporary failure',
        statusCode: 500,
      );
    var picked = 0;
    await _mount(
      tester,
      repository,
      picker: () async {
        picked++;
        return PlatformFile(
          name: 'assurance.pdf',
          size: 4,
          readStream: Stream.value([37, 80, 68, 70]),
        );
      },
    );
    await _open(tester);
    await _pick(tester);
    await tester.tap(_key('equipment-document-save'));
    await tester.pumpAndSettle();
    expect(_key('equipment-document-save'), findsOneWidget);
    repository.uploadError = null;
    await tester.tap(_key('equipment-document-save'));
    await tester.pumpAndSettle();
    expect(_key('equipment-document-42'), findsOneWidget);
    expect(repository.calls.where((call) => call.$1 == 'upload'), hasLength(2));
    expect(picked, 1);
  });

  testWidgets('an invalid new selection clears the previous valid file', (
    tester,
  ) async {
    var picked = 0;
    final repository = _Repository();
    await _mount(
      tester,
      repository,
      picker: () async => ++picked == 1
          ? PlatformFile(name: 'assurance.pdf', size: 4, bytes: Uint8List(4))
          : PlatformFile(name: 'unsupported.exe', size: 4, bytes: Uint8List(4)),
    );
    await _open(tester);
    await _pick(tester);
    expect(
      tester.widget<FilledButton>(_key('equipment-document-save')).onPressed,
      isNotNull,
    );
    await _pick(tester);
    expect(find.text('assurance.pdf'), findsNothing);
    expect(
      tester.widget<FilledButton>(_key('equipment-document-save')).onPressed,
      isNull,
    );
    expect(repository.uploaded, isNull);
  });

  testWidgets('oversized selection never reads or uploads bytes', (
    tester,
  ) async {
    var subscribed = false;
    final repository = _Repository();
    await _mount(
      tester,
      repository,
      picker: () async => PlatformFile(
        name: 'large.pdf',
        size: equipmentDocumentMaxBytes + 1,
        readStream: Stream<List<int>>.multi((controller) {
          subscribed = true;
          controller.close();
        }),
      ),
    );
    await _open(tester);
    await _pick(tester);
    expect(
      find.text(AppLocalizationsFr().equipmentDocumentTooLarge),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(_key('equipment-document-save')).onPressed,
      isNull,
    );
    expect(subscribed, isFalse);
    expect(repository.uploaded, isNull);
  });

  testWidgets(
    'export shares authenticated downloaded bytes with the original filename',
    (tester) async {
      final repository = _Repository(items: [_document()])
        ..downloadPending = Completer<List<int>>();
      Map<String, dynamic>? exported;
      await _mount(
        tester,
        repository,
        exporter:
            ({
              required bytes,
              required filename,
              required mimeType,
              required origin,
            }) async {
              exported = {
                'bytes': bytes,
                'filename': filename,
                'mimeType': mimeType,
              };
              expect(origin.width, greaterThan(0));
            },
      );
      await tester.tap(_key('equipment-document-export-42'));
      await tester.pump();
      expect(repository.downloadedId, 42);
      expect(exported, isNull);
      expect(
        tester
            .widget<IconButton>(_key('equipment-document-delete-42'))
            .onPressed,
        isNull,
      );
      repository.downloadPending!.complete([37, 80, 68, 70]);
      await tester.pumpAndSettle();
      expect(exported, {
        'bytes': [37, 80, 68, 70],
        'filename': 'assurance.pdf',
        'mimeType': 'application/pdf',
      });
    },
  );

  testWidgets(
    'delete requires confirmation and removes the provided document',
    (tester) async {
      final repository = _Repository(items: [_document()])
        ..deletePending = Completer<void>();
      final l10n = AppLocalizationsFr();
      await _mount(tester, repository);
      expect(find.text(l10n.equipmentDocumentProvided), findsOneWidget);
      expect(find.text(l10n.equipmentDocumentExpired), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsNothing);
      await tester.tap(_key('equipment-document-delete-42'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.equipmentDocumentDeleteConfirm), findsOneWidget);
      expect(repository.deletedId, isNull);
      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();
      expect(repository.deletedId, isNull);
      await tester.tap(_key('equipment-document-delete-42'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.equipmentDocumentDelete),
      );
      await tester.pump();
      expect(repository.deletedId, 42);
      expect(
        tester
            .widget<IconButton>(_key('equipment-document-delete-42'))
            .onPressed,
        isNull,
      );
      repository.deletePending!.complete();
      await tester.pumpAndSettle();
      expect(_key('equipment-document-42'), findsNothing);
      expect(find.text(l10n.equipmentDocumentEmpty), findsOneWidget);
    },
  );

  testWidgets('failed private list can be retried', (tester) async {
    final repository = _Repository()
      ..listError = const ApiException(message: 'Unavailable', statusCode: 500);
    await _mount(tester, repository);
    expect(_key('equipment-document-add'), findsNothing);
    repository.listError = null;
    await tester.tap(find.text(AppLocalizationsFr().commonRetry));
    await tester.pumpAndSettle();
    expect(
      find.text(AppLocalizationsFr().equipmentDocumentEmpty),
      findsOneWidget,
    );
  });

  for (final language in ['fr', 'en']) {
    testWidgets(
      'documents and upload dialog fit 320px at text scale 2 in $language',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _mount(
          tester,
          _Repository(items: [_document()]),
          language: language,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        await _open(tester);
        final l10n = language == 'fr'
            ? AppLocalizationsFr()
            : AppLocalizationsEn();
        expect(find.text(l10n.equipmentDocumentFormats), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
