# Icônes de l'application

Ces fichiers sont **générés**. Ne pas les retoucher à la main : modifier le logo
source, puis régénérer.

```bash
dart run tool/icones/bin/icone.dart assets/icon/logo_source.png assets/icon
dart run flutter_launcher_icons
```

La première commande prépare les sources, la seconde les décline en toutes les
densités Android et iOS, d'après [`flutter_launcher_icons.yaml`](../../flutter_launcher_icons.yaml).

## Pourquoi un script plutôt que le logo tel quel

Le logo d'origine (`logo_source.png`) porte son propre cadre arrondi, avec un
reflet de verre en haut à gauche. Android et iOS appliquent **leur** masque
par-dessus :

- iOS arrondit le carré qu'on lui donne — l'arrondi dessiné plus le sien
  produisent un double encadrement, et les coins du fond dépassent ;
- Android découpe selon le lanceur un cercle, un carré arrondi ou une goutte, et
  ne garantit que les **66 % centraux**. L'engrenage et la clé, qui touchent
  presque le cadre, en sortiraient rognés.

Le script détoure donc l'emblème seul et le recompose aux bonnes proportions.
Le détourage distingue l'emblème du fond par la **dominante bleue** plutôt que
par la clarté : décrit comme « argenté donc lumineux », le métal à l'ombre
passait pour du fond et l'engrenage ressortait rongé, la calandre et les phares
creux.

## Fichiers produits

| Fichier | Usage |
|---|---|
| `app_icon.png` | 1024², plein cadre — iOS et ancien format Android |
| `app_icon_foreground.png` | 1024², transparent — calque avant de l'icône adaptative |
| `app_icon_ardoise.png` | variante sur le bleu de l'application, non utilisée |
| `embleme.png` | emblème seul, fond transparent — web, documents |
| `play_icone_512.png` | icône de la fiche Play (512², opaque, sans coins arrondis) |
| `play_banniere_1024x500.png` | bandeau de la fiche Play (dimensions imposées) |

Le bandeau laisse sa moitié droite vide : Play y superpose parfois le nom de
l'application et le bouton d'installation. Il n'y a pas de texte dessus — à
ajouter si tu en veux, avec un outil graphique.

## Deux fonds

Le fond retenu est le bleu roi du logo (`#0B4A9E`). L'application, elle, part
d'un bleu ardoise plus doux (`#1F6587` sur la barre de navigation) : il y a donc
un léger décrochage entre l'icône et le premier écran.

`app_icon_ardoise.png` est la même composition sur le bleu de l'application.
Elle n'est pas retenue parce que l'ombre portée du dessin, d'un marine soutenu,
a été faite pour le bleu roi : sur un fond plus clair elle ressort comme un
liseré sale. Passer à cette variante demanderait de retoucher l'ombre dans le
logo source.
