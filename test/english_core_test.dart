import 'dart:typed_data';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/l10n/langue.dart';
import 'package:auto/l10n/app_localizations_en.dart';
import 'package:auto/l10n/app_localizations_fr.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CaptureAdapter implements HttpClientAdapter {
  final languages = <String>[];
  final capabilities = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capabilities.add(options.headers['X-AutoParc-Capabilities']);
    languages.add(
      options.headers.entries
              .firstWhere(
                (entry) => entry.key.toLowerCase() == 'accept-language',
              )
              .value
          as String,
    );
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'HTTP uses the restored language and switches the same client immediately',
    () async {
      final adapter = _CaptureAdapter();
      final container = ProviderContainer(
        overrides: [
          localeInitialeProvider.overrideWithValue(localeAnglais),
          apiHttpClientAdapterProvider.overrideWithValue(adapter),
        ],
      );
      addTearDown(container.dispose);
      final client = container.read(apiClientProvider);
      await client.get('/catalog/language-proof');

      // Start persistence without waiting: the next request must already be French.
      final savingFrench = container
          .read(langueProvider.notifier)
          .definir(localeFrancais);
      await client.get('/catalog/language-proof');
      await savingFrench;
      await container.read(langueProvider.notifier).definir(localeAnglais);
      await client.get('/catalog/language-proof');

      expect(adapter.languages, ['en', 'fr', 'en']);
      expect(adapter.capabilities, List.filled(3, 'nullable-part-type'));
      expect(
        identical(client, container.read(apiClientProvider)),
        isTrue,
        reason:
            'Repositories holding the shared client must receive the new header too.',
      );
    },
  );

  test('an unsupported language is never sent to the bilingual API', () async {
    final adapter = _CaptureAdapter();
    final client = ApiClient(languageCode: 'es', httpClientAdapter: adapter);
    await client.get('/catalog/language-proof');
    client.setLanguage('en');
    await client.get('/catalog/language-proof');
    client.setLanguage('unknown');
    await client.get('/catalog/language-proof');
    expect(adapter.languages, ['fr', 'en', 'fr']);
  });

  test(
    'English API failures retain business codes and diagnostic references',
    () {
      final en = AppLocalizationsEn();
      final forbidden = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(path: '/vehicles'),
          response: Response(
            requestOptions: RequestOptions(path: '/vehicles'),
            statusCode: 403,
            data: {
              'message': 'Votre role ne permet pas cette action.',
              'code': 'permission_denied',
            },
          ),
        ),
      );
      expect(messageFor(forbidden, l10n: en), en.commonErrorPermission);
      expect(forbidden.code, 'permission_denied');
      expect(
        forbidden.sessionRejected,
        isFalse,
        reason: 'Translating a refusal must not turn it into a logout.',
      );

      const server = ApiException(
        statusCode: 500,
        message: 'SQLSTATE private detail',
        requestId: 'REQ-42',
      );
      final visible = messageFor(server, l10n: en);
      expect(visible, en.commonErrorReference(en.commonErrorServer, 'REQ-42'));
      expect(visible, isNot(contains('SQLSTATE')));
    },
  );

  test(
    'network, validation and local failures use English without rewriting user data',
    () {
      final en = AppLocalizationsEn();
      final fr = AppLocalizationsFr();
      const network = ApiException(
        message: 'Connection timed out',
        isNetworkFailure: true,
      );
      expect(messageFor(network, l10n: en), en.commonErrorNetwork);
      expect(messageFor(network, l10n: fr), network.userMessage);
      expect(
        messageFor(StateError('No element'), l10n: en),
        en.commonErrorGeneric,
      );
      expect(
        messageFor(
          const RefusLocal(
            'Trop de tentatives. Réessayez dans quelques minutes.',
          ),
          l10n: en,
        ),
        en.commonErrorThrottled,
      );

      const validation = ApiException(
        statusCode: 422,
        message: 'Invalid input',
        errors: {
          'description': ['Keep the seller’s own wording.'],
        },
      );
      expect(
        messageFor(validation, l10n: en),
        'Keep the seller’s own wording.',
      );
    },
  );
}
