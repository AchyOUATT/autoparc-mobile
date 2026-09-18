import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';

/// Prépare les sources d'icône à partir du logo fourni.
///
/// Le logo d'origine contient son propre cadre arrondi, avec un reflet de verre
/// en haut à gauche. Android et iOS appliquent *leur* masque par-dessus : le
/// cadre dessiné produit un double encadrement, et sur Android les lanceurs
/// découpent un cercle ou une goutte dont seuls les 66 % centraux sont garantis
/// — l'engrenage et la clé en sortiraient rognés.
///
/// On extrait donc l'emblème seul, puis on le recompose :
///   • `app_icon.png`            plein cadre, fond uni, pour iOS et l'ancien
///                               format Android ;
///   • `app_icon_foreground.png` transparent, emblème réduit à la zone sûre,
///                               pour l'icône adaptative Android.

/// Un pixel appartient-il à l'emblème ?
///
/// On décrit le fond, pas l'emblème. Le décrire par sa clarté — « argenté donc
/// lumineux » — écartait tout le métal à l'ombre : l'engrenage ressortait
/// rongé, la calandre et les phares creux. Le métal reste neutre même dans
/// l'ombre, alors que le fond est franchement bleu partout : de la marine la
/// plus sombre à la lueur cyan, l'écart entre bleu et rouge y dépasse 60.
///
/// Le reflet de verre du cadre tombe du même côté, avec un écart de 112 : c'est
/// voulu, on veut s'en débarrasser.
/// Un rapport, pas un écart : le fond va du marine presque noir au cyan vif, et
/// un seuil absolu laissait les coins les plus sombres du côté de l'emblème.
/// Tout le fond devenait alors une pièce touchant le bord, donc rejetée — et
/// l'emblème, collé à elle, partait avec.
bool _estEmbleme(int r, int g, int b) => !(b >= 50 && b > r * 2.2);

/// Masque d'opacité : 255 sur l'emblème, 0 sur le fond.
///
/// Un simple seuil ne suffirait pas. Le pare-brise, la calandre et les phares
/// sont sombres ou bleus — donc « fond » au sens du critère — mais ils sont
/// enfermés dans la carrosserie et font partie du dessin. On part donc des
/// bords de l'image et on ne propage que de proche en proche : ce qui n'est pas
/// atteignable depuis l'extérieur est conservé.
Uint8List _masque(Image src) {
  final l = src.width, h = src.height;
  final masque = Uint8List(l * h)..fillRange(0, l * h, 255);
  final vu = Uint8List(l * h);
  final pile = <int>[];

  void pousser(int x, int y) {
    if (x < 0 || y < 0 || x >= l || y >= h) return;
    final i = y * l + x;
    if (vu[i] == 1) return;
    final p = src.getPixel(x, y);
    if (_estEmbleme(p.r.toInt(), p.g.toInt(), p.b.toInt())) return;
    vu[i] = 1;
    masque[i] = 0;
    pile.add(i);
  }

  for (var x = 0; x < l; x++) {
    pousser(x, 0);
    pousser(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    pousser(0, y);
    pousser(l - 1, y);
  }

  while (pile.isNotEmpty) {
    final i = pile.removeLast();
    final x = i % l, y = i ~/ l;
    pousser(x - 1, y);
    pousser(x + 1, y);
    pousser(x, y - 1);
    pousser(x, y + 1);
  }

  return masque;
}

/// Distance au bord en deçà de laquelle une pièce appartient au cadre.
///
/// Le reflet de verre atteint 180 px du bord, l'emblème commence à 195. La
/// marge est mince mais nette, et il n'existe rien entre les deux.
const _bandeDuCadre = 170;

/// Retire du masque tout ce qui appartient au cadre arrondi.
///
/// Le reflet de verre est clair et neutre : il passe le critère de l'emblème,
/// et il n'est pas atteignable depuis les bords puisqu'il forme un arc. Il
/// survivait donc au détourage, et son extrémité en haut à gauche étirait la
/// boîte englobante jusqu'au bord de l'image — l'emblème se retrouvait décentré
/// et réduit d'autant.
///
/// On ne peut pas simplement garder la plus grosse pièce : les ombres du métal
/// brossé cassent l'emblème en centaines de morceaux disjoints, et la plus
/// grosse ne couvre que le milieu de la carrosserie. On juge donc par la
/// position — une pièce qui mord sur la bande du bord est du cadre — ce qui
/// conserve les dents de l'engrenage comme les bouts de la clé.
void _retirerLeCadre(Uint8List masque, int l, int h) {
  final etiquette = Int32List(l * h)..fillRange(0, l * h, -1);
  final aJeter = <int>{};
  var courante = 0, jetees = 0;

  for (var depart = 0; depart < masque.length; depart++) {
    if (masque[depart] == 0 || etiquette[depart] != -1) continue;

    var minX = l, minY = h, maxX = 0, maxY = 0;
    final pile = <int>[depart];
    etiquette[depart] = courante;

    while (pile.isNotEmpty) {
      final i = pile.removeLast();
      final x = i % l, y = i ~/ l;

      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;

      for (final (dx, dy) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= l || ny >= h) continue;
        final j = ny * l + nx;
        if (masque[j] == 0 || etiquette[j] != -1) continue;
        etiquette[j] = courante;
        pile.add(j);
      }
    }

    if (minX < _bandeDuCadre ||
        minY < _bandeDuCadre ||
        maxX > l - _bandeDuCadre ||
        maxY > h - _bandeDuCadre) {
      aJeter.add(courante);
      jetees++;
    }

    courante++;
  }

  stdout.writeln('  $courante pièces, $jetees rejetées comme appartenant au cadre');

  for (var i = 0; i < masque.length; i++) {
    if (aJeter.contains(etiquette[i])) masque[i] = 0;
  }
}

