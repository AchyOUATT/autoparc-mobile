import '../../../l10n/app_localizations.dart';

String needStatusLabel(AppLocalizations l10n, String code) => switch (code) {
  'pending' => l10n.needsStatusPending,
  'approved' => l10n.needsStatusApproved,
  'contacted' => l10n.needsStatusContacted,
  'fulfilled' => l10n.needsStatusFulfilled,
  'cancelled' => l10n.needsStatusCancelled,
  _ => code,
};

String needTypeLabel(AppLocalizations l10n, String code) => switch (code) {
  'vehicle' => l10n.catalogSectionVehicle,
  'part' => l10n.needsTypeSparePart,
  'accessory' => l10n.needsTypeAccessory,
  _ => code,
};
