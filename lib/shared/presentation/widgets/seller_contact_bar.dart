import 'package:flutter/material.dart';

import '../../../core/utils/lien_externe.dart';
import '../../../l10n/app_localizations.dart';
import '../../models/product_seller.dart';

/// Partner listings are handled directly by their seller, outside the shop cart.
class SellerContactBar extends StatelessWidget {
  final ProductSeller seller;

  const SellerContactBar({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = seller.telephoneUri;
    final whatsapp = seller.whatsappUri;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seller.companyName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: phone == null ? null : () => ouvrirLien(
                    context,
                    phone,
                    valeurACopier: seller.phone,
                    ceQuiNePeutPasSOuvrir: l10n.shellContactDialerTarget,
                  ),
                  icon: const Icon(Icons.phone_outlined),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.catalogCallAction),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: whatsapp == null ? null : () => ouvrirLien(
                    context,
                    whatsapp,
                    valeurACopier: seller.whatsappNumber!,
                    ceQuiNePeutPasSOuvrir: 'WhatsApp',
                  ),
                  icon: const Icon(Icons.chat_outlined),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('WhatsApp'),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
