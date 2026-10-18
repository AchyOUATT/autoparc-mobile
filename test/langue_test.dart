import 'package:auto/core/l10n/langue.dart';
import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/langues.dart';

/// LE RÉGLAGE DE LANGUE : ce qu'il change à l'écran, et ce qu'il garde.
///
/// ── LES TROIS CHOSES QUI DOIVENT TENIR ──────────────────────────────────────
///
/// 1. LE FRANÇAIS EST LE DÉFAUT, ET LA LOCALE DU SYSTÈME EST IGNORÉE. C'est la
///    décision contre-intuitive du lot, et celle qu'un relecteur pressé
///    « corrigerait » en retirant `locale:` du `MaterialApp` — ce qui paraît
///    plus poli et ne l'est pas : dans la sous-région, beaucoup d'appareils
///    sortent de boîte en anglais, y compris chez des utilisateurs
///    francophones. Suivre la locale système ferait basculer une partie du parc
///    DÉJÀ INSTALLÉ à la simple mise à jour.
///
///    Et la bascule serait SILENCIEUSE : `AppLocalizations.supportedLocales`
///    commence par `Locale('en')`, parce que `gen-l10n` range les `.arb` par
///    ordre alphabétique, et `basicLocaleListResolution` prend le premier
///    supporté qui corresponde. Un `MaterialApp` sans `locale:` servirait donc
///    l'anglais à tout appareil réglé en anglais. Le test « la locale du
///    système ne décide de rien » est la non-vacuité de cette décision.
///
/// 2. LE CHOIX SURVIT AU REDÉMARRAGE. `SharedPreferences.resetStatic()` est
///    l'outil employé par `premiere_utilisation_test.dart` pour la même
///    question sur l'onboarding : il jette l'instance en mémoire, de sorte que
///    la relecture passe réellement par le disque simulé. Sans cela, un
///    `LangueService` qui ne garderait sa valeur qu'en mémoire passerait au
///    vert.
///
/// 3. LA BASCULE CHANGE CE QUI EST PEINT, et pas seulement l'état du provider.
///    Trois maillons séparent l'un de l'autre : le provider, le `locale:` du
///    `MaterialApp`, et `definirLocaleMontants` pour la ponctuation des
///    montants. Le troisième est un réglage de module, donc le plus facile à
///    oublier ; il est éprouvé ici sur la chaîne rendue.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // La locale des montants est un réglage de module : un test qui la laisse en
  // anglais ferait mentir les suivants, et ceux des autres fichiers si l'ordre
  // d'exécution changeait.
  tearDown(() => definirLocaleMontants(localeFr));

  group('La persistance du choix', () {
    test('une installation neuve est en français', () async {
      expect(
        await LangueService.lire(),
        localeFrancais,
        reason:
            'Le défaut décide de la langue de tout le parc déjà installé. '
            'À l\'anglais, une mise à jour ferait basculer des milliers '
            'd\'écrans que personne n\'a demandé à changer.',
      );
    });

    test('le choix de l\'anglais survit au redémarrage', () async {
      await LangueService.ecrire(localeAnglais);

      // Comme dans premiere_utilisation_test.dart : on jette l'instance en
      // mémoire pour relire par le disque.
      SharedPreferences.resetStatic();

      expect(
        await LangueService.lire(),
        localeAnglais,
        reason:
            'Un client anglophone qui rouvre l\'application la retrouve en '
            'français : le choix n\'a pas été écrit, il n\'était qu\'en '
            'mémoire.',
      );
    });

    test('le retour au français survit aussi', () async {
      await LangueService.ecrire(localeAnglais);
      await LangueService.ecrire(localeFrancais);
      SharedPreferences.resetStatic();

      expect(await LangueService.lire(), localeFrancais);
    });

    test('une valeur inconnue sur le disque retombe sur le français', () async {
      // Une version future pourrait écrire 'es' puis être désinstallée au
      // profit de celle-ci. Le repli doit être le français, pas une exception
      // au démarrage — `lire()` est appelé dans `main()`, avant `runApp`.
      SharedPreferences.setMockInitialValues({'langue': 'es'});

      expect(await LangueService.lire(), localeFrancais);
    });

    test('le notifier écrit ce qu\'il annonce', () async {
      final conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);

      await conteneur.read(langueProvider.notifier).definir(localeAnglais);

      expect(conteneur.read(langueProvider), localeAnglais);
      SharedPreferences.resetStatic();
      expect(await LangueService.lire(), localeAnglais);
    });
  });

  group('La locale du système ne décide de rien', () {
    testWidgets('un appareil réglé en anglais reste en français', (
      tester,
    ) async {
      // L'appareil dit « en-US », et rien n'a été choisi dans l'application.
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const _CoqueLangue());
      await tester.pump();

      expect(
        find.text('Accueil'),
        findsOneWidget,
        reason:
            'L\'application suit la locale du système : un propriétaire '
            'francophone dont le téléphone est sorti de boîte en anglais '
            'trouve son application en anglais après une simple mise à jour. '
            'Voir lib/core/l10n/langue.dart.',
      );
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('et un appareil réglé en français reste en français', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('fr', 'BF')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const _CoqueLangue());
      await tester.pump();

      expect(find.text('Accueil'), findsOneWidget);
    });

    testWidgets('SANS `locale:`, l\'application basculerait bien en anglais', (
      tester,
    ) async {
      // LA NON-VACUITÉ DE LA DÉCISION, et elle était indispensable : sans ce
      // test, « on ne suit pas la locale du système » resterait une phrase de
      // commentaire, et personne ne saurait si la retirer changerait quoi que
      // ce soit. On monte donc la MÊME coque, au même réglage d'appareil, en
      // retirant la seule ligne qui porte la décision.
      //
      // Le résultat mesuré : « Home ». `basicLocaleListResolution` compare
      // `platformDispatcher.locales` — ici `[en_US]` — à
      // `AppLocalizations.supportedLocales`, que `gen-l10n` écrit dans l'ordre
      // alphabétique des `.arb` et qui commence donc par `Locale('en')`. La
      // correspondance est franche, et l'anglais gagne.
      //
      // C'est exactement le scénario que le propriétaire ne veut pas : dans la
      // sous-région, beaucoup d'appareils de propriétaires francophones sont
      // livrés en anglais. Retirer `locale:` les ferait tous basculer à la
      // prochaine mise à jour.
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const _CoqueSansLocale());
      await tester.pump();

      expect(
        find.text('Home'),
        findsOneWidget,
        reason:
            'La résolution automatique de Flutter ne choisit plus l\'anglais '
            'sur un appareil en anglais. Alors `locale:` ne protège plus de '
            'rien, et la décision écrite dans lib/core/l10n/langue.dart doit '
            'être remesurée avant d\'être maintenue.',
      );
    });
  });

  group('La bascule change ce qui est peint', () {
    testWidgets('le texte et la ponctuation des montants suivent', (
      tester,
    ) async {
      final conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: conteneur,
          child: const _CoqueLangue(propreScope: false),
        ),
      );
      await tester.pump();

      expect(find.text('Accueil'), findsOneWidget);
      expect(
        find.text('96 000 FCFA'),
        findsOneWidget,
        reason:
            'Le montant français groupe ses milliers par une espace fine '
            'insécable U+202F et colle son symbole par U+00A0 — c\'est ce que '
            'rend `NumberFormat.currency(locale: fr_FR)` sous intl 0.20.3.',
      );

      // La bascule, telle que la tuile du tiroir l'exécute.
      await conteneur.read(langueProvider.notifier).definir(localeAnglais);
      await tester.pump();

      expect(
        find.text('Home'),
        findsOneWidget,
        reason:
            'Le `locale:` du `MaterialApp` ne suit pas le provider : la '
            'bascule change l\'état et rien à l\'écran.',
      );
      expect(find.text('Accueil'), findsNothing);
      expect(
        find.text('96,000 FCFA'),
        findsOneWidget,
        reason:
            'Le texte a basculé mais pas les montants : '
            '`definirLocaleMontants` n\'est pas appelé dans le `build` qui '
            'observe la langue, et l\'anglophone lit « 96 000 FCFA ».',
      );

      // Et le retour, parce qu'un réglage qui ne revient pas est un piège.
      await conteneur.read(langueProvider.notifier).definir(localeFrancais);
      await tester.pump();

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('96 000 FCFA'), findsOneWidget);
    });

    testWidgets('la langue lue au démarrage est celle du premier rendu', (
      tester,
    ) async {
      // Ce que fait `main()` : il LIT la langue avant `runApp` et la pose en
      // surcharge, pour qu'aucune trame ne soit peinte dans la mauvaise langue.
      // Une lecture tardive donnerait un clignotement à chaque lancement, chez
      // tout utilisateur anglophone.
      await LangueService.ecrire(localeAnglais);
      final langue = await LangueService.lire();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [localeInitialeProvider.overrideWithValue(langue)],
          child: const _CoqueLangue(propreScope: false),
        ),
      );

      // UNE SEULE trame : si l'anglais n'arrivait qu'après la lecture
      // asynchrone, « Accueil » serait peint ici.
      await tester.pump();

      expect(
        find.text('Home'),
        findsOneWidget,
        reason:
            'Le premier rendu est en français alors que l\'anglais était '
            'enregistré : la langue n\'est pas lue avant `runApp`, et '
            'l\'application clignote à chaque lancement.',
      );
    });
  });
}

