import 'package:equatable/equatable.dart';

/// Le résumé des véhicules compatibles, tel que l'API le rend pour une CARTE.
///
/// ── POURQUOI UNE SEULE CLASSE POUR LES PIÈCES ET LES ACCESSOIRES ────────────
///
/// Le serveur rend exactement la même structure sur les deux ressources, par
/// deux méthodes jumelles — `PartResource::resumeCompatibilite` et
/// `AccessoryResource::resumeCompatibilite` — dont le commentaire dit
/// pourquoi : « les deux cartes du catalogue affichent la même ligne, et deux
/// résumés différents se seraient mis à diverger ». Deux classes Dart auraient
/// rouvert ici la divergence que le serveur a fermée là-bas.
///
/// ── `count` N'EST PAS `vehicles.length`, ET C'EST TOUT L'INTÉRÊT ────────────
///
/// `vehicles` est PLAFONNÉ À TROIS côté serveur, pour le poids de la réponse :
/// une page de catalogue porte vingt articles, et un accessoire universel peut
/// déclarer des dizaines de modèles. `count` est le total réel, après
/// déduplication — un même modèle revient autant de fois qu'il a reçu de
/// moteurs, et le serveur l'écarte avant de compter.
///
/// La carte a donc besoin des deux : les noms pour dire LESQUELS, le compte
/// pour dire COMBIEN RESTENT. Confondre les deux ferait écrire « +0 » sur un
/// article compatible avec douze modèles.
class CompatibilitySummary extends Equatable {
  /// Le nombre TOTAL de modèles compatibles, doublons écartés.
  final int count;

  /// Les premiers noms, au plus trois — « Corolla », « Tucson », « Rio ».
  ///
  /// LE MODÈLE SEUL, SANS LA MARQUE, depuis que le propriétaire l'a tranché
  /// sur la première mesure : à « Toyota Corolla », les trois noms ne
  /// tenaient sur la carte que dans 3 cases sur 12 et la ligne montrait
  /// surtout son « +N ». Le serveur compose maintenant
  /// `vehicleModel?->name`, et il porte sur place le risque assumé — deux
  /// marques pourraient nommer un modèle pareillement, et la déduplication
  /// les confondrait, [count] comprise.
  ///
  /// Jamais `null` : une liste vide dit « aucun nom », ce qui est vrai quand la
  /// pièce n'a aucune compatibilité déclarée. L'absence d'information, elle, se
  /// dit par un `compatibility` nul sur le modèle porteur.
  final List<String> vehicles;

  const CompatibilitySummary({required this.count, this.vehicles = const []});

  factory CompatibilitySummary.fromJson(Map<String, dynamic> json) =>
      CompatibilitySummary(
        // Tolérant sur le type, comme `PartStock.quantity` juste à côté et pour
        // la même raison : Laravel ne rafraîchit pas le modèle après `create()`
        // et un champ absent de la requête ressort `null`, où un cast sec lève
        // un `_TypeError` que ni `ApiException` ni `DioException` n'attrapent.
        count: (json['count'] as num?)?.toInt() ?? 0,
        vehicles:
            (json['vehicles'] as List?)
                ?.map((v) => (v as String?) ?? '')
                // Un nom vide vient d'un fitment dont le modèle a perdu sa
                // marque : le serveur `trim()`e la concaténation et le filtre,
                // mais il le filtre AVANT de compter, donc un vide qui
                // arriverait ici fausserait le « +N ». On le refuse des deux
                // côtés.
                .where((v) => v.isNotEmpty)
                .toList(growable: false) ??
            const [],
      );

  /// Vrai quand il n'y a rien à afficher du tout.
  ///
  /// Les DEUX conditions, et pas seulement la liste : un `count` à zéro avec
  /// une liste vide est le cas normal d'un article sans compatibilité
  /// déclarée, et la ligne doit alors DISPARAÎTRE — pas afficher un séparateur
  /// orphelin ni un « +0 ».
  bool get estVide => vehicles.isEmpty || count == 0;

  @override
  List<Object?> get props => [count, vehicles];
}
