# Parcours partenaire et correction F2

Travail préparé sur `codex/partenaires-inscription-validation-2026-10-22`.
Le backend correspondant se trouve sur
`autoparc-backend:codex/catalogue-finitions-rapport-2026-10-21`.

## Parcours partenaire

Le menu « Espace partenaire » ouvre une session dédiée, distincte de la
connexion du personnel et de Firebase. Les données de cette session ne
donnent pas accès au back-office.

Le parcours comprend :

1. Inscription de l'entreprise et confirmation du mot de passe.
2. Attente de validation, lecture du statut et actualisation.
3. Après approbation, gestion des véhicules, pièces et accessoires de
   l'entreprise : création, modification, brouillons, publication et archivage.
4. Tarifs véhicule à vendre, à louer ou les deux, avec prix journalier ou
   mensuel pour la location.
5. Gestion des photos, couverture et ordre, du stock et de la disponibilité.
6. Validation des demandes par les responsables dans un écran séparé.

Les annonces partenaires conduisent à une prise de contact du vendeur.
Cette livraison ne crée pas de paiement en ligne ou de panier multivendeur.

## F2 — Édition sans ancienne classification

Le défaut F2 du rapport externe décrit la conservation d'un ancien modèle
ou d'une ancienne finition lors d'une modification partielle. Le backend
vérifie déjà la classification résultante, y compris les liens omis dans
la requête. Le formulaire mobile doit donc envoyer le retrait explicite
des dépendances qu'il a effacées.

Le formulaire du parc retrouve désormais ses références par identifiant.
Deux générations portant le même nom ne sont plus rapprochées par libellé.
Changer de marque retire le modèle précédent ; changer de modèle retire
la finition, les données moteur et les valeurs techniques dépendantes.
L'enregistrement transmet les liens retirés à `null`.

Le formulaire de création du garage applique les mêmes transitions, y compris
le passage à un modèle libre. Il reste un formulaire de création : aucun
nouvel écran d'édition de classification du garage n'est ajouté dans ce lot.

Le formulaire historique du parc utilise aussi le forfait mensuel existant
dans l'API. Il accepte le journalier seul, le mensuel seul ou les deux et
transmet explicitement la suppression d'un ancien tarif.

## État de vérification

Le contrôle des différences Git passe. Les tests de parcours, de contrats API,
de formulaires et de transitions F2 sont préparés dans `test/`.

**Les tests Flutter, l'analyse Dart, le build et les captures ne sont pas
encore exécutés.** Le SDK officiel 3.47.2 est cloné, les archives des
dépendances sont vérifiées, mais le téléchargement de Dart et du moteur sur
`storage.googleapis.com` est bloqué par la politique réseau de l'environnement.
Le domaine a été ajouté au brouillon réseau ; cette configuration doit être
appliquée avant de reprendre l'installation.

L'environnement dispose de Chromium, mais pas d'émulateur Android ni de
`/dev/kvm`. Une éventuelle capture via Flutter Web au format mobile devra
être présentée comme telle. Aucun écran fictif n'a été produit.

Le backend a sa propre validation PHP. Les résultats PHP ne prouvent pas
le bon fonctionnement de ces nouveaux écrans Flutter.
