import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
// `yaml` arrive par `flutter_test` : il n'est pas declare dans le pubspec, et
// c'est assume — voir le test qui parse le workflow, en bas de ce fichier.
// ignore: depend_on_referenced_packages
import 'package:yaml/yaml.dart';

import 'package:auto/core/api/endpoints.dart';

/// Le garde-fou qui empêche un build de release de partir avec l'adresse de
/// l'émulateur.
///
/// Ce qu'il y avait à empêcher : `flutter build apk --release` lancé à la main,
/// hors du workflow, ne passe pas `--dart-define=API_BASE_URL=...`. Le paquet
/// sortait d'apparence normale et parlait à 10.0.2.2 — l'hôte vu depuis un
/// émulateur Android, inexistant ailleurs. Depuis que le partage compose ses
/// liens à partir de cette même racine, un tel paquet expédie
/// `http://10.0.2.2:8000/v/12` dans les conversations WhatsApp de vrais
/// clients : inerte chez le destinataire, et muet chez l'expéditeur.
///
/// La moitié de ce fichier relance de VRAIES compilations, parce qu'un test
/// qui n'interrogerait que les constantes d'[Endpoints] resterait vert si on
/// retirait l'`assert`. `dart compile kernel` sur `endpoints.dart` seul coûte
/// deux secondes et reproduit l'étape exacte où le build doit s'arrêter :
/// l'évaluation des constantes par le front-end. C'est aussi pour cela
/// qu'`endpoints.dart` n'importe rien — il se compile sans `dart:ui`.
void main() {
  /// L'exécutable `dart`. D'abord le PATH — ce que fournit
  /// `subosito/flutter-action` sur la CI — puis le SDK qui fait tourner ces
  /// tests, déduit de `flutter_tester.exe` : il vit sous
  /// `<flutter>/bin/cache/artifacts/engine/...`, et `dart` sous `<flutter>/bin`.
  ///
  /// Aucune échappatoire si rien ne répond : un `skip` laisserait le garde-fou
  /// non éprouvé, et c'est précisément ce que ce fichier doit interdire.
  late final String dart = _trouverDart();

  /// Compile `lib/core/api/endpoints.dart` seul, avec les `-D` demandés, et
  /// rend le code de sortie et la sortie d'erreur.
  ///
  /// Le point d'entrée est écrit hors du dépôt et importe le fichier par son
  /// URI absolue : rien n'est ajouté à `lib/`, et aucune résolution de paquet
  /// n'est nécessaire puisqu'`endpoints.dart` n'a pas d'import.
  ProcessResult compiler(List<String> defines) {
    final chemin =
        File('lib/core/api/endpoints.dart').absolute.uri.toString();
    final bac = Directory.systemTemp.createTempSync('garde_adresse_');
    try {
      final entree = File('${bac.path}/point_entree.dart')
        ..writeAsStringSync(
          "import '$chemin';\nvoid main() => print(Endpoints.baseUrl);\n",
        );

      return Process.runSync(
        dart,
        [
          'compile',
          'kernel',
          ...defines,
          entree.path,
          '-o',
          '${bac.path}/sortie.dill',
        ],
        runInShell: true,
      );
    } finally {
      bac.deleteSync(recursive: true);
    }
  }

  // ── Ce que voit la compilation de ces tests mêmes ───────────────────────

  group('la configuration du développement quotidien', () {
    /// Ce test n'existe que pour ancrer les trois suivants : si l'adresse par
    /// défaut change, c'est ici que ça se voit, et pas dans un échec obscur.
    test('le défaut est bien l\'adresse de l\'émulateur', () {
      expect(Endpoints.baseUrl, 'http://10.0.2.2:8000/api');
    });

    /// `flutter test` et `flutter run` ne passent pas de `--dart-define` : la
    /// garde doit les laisser tranquilles, sinon elle sera retirée au premier
    /// agacement. Que ce fichier s'exécute en est déjà la preuve — il a
    /// fallu compiler `endpoints.dart` pour y arriver.
    test('aucun API_BASE_URL n\'est fourni, et rien ne s\'y oppose', () {
      expect(Endpoints.urlFournieALaCompilation, isFalse);
      expect(Endpoints.urlDeDeveloppement, isTrue);
    });

    /// La même configuration, jugée par la règle : impubliable. C'est bien
    /// celle-là que le build de release doit refuser.
    test('cette configuration ne serait pas publiable', () {
      expect(Endpoints.adressePubliable, isFalse);
    });
  });

  group('le constructeur de garde', () {
    /// En debug les `assert` sont actifs, donc le constructeur se juge aussi
    /// à l'exécution. C'est la règle nue, sans compilation : faux refuse.
    test('refuse une adresse impubliable', () {
      expect(
        () => GardeAdresseRelease.verifiee(false),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepte une adresse publiable', () {
      expect(() => GardeAdresseRelease.verifiee(true), returnsNormally);
    });
  });

  // ── Les compilations, qui seules prouvent que la garde mord ─────────────

  group('un build de release', () {
    /// LE test. `-Ddart.vm.product=true` est ce que Flutter positionne pour un
    /// `--release`, et c'est la définition de `kReleaseMode`. Retirer
    /// l'`assert` d'`endpoints.dart` fait passer cette compilation, donc tomber
    /// ce test.
    test('sans API_BASE_URL : la compilation échoue, et dit quoi faire', () {
      final r = compiler(['-Ddart.vm.product=true']);

      expect(r.exitCode, isNot(0),
          reason: 'un release sans adresse de production a compilé');

      final sortie = '${r.stdout}${r.stderr}';
      // Sous-chaînes sans accent : la console Windows recode la sortie du
      // compilateur, et un « é » attendu ferait échouer le test pour la
      // mauvaise raison.
      expect(sortie, contains('assertion failed'));
      expect(sortie, contains('API_BASE_URL'));
      expect(sortie, contains('dart-define'));
    });

    /// Explicite ou par défaut, l'émulateur est refusé : c'est la valeur qui a
    /// expédié les liens inertes, pas la manière dont elle est arrivée.
    test('avec l\'adresse de l\'émulateur passée exprès : refusé aussi', () {
      final r = compiler([
        '-Ddart.vm.product=true',
        '-DAPI_BASE_URL=http://10.0.2.2:8000/api',
      ]);

      expect(r.exitCode, isNot(0));
    });

    /// La ligne de la CI, recopiée depuis `.github/workflows/build-apk.yml`.
    /// Elle doit compiler, sans quoi la garde casserait la seule chaîne qui
    /// produit un .aab.
    test('avec l\'adresse de production : la compilation passe', () {
      final r = compiler([
        '-Ddart.vm.product=true',
        '-DAPI_BASE_URL=https://autoparc-backend.onrender.com/api',
      ]);

      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    });

    /// Debug et profil ne sont pas concernés : ils ne vont chez personne.
    /// `dart compile kernel` met `dart.vm.product` à vrai par défaut — mesuré
    /// — d'où le `=false` explicite pour représenter un build de debug.
    test('hors release, le défaut émulateur compile sans rien dire', () {
      final r = compiler(['-Ddart.vm.product=false']);

      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    });
  });

  // ── Et la CI, qui doit continuer à passer la valeur ─────────────────────

  group('le workflow de publication', () {
    /// La garde ne sert à rien si la CI cesse de passer l'adresse : le build
    /// échouerait alors sur GitHub, après plusieurs minutes, au lieu de
    /// n'échouer qu'à la main. Ce test fait tomber la suite d'abord.
    ///
    /// Deux étapes passent le define — l'App Bundle pour Play, l'APK pour
    /// l'installation directe — d'où les deux occurrences attendues.
    test('passe une adresse de production aux deux builds', () {
      final yml = File('.github/workflows/build-apk.yml').readAsStringSync();
      final defines = RegExp(r'--dart-define=API_BASE_URL=(\S+)')
          .allMatches(yml)
          .map((m) => m.group(1)!)
          .toList();

      expect(defines, hasLength(2));
      for (final valeur in defines) {
        expect(valeur, startsWith('https://'));
        expect(valeur, endsWith('/api'));
        expect(valeur, isNot(contains('10.0.2.2')));
        expect(valeur, isNot(contains('192.168.')));
        expect(valeur, isNot(contains('ngrok')));
      }
    });

    /// L'hôte est écrit TROIS fois dans ce workflow : deux `--dart-define` et
    /// le `HOTE_PRODUCTION` de l'étape qui relit les binaires produits. Ce test
    /// interdit la dérive entre les trois.
    ///
    /// Pourquoi trois écritures et non une variable : les deux `--dart-define`
    /// doivent rester LITTÉRALES, parce que le test ci-dessus lit ce fichier et
    /// apparie `--dart-define=API_BASE_URL=(\S+)`. Un `${{ env.… }}` y
    /// capturerait `${{`, ferait tomber la suite, et avec elle le workflow
    /// entier — `flutter test` précède les builds. Le choix est donc : trois
    /// écritures et un test qui les lie, plutôt qu'une indirection YAML qui
    /// casse l'autre garde.
    test('l\'hôte du garde des binaires est celui des deux defines', () {
      final yml = File('.github/workflows/build-apk.yml').readAsStringSync();

      final hoteDuGarde = RegExp(r'HOTE_PRODUCTION:\s*(\S+)').firstMatch(yml)?.group(1);
      expect(hoteDuGarde, isNotNull,
          reason: 'L\'étape qui relit les binaires produits a disparu du workflow.');

      final hotesDesDefines = RegExp(r'--dart-define=API_BASE_URL=https://([^/\s]+)/api')
          .allMatches(yml)
          .map((m) => m.group(1)!)
          .toSet();

      expect(hotesDesDefines, {hoteDuGarde},
          reason: 'Le garde vérifierait un hôte que les builds ne compilent pas.');
    });

    /// Le garde ne sert à rien s'il s'exécute APRÈS la publication.
    test('le garde des binaires précède la publication des artefacts', () {
      final yml = File('.github/workflows/build-apk.yml').readAsStringSync();

      final garde = yml.indexOf('Vérifier l\'adresse compilée dans les binaires');
      final publication = yml.indexOf('Publier les artefacts');

      expect(garde, greaterThan(0));
      expect(publication, greaterThan(0));
      expect(garde, lessThan(publication));
    });

    /// Les deux motifs d'extraction diffèrent, et ce n'est pas un oubli : un
    /// App Bundle range ses bibliothèques sous `base/lib/`, un APK sous `lib/`.
    /// Confondre les deux ferait passer le garde à vide — aucune bibliothèque
    /// extraite, donc aucune vérifiée — et c'est exactement le genre de panne
    /// silencieuse qu'un garde ne doit pas avoir.
    test('le garde lit les deux artefacts, avec le motif propre à chacun', () {
      final yml = File('.github/workflows/build-apk.yml').readAsStringSync();

      expect(yml, contains("'base/lib/*/libapp.so' 'App Bundle'"));
      expect(yml, contains("'lib/*/libapp.so' 'APK'"));
      // Et il refuse une extraction vide au lieu de la prendre pour un succès.
      expect(yml, contains('aucun libapp.so extrait'));
    });

    /// LE WORKFLOW DOIT PARSER, et rien ne le vérifiait.
    ///
    /// Tous les tests de ce groupe lisent le fichier comme du TEXTE : ils
    /// resteraient verts sur un YAML dont l'indentation est fautive, et c'est
    /// GitHub qui refuserait le workflow — donc plus aucun build, et la panne
    /// se découvre au moment où l'on veut publier.
    ///
    /// Le besoin n'est pas théorique : ce fichier a été édité quatre fois en
    /// une séance pour y poser le garde des binaires, et deux de ces éditions
    /// ont fait tomber le test du comptage des defines — un garde qui se
    /// casse en silence au mauvais moment est précisément ce qu'on cherche à
    /// éviter.
    ///
    /// `yaml` arrive par `flutter_test` et n'est pas déclaré : l'import est
    /// donc signalé par l'analyseur, et tu, plutôt que d'alourdir le
    /// `pubspec` d'une dépendance de développement pour quinze lignes.
    test('le workflow parse, et ses étapes sont dans l\'ordre utile', () {
      final doc = loadYaml(File('.github/workflows/build-apk.yml').readAsStringSync()) as YamlMap;

      final etapes = (doc['jobs'] as YamlMap).values.first['steps'] as YamlList;
      final noms = etapes.map((e) => (e as YamlMap)['name']?.toString()).toList();

      // Les tests précèdent les builds : une suite rouge ne doit pas produire
      // d'artefact. C'est aussi ce qui donne leur valeur aux gardes de ce
      // fichier, qui vivent dans la suite.
      expect(noms.indexOf('Tests'), lessThan(noms.indexOf("Construire l'App Bundle (Play Store)")));

      final garde = etapes.firstWhere(
        (e) => (e as YamlMap)['name'] == "Vérifier l'adresse compilée dans les binaires",
        orElse: () => throw StateError('L\'étape du garde des binaires a disparu du workflow.'),
      ) as YamlMap;

      expect((garde['env'] as YamlMap)['HOTE_PRODUCTION'], isA<String>());
      expect(garde['run'].toString(), contains('libapp.so'));
    });
  });
}

/// Le chemin de l'exécutable `dart`, ou un échec qui nomme la cause.
String _trouverDart() {
  final candidats = <String>['dart'];

  // <flutter>/bin/cache/artifacts/engine/<plateforme>/flutter_tester.exe
  // → remonter jusqu'à <flutter>/bin.
  var dossier = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 6 && dossier.path != dossier.parent.path; i++) {
    for (final nom in const ['dart', 'dart.exe', 'dart.bat']) {
      final candidat = File('${dossier.path}/bin/$nom');
      if (candidat.existsSync()) candidats.add(candidat.path);
    }
    dossier = dossier.parent;
  }

  for (final candidat in candidats) {
    try {
      final r =
          Process.runSync(candidat, ['--version'], runInShell: true);
      if (r.exitCode == 0) return candidat;
    } on ProcessException {
      continue;
    }
  }

  throw StateError(
    'Aucun exécutable « dart » trouvé (essayés : ${candidats.join(', ')}). '
    'La garde de lib/core/api/endpoints.dart n\'a donc pas pu être éprouvée, '
    'et ce test refuse de passer sans l\'avoir fait.',
  );
}
