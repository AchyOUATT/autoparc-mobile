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
Directory? dossierDesPolices() {
  final candidats = <String>[
    if (Platform.environment['FLUTTER_ROOT'] case final r?) r,
    // bin/cache/artifacts/engine/<plateforme>/<binaire> → six crans au-dessus
    Directory(
      Platform.resolvedExecutable,
    ).parent.parent.parent.parent.parent.parent.path,
  ];

  for (final racine in candidats) {
    final d = Directory('$racine/bin/cache/artifacts/material_fonts');
    if (d.existsSync()) return d;
  }
  return null;
}

/// Charge Roboto et les icônes Material, ou lève.
///
/// [exigerRoboto] à false pour les bancs qui rendent des images sans mesurer
/// de largeur : une capture sans Roboto est moins jolie, elle n'est pas
/// fausse. Les bancs de géométrie, eux, laissent le défaut à true — mesurer
/// la mauvaise police ne produit pas une mesure approximative mais une mesure
/// qui ne décrit aucun téléphone.
Future<void> chargerPolices({bool exigerRoboto = true}) async {
  final dossier = dossierDesPolices();

  if (dossier == null) {
    if (!exigerRoboto) return;
    throw StateError(
      'Les polices du SDK sont introuvables : ni FLUTTER_ROOT '
      '(${Platform.environment['FLUTTER_ROOT'] ?? 'non défini'}) ni la racine '
      'déduite de ${Platform.resolvedExecutable} ne portent '
      'bin/cache/artifacts/material_fonts.\n'
      'Ce banc mesure des largeurs de texte au dixième de point : sans Roboto '
      'il mesurerait la police de repli, presque deux fois plus large.\n'
      'Sur une machine neuve ou en CI : `flutter precache --universal`.',
    );
  }

  const fontes = {
    'Roboto': ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf'],
    'MaterialIcons': ['materialicons-regular.otf'],
  };

  for (final entree in fontes.entries) {
    final chargeur = FontLoader(entree.key);
    var trouvee = false;

    for (final nom in entree.value) {
      final fichier = File('${dossier.path}/$nom');
      if (!fichier.existsSync()) continue;
      chargeur.addFont(
        Future.value(fichier.readAsBytesSync().buffer.asByteData()),
      );
      trouvee = true;
    }

    if (trouvee) {
      await chargeur.load();
    } else if (entree.key == 'Roboto' && exigerRoboto) {
      throw StateError(
        'Le dossier ${dossier.path} existe mais ne contient aucun fichier '
        'Roboto. Installation incomplète : `flutter precache --universal`.',
      );
    }
  }
}
