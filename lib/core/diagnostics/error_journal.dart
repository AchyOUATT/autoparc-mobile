import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:path/path.dart' as p;

/// Conserve la trace des erreurs, pour celles qui ne se reproduisent pas.
///
/// Un écran rouge est apparu une fois en manipulant l'application —
/// `'_dependents.isEmpty': is not true`, la même famille d'assertion qu'un
/// défaut déjà corrigé ailleurs, où `ref` servait après le démontage du widget.
/// Huit tentatives de reproduction n'ont rien donné, et la trace avait disparu
/// du journal système quand il a fallu la lire : le tampon de `logcat` est
/// circulaire, et une poignée de minutes suffit à l'écraser.
///
/// D'où ce journal : les erreurs partent toujours vers la console, mais elles
/// sont aussi écrites sur le disque de l'appareil. Un défaut qui se manifeste
/// une fois par jour devient alors observable, au lieu de n'être qu'un souvenir.
///
/// Le fichier reste sur l'appareil. Rien n'est envoyé nulle part — ce serait une
/// collecte de données à déclarer, pour un besoin de mise au point.
class ErrorJournal {
  ErrorJournal._();

  static const _fichier = 'erreurs.log';

  /// Au-delà, le journal est reparti de zéro. Assez pour plusieurs dizaines de
  /// traces, trop peu pour peser sur le stockage.
  static const _tailleMax = 256 * 1024;

  static File? _cible;
  static bool _installe = false;

  /// Installe les deux collecteurs d'erreurs de Flutter.
  ///
  /// `FlutterError.onError` attrape ce qui casse pendant le rendu — les
  /// assertions du framework, dont celle qu'on cherche. `PlatformDispatcher.
  /// onError` attrape ce qui échappe à une zone asynchrone, qui autrement
  /// disparaîtrait sans bruit.
  ///
  /// Le comportement d'origine est conservé dans les deux cas : on ajoute une
  /// écriture, on ne remplace pas l'affichage.
  static Future<void> installer() async {
    await _preparerFichier();

    // Une seconde installation enchaînerait le nouveau gestionnaire au premier,
    // qui est déjà le nôtre : chaque erreur serait alors consignée deux fois, et
    // trois après un troisième appel. Le journal deviendrait illisible à mesure
    // qu'on s'en sert.
    if (_installe) return;
    _installe = true;

    final precedent = FlutterError.onError;

    FlutterError.onError = (details) {
      _consigner(
        'FlutterError',
        details.exceptionAsString(),
        details.stack,
        contexte: details.context?.toStringDeep(),
        bibliotheque: details.library,
      );
      precedent?.call(details);
    };

    PlatformDispatcher.instance.onError = (erreur, pile) {
      _consigner('Asynchrone', erreur.toString(), pile);
      return false; // false : le comportement par défaut suit son cours.
    };
  }

  /// Contenu du journal, vide s'il n'existe pas encore.
  static Future<String> lire() async {
    final f = _cible;
    if (f == null || !f.existsSync()) return '';
    return f.readAsString();
  }

  /// Chemin du fichier, pour pouvoir le récupérer avec `adb pull`.
  static String? get chemin => _cible?.path;

  static Future<void> _preparerFichier() async {
    try {
      // `getDatabasesPath` vient de sqflite, déjà présent : un dossier
      // inscriptible et durable, sans ajouter de dépendance pour un outil de
      // mise au point.
      _cible = File(p.join(await getDatabasesPath(), _fichier));

      if (_cible!.existsSync() && _cible!.lengthSync() > _tailleMax) {
        _cible!.writeAsStringSync('');
      }
    } catch (e) {
      // Sans fichier, les erreurs continuent d'aller à la console : le
      // diagnostic est moins pratique, l'application n'est pas affectée.
      debugPrint('[Journal] Fichier indisponible : $e');
      _cible = null;
    }
  }

  static void _consigner(
    String origine,
    String message,
    StackTrace? pile, {
    String? contexte,
    String? bibliotheque,
  }) {
    final entree = StringBuffer()
      ..writeln('──────────────────────────────────────────────')
      ..writeln('${DateTime.now().toIso8601String()}  [$origine]')
      ..writeln(message);

    if (bibliotheque != null) entree.writeln('Bibliothèque : $bibliotheque');
    if (contexte != null)     entree.writeln('Contexte : $contexte');
    if (pile != null)         entree.writeln(pile.toString());

    // La console d'abord : elle reste le canal le plus direct quand on est
    // devant la machine au bon moment.
    debugPrint('[Journal] $origine : $message');

    try {
      _cible?.writeAsStringSync(
        entree.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Écrire le journal ne doit jamais devenir la cause d'une erreur.
    }
  }
}
