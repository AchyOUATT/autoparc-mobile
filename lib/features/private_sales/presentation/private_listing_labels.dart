import '../../../l10n/app_localizations.dart';
import '../data/private_listing_repository.dart';

/// Les libellés suivent la langue de l'écran, jamais le modèle de données.
String privateListingStatusLabel(
  PrivateListing listing,
  AppLocalizations l10n,
) => switch (listing.status) {
  'draft' => l10n.privateSalesStatusDraft,
  'pending' => l10n.privateSalesStatusPending,
  'published' => l10n.privateSalesStatusPublished,
  'rejected' => l10n.privateSalesStatusRejected,
  'withdrawn' => l10n.privateSalesStatusWithdrawn,
  'sold' => l10n.privateSalesStatusSold,
  _ => l10n.privateSalesPrivateSeller,
};

String privateListingTransmissionLabel(String value, AppLocalizations l10n) =>
    switch (value) {
      'manual' => l10n.catalogTransmissionManual,
      'automatic' => l10n.catalogTransmissionAutomatic,
      'cvt' => l10n.catalogTransmissionCvt,
      'dual_clutch' => l10n.privateSalesTransmissionDualClutch,
      'single_speed' => l10n.privateSalesTransmissionSingleSpeed,
      _ => value,
    };
