import '../../../../l10n/app_localizations.dart';

String vehicleFaultCategoryLabel(String value, AppLocalizations l10n) =>
    switch (value) {
      'engine' => l10n.vehiclesFaultCategoryEngine,
      'transmission' => l10n.vehiclesFaultCategoryTransmission,
      'electrical' => l10n.vehiclesFaultCategoryElectrical,
      'braking' => l10n.vehiclesFaultCategoryBraking,
      'suspension' => l10n.vehiclesFaultCategorySuspension,
      'steering' => l10n.vehiclesFaultCategorySteering,
      'cooling' => l10n.vehiclesFaultCategoryCooling,
      'air_conditioning' => l10n.vehiclesFaultCategoryAirConditioning,
      'bodywork' => l10n.vehiclesFaultCategoryBodywork,
      'interior' => l10n.vehiclesFaultCategoryInterior,
      'electronics' => l10n.vehiclesFaultCategoryElectronics,
      'tyres' => l10n.vehiclesFaultCategoryTyres,
      'other' => l10n.vehiclesFaultCategoryOther,
      _ => value,
    };

String vehicleFaultSeverityLabel(String value, AppLocalizations l10n) =>
    switch (value) {
      'minor' => l10n.vehiclesFaultSeverityMinor,
      'moderate' => l10n.vehiclesFaultSeverityModerate,
      'major' => l10n.vehiclesFaultSeverityMajor,
      'critical' => l10n.vehiclesFaultSeverityCritical,
      _ => value,
    };

String vehicleFaultStatusLabel(String value, AppLocalizations l10n) =>
    switch (value) {
      'declared' => l10n.vehiclesFaultStatusDeclared,
      'diagnosed' => l10n.vehiclesFaultStatusDiagnosed,
      'quoted' => l10n.vehiclesFaultStatusQuoted,
      'repairing' => l10n.vehiclesFaultStatusRepairing,
      'repaired' => l10n.vehiclesFaultStatusRepaired,
      'wont_fix' => l10n.vehiclesFaultStatusWontFix,
      _ => value,
    };
