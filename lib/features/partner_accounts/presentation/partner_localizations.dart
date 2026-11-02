import '../../../l10n/app_localizations.dart';
import '../data/partner_repository.dart';

/// Presentation labels only: API paths and enum values keep their contract.
String partnerListingKindLabel(
  AppLocalizations l10n,
  PartnerListingKind kind,
) => switch (kind) {
  PartnerListingKind.vehicles => l10n.commonVehicles,
  PartnerListingKind.parts => l10n.catalogPartListTitle,
  PartnerListingKind.accessories => l10n.commonAccessories,
};

String partnerInventoryTitle(AppLocalizations l10n, PartnerListingKind kind) =>
    switch (kind) {
      PartnerListingKind.vehicles => l10n.partnerAccountsMyVehicles,
      PartnerListingKind.parts => l10n.partnerAccountsMyParts,
      PartnerListingKind.accessories => l10n.partnerAccountsMyAccessories,
    };

String partnerAccessoryCategory(AppLocalizations l10n, String category) =>
    switch (category) {
      'esthetique' => l10n.catalogAccessoryCategoryStyling,
      'confort' => l10n.catalogAccessoryCategoryComfort,
      'securite' => l10n.catalogAccessoryCategorySafety,
      'multimedia' => l10n.catalogAccessoryCategoryMultimedia,
      'utilitaire' => l10n.catalogAccessoryCategoryUtility,
      _ => category,
    };
