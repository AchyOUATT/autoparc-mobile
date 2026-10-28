import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/currency_format.dart';
import '../../../core/utils/lien_externe.dart';
import '../data/private_listing_repository.dart';

class PrivateListingDetail extends StatelessWidget {
  const PrivateListingDetail({
    super.key,
    required this.listing,
    this.publicListing = true,
  });
  final PrivateListing listing;
  final bool publicListing;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Annonce de particulier'),
      actions: [
        if (publicListing)
          IconButton(
            tooltip: 'Partager l’annonce',
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
        const Align(
          alignment: Alignment.centerLeft,
          child: Chip(label: Text('Particulier')),
        ),
        Text(listing.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          formatXof(listing.number('price').toDouble()),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          '${listing.number('year')} · ${listing.number('mileage_km')} km · ${listing.text('city')}',
        ),
        const SizedBox(height: 16),
        for (final entry in const {
          'engine_type': 'Carburant',
          'drivetrain': 'Motricité',
          'color': 'Couleur',
        }.entries)
          if (listing.identityText(entry.key).isNotEmpty)
            Text('${entry.value} : ${listing.identityText(entry.key)}'),
        if (listing.text('transmission').isNotEmpty)
          Text(
            'Boîte : ${const {'manual': 'Manuelle', 'automatic': 'Automatique', 'cvt': 'CVT', 'dual_clutch': 'Double embrayage', 'single_speed': 'Rapport unique'}[listing.text('transmission')] ?? listing.text('transmission')}',
          ),
        const SizedBox(height: 12),
        for (final photo in listing.photos)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                '${photo['url']}',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 160,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
        Text(listing.text('description')),
        const Divider(height: 32),
        Text(
          listing.text('seller_name'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (listing.fields['phone_verified'] == true)
          const Text('Téléphone vérifié'),
        const Text('Le véhicule n’a pas été inspecté par AutoParc.'),
        if (listing.text('phone').isNotEmpty) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.call_outlined),
            label: const Text('Appeler le vendeur'),
            onPressed: () => ouvrirLien(
              context,
              Uri(scheme: 'tel', path: listing.text('phone')),
              valeurACopier: listing.text('phone'),
              ceQuiNePeutPasSOuvrir: 'le composeur',
            ),
          ),
          if (listing.fields['whatsapp_enabled'] == true)
            OutlinedButton.icon(
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Contacter sur WhatsApp'),
              onPressed: () => ouvrirLien(
                context,
                Uri.https(
                  'wa.me',
                  '/${listing.text('phone').replaceAll(RegExp(r'\D'), '')}',
                ),
                valeurACopier: listing.text('phone'),
                ceQuiNePeutPasSOuvrir: 'WhatsApp',
              ),
            ),
        ],
      ],
    ),
  );
}
