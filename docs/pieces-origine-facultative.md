# Pièces sans origine : transition compatible

Cette app ne demande et n'envoie plus le champ Type dans les formulaires de
pièces. L'état reste demandé; l'origine historique d'une pièce modifiée est
préservée par omission du champ.

Déployer d'abord le backend de la PR #10 avec sa migration et la négociation
de représentation. Les clients HTTP public/staff et partenaire envoient
`X-AutoParc-Capabilities: nullable-part-type` pour accepter `type: null`.
Le modèle accepte aussi la sentinelle `unknown` d'une réponse ancienne et la
traite comme une origine non renseignée, sans badge d'origine.

Les installations précédentes reçoivent du backend une chaîne non vide
`unknown` à la place du null, sans inventer une origine dans la base. Elles
continuent à lire le catalogue et les pièces compatibles. Leurs anciens
formulaires restent ceux de leur version; seule la nouvelle app retire Type.
Les valeurs connues (`oem`, `oes`, `aftermarket`, `salvage`) restent inchangées.

Le backend ajoute Vary sur l'en-tête de capacité. Cet en-tête ne confère aucun
droit et ne remplace ni les sessions ni les contrôles de propriété.
