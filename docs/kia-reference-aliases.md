# Noms commerciaux des modèles selon le marché

Le référentiel `/catalog/sync` peut fournir un tableau facultatif `aliases`
sur chaque modèle/génération. L'application affiche par exemple
`Cerato / Forte (BD, depuis 2018)` en français, ou
`Cerato / Forte (BD, since 2018)` en anglais.

Les formulaires d'enregistrement staff et partenaire, le formulaire de vente
particulière, les choix du garage et les sélecteurs de compatibilité utilisent
ces mêmes libellés. La sélection conserve l'identifiant et le nom canonique
du modèle : un autre nom commercial ne crée pas une seconde génération.

Le serveur décide des noms applicables à chaque génération. Aucun nom KIA
n'est codé en dur dans le client. Un alias ne fournit ni moteur, ni boîte,
ni consommation, ni preuve de compatibilité entre pièces.

Le champ absent, nul ou de type incorrect est ignoré. Les éléments non textuels,
les chaînes vides, les doublons sans égard à la casse et le nom canonique
répété sont ignorés. Le cache conserve le JSON brut ; un delta remplace la
ligne de même ID, puis le même parseur s'applique en ligne et hors ligne.

Validation : tests des anciens et nouveaux formats API, libellés FR/EN,
sélection du même ID par le nom régional, synchronisation complète,
delta et repli hors ligne.
