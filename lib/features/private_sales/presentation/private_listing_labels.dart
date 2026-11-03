import '../../../core/l10n/transmission_labels.dart';
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
    transmissionLabel(value, l10n);
