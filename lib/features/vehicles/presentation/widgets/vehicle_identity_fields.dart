import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/catalog_refs.dart';
import '../../data/models/vehicle_classification_selection.dart';
import 'vehicle_reference_dropdown.dart';

/// Vehicle identity uses the same selectors and dependency transitions as registration.
/// Submission stays with the caller, so this widget cannot create stock or publish a listing.
class VehicleIdentityFields extends StatelessWidget {
  const VehicleIdentityFields({
    super.key,
    required this.refs,
    required this.selection,
    required this.yearController,
    required this.mileageController,
    required this.freeModelController,
    required this.freeModel,
    required this.onFreeModelChanged,
    required this.onChanged,
    required this.onModelChanged,
    required this.color,
    required this.onColorChanged,
    required this.transmission,
    required this.onTransmissionChanged,
    this.enabled = true,
  });

  final CatalogRefs refs;
  final VehicleClassificationSelection selection;
  final TextEditingController yearController,
      mileageController,
      freeModelController;
  final bool freeModel, enabled;
  final ValueChanged<bool> onFreeModelChanged;
  final VoidCallback onChanged, onModelChanged;
  final ColorRef? color;
  final ValueChanged<ColorRef?> onColorChanged;
  final String? transmission;
  final ValueChanged<String?> onTransmissionChanged;

