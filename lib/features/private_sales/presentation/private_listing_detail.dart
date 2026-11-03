import '../../../core/l10n/reference_labels.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/contact/autoparc_contact_provider.dart';
import '../../../core/widgets/product_gallery.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/lien_externe.dart';
import '../data/private_listing_repository.dart';
import 'private_listing_labels.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../catalog/presentation/providers/catalog_providers.dart';
import '../../inspections/presentation/staff_inspection_widgets.dart';
import '../../vehicles/presentation/widgets/declared_faults_section.dart';

class PrivateListingDetail extends ConsumerWidget {
  const PrivateListingDetail({
    super.key,
    required this.listing,
    this.publicListing = true,
  });
  final PrivateListing listing;
  final bool publicListing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final photoUrls = listing.photoUrls;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privateSalesDetailTitle),
        actions: [
          if (publicListing)
            IconButton(
              tooltip: l10n.privateSalesShare,
              icon: const Icon(Icons.share_outlined),
              onPressed: () async {
                final box = context.findRenderObject() as RenderBox?;
                await SharePlus.instance.share(
                  ShareParams(
                    text: '${listing.title}\n${listing.text('share_url')}',
                    sharePositionOrigin: box == null
                        ? null
                        : box.localToGlobal(Offset.zero) & box.size,
                  ),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text(l10n.privateSalesPrivateSeller)),
          ),
          Text(listing.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            formatXof(listing.number('price').toDouble()),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            privateListingVehicleSummary(listing, l10n),
          ),
          const SizedBox(height: 16),
          for (final entry in {
            'engine_type': l10n.privateSalesFuel,
            'drivetrain': l10n.privateSalesDrivetrain,
            'color': l10n.catalogFieldColour,
          }.entries)
            if (listing.identityText(entry.key).isNotEmpty)
              Text(
                l10n.privateSalesFieldValue(entry.value, switch (entry.key) {
                  'engine_type' => referenceFuelLabel(
                    null,
                    listing.identityText(entry.key),
                    l10n,
                  ),
                  'drivetrain' => referenceDrivetrainLabel(
                    listing.identityText('drivetrain_code'),
                    listing.identityText(entry.key),
                    l10n,
                  ),
                  'color' => referenceColourLabel(
                    listing.identityText(entry.key),
                    l10n,
                  ),
                  _ => listing.identityText(entry.key),
                }),
              ),
          if (listing.text('transmission').isNotEmpty)
            Text(
              l10n.privateSalesFieldValue(
                l10n.catalogFieldTransmission,
                privateListingTransmissionLabel(
                  listing.text('transmission'),
                  l10n,
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (photoUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ProductGallery(
                    key: ValueKey(
                      'private-photos:${listing.id}:${photoUrls.join('|')}',
                    ),
                    urls: photoUrls,
                    titre: listing.title,
                    fallback: const Center(
                      child: Icon(Icons.directions_car_outlined),
                    ),
                  ),
                ),
              ),
            ),
          Text(listing.text('description')),
          const Divider(height: 32),
          DeclaredFaultsSection(declaration: listing.faultDeclaration),
          const Divider(height: 32),
          if (!publicListing) ...[
            Text(
              listing.text('seller_name'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (listing.fields['phone_verified'] == true)
              Text(l10n.privateSalesPhoneVerified),
          ],
          StaffInspectionSection(
            key: ValueKey('private-listing-inspection:${listing.id}'),
            source: 'private_listing',
            sourceId: listing.id,
            inspectionSummary: listing.inspection,
            canManage: auth.canManageInspections,
            uninspectedLabel: l10n.privateSalesNotInspected,
            onChanged: () => ref.invalidate(vehicleListProvider),
          ),
          _BlocDeContact(
            listing: listing,
            depuisLaListePublique: publicListing,
          ),
        ],
      ),
    );
  }
}

/// The display mode determines the contact channel, including with an old
/// payload containing the seller's details. Public buyers always use AutoParc.
class _BlocDeContact extends ConsumerWidget {
  const _BlocDeContact({
    required this.listing,
    required this.depuisLaListePublique,
  });
  final PrivateListing listing;
  final bool depuisLaListePublique;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (depuisLaListePublique) {
      final contact = ref.watch(autoparcContactProvider);
      final message = l10n.privateSalesAutoParcMessage(
        listing.title,
        listing.text('share_url'),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.privateSalesAutoParcContactNotice),
          const SizedBox(height: 4),
          Text(contact.phoneDisplay),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.call_outlined),
            label: Text(l10n.privateSalesCallAutoParc),
            onPressed: () => ouvrirLien(
              context,
              contact.phoneUri,
              valeurACopier: contact.phoneDisplay,
              ceQuiNePeutPasSOuvrir: l10n.shellContactDialerTarget,
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.chat_outlined),
            label: Text(l10n.privateSalesWhatsappAutoParc),
            onPressed: () => ouvrirLien(
              context,
              contact.whatsappUri.replace(
                query: 'text=${Uri.encodeComponent(message)}',
              ),
              valeurACopier: contact.phoneDisplay,
              ceQuiNePeutPasSOuvrir: 'WhatsApp',
            ),
          ),
        ],
      );
    }

    final numero = listing.verifiedPhone;
    if (numero.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.call_outlined),
          label: Text(l10n.privateSalesCallSeller),
          onPressed: () => ouvrirLien(
            context,
            Uri(scheme: 'tel', path: numero),
            valeurACopier: numero,
            ceQuiNePeutPasSOuvrir: l10n.shellContactDialerTarget,
          ),
        ),
        if (listing.fields['whatsapp_enabled'] == true)
          OutlinedButton.icon(
            icon: const Icon(Icons.chat_outlined),
            label: Text(l10n.privateSalesContactWhatsapp),
            onPressed: () => ouvrirLien(
              context,
              Uri.https('wa.me', '/${numero.replaceAll(RegExp(r'\D'), '')}'),
              valeurACopier: numero,
              ceQuiNePeutPasSOuvrir: 'WhatsApp',
            ),
          ),
      ],
    );
  }
}
