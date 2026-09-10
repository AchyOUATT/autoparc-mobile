// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // `onboardingDone` est devenu obligatoire : le test ne compilait plus.
    await tester.pumpWidget(
      const ProviderScope(child: AutoParcApp(onboardingDone: true)),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  },
      // Monter l'application entiere demarre FirebaseMessaging, qui exige un
      // Firebase.initializeApp() impossible hors appareil. Le rendre executable
      // suppose de simuler les canaux de plateforme — a faire le jour ou l'on
      // testera vraiment des ecrans, pas pour ce test de squelette.
      skip: true);
}
