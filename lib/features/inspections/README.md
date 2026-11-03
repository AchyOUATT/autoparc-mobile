# Inspections du personnel AutoParc

`StaffInspectionBadge` affiche le bouclier avec coche et le libellé localisé
« Inspecté par AutoParc ». Les points à prévoir ou bloquants restent visibles sur
la carte. Un appui ouvre le rapport daté, son kilométrage et les points contrôlés.
Un résumé absent, invalide ou expiré ne produit aucun badge.

`StaffInspectionSection` ajoute la création, le remplacement et le retrait motivé
pour les administrateurs, responsables et mécaniciens. La permission est aussi
vérifiée par l’API. Les autres utilisateurs consultent uniquement le rapport
public ; la publication d’une annonce et les contrôles du garage personnel ne
créent pas d’inspection.

Les cibles gardent leurs identifiants natifs : `source` vaut `vehicle` ou
`private_listing`, et `sourceId` est numérique. Les rapports publics passent par
`/catalog/vehicle-inspections/{id}`. La gestion et l’historique utilisent
`/vehicle-inspections/{source}/{sourceId}` et
`/vehicle-inspections/{id}/withdraw`. Une cible non publiée utilise son historique
authentifié pour consulter le rapport. Les noms du personnel ne font pas partie
du modèle public ni de son affichage.

Le formulaire exige un kilométrage, un résumé, au moins un point effectivement
contrôlé et la confirmation d’un contrôle physique. Une date de fin reste
facultative. Le résultat et les compteurs viennent du serveur. `onChanged`
rafraîchit le catalogue après une création ou un retrait ; l’état de la section
est aussi actualisé immédiatement.

Les cartes du catalogue, des annonces privées publiques et de la vitrine
d’accueil affichent le badge. Les fiches permettent de consulter le rapport et,
selon le rôle, de le gérer. Les coordonnées publiques des particuliers restent
celles d’AutoParc.

Vérifications : `staff_inspection_module_test.dart`,
`staff_inspection_catalog_test.dart`, `staff_inspection_card_surfaces_test.dart`
et `auth_capabilities_test.dart`. Les libellés sont présents en français et en
anglais dans les ARB et leurs fichiers générés.

Déployer l’API avec sa migration `2026_11_02_000002` avant cette version mobile.
