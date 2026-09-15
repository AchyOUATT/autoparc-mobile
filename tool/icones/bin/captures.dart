import 'dart:io';
import 'package:image/image.dart';

/// Met les captures de l'émulateur au format que Google Play accepte.
///
/// L'écran de l'émulateur fait 1344×2992, soit un rapport de 9:20. Play
/// n'accepte qu'entre 16:9 et 9:16 : une capture brute serait refusée pour
/// « proportions non conformes », un motif qui ne dit pas d'où vient le
/// problème.
///
/// On pose donc chaque capture sur un cadre 1080×1920, sur le bleu de l'icône.
/// Recadrer aurait coûté le haut et le bas de chaque écran — c'est-à-dire la
/// barre de titre et la barre de navigation, les deux repères qui permettent de
/// comprendre ce qu'on regarde.
///
///   dart run tool/icones/bin/captures.dart docs/captures

/// Bleu de l'icône : les bandes latérales se lisent comme un cadre voulu,
/// pas comme du vide.
final _fond = ColorRgb8(0x0B, 0x4A, 0x9E);

const _largeur = 1080;
const _hauteur = 1920;

/// Part de la hauteur occupée par la capture. Un peu moins que tout, pour que
/// l'écran ne touche pas les bords.
const _proportion = 0.96;

void main(List<String> args) {
  final dossier = Directory(args.isEmpty ? 'docs/captures' : args[0]);

  final brutes = dossier
      .listSync()
      .whereType<File>()
      .where((f) => f.path.contains('brut-') && f.path.endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (brutes.isEmpty) {
    stderr.writeln('Aucune capture « brut-*.png » dans ${dossier.path}');
    exit(1);
  }

  for (final fichier in brutes) {
    final source = decodePng(fichier.readAsBytesSync())!;

    final hauteurCible = (_hauteur * _proportion).round();
    final echelle      = hauteurCible / source.height;
    final redimensionne = copyResize(
      source,
      width: (source.width * echelle).round(),
      height: hauteurCible,
      interpolation: Interpolation.cubic,
    );

    if (redimensionne.width > _largeur) {
      stderr.writeln('${fichier.path} : trop large une fois mise à l\'échelle, '
          'la capture déborderait du cadre.');
      exit(1);
    }

    final toile = Image(width: _largeur, height: _hauteur, numChannels: 3);
    fill(toile, color: _fond);

    compositeImage(
      toile,
      redimensionne,
      dstX: (_largeur - redimensionne.width) ~/ 2,
      dstY: (_hauteur - redimensionne.height) ~/ 2,
    );

    final nom = fichier.uri.pathSegments.last.replaceFirst('brut-', 'play-');
    final sortie = '${dossier.path}/$nom';
    File(sortie).writeAsBytesSync(encodePng(toile));

    stdout.writeln('$nom  ${_largeur}x$_hauteur  '
        '(capture ${redimensionne.width}x${redimensionne.height}, '
        'bandes de ${(_largeur - redimensionne.width) ~/ 2} px)');
  }
}
