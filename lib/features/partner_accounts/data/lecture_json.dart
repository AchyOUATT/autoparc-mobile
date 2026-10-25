/// Lecture tolérante du JSON de l'espace partenaire.
///
/// ── POURQUOI CE FICHIER EXISTE ────────────────────────────────────────────
///
/// Les écrans partenaire lisaient les réponses du serveur par des casts durs :
/// `account['id'] as int`, `account['phone'] as String`,
/// `(response['data'] as List)`, `(photo['id'] as num).toInt()`. Aucun repli,
/// aucun `?`. Un champ nul, absent, ou sérialisé dans un autre type ne donne
/// alors pas un message d'erreur mais un `TypeError` levé DANS le `build()` du
/// widget — c'est-à-dire un écran rouge, que `messageFor()` ne rattrape pas
/// puisqu'il ne traite que les erreurs réseau.
///
/// Ce n'est pas une inquiétude théorique : le dépôt a déjà payé cette faute.
/// `lib/core/update/version_minimale.dart` la raconte — « Laravel sérialise
/// volontiers les nombres en texte, et c'est exactement ce qui avait fait
/// tomber le catalogue entier : "2450000.00" lu comme un `num?` donnait
/// `type 'String' is not a subtype of type 'num?'` ». Les helpers `_double()`
/// de `fuel_fill.dart`, `motorisation.dart` et `owned_vehicle.dart` existent
/// tous pour la même raison.
///
/// ── POURQUOI UN FICHIER PARTAGÉ, ALORS QUE LE PROJET DUPLIQUE ─────────────
///
/// La convention du dépôt est un helper privé par fichier de modèle, et elle
/// se défend quand il y a un helper par forme de donnée. Ici il y avait SIX
/// sites de lecture risqués répartis sur TROIS fichiers de la même
/// fonctionnalité — `partner_applications_page`, `partner_listings_page` et
/// `partner_media_page`. Trois copies de plus auraient été une copie de trop.
///
/// Portée volontairement locale à la fonctionnalité : le jour où l'espace
/// partenaire parlera à des modèles typés plutôt qu'à des `Map`, ce fichier
/// disparaîtra avec eux. Il n'a pas vocation à devenir un utilitaire du cœur.
library;

/// Un entier, quelle que soit la forme reçue : `12`, `12.0`, `« 12 »`.
///
/// `int.tryParse` refuse « 12.0 », que PHP produit dès qu'une valeur a croisé
/// un cast flottant. On retombe donc sur `double.tryParse`, exactement comme
/// `_entier()` de `version_minimale.dart`.
int? entier(Object? valeur) {
  if (valeur is int) return valeur;
  if (valeur is num) return valeur.toInt();

  final texte = valeur?.toString().trim();
  if (texte == null || texte.isEmpty) return null;

  return int.tryParse(texte) ?? double.tryParse(texte)?.toInt();
}

/// Un texte, ou null. Une chaîne vide vaut une chaîne absente.
///
/// Le serveur rend `""` quand un champ facultatif n'a pas été renseigné, et
/// afficher une ligne vide vaut moins qu'afficher le repli de l'appelant.
String? texte(Object? valeur) {
  if (valeur == null) return null;
  final texte = valeur.toString().trim();
  return texte.isEmpty ? null : texte;
}

/// Une liste de `Map<String, dynamic>`, et jamais une exception.
///
/// Ce qui n'est pas une liste rend une liste VIDE, et les éléments qui ne sont
/// pas des maps sont écartés un par un. Un seul élément mal formé ne doit pas
/// faire perdre la page entière : mieux vaut une annonce manquante qu'un écran
/// rouge.
List<Map<String, dynamic>> listeDeMaps(Object? valeur) {
  if (valeur is! Iterable) return const [];

  return valeur
      .whereType<Map>()
      .map((element) => Map<String, dynamic>.from(element))
      .toList();
}

/// Une map, ou une map vide. Évite la cascade de `as Map? ?? const {}`.
Map<String, dynamic> map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : const {};
