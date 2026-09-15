# Captures pour la fiche Play

Les fichiers `play-*.png` sont ceux à téléverser. Les `brut-*.png` sont les
captures d'émulateur d'origine, conservées pour pouvoir recomposer.

## Pourquoi une recomposition

L'écran de l'émulateur fait 1344×2992, soit un rapport de 9:20. Google Play
n'accepte qu'entre 16:9 et 9:16 : une capture brute serait refusée pour
« proportions non conformes », un motif qui ne dit pas d'où vient le problème.

Chaque capture est donc posée sur un cadre 1080×1920, sur le bleu de l'icône.
Recadrer aurait coûté le haut et le bas de l'écran — la barre de titre et la
barre de navigation, les deux repères qui permettent de comprendre ce qu'on
regarde.

## Régénérer

```bash
dart run tool/icones/bin/captures.dart docs/captures
```

Toute capture nommée `brut-*.png` déposée dans ce dossier est reprise.

## Ce qu'elles montrent

| Fichier | Écran |
|---|---|
| `play-1-accueil.png` | Le garage : échéance dépassée en rouge, pièces compatibles, bonnes affaires |
| `play-2-pieces-compatibles.png` | Les 20 pièces qui vont sur le véhicule sélectionné |
| `play-3-fiche-vehicule.png` | Fiche véhicule : prix, caractéristiques, appel et WhatsApp |
| `play-4-catalogue.png` | Catalogue filtrable — à vendre, à louer, bonne affaire, carrosserie |

## Données affichées

Ce sont les données de démonstration du seeder, plus les trois véhicules du
compte de test. **À refaire avec de vraies photos de véhicules** avant
publication : les vignettes montrent aujourd'hui un logo de marque faute
d'images, ce qui se voit.
