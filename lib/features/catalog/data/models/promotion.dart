import 'package:equatable/equatable.dart';

/// Une promotion a durée limitée, telle que le serveur la rend.
///
/// ── CE QUE LE SERVEUR GARANTIT, ET CE QU'IL NE GARANTIT PAS ───────────────
///
/// Il ne rend ce bloc que pendant la FENÊTRE : passée la date de fin, il vaut
/// `null` et le prix normal reprend sa place. L'expiration n'est donc pas
/// quelque chose que l'application doive surveiller — elle lit ce qu'on lui
/// donne, et ce qu'on lui donne est déjà à jour.
///
/// Mais la page reste ouverte pendant que le temps passe. Une promotion qui
/// finit à minuit sur un écran ouvert à 23 h 58 restera affichée jusqu'au
/// prochain chargement. [finie] permet de le détecter sans appeler le serveur,
/// pour les écrans qui s'en soucient.
///
/// ── POURQUOI LA REMISE VIENT DU SERVEUR ───────────────────────────────────
///
/// Elle pourrait se recalculer ici. Elle ne doit pas : le serveur l'arrondit
/// d'une certaine façon, et deux arrondis voisins donneraient « -40 % » sur la
/// carte et « -39,9 % » sur la fiche, pour le même article.
class Promotion extends Equatable {
  /// Le prix pendant la promotion — celui que l'acheteur paie.
  final double price;

  /// Le prix habituel, celui qu'on barre.
  final double normalPrice;

  /// La remise en pourcentage, arrondie au dixième par le serveur.
  final double discountPercent;

  final DateTime? startsAt;
  final DateTime? endsAt;

  const Promotion({
    required this.price,
    required this.normalPrice,
    required this.discountPercent,
    this.startsAt,
    this.endsAt,
  });

  /// Tolérant à tout : un champ manquant ou illisible rend `null` plutôt que
  /// de faire tomber la fiche entière. Le serveur sérialise ses `decimal` en
  /// CHAÎNES — c'est la faute qui avait fait tomber le catalogue complet.
  static Promotion? fromJson(Object? json) {
    if (json is! Map) return null;

    final price = _nombre(json['price']);
    final normal = _nombre(json['normal_price']);

    if (price == null || normal == null || normal <= price) return null;

    return Promotion(
      price: price,
      normalPrice: normal,
      discountPercent: _nombre(json['discount_percent']) ?? 0,
      startsAt: _date(json['starts_at']),
      endsAt: _date(json['ends_at']),
    );
  }

  /// La promotion est-elle terminée au moment où on regarde ?
  ///
  /// Normalement jamais : le serveur ne rend ce bloc que dans la fenêtre. Mais
  /// une page ouverte traverse minuit, et il vaut mieux cesser d'annoncer une
  /// remise que la laisser vieillir à l'écran.
  bool get finie => endsAt != null && endsAt!.isBefore(DateTime.now());

  /// Ce que l'acheteur économise, en francs.
  double get economie => normalPrice - price;

  static double? _nombre(Object? valeur) =>
      valeur == null ? null : double.tryParse('$valeur');

  static DateTime? _date(Object? valeur) =>
      valeur is String ? DateTime.tryParse(valeur)?.toLocal() : null;

  @override
  List<Object?> get props => [price, normalPrice, discountPercent, endsAt];
}
