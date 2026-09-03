import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/catalog_refs.dart';
import '../../data/vehicle_admin_repository.dart';

/// Toutes les tables de référence (brands, models, engine types…)
/// — chargées une seule fois au lancement du formulaire.
final catalogRefsProvider = FutureProvider<CatalogRefs>((ref) {
  return ref.read(vehicleAdminRepositoryProvider).loadRefs();
});

/// Liste des pays pour les sélecteurs d'origine / immatriculation.
final countriesProvider = FutureProvider<List<CountryRef>>((ref) {
  return ref.read(vehicleAdminRepositoryProvider).loadCountries();
});
