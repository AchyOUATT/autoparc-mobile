import 'package:flutter/material.dart';

import 'catalog_image.dart';

/// La galerie photo d'un article, pour le bandeau d'une fiche.
///
/// Les fiches affichaient une icône codée en dur : ni `coverUrl`, ni `media`.
/// Les photos existaient, l'API les renvoyait, les cartes de la liste en
/// montraient une — seule la fiche, l'écran où on les cherche, n'en montrait
/// aucune. Ce widget remplace cette icône, qui devient le repli.
///
/// Trois états, et le choix est fait ici plutôt que chez l'appelant pour que
/// les deux fiches — pièces et accessoires — se comportent exactement pareil :
///
/// * aucune photo  → [fallback], soit l'icône que la fiche affichait déjà ;
/// * une seule     → l'image, agrandissable au toucher ;
/// * plusieurs     → les images qui défilent, avec des points de position.
class ProductGallery extends StatefulWidget {
  const ProductGallery({
    super.key,
    required this.urls,
    required this.fallback,
    this.titre,
  });

  /// Les photos, couverture en tête. Vide = aucune photo.
  final List<String> urls;

  /// Ce qu'on montre quand il n'y a rien à montrer.
  final Widget fallback;

  /// Nom de l'article, affiché en plein écran. Facultatif.
  final String? titre;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final _controleur = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _ouvrirPleinEcran(int depuis) {
    // rootNavigator : la vue plein écran doit passer par-dessus la barre
    // d'onglets du bas, pas s'insérer dedans.
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _GaleriePleinEcran(
          urls: widget.urls,
          depart: depuis,
          titre: widget.titre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return widget.fallback;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controleur,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _ouvrirPleinEcran(i),
            child: CatalogImage(
              url: widget.urls[i],
              fallback: widget.fallback,
            ),
          ),
        ),

        // Les points ne s'affichent qu'à partir de deux photos : un point seul
        // n'indique rien et laisse croire qu'il en manque.
        if (widget.urls.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.urls.length, (i) {
                final actif = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: actif ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    // Sombres, et non blanches. Le raisonnement precedent
                    // etait inverse : il disait eviter « une teinte claire,
                    // qui disparaissait sur une boite de piece blanche », et
                    // retenait le blanc. Or les photos de produit sont
                    // justement sur fond blanc presque a chaque fois — c'est
                    // la que ces points devenaient invisibles, leur seule
                    // ombre portee ne suffisant pas a les detacher.
                    //
                    // Le halo clair sous les points sombres fait le travail
                    // symetrique sur les rares photos foncees.
                    color: Colors.black.withValues(alpha: actif ? 0.70 : 0.28),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: const [
                      BoxShadow(color: Colors.white54, blurRadius: 3),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

/// La vue plein écran : une photo à la fois, zoomable, défilement latéral.
class _GaleriePleinEcran extends StatefulWidget {
  const _GaleriePleinEcran({
    required this.urls,
    required this.depart,
    this.titre,
  });

  final List<String> urls;
  final int depart;
  final String? titre;

  @override
  State<_GaleriePleinEcran> createState() => _GaleriePleinEcranState();
}

class _GaleriePleinEcranState extends State<_GaleriePleinEcran> {
  late final PageController _controleur =
      PageController(initialPage: widget.depart);
  late int _page = widget.depart;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plusieurs = widget.urls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          plusieurs ? '${_page + 1} / ${widget.urls.length}'
                    : (widget.titre ?? ''),
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: PageView.builder(
        controller: _controleur,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (_, i) => InteractiveViewer(
          // 1 à 4× : au-delà, les photos du catalogue n'ont pas la définition
          // qui justifierait le grossissement.
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: CatalogImage(
              url: widget.urls[i],
              fit: BoxFit.contain,
              fallback: const Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 64, color: Colors.white38),
              ),
              whileLoading: const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
