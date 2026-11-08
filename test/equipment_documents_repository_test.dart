import 'dart:convert';
import 'dart:typed_data';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as partner;
import 'package:auto/features/vehicles/data/equipment_documents_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _PartnerTokens extends partner.PartnerTokenStore {
  @override
  Future<partner.PartnerSessionStockee?> readSession() async =>
      const partner.PartnerSessionStockee(token: 'partner-document-token');

  @override
  Future<void> writeSession(
    String token, [
    Map<String, dynamic>? profile,
  ]) async {}

  @override
  Future<void> clear() async {}
}

class _DocumentAdapter implements HttpClientAdapter {
  _DocumentAdapter(this.reply);

  final ResponseBody Function(RequestOptions) reply;
  final requests = <RequestOptions>[];
  final requestBodies = <List<int>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    requestBodies.add(bytes);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(dynamic data, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, dynamic> _documentJson({String? expiry}) => {
  'id': 42,
  'document_type': 'insurance',
  'original_name': 'assurance.pdf',
  'mime_type': 'application/pdf',
  'size': 19,
  'expires_on': expiry,
  'status': 'provided',
  'uploaded_at': '2026-11-08T09:15:00Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'sanctum_token': 'staff-document-token',
    });
  });

  for (final mode in VehicleFormMode.values) {
    group(mode.name, () {
      late _DocumentAdapter staffAdapter;
      late _DocumentAdapter partnerAdapter;
      late EquipmentDocumentsRepository repository;

      _DocumentAdapter getAdapter() =>
          mode.estPartenaire ? partnerAdapter : staffAdapter;

      String getPath() =>
          '${mode.estPartenaire ? '/partner' : ''}/vehicles/71/equipment-documents';

      void arrange(ResponseBody Function(RequestOptions) reply) {
        staffAdapter = _DocumentAdapter(reply);
        partnerAdapter = _DocumentAdapter(reply);
        final partnerDio = Dio(
          BaseOptions(baseUrl: 'https://api.example.test/api'),
        )..httpClientAdapter = partnerAdapter;
        repository = EquipmentDocumentsRepository(
          ApiClient(httpClientAdapter: staffAdapter),
          partner.PartnerRepository(
            dio: partnerDio,
            tokenStore: _PartnerTokens(),
          ),
        );
      }

      void expectPrivateSession(RequestOptions request) {
        expect(
          request.headers['Authorization'],
          mode.estPartenaire
              ? 'Bearer partner-document-token'
              : 'Bearer staff-document-token',
        );
        expect(
          mode.estPartenaire ? staffAdapter.requests : partnerAdapter.requests,
          isEmpty,
          reason: 'The other account session must not receive this request.',
        );
      }

      test('an empty document list keeps documents optional', () async {
        arrange((_) => _json({'data': []}));

        expect(await repository.documents(71, mode: mode), isEmpty);

        final request = getAdapter().requests.single;
        expect(request.method, 'GET');
        expect(request.path, getPath());
        expectPrivateSession(request);
      });

      test('private metadata is parsed as provided, never verified', () async {
        arrange(
          (_) => _json({
            'data': [_documentJson(expiry: '2027-01-31')],
          }),
        );

        final documents = await repository.documents(71, mode: mode);

        expect(documents, hasLength(1));
        final document = documents.single;
        expect(document.id, 42);
        expect(document.type, EquipmentDocumentType.insurance);
        expect(document.originalName, 'assurance.pdf');
        expect(document.mimeType, 'application/pdf');
        expect(document.size, 19);
        expect(document.status, 'provided');
        expect(document.expiresOn, '2027-01-31');
        expect(document.uploadedAt, DateTime.utc(2026, 11, 8, 9, 15));
        expectPrivateSession(getAdapter().requests.single);
      });

      test('upload sends only document, type and optional expiry', () async {
        arrange(
          (_) => _json({'data': _documentJson(expiry: '2027-01-31')}, 201),
        );
        final pdfBytes = utf8.encode('%PDF-1.7\nassurance');

        final document = await repository.upload(
          71,
          mode: mode,
          filename: 'assurance.pdf',
          bytes: pdfBytes,
          type: EquipmentDocumentType.insurance,
          expiresOn: '2027-01-31',
        );

        expect(document.id, 42);
        final adapter = getAdapter();
        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.path, getPath());
        final form = request.data as FormData;
        expect(Map.fromEntries(form.fields), {
          'document_type': 'insurance',
          'expires_on': '2027-01-31',
        });
        expect(form.files, hasLength(1));
        expect(form.files.single.key, 'document');
        expect(form.files.single.value.filename, 'assurance.pdf');
        expect(form.files.single.value.length, pdfBytes.length);
        expect(
          utf8.decode(adapter.requestBodies.single),
          contains('%PDF-1.7\nassurance'),
        );
        expectPrivateSession(request);
      });

      test('upload omits an expiry which was not supplied', () async {
        arrange((_) => _json({'data': _documentJson()}, 201));

        final document = await repository.upload(
          71,
          mode: mode,
          filename: 'titre.pdf',
          bytes: [37, 80, 68, 70],
          type: EquipmentDocumentType.ownership,
        );

        expect(document.expiresOn, isNull);
        final request = getAdapter().requests.single;
        expect(Map.fromEntries((request.data as FormData).fields), {
          'document_type': 'ownership',
        });
        expectPrivateSession(request);
      });

      test(
        'download fetches authenticated bytes from the private endpoint',
        () async {
          final expectedBytes = [37, 80, 68, 70, 0, 255];
          arrange(
            (_) => ResponseBody.fromBytes(
              expectedBytes,
              200,
              headers: {
                Headers.contentTypeHeader: ['application/pdf'],
              },
            ),
          );

          expect(await repository.download(71, 42, mode: mode), expectedBytes);

          final request = getAdapter().requests.single;
          expect(request.method, 'GET');
          expect(request.path, '${getPath()}/42/download');
          expect(request.responseType, ResponseType.bytes);
          expectPrivateSession(request);
        },
      );

      test('delete targets the private document under the vehicle', () async {
        arrange((_) => _json({'message': 'Deleted'}));

        await repository.delete(71, 42, mode: mode);

        final request = getAdapter().requests.single;
        expect(request.method, 'DELETE');
        expect(request.path, '${getPath()}/42');
        expectPrivateSession(request);
      });

      test(
        'download preserves account rejection from an error JSON body',
        () async {
          arrange(
            (_) => _json({
              'message': 'Compte désactivé.',
              'code': 'account_disabled',
            }, 403),
          );
          await expectLater(
            repository.download(71, 42, mode: mode),
            throwsA(
              mode.estPartenaire
                  ? isA<partner.PartnerApiException>()
                        .having(
                          (e) => e.sessionRejected,
                          'session rejected',
                          isTrue,
                        )
                        .having(
                          (e) => e.message,
                          'message',
                          'Compte désactivé.',
                        )
                  : isA<ApiException>()
                        .having(
                          (e) => e.sessionRejected,
                          'session rejected',
                          isTrue,
                        )
                        .having(
                          (e) => e.message,
                          'message',
                          'Compte désactivé.',
                        ),
            ),
          );
        },
      );

      test(
        'download preserves storage-unavailable errors without rejecting session',
        () async {
          arrange(
            (_) => _json({
              'message': 'Stockage temporairement indisponible.',
            }, 503),
          );
          await expectLater(
            repository.download(71, 42, mode: mode),
            throwsA(
              mode.estPartenaire
                  ? isA<partner.PartnerApiException>()
                        .having(
                          (e) => e.sessionRejected,
                          'session rejected',
                          isFalse,
                        )
                        .having((e) => e.statusCode, 'status', 503)
                        .having(
                          (e) => e.message,
                          'message',
                          'Stockage temporairement indisponible.',
                        )
                  : isA<ApiException>()
                        .having(
                          (e) => e.sessionRejected,
                          'session rejected',
                          isFalse,
                        )
                        .having((e) => e.statusCode, 'status', 503)
                        .having(
                          (e) => e.message,
                          'message',
                          'Stockage temporairement indisponible.',
                        ),
            ),
          );
        },
      );
    });
  }

  test('an expiry date stays current throughout that day', () {
    final document = EquipmentDocument.fromJson(
      _documentJson(expiry: '2026-11-08'),
    );
    expect(document.isExpired(DateTime(2026, 11, 7, 23, 59)), isFalse);
    expect(document.isExpired(DateTime(2026, 11, 8, 23, 59)), isFalse);
    expect(document.isExpired(DateTime(2026, 11, 9)), isTrue);
    expect(EquipmentDocument.fromJson(_documentJson()).isExpired(), isFalse);
  });
}
