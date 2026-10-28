import 'package:auto/core/contact/autoparc_contact_provider.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/cart/data/models/cart_item.dart';
import 'package:auto/features/cart/presentation/pages/cart_page.dart';
import 'package:auto/features/cart/presentation/providers/cart_provider.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Contact extends StateNotifier<AutoParcContact>
    implements AutoParcContactNotifier {
  _Contact(super.state);

  void change(String phone) => state = AutoParcContact.parse(phone);

  @override
  Future<bool> refresh() async => true;

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Cart extends CartNotifier {
  @override
  List<CartItem> build() => const [
    CartItem(
      id: 1,
      sku: 'TEST',
      name: 'Article de test',
      unitPriceHt: 1000,
      unitPriceTtc: 1180,
      currency: 'XOF',
      itemType: CartItemType.part,
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final launched = <Uri>[];

  setUp(() {
    launched.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'launch') {
            launched.add(Uri.parse((call.arguments as Map)['url'] as String));
          }
          return true;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget app(
    Widget page,
    _Contact contact, {
    AuthState auth = const AuthState(),
  }) => ProviderScope(
    overrides: [
      autoparcContactProvider.overrideWith((_) => contact),
      authProvider.overrideWith((_) => _Auth(auth)),
      unreadCountProvider.overrideWith((_) async => 0),
      cartProvider.overrideWith(_Cart.new),
      vehicleDetailProvider(41).overrideWith((_) async => _vehicle()),
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    ),
  );

  testWidgets(
    'le menu Contact suit les changements et ouvre le nouveau numéro',
    (tester) async {
      final contact = _Contact(AutoParcContact.parse('+22670123456'));
      await tester.pumpWidget(
        app(
          const Scaffold(drawer: AppDrawer(), body: SizedBox.shrink()),
          contact,
          auth: const AuthState(type: AuthType.client),
        ),
      );
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Nous contacter'),
        180,
        scrollable: find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Nous contacter'));
      await tester.pumpAndSettle();
      expect(find.text('+226 70 12 34 56'), findsNWidgets(2));

      contact.change('+33123456789');
      await tester.pump();
      expect(find.text('+226 70 12 34 56'), findsNothing);
      expect(find.text('+33123456789'), findsNWidgets(2));
      await tester.tap(find.byIcon(Icons.phone_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      expect(launched.map((uri) => uri.toString()), [
        'tel:+33123456789',
        'https://wa.me/33123456789',
      ]);
    },
  );

  testWidgets(
    'les appels et WhatsApp de la fiche véhicule suivent le réglage',
    (tester) async {
      final contact = _Contact(AutoParcContact.parse('+33123456789'));
      await tester.pumpWidget(
        app(
          VehicleDetailPage(vehicleId: 41, initialVehicle: _vehicle()),
          contact,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Appeler'));
      await tester.pumpAndSettle();
      contact.change('+22670123456');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'WhatsApp'));
      await tester.pumpAndSettle();
      expect(launched.map((uri) => uri.toString()), [
        'tel:+33123456789',
        'https://wa.me/22670123456',
      ]);
    },
  );

  testWidgets('le panier envoie sa commande au numéro courant', (tester) async {
    final contact = _Contact(AutoParcContact.parse('+33123456789'));
    await tester.pumpWidget(app(const CartPage(), contact));
    await tester.pumpAndSettle();
    // Changement après le montage : le bouton lit la valeur au moment du clic.
    contact.change('+22670123456');
    await tester.tap(find.text('Commander via WhatsApp'));
    await tester.pumpAndSettle();
    expect(launched, hasLength(1));
    expect(launched.single.host, 'wa.me');
    expect(launched.single.path, '/22670123456');
    expect(
      launched.single.queryParameters['text'],
      contains('Article de test'),
    );

    // ── L'ENCODAGE SUR LE FIL, et pourquoi `queryParameters` ne suffit pas ──
    //
    // `queryParameters` DÉCODE, et le décodeur de Dart rend « + » comme une
    // espace : les trois assertions ci-dessus passent donc que l'URL porte
    // « %20 » ou « + ». C'est exactement ce qui a laissé passer une
    // régression — `replace(queryParameters: …)` encodait les espaces en
    // « + », que wa.me ne garantit pas de relire comme telles. On regarde
    // donc la chaîne BRUTE, celle que WhatsApp reçoit.
    final url = launched.single.toString();
    expect(
      url,
      isNot(contains('+')),
      reason: 'Une espace encodée en « + » arrive littéralement dans le '
          'message : c’est le seul chemin de commande d’un acheteur.',
    );
    expect(url, contains('%20'));
  });

  for (final role in [
    'admin',
    'manager',
    'sales',
    'mechanic',
    'warehouse',
    'viewer',
  ]) {
    testWidgets('entrée des paramètres adaptée au rôle $role', (tester) async {
      await tester.pumpWidget(
        app(
          const Scaffold(drawer: AppDrawer(), body: SizedBox.shrink()),
          _Contact(AutoParcContact.fallback),
          auth: AuthState(
            type: AuthType.staff,
            staffUser: StaffUser(
              id: 1,
              name: 'Équipe',
              email: 'test@example.test',
              role: role,
            ),
          ),
        ),
      );
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      expect(
        find.text('Paramètres · Contact AutoParc'),
        role == 'admin' || role == 'manager' ? findsOneWidget : findsNothing,
      );
    });
  }
}

Vehicle _vehicle() => Vehicle.fromJson({
  'id': 41,
  'reference': 'TEST-41',
  'designation': 'Véhicule de test',
  'vehicle_type': 'passenger',
  'registration_status': {'value': 'registered', 'label': 'Immatriculé'},
  'identity': {'brand': 'Test', 'model': 'Test', 'year': 2023},
  'technical': <String, dynamic>{},
  'commercial': {
    'condition': 'used',
    'status': 'in_stock',
    'availability': 'sale',
    'sale_price': 1000,
  },
  'media': [],
  'features': [],
});
