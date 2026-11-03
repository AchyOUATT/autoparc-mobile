import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/contact/autoparc_contact_provider.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/features/private_sales/presentation/private_listing_detail.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Contact extends StateNotifier<AutoParcContact>
    implements AutoParcContactNotifier {
  _Contact(super.state);

  void change(String phone) => state = AutoParcContact.parse(phone);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Api extends ApiClient {
  final paths = <String>[];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    paths.add(path);
    return {'data': _listing.fields};
  }
}

// Old payloads or an owner response may still contain personal data. The
// explicit public display mode must never use those fields or their channels.
const _listing = PrivateListing({
  'id': 23,
  'title': 'Toyota Camry 2013',
  'year': 2013,
  'price': 4500000,
  'mileage_km': 85000,
  'city': 'Ouagadougou',
  'currency': 'XOF',
  'description': 'Véhicule entretenu',
  'seller_name': 'PERSONAL-SELLER-NAME',
  'phone': '+22670000023',
  'phone_claimed': '+22670000024',
  'verified_phone': '+22670000023',
  'phone_verified': true,
  'whatsapp_enabled': true,
  'whatsapp': '+22670000025',
  'share_url': 'https://example.invalid/annonces/23',
  'contact_via': 'seller',
  'photos': <Map<String, dynamic>>[],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const launcher = MethodChannel('plugins.flutter.io/url_launcher');
  final launched = <Uri>[];
  String? copied;
  var canOpen = true;

  setUp(() {
    launched.clear();
    copied = null;
    canOpen = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, (call) async {
          if (call.method == 'launch') {
            launched.add(Uri.parse((call.arguments as Map)['url'] as String));
          }
          return canOpen;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> open(
    WidgetTester tester,
    _Contact contact,
    _Api api, {
    Locale locale = const Locale('fr'),
    bool publicListing = true,
  }) async {
    tester.view.physicalSize = const Size(360, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          autoparcContactProvider.overrideWith((_) => contact),
          privateListingRepositoryProvider.overrideWithValue(
            PrivateListingRepository(api),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrivateListingDetail(
            listing: _listing,
            publicListing: publicListing,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in [const Locale('fr'), const Locale('en')]) {
    testWidgets(
      'public legacy payload uses AutoParc in ${locale.languageCode}',
      (tester) async {
        final api = _Api();
        final contact = _Contact(AutoParcContact.parse('+22675570484'));
        final l10n = await AppLocalizations.delegate.load(locale);
        await open(tester, contact, api, locale: locale);

        expect(find.text(_listing.text('seller_name')), findsNothing);
        expect(find.textContaining('+22670000023'), findsNothing);
        expect(find.textContaining('+22670000024'), findsNothing);
        expect(find.textContaining('+22670000025'), findsNothing);
        expect(find.text(l10n.privateSalesPhoneVerified), findsNothing);
        expect(find.text(l10n.privateSalesCallSeller), findsNothing);
        expect(
          find.text(l10n.privateSalesAutoParcContactNotice),
          findsOneWidget,
        );
        expect(api.paths, isEmpty);

        await tester.ensureVisible(find.text(l10n.privateSalesCallAutoParc));
        await tester.tap(find.text(l10n.privateSalesCallAutoParc));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text(l10n.privateSalesWhatsappAutoParc),
        );
        await tester.tap(find.text(l10n.privateSalesWhatsappAutoParc));
        await tester.pumpAndSettle();

        expect(launched.first.toString(), 'tel:+22675570484');
        expect(launched.last.host, 'wa.me');
        expect(launched.last.path, '/22675570484');
        final message = launched.last.queryParameters['text']!;
        expect(message, contains(_listing.title));
        expect(message, contains(_listing.text('share_url')));
        expect(message, isNot(contains(_listing.text('seller_name'))));
        expect(message, isNot(contains('70000023')));
        expect(launched.last.toString(), contains('%20'));
        expect(launched.last.toString(), isNot(contains('+')));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('public buttons follow the back-office contact while open', (
    tester,
  ) async {
    final contact = _Contact(AutoParcContact.parse('+22675570484'));
    final api = _Api();
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await open(tester, contact, api);
    contact.change('+33123456789');
    await tester.pump();
    expect(find.text('+33123456789'), findsOneWidget);
    expect(find.text('+226 75 57 04 84'), findsNothing);

    await tester.ensureVisible(find.text(l10n.privateSalesCallAutoParc));
    await tester.tap(find.text(l10n.privateSalesCallAutoParc));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.privateSalesWhatsappAutoParc));
    await tester.tap(find.text(l10n.privateSalesWhatsappAutoParc));
    await tester.pumpAndSettle();
    expect(launched.first.toString(), 'tel:+33123456789');
    expect(launched.last.host, 'wa.me');
    expect(launched.last.path, '/33123456789');
    expect(api.paths, isEmpty);
  });

  testWidgets('public failed action copies AutoParc contact only', (
    tester,
  ) async {
    canOpen = false;
    final contact = _Contact(AutoParcContact.parse('+33123456789'));
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await open(tester, contact, _Api());
    await tester.ensureVisible(find.text(l10n.privateSalesCallAutoParc));
    await tester.tap(find.text(l10n.privateSalesCallAutoParc));
    await tester.pumpAndSettle();
    expect(copied, '+33123456789');
    expect(find.textContaining(_listing.text('phone')), findsNothing);
  });

  testWidgets('owner detail keeps personal seller channels without a request', (
    tester,
  ) async {
    final api = _Api();
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await open(
      tester,
      _Contact(AutoParcContact.parse('+33123456789')),
      api,
      publicListing: false,
    );
    expect(find.text(_listing.text('seller_name')), findsOneWidget);
    expect(find.text(l10n.privateSalesPhoneVerified), findsOneWidget);
    expect(find.text(l10n.privateSalesAutoParcContactNotice), findsNothing);
    await tester.ensureVisible(find.text(l10n.privateSalesCallSeller));
    await tester.tap(find.text(l10n.privateSalesCallSeller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.privateSalesContactWhatsapp));
    await tester.tap(find.text(l10n.privateSalesContactWhatsapp));
    await tester.pumpAndSettle();
    expect(launched.first.toString(), 'tel:+22670000023');
    expect(launched.last.path, '/22670000023');
    expect(api.paths, isEmpty);
  });
}
