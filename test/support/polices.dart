import 'dart:io';

import 'package:flutter/services.dart';

/// Le chargement de Roboto pour les bancs qui mesurent du texte.
///
/// ── POURQUOI CE FICHIER EXISTE ──────────────────────────────────────────────
///
/// Quatre bancs portaient la même fonction, copiée, et tous les quatre
/// abandonnaient EN SILENCE quand les polices manquaient. Le défaut a coûté
/// une publication : la CI a mesuré des cartes de 617,5 points là où le poste
/// de développement en mesure 376,5, et les tests de densité sont tombés un
/// par un sur des chiffres incompréhensibles.
///
/// La cause : sans Roboto, Flutter se rabat sur une police d'essai presque
/// deux fois plus large. « 95 000 km • Essence » y vaut 228,0 points contre
/// 117,1 avec Roboto. Tout ce qui se replie se replie alors davantage, et
/// toutes les hauteurs mesurées deviennent fausses — pas un peu fausses, du
/// simple au double.
///
/// ── CE QUI A CHANGÉ ─────────────────────────────────────────────────────────
///
/// Deux chemins pour trouver le SDK au lieu d'un, et un ÉCHEC bruyant au lieu
/// d'un abandon muet. Une seule erreur à la racine vaut mieux que douze
/// symptômes à l'autre bout.

/// Le dossier des polices du SDK, trouvé sans dépendre de l'environnement.
///
/// `FLUTTER_ROOT` est posé par `flutter test` dans le processus fils — il est
/// donc présent même quand le shell ne l'a pas, ce qui a longtemps masqué le
/// problème. Mais la variable peut pointer une installation dont les
/// artefacts n'ont jamais été téléchargés : Flutter ne les récupère qu'à la
/// demande, et une machine de CI neuve qui ne fait que `flutter test` n'a
/// aucune raison de les avoir.
///
/// `Platform.resolvedExecutable` vaut
/// `<racine>/bin/cache/artifacts/engine/<plateforme>/flutter_tester`, donc la
/// racine se déduit du binaire lui-même. On essaie les deux.
List<Directory> dossiersDesPolices() {
  final racines = <String>[
    if (Platform.environment['FLUTTER_ROOT'] case final r?) r,
    // bin/cache/artifacts/engine/<plateforme>/<binaire> → six crans au-dessus
    Directory(
      Platform.resolvedExecutable,
    ).parent.parent.parent.parent.parent.parent.path,
  ];

  return [
    // LE DÉPÔT D'ABORD, et c'est la correction qui a tout réglé. Le SDK ne
    // livre PLUS Roboto sous Linux : sur la CI, le dossier material_fonts
    // existe et ne contient que les icônes. Mesuré par l'erreur que ce
    // fichier lève désormais :
    //
    //   Le dossier /opt/hostedtoolcache/flutter/stable-3.47.2-x64/flutter/
    //   bin/cache/artifacts/material_fonts existe mais ne contient aucun
    //   fichier Roboto.
    //
    // Le cache Windows de ce poste en gardait une copie héritée, d'où des
    // mesures justes en local et fausses en CI — 376,5 points contre 617,5.
    // `flutter precache --universal` n'y change rien : la police n'est plus
    // dans l'artefact.
    //
    // 500 ko de binaires dans l'historique, donc, et le fichier voisin de ce
    // commentaire explique pourquoi le projet les avait refusés. Ce refus a
    // coûté une publication : des mesures au dixième de point ne peuvent pas
    // dépendre de ce que la machine veut bien fournir.
    Directory('test/fonts'),
    for (final r in racines) Directory('$r/bin/cache/artifacts/material_fonts'),
  ].where((d) => d.existsSync()).toList();
}

/// Charge Roboto et les icônes Material, ou lève.
///
/// [exigerRoboto] à false pour les bancs qui rendent des images sans mesurer
/// de largeur : une capture sans Roboto est moins jolie, elle n'est pas
/// fausse. Les bancs de géométrie, eux, laissent le défaut à true — mesurer
/// la mauvaise police ne produit pas une mesure approximative mais une mesure
/// qui ne décrit aucun téléphone.
Future<void> chargerPolices({bool exigerRoboto = true}) async {
  final dossiers = dossiersDesPolices();

  const fontes = {
    'Roboto': ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf'],
    'MaterialIcons': ['materialicons-regular.otf'],
  };

  for (final entree in fontes.entries) {
    final chargeur = FontLoader(entree.key);
    var trouvees = 0;

    // Chaque FICHIER est cherché dans chaque dossier, et non le dossier
    // entier dans l'ordre : le dépôt porte Roboto, le SDK porte les icônes.
    // Chercher « le premier dossier qui existe » aurait pris le dépôt et
    // perdu les icônes.
    for (final nom in entree.value) {
      for (final d in dossiers) {
        final fichier = File('${d.path}/$nom');
        if (!fichier.existsSync()) continue;
        chargeur.addFont(
          Future.value(fichier.readAsBytesSync().buffer.asByteData()),
        );
        trouvees++;
        break;
      }
    }

    if (trouvees > 0) {
      await chargeur.load();
    } else if (entree.key == 'Roboto' && exigerRoboto) {
      throw StateError(
        'Aucun fichier Roboto trouvé. Cherché dans :\n'
        '${dossiers.map((d) => '  ${d.path}').join('\n')}\n'
        'Le dépôt en porte normalement une copie dans test/fonts — '
        'a-t-elle été supprimée ? Ce banc mesure des largeurs au dixième de '
        'point : sans Roboto il mesurerait la police de repli, presque deux '
        'fois plus large, et rendrait des chiffres qui ne décrivent aucun '
        'téléphone.',
      );
    }
  }
}
