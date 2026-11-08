import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../catalog/data/models/vehicle.dart';
import 'rental_vehicle_register_page.dart';
import 'vehicle_form_mode.dart';
import 'vehicle_register_page.dart';
import 'equipment_register_page.dart';

enum _RegistrationPurpose { sale, rental }

enum _AssetFamily { roadVehicle, equipment }

/// Keeps both registration paths in the caller's route so its save result is
/// returned to the catalogue or partner inventory that opened it.
class VehicleRegistrationPage extends StatefulWidget {
  const VehicleRegistrationPage({
    super.key,
    this.existing,
    this.mode = VehicleFormMode.personnel,
  });

  final Vehicle? existing;
  final VehicleFormMode mode;

  @override
  State<VehicleRegistrationPage> createState() =>
      _VehicleRegistrationPageState();
}

class _VehicleRegistrationPageState extends State<VehicleRegistrationPage> {
  _RegistrationPurpose? _purpose;
  _AssetFamily? _family;

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    if (existing != null) {
      if (existing.isEquipment) {
        return EquipmentRegisterPage(existing: existing, mode: widget.mode);
      }
      if (existing.commercial.availability == 'rent') {
        return RentalVehicleRegisterPage(existing: existing, mode: widget.mode);
      }
      return VehicleRegisterPage(
        existing: existing,
        mode: widget.mode,
        // A historical mixed offer retains both sets of prices when edited.
        saleOnly: existing.commercial.availability != 'both',
      );
    }

    if (_purpose != null && _family == null) return _chooseFamily(context);
    if (_family == _AssetFamily.equipment) {
      return EquipmentRegisterPage(
        mode: widget.mode,
        initialAvailability: _purpose == _RegistrationPurpose.sale
            ? 'sale'
            : 'rent',
      );
    }
    switch (_purpose) {
      case _RegistrationPurpose.sale:
        return VehicleRegisterPage(mode: widget.mode, saleOnly: true);
      case _RegistrationPurpose.rental:
        return RentalVehicleRegisterPage(mode: widget.mode);
      case null:
        break;
    }

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('vehicle-registration-choice'),
      appBar: AppBar(title: Text(l10n.vehicleRegistrationEntryTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l10n.vehicleRegistrationChoosePurpose,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _PurposeCard(
                key: const ValueKey('vehicle-registration-rental'),
                icon: Icons.key_outlined,
                title: l10n.vehicleRegistrationRentalTitle,
                description: l10n.vehicleRegistrationRentalHelp,
                onTap: () =>
                    setState(() => _purpose = _RegistrationPurpose.rental),
              ),
              const SizedBox(height: 16),
              _PurposeCard(
                key: const ValueKey('vehicle-registration-sale'),
                icon: Icons.sell_outlined,
                title: l10n.vehicleRegistrationSaleTitle,
                description: l10n.vehicleRegistrationSaleHelp,
                onTap: () =>
                    setState(() => _purpose = _RegistrationPurpose.sale),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chooseFamily(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('vehicle-registration-family'),
      appBar: AppBar(
        title: Text(l10n.vehicleRegistrationEntryTitle),
        leading: BackButton(onPressed: () => setState(() => _purpose = null)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l10n.vehicleRegistrationFamilyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _PurposeCard(
                key: const ValueKey('vehicle-registration-road'),
                icon: Icons.directions_car_outlined,
                title: l10n.vehicleRegistrationRoadTitle,
                description: l10n.vehicleRegistrationRoadHelp,
                onTap: () => setState(() => _family = _AssetFamily.roadVehicle),
              ),
              const SizedBox(height: 16),
              _PurposeCard(
                key: const ValueKey('vehicle-registration-equipment'),
                icon: Icons.agriculture_outlined,
                title: l10n.vehicleRegistrationEquipmentTitle,
                description: l10n.vehicleRegistrationEquipmentHelp,
                onTap: () => setState(() => _family = _AssetFamily.equipment),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurposeCard extends StatelessWidget {
  const _PurposeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(description),
            ],
          ),
        ),
      ),
    ),
  );
}
