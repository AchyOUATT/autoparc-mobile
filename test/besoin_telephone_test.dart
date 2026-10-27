import 'package:auto/core/api/api_client.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/needs/data/needs_repository.dart';
import 'package:auto/features/needs/presentation/pages/submit_need_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sans numéro, personne ne peut rappeler.
///
/// ── LE DEFAUT QUE CE BANC FERME ────────────────────────────────────────────
///
/// Ce formulaire n'envoyait AUCUN contact : sa charge se limitait au type, à la
/// description, au budget et au `firebase_uid` quand il y en avait un. Et
/// `POST /api/needs` est une route PUBLIQUE, donc le déposant peut être
/// anonyme.
///
/// Côté serveur le trou était symétrique, et pire : `customer_needs` portait
/// déjà `contact_phone`, `contact_name` et `contact_email`, tous trois dans
/// `$fillable`, lus par le modèle Flutter et affichés au personnel — mais
/// `StoreCustomerNeedRequest` n'en validait aucun, donc un numéro envoyé aurait
/// été jeté en silence par `create($request->validated())`.
///
/// Résultat mesuré : un visiteur déposait un besoin, tout le personnel recevait
/// « Nouveau besoin client », et personne ne pouvait le rappeler.
/// La page exige une connexion : son garde est `!auth.isAuthenticated`, donc
/// personnel OU client. Sans cette surcharge elle ne rend que « Connexion
/// requise » et le formulaire n'existe pas dans l'arbre.
///
/// On se place en PERSONNEL a dessein : c'est le chemin ou aucun contact ne
/// partait. Un client envoie au moins son `firebase_uid`, qui laisse une piste ;
/// un membre du personnel qui depose pour quelqu'un au comptoir n'envoyait
/// rien du tout.
class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(const AuthState(
          type: AuthType.staff,
          staffUser: StaffUser(
            id: 1,
            name: 'Responsable',
            email: 'staff@example.test',
            role: 'manager',
          ),
        ));

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Depot extends NeedsRepository {
  // `NeedsRepository` prend un `ApiClient` : on lui en passe un vrai, dont
  // aucune methode ne sera appelee puisque `submitNeed` est surcharge.
  _Depot() : super(ApiClient());

  Map<String, dynamic>? envoye;

  @override
  Future<void> submitNeed(Map<String, dynamic> payload) async {
    envoye = payload;
  }
}

