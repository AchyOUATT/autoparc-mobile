import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../vehicles/presentation/widgets/equipment_details_section.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/presentation/providers/catalog_providers.dart';
import '../../garage/data/models/owned_vehicle.dart';

/// Brouillon d'un besoin, prérempli depuis une page de recherche.
///
/// Les types acceptés par le serveur et le formulaire sont seulement
/// `vehicle`, `part` et `accessory`. Une recherche de location ou d'engin
/// reste donc un besoin « véhicule », et le contexte (location, engin, ville,
/// texte cherché, véhicule du garage) passe dans la description.
class NeedDraft {
  static const types = {'vehicle', 'part', 'accessory'};

  final String type;
  final String? description;
  final int? brandId;
  final int? vehicleModelId;
  final String? bodyStyle;
  final int? yearMin;
  final int? yearMax;
  final int? partCategoryId;
  final String? accessoryCategory;
  final String? oemNumber;
  final int? needManufacturerId;
  final double? budgetMax;

  const NeedDraft({
    required this.type,
    this.description,
    this.brandId,
    this.vehicleModelId,
    this.bodyStyle,
    this.yearMin,
    this.yearMax,
    this.partCategoryId,
    this.accessoryCategory,
    this.oemNumber,
    this.needManufacturerId,
    this.budgetMax,
  });

  factory NeedDraft.fromQuery(Map<String, String> params) {
    final raw = params['type'] ?? 'vehicle';
    return NeedDraft(type: types.contains(raw) ? raw : 'vehicle');
  }

  factory NeedDraft.fromVehicleFilter(
    VehicleFilter filter,
    AppLocalizations l10n,
  ) {
    final lignes = <String>[
      if (filter.availability == 'rent') l10n.catalogNeedDraftRent,
      if (filter.assetKind == 'equipment') l10n.catalogNeedDraftEquipment,
      if (filter.equipmentType != null)
        equipmentTypeLabel(filter.equipmentType, l10n),
      if (filter.search?.trim().isNotEmpty == true)
        l10n.catalogNeedDraftSearch(filter.search!.trim()),
      if (filter.city?.trim().isNotEmpty == true)
        l10n.catalogNeedDraftCity(filter.city!.trim()),
    ];
    return NeedDraft(
      type: 'vehicle',
      description: lignes.isEmpty ? null : lignes.join('\n'),
      bodyStyle: filter.bodyStyle,
      yearMin: filter.yearMin,
      yearMax: filter.yearMax,
      budgetMax: filter.priceMax,
    );
  }

  factory NeedDraft.fromPartFilter(
    PartFilter filter,
    AppLocalizations l10n, {
    OwnedVehicle? garageVehicle,
  }) {
    final lignes = <String>[
      if (filter.search?.trim().isNotEmpty == true)
        l10n.catalogNeedDraftSearch(filter.search!.trim()),
      if (garageVehicle != null)
        l10n.catalogNeedDraftGarageVehicle(garageVehicle.displayName),
      if (filter.city?.trim().isNotEmpty == true)
        l10n.catalogNeedDraftCity(filter.city!.trim()),
    ];
    return NeedDraft(
      type: 'part',
      description: lignes.isEmpty ? null : lignes.join('\n'),
      partCategoryId: filter.categoryId,
      oemNumber: filter.oem,
    );
  }

  factory NeedDraft.fromAccessoryFilter(
    AccessoryFilter filter,
    AppLocalizations l10n,
  ) {
    final lignes = <String>[
      if (filter.search?.trim().isNotEmpty == true)
        l10n.catalogNeedDraftSearch(filter.search!.trim()),
      if (filter.city?.trim().isNotEmpty == true)
        l10n.catalogNeedDraftCity(filter.city!.trim()),
    ];
    return NeedDraft(
      type: 'accessory',
      description: lignes.isEmpty ? null : lignes.join('\n'),
      accessoryCategory: filter.category,
      budgetMax: filter.priceMax,
    );
  }

  factory NeedDraft.fromCompatibleParts(
    AppLocalizations l10n, {
    OwnedVehicle? vehicle,
    int? categoryId,
  }) {
    return NeedDraft(
      type: 'part',
      description: vehicle == null
          ? null
          : l10n.catalogNeedDraftGarageVehicle(vehicle.displayName),
      partCategoryId: categoryId,
    );
  }

  String get route =>
      '/needs/new?type=${types.contains(type) ? type : 'vehicle'}';
}

/// Ouvre le formulaire de besoin, en lui passant le brouillon.
void openNeedForm(BuildContext context, NeedDraft draft) {
  context.push(draft.route, extra: draft);
}
