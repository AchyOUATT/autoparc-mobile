import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// La ligne « session à confirmer », dans le vrai tiroir.
///
/// ── POURQUOI ELLE EXISTE ───────────────────────────────────────────────────
///
/// Le démarrage est désormais optimiste : l'application s'ouvre sur ce que le
/// coffre contient, sans attendre le réseau, et une vérification confirme
/// ensuite. Pendant ce court intervalle l'état affiché est une HYPOTHESE — et
/// si le coffre vient d'une version antérieure il ne porte pas de profil, donc
/// pas de rôle, donc aucune tuile du personnel.
///
/// Sans cette ligne, l'employé conclut qu'il a perdu ses droits. C'est le seul
/// endroit de l'interface qui lui dit que l'application est encore en train de
/// se renseigner.
///
/// Elle REMPLACE la ligne du rôle : en seconde ligne, l'en-tête débordait de 2
/// pixels dès un grossissement de texte x1.5 — le dernier banc de ce fichier
/// l'a mesuré, et c'est lui qui a décidé de la forme.
class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

void main() {
  const employe = StaffUser(
    id: 1,
    name: 'Awa Traoré',
    email: 'awa@autoparc.bf',
    role: 'admin',
  );

  Future<void> poserTiroir(WidgetTester tester, AuthState session) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authProvider.overrideWith((_) => _Auth(session))],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(drawer: AppDrawer(), body: SizedBox.shrink()),
      ),
    ));

    // Le tiroir est ouvert par le geste, comme dans l'application.
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('une session non confirmée le dit à la place du rôle', (tester) async {
    await poserTiroir(
      tester,
      const AuthState(
        type: AuthType.staff,
        staffUser: employe,
        verified: false,
      ),
    );

    expect(find.text('Awa Traoré'), findsOneWidget,
        reason: 'Le nom reste : il vient du coffre et ne dépend pas de la '
            'vérification.');
    expect(find.text('Session à confirmer…'), findsOneWidget);
    expect(find.text('Personnel — admin'), findsNothing,
        reason: 'Le rôle lu au coffre est une hypothèse tant que rien ne l’a '
            'confirmé ; on annonce l’attente plutôt que lui.');
  });

  testWidgets('une session confirmée n’affiche aucun indicateur', (tester) async {
    await poserTiroir(
      tester,
      const AuthState(type: AuthType.staff, staffUser: employe),
    );

    expect(find.text('Personnel — admin'), findsOneWidget);
    expect(find.text('Session à confirmer…'), findsNothing);
  });

  /// Une session d'avant cette version n'a pas de profil au coffre. Le rôle est
  /// alors vide — et c'est précisément le cas où l'employé a besoin d'une
  /// explication, puisqu'il ne verra aucune tuile.
  testWidgets('sans profil au coffre, l’indicateur est là quand même', (
    tester,
  ) async {
    await poserTiroir(
      tester,
      const AuthState(type: AuthType.staff, verified: false),
    );

    expect(find.text('Session à confirmer…'), findsOneWidget);
  });

  testWidgets('un visiteur ne voit rien de tout cela', (tester) async {
    await poserTiroir(tester, const AuthState());

    expect(find.text('Non connecté'), findsOneWidget);
    expect(find.text('Session à confirmer…'), findsNothing);
  });

  /// `sessionAConfirmer` vaut `isStaff && !verified`, et ce banc épingle le
  /// PREMIER terme. Sans lui, un visiteur ou un client dont l'état porterait
  /// `verified: false` verrait « Session à confirmer… » — alors qu'il n'a
  /// aucune session du personnel à confirmer. Rien ne construit cet état
  /// aujourd'hui ; c'est précisément pour que demain non plus.
  testWidgets('un visiteur non vérifié ne voit rien non plus', (tester) async {
    await poserTiroir(tester, const AuthState(verified: false));

    expect(find.text('Session à confirmer…'), findsNothing);
    expect(find.text('Non connecté'), findsOneWidget);
  });

  /// LE BANC DE DEBORDEMENT.
  ///
  /// L'en-tête du tiroir est contraint en hauteur. Ajouter une ligne sous le
  /// rôle est exactement le genre de modification qui déborde au grossissement
  /// de texte, et le dépôt éprouve l'application jusqu'à x2.0 ailleurs.
  testWidgets('rien ne déborde, du texte normal à x2.0', (tester) async {
    for (final echelle in [1.0, 1.3, 1.5, 2.0]) {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider.overrideWith((_) => _Auth(const AuthState(
                type: AuthType.staff,
                staffUser: employe,
                verified: false,
              ))),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: child!,
          ),
          home: const Scaffold(drawer: AppDrawer(), body: SizedBox.shrink()),
        ),
      ));

      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'Débordement de l’en-tête du tiroir à l’échelle $echelle.');
      expect(find.text('Session à confirmer…'), findsOneWidget,
          reason: 'La ligne a disparu à l’échelle $echelle.');
    }
  });
}
