import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/update/ecran_mise_a_jour.dart';
import 'package:auto/core/update/version_minimale.dart';
import 'package:auto/l10n/app_localizations.dart';

import 'support/langues.dart';

/// Le plancher de version, et surtout ce qui arrive quand il échoue.
///
/// Deux moitiés, et elles ne pèsent pas le même poids.
///
/// La première vérifie la comparaison : 69 contre 70 bloque, 70 contre 70 ne
/// bloque pas. C'est trois lignes de code et personne ne s'attend à les voir
/// casser.
///
/// La seconde vérifie les défaillances — réseau coupé, HTTP 500, JSON
/// illisible, champ absent, versionCode local illisible — et c'est elle qui
/// compte. La règle qui prime sur toutes les autres est que l'application ne
/// bloque jamais sur une erreur : bloquer tout le parc parce que le serveur
/// tousse serait pire que le défaut qu'on corrige, et ce serveur-là dort sur
/// son offre gratuite au bout de trente secondes d'inactivité. Ces cas ne
/// sont pas des cas limites : ce sont ceux du premier démarrage du matin.
///
/// Ils sont écrits ici pour qu'on ne puisse pas les casser par mégarde. Un
/// `catch` qui se resserre, un `throw` ajouté dans le modèle, un
/// `validateStatus` retiré : chacun de ces gestes rend l'application
/// inutilisable hors ligne, et aucun ne se voit à la relecture.
void main() {
  // ── Un serveur de papier ──────────────────────────────────────────────

  /// Un Dio dont l'adaptateur rend une réponse fixée, sans réseau.
  ///
  /// On passe par un vrai `Dio` et non par un faux service : c'est Dio qui
  /// décode le JSON, applique `validateStatus` et lève sur l'adaptateur. Un
  /// faux posé plus haut testerait notre propre mise en scène, pas le
  /// chemin que le code emprunte en production.
  Dio serveurQuiRend(String corps, {int code = 200}) =>
      Dio()..httpClientAdapter = _AdaptateurFixe(corps: corps, code: code);

  Dio serveurInjoignable() =>
      Dio()..httpClientAdapter = _AdaptateurFixe(reseauCoupe: true);

  Future<VerdictMiseAJour> verdict({
    required Dio client,
    int? versionInstallee = 69,
  }) =>
      ServiceVersionMinimale(
        client: client,
        lireVersionInstallee: () async => versionInstallee,
      ).verifier();

  String reponse({Object? min = 70, String? message, String? url}) {
    final champs = <String>[
      if (min != null) '"min_version_code": ${_litteral(min)}',
      '"latest_version_code": 72',
      if (url != null) '"store_url": "$url"',
      if (message != null) '"message": "$message"',
    ];
    return '{${champs.join(', ')}}';
  }

  // ── La comparaison ────────────────────────────────────────────────────

  group('Comparaison au plancher', () {
    test('69 sous un plancher de 70 : la mise à jour est exigée', () async {
      final v = await verdict(
        client: serveurQuiRend(reponse(
          message: 'Votre version ne parle plus au serveur.',
          url: 'https://play.google.com/store/apps/details?id=bf.autoparc',
        )),
        versionInstallee: 69,
      );

      expect(v.exigee, isTrue);
      expect(v.message, 'Votre version ne parle plus au serveur.');
      expect(v.urlStore, contains('play.google.com'));
    });

    /// L'égalité ne bloque pas. C'est la version plancher elle-même : la
    /// bloquer reviendrait à demander d'installer ce qui est déjà installé,
    /// et l'utilisateur tournerait en rond entre le store et l'écran.
    test('70 contre un plancher de 70 : rien à faire', () async {
      final v = await verdict(
        client: serveurQuiRend(reponse()),
        versionInstallee: 70,
      );

      expect(v.exigee, isFalse);
    });

    test('71 contre un plancher de 70 : rien à faire', () async {
      final v = await verdict(
        client: serveurQuiRend(reponse()),
        versionInstallee: 71,
      );

      expect(v.exigee, isFalse);
    });

    /// Laravel sérialise volontiers les nombres en texte — c'est ce qui avait
    /// fait tomber le catalogue entier avec « 2450000.00 ». Ici la
    /// conséquence serait inverse et plus sournoise : le plancher cesserait
    /// simplement de s'appliquer, sans message d'erreur nulle part.
    test('un plancher rendu en chaîne (« 70 ») est lu correctement', () async {
      final v = await verdict(
        client: serveurQuiRend(reponse(min: '70')),
        versionInstallee: 69,
      );

      expect(v.exigee, isTrue);
    });

    test('le message par défaut sert quand le serveur n\'en donne pas',
        () async {
      final v = await verdict(
        client: serveurQuiRend(reponse()),
        versionInstallee: 69,
      );

      expect(v.exigee, isTrue);
      expect(v.message, messageMiseAJourParDefaut);
    });
  });

  // ── Les défaillances : la règle qui prime ─────────────────────────────

  group('Aucune défaillance ne bloque', () {
    test('min_version_code absent de la réponse : rien à faire', () async {
      final v = await verdict(
        client: serveurQuiRend(reponse(min: null)),
        versionInstallee: 1,
      );

      expect(v.exigee, isFalse);
    });

    test('min_version_code non numérique : rien à faire', () async {
      final v = await verdict(
        client: serveurQuiRend(reponse(min: 'bientôt')),
        versionInstallee: 1,
      );

      expect(v.exigee, isFalse);
    });

    /// Le cas du téléphone dans un sous-sol, et celui du serveur endormi
    /// au-delà des cinq secondes accordées. Les deux arrivent tous les jours.
    test('erreur réseau : rien à faire, et surtout pas de blocage', () async {
      final v = await verdict(
        client: serveurInjoignable(),
        versionInstallee: 1,
      );

      expect(v.exigee, isFalse);
    });

    test('HTTP 500 : rien à faire', () async {
      final v = await verdict(
        client: serveurQuiRend(reponse(), code: 500),
        versionInstallee: 1,
      );

      expect(v.exigee, isFalse);
    });

    /// La page d'erreur HTML d'un hébergeur, servie avec un en-tête JSON.
    /// C'est la forme qu'a prise la panne du 11 octobre côté passerelle.
    test('JSON illisible : rien à faire', () async {
      final v = await verdict(
        client: serveurQuiRend('<html><body>502 Bad Gateway</body></html>'),
        versionInstallee: 1,
      );

      expect(v.exigee, isFalse);
    });

    /// `PackageInfo` rend `buildNumber` en chaîne, et elle peut être vide.
    /// Sans versionCode local, il n'y a rien à comparer — et comparer avec
    /// zéro bloquerait tout le monde.
    test('versionCode local illisible : rien à faire', () async {
      final v = await verdict(
        client: serveurQuiRend(reponse()),
        versionInstallee: null,
      );

      expect(v.exigee, isFalse);
    });
  });

  // ── L'écran bloquant ──────────────────────────────────────────────────

  group('Écran bloquant', () {
    const messageServeur =
        'La version installée ne peut plus lire les prix du catalogue.';

    Widget ecran() => const MaterialApp(
          // L'écran bloquant porte désormais du texte traduit (son bouton).
          // Voir test/support/langues.dart.
          locale: localeFr,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EcranMiseAJour(
            message: messageServeur,
            urlStore: 'https://play.google.com/store/apps/details?id=bf.autoparc',
          ),
        );

    testWidgets('affiche le message du serveur et le bouton', (tester) async {
      await tester.pumpWidget(ecran());

      expect(find.text(messageServeur), findsOneWidget);

      final bouton = find.widgetWithText(FilledButton, 'Mettre à jour');
      expect(bouton, findsOneWidget);
      expect(
        tester.widget<FilledButton>(bouton).onPressed,
        isNotNull,
        reason: 'Le bouton doit être actionnable quand le serveur a donné '
            'une adresse.',
      );
    });

    /// Le cœur du dispositif. Un écran qu'on peut écarter ne sert à rien : la
    /// version périmée reprendrait ses appels à l'API derrière.
    testWidgets('le Retour système ne le ferme pas', (tester) async {
      final navigateur = GlobalKey<NavigatorState>();

      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigateur,
        // L'écran poussé plus bas porte du texte traduit : les délégués
        // doivent être sur CE `MaterialApp`, qui est celui qui l'héberge.
        locale: localeFr,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('Catalogue')),
      ));

      // Posé sur une route antérieure : si le Retour passait, « Catalogue »
      // réapparaîtrait. Sans route dessous, le test ne distinguerait pas un
      // Retour intercepté d'un Retour sans effet.
      //
      // `unawaited` parce que la Future de `push` ne se résout qu'au
      // dépilement — c'est-à-dire, si tout va bien, jamais.
      unawaited(navigateur.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const EcranMiseAJour(
            message: messageServeur,
            urlStore: 'https://play.google.com/store/apps/details?id=bf.autoparc',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(messageServeur), findsOneWidget);
      expect(find.text('Catalogue'), findsNothing);

      await _retourSysteme(tester);

      expect(find.text(messageServeur), findsOneWidget);
      expect(
        find.text('Catalogue'),
        findsNothing,
        reason: 'Le Retour système a dépilé l\'écran bloquant.',
      );
    });

    /// Le bouton reste visible sans adresse, mais inerte : un écran bloquant
    /// sans aucune commande laisserait croire à une application cassée.
    testWidgets('sans adresse de store, le bouton est grisé', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        locale: localeFr,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EcranMiseAJour(message: messageServeur),
      ));

      final bouton = find.widgetWithText(FilledButton, 'Mettre à jour');
      expect(bouton, findsOneWidget);
      expect(tester.widget<FilledButton>(bouton).onPressed, isNull);
    });
  });

  // La tenue en 320x640 à l'échelle 1,3 est vérifiée dans
  // `responsive_test.dart`, avec les autres écrans et le même banc : creux
  // système compris, défilement compris.

  // ── L'interrupteur de l'espace partenaire ─────────────────────────────
  //
  // Il voyage sur cette même réponse, et pour une raison qui n'est pas de
  // commodité : c'est le SEUL interrupteur distant de l'application. Il n'y a
  // ni configuration distante, ni constante de compilation. Une fois un binaire
  // publié, ce champ est le seul moyen de masquer l'entrée de l'espace
  // partenaire — dont la tuile de tiroir n'avait, jusqu'ici, aucune condition.
  //
  // LE SENS DU DÉFAUT EST L'OBJET DE CES TESTS, et il est l'inverse de celui du
  // plancher. Le plancher ne bloque jamais sur une défaillance, parce que
  // bloquer tout le parc serait pire que le défaut. Ici c'est le contraire :
  // dans le doute on FERME, parce qu'une entrée affichée à tort mène à un refus
  // du serveur, tandis qu'une entrée masquée à tort se rattrape en relançant
  // l'application.
  //
  // Ce que ces tests NE couvrent pas : la condition posée sur la tuile
  // elle-même, dans `main.dart`. `_AppDrawer` est privé, et le rendre public
  // pour l'atteindre coûterait plus que la ligne qu'on vérifierait. La logique,
  // elle, est ici.

  group('Interrupteur de l\'espace partenaire — lecture', () {
    Future<PlancherDeVersion?> plancherDe(String corps) => ServiceVersionMinimale(
          client: serveurQuiRend(corps),
          lireVersionInstallee: () async => 69,
        ).lire();

    // PHP sérialise un booléen de bien des façons selon qu'il a croisé un cast
    // ou une variable d'environnement.
    for (final forme in ['true', '1', '"1"', '"true"', '"TRUE"', '"yes"', '"on"']) {
      test('$forme ouvre l\'espace', () async {
        final plancher = await plancherDe('{"min_version_code": 70, "partner_space_open": $forme}');

        expect(plancher!.espacePartenaireOuvert, isTrue, reason: '$forme devrait ouvrir');
      });
    }

    // `"false"` est le piège : une chaîne non vide, donc vraie pour tout test
    // de vérité laxiste. C'est exactement la forme qu'un serveur produit quand
    // la variable d'environnement a été renseignée à « false » en texte.
    for (final forme in ['false', '0', '"0"', '"false"', '"FALSE"', '""', 'null', '"nimportequoi"', '[]']) {
      test('$forme laisse l\'espace fermé', () async {
        final plancher = await plancherDe('{"min_version_code": 70, "partner_space_open": $forme}');

        expect(plancher!.espacePartenaireOuvert, isFalse, reason: '$forme ne devrait pas ouvrir');
      });
    }

    test('champ absent — un serveur antérieur au drapeau — laisse fermé', () async {
      final plancher = await plancherDe('{"min_version_code": 70}');

      expect(plancher!.espacePartenaireOuvert, isFalse);
    });

    test('la lecture du plancher reste correcte à côté du drapeau', () async {
      // Contre-épreuve : si l'ajout du drapeau avait cassé le reste de la
      // réponse, les tests ci-dessus passeraient quand même.
      final plancher = await plancherDe('{"min_version_code": 70, "partner_space_open": true}');

      expect(plancher!.minVersionCode, 70);
      expect(plancher.espacePartenaireOuvert, isTrue);
    });
  });

  group('Interrupteur de l\'espace partenaire — le provider ferme dans le doute', () {
    ProviderContainer conteneur(Dio client) => ProviderContainer(overrides: [
          serviceVersionMinimaleProvider.overrideWithValue(ServiceVersionMinimale(
            client: client,
            lireVersionInstallee: () async => 69,
          )),
        ]);

    test('pendant la lecture : fermé', () {
      final c = conteneur(serveurQuiRend('{"partner_space_open": true}'));
      addTearDown(c.dispose);

      // Lu AVANT d'attendre la Future : c'est l'état des premières images de
      // l'application, celles où le tiroir peut déjà s'ouvrir.
      expect(c.read(espacePartenaireOuvertProvider), isFalse);
    });

    test('réseau coupé : fermé', () async {
      final c = conteneur(serveurInjoignable());
      addTearDown(c.dispose);

      await c.read(plancherDeVersionProvider.future);

      expect(c.read(espacePartenaireOuvertProvider), isFalse);
    });

    test('HTTP 500 : fermé', () async {
      final c = conteneur(serveurQuiRend('{"partner_space_open": true}', code: 500));
      addTearDown(c.dispose);

      await c.read(plancherDeVersionProvider.future);

      expect(c.read(espacePartenaireOuvertProvider), isFalse);
    });

    test('oui franc : ouvert', () async {
      final c = conteneur(serveurQuiRend('{"min_version_code": 70, "partner_space_open": true}'));
      addTearDown(c.dispose);

      await c.read(plancherDeVersionProvider.future);

      // Sans ce test, « fermé » en dur passerait tous les précédents.
      expect(c.read(espacePartenaireOuvertProvider), isTrue);
    });

    test('un seul appel réseau nourrit le verdict ET le drapeau', () async {
      // Cet appel est celui qui réveille l'instance endormie du plan gratuit,
      // mesuré à 34,8 s. Le dédoubler le ferait payer deux fois à chaque
      // démarrage.
      final adaptateur = _AdaptateurFixe(corps: '{"min_version_code": 70, "partner_space_open": true}');
      final c = conteneur(Dio()..httpClientAdapter = adaptateur);
      addTearDown(c.dispose);

      await c.read(plancherDeVersionProvider.future);
      await c.read(verdictMiseAJourProvider.future);
      c.read(espacePartenaireOuvertProvider);

      expect(adaptateur.appels, 1, reason: 'La réponse de version doit être lue une seule fois.');
    });
  });
}

