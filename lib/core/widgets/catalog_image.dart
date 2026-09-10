import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Photo distante mise en cache sur disque.
///
/// `Image.network` ne conserve les octets qu'en mémoire : chaque redémarrage de
/// l'application retéléchargeait les photos déjà vues, et faire défiler une
/// liste puis revenir en arrière suffisait souvent à les redemander. Sur une
/// connexion facturée au volume, les photos sont de loin le poste le plus lourd
/// de l'application — bien devant les tables de référence.
///
/// [fallback] tient les deux rôles habituels : ce qu'on affiche pendant le
/// chargement et ce qu'on affiche si l'image ne vient pas. Les listes y
/// mettent leur vignette de remplacement, ce qui évite le carré gris.
/// [whileLoading] permet de dissocier les deux quand le repli d'erreur serait
/// trompeur avant même l'échec (icône « image cassée », par exemple).
class CatalogImage extends StatelessWidget {
  const CatalogImage({
    super.key,
    required this.url,
    required this.fallback,
    this.whileLoading,
    this.fit = BoxFit.cover,
  });

  final String  url;
  final Widget  fallback;
  final Widget? whileLoading;
  final BoxFit  fit;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        // Assez court pour ne pas donner l'impression d'un écran qui hésite,
        // assez long pour éviter le clignotement quand l'image vient du disque.
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder:  (_, __)      => whileLoading ?? fallback,
        errorWidget:  (_, __, ___) => fallback,
      );
}