void main() {
  late _Depot depot;

  setUp(() => depot = _Depot());

  /// On pompe par DUREE et non par `pumpAndSettle`.
  ///
  /// La page charge ses referentiels — marques, categories, fabricants — par
  /// des `FutureProvider` qui appellent le reseau. En banc ils restent en
  /// attente, donc leurs indicateurs de chargement tournent indefiniment et
  /// `pumpAndSettle` ne rend jamais la main : il expire. Rien de ce que ce banc
  /// mesure ne depend de ces listes.
  Future<void> ouvrir(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        needsRepositoryProvider.overrideWithValue(depot),
        authProvider.overrideWith((_) => _Auth()),
      ],
      child: const MaterialApp(home: SubmitNeedPage()),
    ));
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// La page vit dans un `ListView`, donc la construction est PARESSEUSE : un
  /// widget sous la ligne de flottaison n'existe pas encore dans l'arbre, et
  /// `find` ne le voit pas. `scrollUntilVisible` fait defiler jusqu'a ce que le
  /// localisateur morde — c'est pour cela qu'on passe par la, et non par
  /// `ensureVisible`, qui exige que le widget existe deja.
  ///
  /// Les champs sont vises par CLE et non par texte ni par index : viser par
  /// index rendait les bancs du formulaire partenaire faux des qu'un champ
  /// etait ajoute en amont, en silence.
  Future<Finder> atteindre(WidgetTester tester, Finder cible) async {
    // `scrollUntilVisible` appelle `.single` sur `find.byType(Scrollable)` :
    // la page en contient plusieurs, donc on designe le sien — le premier de
    // l arbre, celui du `ListView` qui porte le formulaire.
    await tester.scrollUntilVisible(
      cible,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 200));

    return cible;
  }

  Future<void> remplirLeStrictMinimum(WidgetTester tester) async {
    final champ = await atteindre(tester, find.byKey(const Key('besoin-description')));
    await tester.enterText(champ, 'Cherche une berline diesel, boîte automatique.');
    await tester.pump();
  }

  Future<void> saisirNumero(WidgetTester tester, int index, String valeur) async {
    final champ = await atteindre(tester, find.byKey(ValueKey('besoin-telephone-$index')));
    await tester.enterText(champ, valeur);
    await tester.pump();
  }

  Future<void> ajouterUnNumero(WidgetTester tester) async {
    final bouton = await atteindre(
      tester,
      find.byKey(const Key('besoin-ajouter-telephone')),
    );
    await tester.tap(bouton);
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> envoyer(WidgetTester tester) async {
    final bouton = await atteindre(tester, find.byKey(const Key('besoin-soumettre')));
    await tester.tap(bouton);
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// LE BANC QUI COMPTE LE PLUS : rien ne part sans numéro.
  testWidgets('sans numéro, le besoin ne part pas', (tester) async {
    await ouvrir(tester);
    await remplirLeStrictMinimum(tester);
    await envoyer(tester);

    expect(depot.envoye, isNull,
        reason: 'Un besoin est parti sans numéro : le personnel sera notifié '
            'et ne pourra pas rappeler.');
    expect(find.text('Indiquez un numéro.'), findsOneWidget);
  });

  testWidgets('un numéro suffit, et part dans contact_phones', (tester) async {
    await ouvrir(tester);
    await remplirLeStrictMinimum(tester);
    await saisirNumero(tester, 0, '+22670000001');
    await envoyer(tester);

    expect(depot.envoye, isNotNull);
    expect(depot.envoye!['contact_phones'], ['+22670000001']);
  });

  testWidgets('un numéro trop court est refusé', (tester) async {
    await ouvrir(tester);
    await remplirLeStrictMinimum(tester);
    await saisirNumero(tester, 0, '12345');
    await envoyer(tester);

    expect(depot.envoye, isNull);
    expect(find.text('Numéro trop court.'), findsOneWidget);
  });

  testWidgets('on peut en ajouter un second, et les deux partent', (tester) async {
    await ouvrir(tester);
    await remplirLeStrictMinimum(tester);
    await saisirNumero(tester, 0, '+22670000001');

    await ajouterUnNumero(tester);

    await saisirNumero(tester, 1, '+22675000002');
    await envoyer(tester);

    expect(depot.envoye!['contact_phones'], ['+22670000001', '+22675000002']);
  });

  /// Un champ ajouté puis laissé blanc ne doit pas partir comme un numéro : le
  /// serveur refuse les chaînes vides, et un besoin perdu pour un champ oublié
  /// serait un acheteur perdu.
  testWidgets('un champ ajouté puis laissé vide ne part pas', (tester) async {
    await ouvrir(tester);
    await remplirLeStrictMinimum(tester);
    await saisirNumero(tester, 0, '+22670000001');

    await ajouterUnNumero(tester);

    await envoyer(tester);

    expect(depot.envoye!['contact_phones'], ['+22670000001'],
        reason: 'Le champ vide est parti comme un numéro.');
  });

  /// Le serveur en accepte trois au plus : le bouton doit disparaître avant,
  /// plutôt que de laisser composer une charge que le serveur refusera.
  testWidgets('le bouton d’ajout disparaît au troisième numéro', (tester) async {
    await ouvrir(tester);

    for (var pose = 0; pose < 2; pose++) {
      await ajouterUnNumero(tester);
    }

    expect(find.byKey(const Key('besoin-ajouter-telephone')), findsNothing,
        reason: 'Le serveur en accepte trois au plus : le bouton doit '
            'disparaitre avant qu on puisse composer une charge refusee.');
  });

  testWidgets('un numéro ajouté peut être retiré', (tester) async {
    await ouvrir(tester);
    await remplirLeStrictMinimum(tester);
    await saisirNumero(tester, 0, '+22670000001');

    await ajouterUnNumero(tester);
    await saisirNumero(tester, 1, '+22675000002');

    final retirer = await atteindre(tester, find.byIcon(Icons.remove_circle_outline));
    await tester.tap(retirer);
    await tester.pump(const Duration(milliseconds: 200));

    await envoyer(tester);

    expect(depot.envoye!['contact_phones'], ['+22670000001']);
  });
}
