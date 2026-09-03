/// Résultat de compatibilité d'une pièce avec un véhicule du garage.
///
/// Interprétation :
///   - compatible = true                         → ✅ Compatible
///   - compatible = false, compatibilityReady = true  → ⛔ Non compatible (données précises, pas de fitment)
///   - compatible = false, compatibilityReady = false → ⚠️ Non déterminé (données incomplètes)
class GarageCompatibility {
  final int vehicleId;
  final String displayName;
  final int year;
  final bool compatible;

  /// Vrai si le véhicule dispose d'une motorisation ou d'un code moteur permettant
  /// un matching précis. Faux = résultat incertain.
  final bool compatibilityReady;

  const GarageCompatibility({
    required this.vehicleId,
    required this.displayName,
    required this.year,
    required this.compatible,
    required this.compatibilityReady,
  });

  factory GarageCompatibility.fromJson(Map<String, dynamic> j) =>
      GarageCompatibility(
        vehicleId:          j['vehicle_id']          as int,
        displayName:        j['display_name']        as String,
        year:               j['year']                as int,
        compatible:         j['compatible']          as bool,
        compatibilityReady: j['compatibility_ready'] as bool? ?? false,
      );
}
