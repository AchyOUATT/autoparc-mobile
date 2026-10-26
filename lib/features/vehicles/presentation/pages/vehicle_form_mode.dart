/// Pour qui ce formulaire de véhicule est ouvert.
///
/// ── POURQUOI UN MODE, ET NON UN SECOND FORMULAIRE ──────────────────────────
///
/// L'espace partenaire avait le sien : 441 lignes contre 1521, et neuf champs
/// que le personnel renseignait sans que le partenaire puisse même les voir.
/// L'écart n'était pas une décision, c'était une dérive — deux écrans écrits
/// séparément, pour deux publics, que rien ne tenait synchronisés. Chaque
/// question ajoutée d'un côté creusait le fossé de l'autre.
///
/// Dupliquer l'écran du personnel l'aurait recreusé aussitôt. Un seul
/// formulaire, deux modes : une question ajoutée profite aux deux, ou elle est
/// explicitement refusée à l'un des deux — et ce refus se lit ici.
///
/// ── CE QUI DIFFERE REELLEMENT, APRES MESURE ───────────────────────────────
///
/// Beaucoup moins qu'on ne le croirait. Le formulaire du personnel n'envoie
/// NI `purchase_price`, NI `status`, NI `reference` : rien du prix d'achat ni
/// de la gestion de parc n'y figure. Et `/catalog/sync` est une route
/// PUBLIQUE, donc les deux espaces lisent déjà les mêmes références sans rien
/// abstraire.
///
/// Il ne reste que trois champs, et c'est le SERVEUR qui les refuse, par
/// `missing` dans `App\Http\Requests\Partner\AuthorizesPartnerCatalog` :
///
///   `deal_type`   — un partenaire se plaçait lui-même dans les promotions de
///                   la boutique, `?deal=1` les remontant toutes.
///   `location_id` — l'agence est une adresse de la boutique.
///   `partner_id`  — le fournisseur source, que seule la boutique renseigne ;
///                   un partenaire n'a pas à rattacher son véhicule à un tiers.
///
/// Les envoyer vaudrait 422 : ils sont donc retirés de la charge ET de
/// l'écran. Montrer un champ qu'on ne peut pas enregistrer serait pire que ne
/// pas le montrer.
enum VehicleFormMode {
  /// Le back-office. Tout est ouvert.
  personnel,

  /// L'espace partenaire. Les trois champs de la boutique sont fermés.
  partenaire;

  /// Les champs que seule la boutique renseigne.
  ///
  /// Un seul drapeau pour les trois, parce qu'ils tombent ensemble et pour la
  /// même raison : ils décrivent la boutique, pas le véhicule.
  bool get peutChoisirLaBoutique => this == VehicleFormMode.personnel;

  bool get estPartenaire => this == VehicleFormMode.partenaire;
}
