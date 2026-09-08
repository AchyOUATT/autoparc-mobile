# Logos de marques

Déposez ici un fichier par marque, **nommé sur le slug de la table `brands`**.
Aucune table de correspondance à maintenir : l'application construit le chemin
`assets/brands/<slug>.svg` directement depuis le slug renvoyé par l'API.

Formats acceptés, dans cet ordre de priorité : `.svg`, puis `.png`.

## Les 25 fichiers attendus

```
bmw            chevrolet      citroen        daihatsu       fiat
ford           honda          hyundai        isuzu          jeep
kia            land-rover     lexus          mazda          mercedes-benz
mitsubishi     nissan         opel           peugeot        renault
ssangyong      subaru         suzuki         toyota         volkswagen
```

Pour vérifier ce qui manque :

```bash
dart run tool/check_brand_logos.dart
```

## Recommandations

- **Fond transparent.** Les logos s'affichent sur des surfaces claires comme
  sombres selon le thème.
- **Cadrage serré.** Le widget `BrandLogo` applique lui-même une marge
  constante ; un fichier avec sa propre marge intégrée paraîtra plus petit
  que les autres.
- **Proportions.** Elles sont très hétérogènes d'une marque à l'autre — un
  bandeau large pour Land Rover, un rond pour BMW. Le widget les inscrit dans
  une boîte carrée en `BoxFit.contain`, donc rien n'est déformé, mais un
  wordmark très large paraîtra visuellement plus petit qu'un badge rond.
  Préférez le monogramme au wordmark quand la marque propose les deux.

## Sources

Salles de presse des constructeurs, Wikimedia Commons, ou Simple Icons pour un
jeu monochrome homogène. Ces logos sont des marques déposées appartenant à
leurs propriétaires : ils servent ici à identifier les véhicules proposés, ne
doivent pas être modifiés, et ne sous-entendent aucun partenariat.