  @override
  Widget build(BuildContext context) {
    final brand = selection.brand;
    final model = selection.model;
    final models = brand == null ? <ModelRef>[] : refs.modelsForBrand(brand.id);
    // An inactive saved generation stays selectable for this record only.
    if (model != null &&
        model.brandId == brand?.id &&
        !models.any((entry) => entry.id == model.id)) {
      models.add(model);
    }
    final trims = model == null ? <TrimRef>[] : refs.trimsForModel(model.id);
    final year = int.tryParse(yearController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VehicleReferenceDropdown<BrandRef>(
          key: const ValueKey('private-sale-brand'),
          label: 'Marque *',
          items: refs.brands
              .where((entry) => entry.isActive || entry.id == brand?.id)
              .toList(),
          value: brand,
          itemLabel: (entry) => entry.name,
          enabled: enabled,
          validator: (value) => value == null ? 'Marque obligatoire' : null,
          onChanged: (value) {
            if (value?.id == brand?.id) return;
            selection.selectBrand(value);
            freeModelController.clear();
            onFreeModelChanged(false);
            onModelChanged();
          },
        ),
        const SizedBox(height: 12),
        if (!freeModel)
          VehicleReferenceDropdown<ModelRef>(
            key: ValueKey('private-sale-model-${brand?.id}'),
            label: 'Modèle *',
            items: models,
            value: model,
            itemLabel: (entry) => entry.displayName,
            enabled: enabled && brand != null,
            validator: (value) => value == null
                ? 'Sélectionnez un modèle ou saisissez le vôtre.'
                : null,
            onChanged: (value) {
              if (value?.id == model?.id) return;
              selection.selectModel(value);
              onModelChanged();
            },
          ),
        if (freeModel)
          TextFormField(
            key: const ValueKey('private-sale-model-libre'),
            controller: freeModelController,
            enabled: enabled && brand != null,
            decoration: const InputDecoration(
              labelText: 'Modèle *',
              hintText: 'Saisissez le nom de votre modèle',
            ),
            maxLength: 80,
            onChanged: (_) => onChanged(),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Renseignez le modèle.'
                : null,
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: !enabled || brand == null
                ? null
                : () {
                    selection.selectModel(null);
                    selection.clearModelDetails();
                    freeModelController.clear();
                    onFreeModelChanged(!freeModel);
                    onModelChanged();
                  },
            icon: Icon(
              freeModel ? Icons.list_alt : Icons.edit_outlined,
              size: 18,
            ),
            label: Text(
              freeModel
                  ? 'Revenir à la liste des modèles'
                  : 'Mon modèle n’est pas dans la liste',
            ),
          ),
        ),
        TextFormField(
          key: const ValueKey('private-sale-year'),
          controller: yearController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Année de fabrication *',
            prefixIcon: Icon(Icons.calendar_today),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          onChanged: (_) => onChanged(),
          validator: (value) {
            final parsed = int.tryParse(value?.trim() ?? '');
            return parsed == null ||
                    parsed < 1900 ||
                    parsed > DateTime.now().year + 1
                ? 'Vérifiez l’année de fabrication.'
                : null;
          },
        ),
        if (model != null && year != null && !model.couvreAnnee(year))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Cette génération est indiquée ${model.yearsLabel ?? ''}. Vérifiez le modèle et l’année.',
            ),
          ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('private-sale-mileage'),
          controller: mileageController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Kilométrage',
            prefixIcon: Icon(Icons.speed),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onChanged(),
          validator: (value) {
            final parsed = int.tryParse(value?.trim() ?? '');
            return parsed == null || parsed < 0 || parsed > 3000000
                ? 'Saisissez un kilométrage valide.'
                : null;
          },
        ),
        const SizedBox(height: 12),
        if (trims.isNotEmpty) ...[
          VehicleReferenceDropdown<TrimRef>(
            key: ValueKey('private-sale-trim-${model?.id}'),
            label: 'Finition',
            items: trims,
            value: selection.trim,
            itemLabel: (entry) => entry.name,
            enabled: enabled,
            onChanged: (value) {
              selection.trim = value;
              onChanged();
            },
          ),
          if (selection.trim != null)
            _clear('Effacer la finition', () {
              selection.trim = null;
              onChanged();
            }),
          const SizedBox(height: 12),
        ],
        VehicleReferenceDropdown<EngineTypeRef>(
          key: ValueKey('private-sale-engine-${model?.id}-$freeModel'),
          label: 'Carburant',
          items: refs.engineTypes,
          value: selection.engineType,
          itemLabel: (entry) => entry.label,
          enabled: enabled,
          onChanged: (value) {
            selection.engineType = value;
            onChanged();
          },
        ),
        if (selection.engineType != null)
          _clear('Effacer le carburant', () {
            selection.engineType = null;
            onChanged();
          }),
        const SizedBox(height: 12),
        VehicleReferenceDropdown<DrivetrainRef>(
          key: ValueKey('private-sale-drivetrain-${model?.id}-$freeModel'),
          label: 'Motricité',
          items: refs.drivetrains,
          value: selection.drivetrain,
          itemLabel: (entry) => entry.label,
          enabled: enabled,
          onChanged: (value) {
            selection.drivetrain = value;
            onChanged();
          },
        ),
        if (selection.drivetrain != null)
          _clear('Effacer la motricité', () {
            selection.drivetrain = null;
            onChanged();
          }),
        const SizedBox(height: 12),
        VehicleReferenceDropdown<ColorRef>(
          label: 'Couleur',
          items: refs.colors,
          value: color,
          itemLabel: (entry) => entry.name,
          enabled: enabled,
          onChanged: onColorChanged,
        ),
        if (color != null)
          _clear('Effacer la couleur', () => onColorChanged(null)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('private-sale-transmission-${transmission ?? 'none'}'),
          initialValue: transmission,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Boîte (facultatif)'),
          items: const [
            DropdownMenuItem(value: 'manual', child: Text('Manuelle')),
            DropdownMenuItem(value: 'automatic', child: Text('Automatique')),
            DropdownMenuItem(value: 'cvt', child: Text('CVT')),
            DropdownMenuItem(
              value: 'dual_clutch',
              child: Text('Double embrayage'),
            ),
            DropdownMenuItem(
              value: 'single_speed',
              child: Text('Rapport unique'),
            ),
          ],
          onChanged: enabled ? onTransmissionChanged : null,
        ),
        if (transmission != null)
          _clear('Effacer la boîte', () => onTransmissionChanged(null)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _clear(String label, VoidCallback action) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(onPressed: enabled ? action : null, child: Text(label)),
  );
}
