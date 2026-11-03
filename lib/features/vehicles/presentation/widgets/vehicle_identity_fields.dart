import '../../../../core/l10n/reference_labels.dart';
import '../../../../core/l10n/transmission_labels.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
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
          label: l10n.privateSalesBrandRequiredLabel,
          items: refs.brands
              .where((entry) => entry.isActive || entry.id == brand?.id)
              .toList(),
          value: brand,
          itemLabel: (entry) => entry.name,
          enabled: enabled,
          validator: (value) =>
              value == null ? l10n.privateSalesBrandRequiredError : null,
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
            label: l10n.privateSalesModelRequiredLabel,
            items: models,
            value: model,
            itemLabel: (entry) => referenceModelDisplayName(entry, l10n),
            enabled: enabled && brand != null,
            validator: (value) =>
                value == null ? l10n.privateSalesModelSelectionError : null,
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
            decoration: InputDecoration(
              labelText: l10n.privateSalesModelRequiredLabel,
              hintText: l10n.privateSalesFreeModelHint,
            ),
            maxLength: 80,
            onChanged: (_) => onChanged(),
            validator: (value) => value == null || value.trim().isEmpty
                ? l10n.privateSalesFreeModelRequired
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
                  ? l10n.privateSalesModelListAction
                  : l10n.privateSalesFreeModelAction,
            ),
          ),
        ),
        TextFormField(
          key: const ValueKey('private-sale-year'),
          controller: yearController,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: l10n.privateSalesManufactureYearLabel,
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
                ? l10n.privateSalesManufactureYearInvalid
                : null;
          },
        ),
        if (model != null && year != null && !model.couvreAnnee(year))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.privateSalesGenerationWarning(referenceModelYears(model, l10n) ?? ''),
            ),
          ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('private-sale-mileage'),
          controller: mileageController,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: l10n.catalogFieldMileage,
            prefixIcon: Icon(Icons.speed),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onChanged(),
          validator: (value) {
            final parsed = int.tryParse(value?.trim() ?? '');
            return parsed == null || parsed < 0 || parsed > 3000000
                ? l10n.privateSalesMileageInvalid
                : null;
          },
        ),
        const SizedBox(height: 12),
        if (trims.isNotEmpty) ...[
          VehicleReferenceDropdown<TrimRef>(
            key: ValueKey('private-sale-trim-${model?.id}'),
            label: l10n.catalogFieldTrim,
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
            _clear(l10n.privateSalesClearTrim, () {
              selection.trim = null;
              onChanged();
            }),
          const SizedBox(height: 12),
        ],
        VehicleReferenceDropdown<EngineTypeRef>(
          key: ValueKey('private-sale-engine-${model?.id}-$freeModel'),
          label: l10n.privateSalesFuel,
          items: refs.engineTypes,
          value: selection.engineType,
          itemLabel: (entry) => referenceFuelLabel(entry.code, entry.label, l10n),
          enabled: enabled,
          onChanged: (value) {
            selection.engineType = value;
            onChanged();
          },
        ),
        if (selection.engineType != null)
          _clear(l10n.privateSalesClearFuel, () {
            selection.engineType = null;
            onChanged();
          }),
        const SizedBox(height: 12),
        VehicleReferenceDropdown<DrivetrainRef>(
          key: ValueKey('private-sale-drivetrain-${model?.id}-$freeModel'),
          label: l10n.privateSalesDrivetrain,
          items: refs.drivetrains,
          value: selection.drivetrain,
          itemLabel: (entry) => referenceDrivetrainLabel(entry.code, entry.label, l10n),
          enabled: enabled,
          onChanged: (value) {
            selection.drivetrain = value;
            onChanged();
          },
        ),
        if (selection.drivetrain != null)
          _clear(l10n.privateSalesClearDrivetrain, () {
            selection.drivetrain = null;
            onChanged();
          }),
        const SizedBox(height: 12),
        VehicleReferenceDropdown<ColorRef>(
          label: l10n.catalogFieldColour,
          items: refs.colors,
          value: color,
          itemLabel: (entry) => referenceColourLabel(entry.name, l10n),
          enabled: enabled,
          onChanged: onColorChanged,
        ),
        if (color != null)
          _clear(l10n.privateSalesClearColour, () => onColorChanged(null)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('private-sale-transmission-${transmission ?? 'none'}'),
          initialValue: transmission,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.privateSalesTransmissionOptional,
          ),
          items: vehicleTransmissionCodes
              .map((code) => DropdownMenuItem(
                value: code,
                child: Text(transmissionLabel(code, l10n)),
              ))
              .toList(),
          onChanged: enabled ? onTransmissionChanged : null,
        ),
        if (transmission != null)
          _clear(
            l10n.privateSalesClearTransmission,
            () => onTransmissionChanged(null),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _clear(String label, VoidCallback action) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(onPressed: enabled ? action : null, child: Text(label)),
  );
}
