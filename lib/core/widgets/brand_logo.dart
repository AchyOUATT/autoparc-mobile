import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Inventaire des logos réellement présents dans le bundle, indexés par slug.
///
/// On lit le manifeste une fois plutôt que de tenter un chargement et de
/// rattraper l'exception : `SvgPicture.asset` n'expose pas d'`errorBuilder`,
/// et piloter l'affichage par exception coûte cher quand 80 cartes défilent.
///
/// Conséquence pratique : l'application fonctionne avec un dossier vide, ou
/// partiellement rempli. Chaque marque sans fichier se rabat sur l'icône
/// générique, sans erreur ni case vide.
final brandLogoAssetsProvider = FutureProvider<Map<String, String>>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final logos = <String, String>{};

  for (final path in manifest.listAssets()) {
    if (!path.startsWith('assets/brands/')) continue;

    final name = path.split('/').last;
    final dot  = name.lastIndexOf('.');
    if (dot <= 0) continue;

    final slug = name.substring(0, dot);
    final ext  = name.substring(dot + 1).toLowerCase();
    if (ext != 'svg' && ext != 'png') continue;

    // Le SVG l'emporte sur le PNG lorsque les deux existent.
    if (ext == 'svg' || !logos.containsKey(slug)) {
      logos[slug] = path;
    }
  }

  return logos;
});

/// Logo d'une marque, ou icône générique à défaut.
///
/// Les proportions des logos vont du bandeau très large (Land Rover) au rond
/// (BMW). Le widget les inscrit dans une boîte carrée en `BoxFit.contain` avec
/// une marge constante : rien n'est déformé, et la grille reste régulière.
class BrandLogo extends ConsumerWidget {
  /// Slug de la marque, tel que renvoyé par l'API (`identity.brand_slug`).
  final String? slug;

  /// Côté de la boîte carrée, marge comprise.
  final double size;

  final IconData fallbackIcon;
  final Color? fallbackColor;

  /// Recolore le logo avec la couleur du thème.
  ///
  /// Le jeu de logos actuel est monochrome noir : sans cette teinte, il tombe
  /// à 1,7:1 sur le fond sombre du thème nuit — mesuré — donc invisible. La
  /// recoloration ne fait rien perdre à un logo déjà monochrome, mais elle
  /// aplatirait un logo en couleurs : passer `false` dans ce cas.
  final bool monochrome;

  const BrandLogo({
    super.key,
    required this.slug,
    this.size = 40,
    this.fallbackIcon = Icons.directions_car,
    this.fallbackColor,
    this.monochrome = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color  = fallbackColor ?? Theme.of(context).colorScheme.outline;
    final assets = ref.watch(brandLogoAssetsProvider).valueOrNull;
    final path   = slug == null ? null : assets?[slug];

    if (path == null) {
      return Icon(fallbackIcon, size: size, color: color);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(size * 0.08),
        child: path.endsWith('.svg')
            ? SvgPicture.asset(
                path,
                fit: BoxFit.contain,
                colorFilter: monochrome
                    ? ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurface,
                        BlendMode.srcIn,
                      )
                    : null,
              )
            : Image.asset(
                path,
                fit: BoxFit.contain,
                color: monochrome
                    ? Theme.of(context).colorScheme.onSurface
                    : null,
                errorBuilder: (_, _, _) =>
                    Icon(fallbackIcon, size: size, color: color),
              ),
      ),
    );
  }
}
