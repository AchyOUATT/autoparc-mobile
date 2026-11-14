import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/garage_repository.dart';
import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';
import 'add_vehicle_to_garage_page.dart';

/// Édition d'un véhicule identifié par l'URL, jamais un formulaire d'ajout.
class EditGarageVehiclePage extends ConsumerStatefulWidget {
  const EditGarageVehiclePage({
    super.key,
    required this.vehicleId,
    this.initial,
  });

  /// Identifiant lu dans l'URL. Null si le segment n'est pas un entier.
  final int? vehicleId;
  final OwnedVehicle? initial;

  @override
  ConsumerState<EditGarageVehiclePage> createState() =>
      _EditGarageVehiclePageState();
}

class _EditGarageVehiclePageState extends ConsumerState<EditGarageVehiclePage> {
  late Future<OwnedVehicle?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _retry() => setState(() => _future = _load());

  Future<OwnedVehicle?> _load() async {
    final id = widget.vehicleId;
    if (id == null) return null;

    final initial = widget.initial;
    if (initial != null && initial.id == id) return initial;

    final listed = ref.read(garageProvider).valueOrNull;
    final fromList = listed?.where((vehicle) => vehicle.id == id).firstOrNull;
    if (fromList != null) return fromList;

    try {
      return await ref.read(garageRepositoryProvider).getVehicle(id);
    } on ApiException catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<OwnedVehicle?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.garageEditVehicleTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.commonErrorGeneric, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retry,
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.garageEditVehicleTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final vehicle = snapshot.data;
        if (vehicle == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.garageEditVehicleTitle)),
            body: Center(child: Text(l10n.garageVehicleNotFound)),
          );
        }

        return AddVehicleToGaragePage(existing: vehicle);
      },
    );
  }
}