/// La coque de langue, réduite à ce qui porte la décision.
///
/// Elle reproduit le câblage de `AutoParcApp` — `locale:` pris dans
/// `langueProvider`, les délégués, et `definirLocaleMontants` appelé dans le
/// `build` du parent — sans son `GoRouter` ni Firebase. `AutoParcApp` elle-même
/// n'est pas montable dans un banc : son `_AppShell` initialise le service de
/// notifications dans un `addPostFrameCallback`, et son routeur ouvre la page
/// d'accueil, qui interroge le garage.
///
/// Ce que cette coque ne prouve donc PAS : que la tuile « Langue » du tiroir
/// appelle bien `definir`. C'est écrit ici plutôt que laissé à supposer. Le
/// chaînon manquant est de trois lignes, et il est sous les yeux dans
/// `_TuileLangue`.
class _CoqueLangue extends ConsumerWidget {
  final bool propreScope;
  const _CoqueLangue({this.propreScope = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contenu = _AppDeLangue();
    return propreScope ? ProviderScope(child: contenu) : contenu;
  }
}

/// La même coque, PRIVÉE de `locale:`.
///
/// Elle n'existe que pour le test de non-vacuité ci-dessus : c'est l'état que
/// l'application aurait si quelqu'un retirait la ligne qui porte la décision.
class _CoqueSansLocale extends StatelessWidget {
  const _CoqueSansLocale();

  @override
  Widget build(BuildContext context) => ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Text(AppLocalizations.of(context).commonHome),
        ),
      ),
    ),
  );
}

class _AppDeLangue extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langue = ref.watch(langueProvider);

    // Le même appel, au même endroit que dans `AutoParcApp.build`.
    definirLocaleMontants(langue);

    return MaterialApp(
      locale: langue,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              Text(AppLocalizations.of(context).commonHome),
              Text(formatXof(96000)),
            ],
          ),
        ),
      ),
    );
  }
}
