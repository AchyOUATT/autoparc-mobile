import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/update/ecran_mise_a_jour.dart';
import 'package:auto/core/update/version_minimale.dart';

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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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
