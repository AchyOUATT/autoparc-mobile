import 'package:flutter/material.dart';

import '../utils/lien_externe.dart';

/// L'écran qui s'interpose quand la version installée est passée sous le
/// plancher servi par l'API.
///
/// Il est volontairement sans issue. Un écran qu'on peut écarter ne remplit
/// pas son office : la version périmée continuerait d'appeler l'API, et c'est
/// précisément ce qu'on veut arrêter. Pas de barre de titre, donc pas de
/// flèche de retour ; pas de tiroir ; pas d'onglets. Le Retour système
/// lui-même est intercepté.
///
/// Son contenu tient en trois éléments : le message du serveur, un bouton, et
/// une icône. Rien d'autre — pas de « plus tard », pas de lien vers le
/// catalogue. Ajouter une sortie, quelle qu'elle soit, c'est retirer au
/// mécanisme la seule chose qu'il apporte.
class EcranMiseAJour extends StatelessWidget {
  /// Le message tel que le serveur l'a écrit. C'est lui qui explique à
  /// l'utilisateur ce qui se passe, et il est modifiable sans republier
  /// l'application — c'est tout l'intérêt de le faire venir de l'API.
  final String message;

  /// L'adresse de la fiche Play. Peut manquer : le serveur sert un contrat,
  /// pas une garantie.
  final String? urlStore;

  const EcranMiseAJour({super.key, required this.message, this.urlStore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lien = _lienDuStore();

    // canPop: false intercepte le Retour système. L'ordre de consultation est
    // le même que pour le shell (voir `_AppShellState` dans main.dart) :
    // `ModalRoute.popDisposition` consulte les PopScope avant d'appeler
    // super, donc ce canPop gagne — et comme on ne fournit aucun
    // `onPopInvokedWithResult`, le geste ne produit simplement rien. C'est
    // l'inverse du shell, qui lui propose de quitter : ici il n'y a nulle
    // part où aller.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            // Défilable, et non centré rigide : à 320 points de large avec un
            // texte à l'échelle 1,3, un message un peu long dépasse la
            // hauteur utile. Sans défilement, Flutter peindrait sa bande
            // rayée par-dessus — sur l'écran dont, par construction, on ne
            // peut pas sortir.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.system_update,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    // Désactivé plutôt que masqué quand l'adresse manque :
                    // un bouton absent laisserait un écran bloquant sans
                    // aucune commande, et donnerait à croire que
                    // l'application est cassée. Grisé, il dit qu'il y a bien
                    // quelque chose à faire, et que ce n'est pas ici.
                    onPressed: lien == null
                        ? null
                        : () => ouvrirLien(
                              context,
                              lien,
                              valeurACopier: lien.toString(),
                              ceQuiNePeutPasSOuvrir: 'la fiche de '
                                  "l'application",
                            ),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Mettre à jour'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// `Uri.tryParse` et non `Uri.parse` : une adresse mal formée côté serveur
  /// ferait lever en pleine construction du widget, et l'écran bloquant
  /// deviendrait un écran rouge.
  Uri? _lienDuStore() {
    final brut = urlStore?.trim();
    if (brut == null || brut.isEmpty) return null;

    final lien = Uri.tryParse(brut);
    return (lien == null || !lien.hasScheme) ? null : lien;
  }
}