/// Rend `litteral` tel qu'il doit apparaître dans le corps JSON : un nombre
/// nu, ou une chaîne entre guillemets — c'est toute la différence que ce
/// fichier cherche à éprouver.
String _litteral(Object valeur) =>
    valeur is String ? '"$valeur"' : valeur.toString();

/// Simule l'appui sur le bouton Retour d'Android.
///
/// Il n'y a pas de raccourci dans `WidgetTester` : le geste arrive par le
/// canal `flutter/navigation`, exactement comme le fait le moteur.
Future<void> _retourSysteme(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// Un adaptateur HTTP qui ne sort pas de la machine.
///
/// `ResponseBody.fromString` avec un en-tête JSON : c'est bien le
/// transformateur de Dio qui décode, donc un corps illisible lève là où il
/// lèverait en production, et non dans le test.
class _AdaptateurFixe implements HttpClientAdapter {
  _AdaptateurFixe({
    this.corps = '',
    this.code = 200,
    this.reseauCoupe = false,
  });

  final String corps;
  final int code;
  final bool reseauCoupe;

  /// Combien de fois l'adaptateur a été sollicité.
  ///
  /// Sert à une seule chose, et elle compte : vérifier que la réponse de
  /// version n'est lue QU'UNE FOIS au démarrage, alors que deux lecteurs en
  /// dépendent désormais. C'est l'appel qui réveille l'instance endormie.
  int appels = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    appels++;
    if (reseauCoupe) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'aucune route vers l\'hôte',
      );
    }

    return ResponseBody.fromString(
      corps,
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
