# Convention des traductions

Les deux catalogues contiennent **1731 clés chacun** au 7 novembre 2026, avec les mêmes identifiants et les mêmes paramètres. Le français reste la langue par défaut. Le choix français/anglais est mémorisé par l’application. La parité des clés et des paramètres est tenue par `test/l10n_parite_test.dart`, qui imprime aussi ce relevé.

## Nommage

Utiliser `<zone><Role>` en lowerCamelCase, par exemple `catalogFieldEngine`, `garageOilChangeLabel` ou `privateSalesPublish`. La zone correspond à la fonctionnalité ; le rôle décrit l’usage. Conserver les identifiants existants. La clé historique `partageMentionBoutique` reste une exception.

Les textes de l’interface sont dans `app_fr.arb` et `app_en.arb`. Ajouter les paramètres dans les métadonnées du catalogue français, utiliser les pluriels ICU pour les quantités, puis régénérer avec `flutter gen-l10n`. Les fichiers Dart générés sont versionnés.

## Inventaire

| Zone | Clés |
|---|---:|
| catalog | 420 |
| garage | 317 |
| vehicles | 257 |
| partnerAccounts | 186 |
| privateSales | 119 |
| needs | 82 |
| inspection | 51 |
| auth | 37 |
| partners | 32 |
| shell | 30 |
| faultDeclaration | 28 |
| cart | 26 |
| home | 26 |
| common | 24 |
| notifications | 19 |
| partnerDashboard | 18 |
| onboarding | 17 |
| passwordRecovery | 16 |
| media | 12 |
| settings | 10 |
| update | 3 |
| partage | 1 |
| **Total** | **1731** |

## Références et données du serveur

Les cartes d’articles, les fiches détaillées, les formulaires, le garage, les espaces partenaire et personnel lisent la langue active. Les caractéristiques contrôlées (carburant, roues motrices, couleur, pays, catégories de pièces et équipements) utilisent leurs codes stables ou un rapprochement exact avec les références livrées. Les valeurs inconnues restent lisibles telles quelles. Les anciens caches et les réponses sans nouveaux codes restent acceptés.

Les noms de marques, modèles et finitions, les descriptions des vendeurs, les notes, les raisons de modération et les diffusions manuelles sont conservés dans leur langue d’origine. Les libellés calculés de consommation sont composés à partir des codes et nombres, sans modifier les valeurs stockées.

Chaque appel API transmet `Accept-Language: fr` ou `en`. Le serveur négocie aussi les variantes régionales et les priorités HTTP, retourne `Content-Language` et `Vary: Accept-Language`, et garde le français si le client ne choisit aucune langue prise en charge. Les erreurs, validations, contrôles du garage et notifications automatiques sont traduits au moment de la réponse ou de la livraison ; aucun contenu utilisateur n’est réécrit. Les notifications push utilisent la langue enregistrée pour chaque appareil.

Le backend nécessite la migration `2026_10_30_000001_add_locale_to_client_fcm_tokens` avant livraison des nouveaux envois FCM. Les anciennes applications continuent de fonctionner en français. Une nouvelle version mobile est nécessaire pour disposer de tous les écrans anglais.

## Vérification

Les tests de widgets doivent nommer explicitement leur locale et installer les délégués d’`AppLocalizations`. Les coques françaises existantes restent françaises. Les tests anglais couvrent les références des cartes et fiches, la conservation des contenus libres, le parcours particulier, le garage, les espaces partenaire/personnel, les erreurs et la propagation de la langue vers l’API. Les tests HTTP vérifient aussi les réponses localisées et les livraisons FCM simulées.

Les nouvelles références de consommation conservent leur niveau de correspondance, leur méthode et leur provenance. Le code hybride `H` ne prouve pas que le véhicule est rechargeable ; le protocole cinq cycles ne prouve pas un nouvel essai. La mesure sur les pleins utilise une clé distincte de la référence. Le formulaire de contact distant et les obstacles à l’envoi d’une annonce suivent également la langue active.