/// Rétrécit le masque de `rayon` pixels.
///
/// Le contour de l'emblème est lissé dans l'image d'origine : ses derniers
/// pixels mélangent l'argent et le bleu marine du fond. Détourés tels quels,
/// ils forment un liseré sombre qui, sur un fond d'une autre couleur, ressemble
/// à un mauvais découpage aux ciseaux. On sacrifie donc les deux pixels du bord
/// plutôt que de les garder sales.
void _eroder(Uint8List masque, int l, int h, int rayon) {
  final copie = Uint8List.fromList(masque);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < l; x++) {
      if (copie[y * l + x] == 0) continue;

      var borde = false;
      for (var dy = -rayon; dy <= rayon && !borde; dy++) {
        for (var dx = -rayon; dx <= rayon && !borde; dx++) {
          final nx = x + dx, ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= l || ny >= h) continue;
          if (copie[ny * l + nx] == 0) borde = true;
        }
      }

      if (borde) masque[y * l + x] = 0;
    }
  }
}

/// Emblème découpé au plus juste, avec un bord adouci.
///
/// Le bord brut serait crénelé : à 48 points sur un écran d'accueil, un contour
/// en escalier se voit plus que le dessin lui-même. Un léger flou du masque
/// suffit, et la frange bleue qu'il laisse disparaît sur le fond bleu de
/// l'icône.
Image _embleme(Image src) {
  final masque = _masque(src);
  _retirerLeCadre(masque, src.width, src.height);
  _eroder(masque, src.width, src.height, 2);

  final l = src.width;

  var minX = src.width, minY = src.height, maxX = 0, maxY = 0;
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      if (masque[y * l + x] != 0) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  stdout.writeln('  emblème détouré : x $minX..$maxX, y $minY..$maxY');

  // `convert` rend une nouvelle image, il ne modifie pas celle qu'on lui passe :
  // écrire le canal alpha sur la copie d'origine ne changeait rien, et le fond
  // ressortait intact.
  final avecAlpha = src.convert(numChannels: 4);
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      avecAlpha.getPixel(x, y).a = masque[y * l + x];
    }
  }

  final rogne = copyCrop(
    avecAlpha,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );

  return gaussianBlur(rogne, radius: 1);
}

/// Pose l'emblème au centre d'un carré, à la proportion demandée.
Image _composer(Image embleme, int cote, double proportion, Color? fond) {
  final toile = Image(width: cote, height: cote, numChannels: 4);

  if (fond != null) {
    fill(toile, color: fond);
  }

  final cible = (cote * proportion).round();
  final echelle = cible / [embleme.width, embleme.height].reduce((a, b) => a > b ? a : b);
  final redimensionne = copyResize(
    embleme,
    width: (embleme.width * echelle).round(),
    height: (embleme.height * echelle).round(),
    interpolation: Interpolation.cubic,
  );

  compositeImage(
    toile,
    redimensionne,
    dstX: (cote - redimensionne.width) ~/ 2,
    dstY: (cote - redimensionne.height) ~/ 2,
  );

  return toile;
}

/// Bandeau de la fiche Play — 1024×500, dimensions imposées.
///
/// L'emblème est posé à gauche : Play superpose parfois le nom et le bouton
/// d'installation sur la droite du bandeau, et un dessin centré s'y fait
/// recouvrir. La moitié droite reste donc volontairement vide.
Image _banniere(Image embleme, Color fond) {
  // Trois canaux, pas quatre. Play exige pour l'image de présentation un JPEG ou
  // un PNG 24 bits *sans* couche de transparence. Une première version était en
  // RVBA : refusée avec un message qui ne parle que de dimensions et de poids —
  // tous deux corrects —, sans nommer la transparence, qui était la cause.
  final toile = Image(width: 1024, height: 500, numChannels: 3);
  fill(toile, color: fond);

  final hauteur = (500 * 0.72).round();
  final echelle = hauteur / embleme.height;
  final pose = copyResize(
    embleme,
    width: (embleme.width * echelle).round(),
    height: hauteur,
    interpolation: Interpolation.cubic,
  );

  compositeImage(
    toile,
    pose,
    dstX: 110,
    dstY: (500 - pose.height) ~/ 2,
  );

  return toile;
}

void main(List<String> args) {
  final source = args[0];
  final dossier = args[1];
  Directory(dossier).createSync(recursive: true);

  stdout.writeln('Lecture de $source');
  final src = decodePng(File(source).readAsBytesSync())!;
  final embleme = _embleme(src);

  // Bleu de l'application, relevé sur la barre de navigation : l'icône et le
  // premier écran se suivent sans décrochage. Le bleu roi du logo d'origine
  // reste disponible en second fichier, pour comparer.
  final bleuApp   = ColorRgb8(0x1F, 0x65, 0x87);
  final bleuRoyal = ColorRgb8(0x0B, 0x4A, 0x9E);

  final sorties = <String, Image>{
    // Plein cadre : iOS et l'ancien format Android masquent eux-mêmes.
    // 78 % laisse la marge que les coins arrondis vont manger.
    'app_icon.png':         _composer(embleme, 1024, 0.78, bleuRoyal),
    'app_icon_ardoise.png': _composer(embleme, 1024, 0.78, bleuApp),

    // Adaptative : le dessin n'est garanti que sur les 66 % centraux, et le
    // système en anime le décalage. flutter_launcher_icons applique en plus
    // son propre retrait de 16 %, qui se multiplie au nôtre : 0,72 × 0,68
    // pose l'emblème sur 49 % de la toile, bien dans la zone sûre, et à une
    // taille comparable aux icônes voisines. À 58 % ici, il tombait à 39 % et
    // paraissait rétréci dans son cercle.
    'app_icon_foreground.png': _composer(embleme, 1024, 0.72, null),

    // Emblème seul, pleine résolution — utile pour le web et les documents.
    'embleme.png': _composer(embleme, 1024, 1.0, null),

    // Icône de la fiche Play : 512×512, opaque, sans coins arrondis — Play
    // applique les siens.
    'play_icone_512.png': _composer(embleme, 512, 0.78, bleuRoyal),
  };

  // Bandeau de la fiche Play : 1024×500 impérativement.
  sorties['play_banniere_1024x500.png'] = _banniere(embleme, bleuRoyal);

  sorties.forEach((nom, image) {
    final chemin = '$dossier/$nom';
    File(chemin).writeAsBytesSync(encodePng(image));
    stdout.writeln('  écrit $nom (${image.width}x${image.height})');
  });
}
