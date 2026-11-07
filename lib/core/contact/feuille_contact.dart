import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../utils/contact_info.dart';
import '../utils/lien_externe.dart';
import 'autoparc_contact_provider.dart';

/// La feuille de contact d'AutoParc — téléphone, WhatsApp, courriel.
///
/// Elle vivait dans le tiroir, en méthode privée d'`AppDrawer`, et n'était
/// donc atteignable que par la tuile « Contact » du bloc client. Un vendeur en
/// attente d'approbation n'avait AUCUN moyen de joindre la boutique depuis
/// l'application : son tableau de bord l'ouvre désormais aussi. Une seule
/// feuille pour les deux appelants, et le même rafraîchissement du numéro à
/// l'ouverture.
void afficherFeuilleContact(BuildContext context, WidgetRef ref) {
  ref.read(autoparcContactProvider.notifier).refresh();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (contexteFeuille) => Consumer(builder: (context, ref, _) {
      final l10n = AppLocalizations.of(contexteFeuille);
      final contact = ref.watch(autoparcContactProvider);

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shellContact,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TuileContact(
              icon: Icons.phone_outlined,
              label: l10n.shellContactPhone,
              value: contact.phoneDisplay,
              onTap: () => ouvrirLien(
                context,
                contact.phoneUri,
                valeurACopier: contact.phoneDisplay,
                ceQuiNePeutPasSOuvrir: l10n.shellContactDialerTarget,
              ),
            ),
            const SizedBox(height: 12),
            TuileContact(
              icon: Icons.chat_outlined,
              iconColor: const Color(0xFF25D366),
              label: 'WhatsApp',
              value: contact.phoneDisplay,
              onTap: () => ouvrirLien(
                context,
                contact.whatsappUri,
                valeurACopier: contact.phoneDisplay,
                // « WhatsApp » reste en dur, et n'a pas de clé : c'est un nom
                // de marque, identique dans les deux langues, et lui donner une
                // clé inviterait un traducteur à le traduire.
                ceQuiNePeutPasSOuvrir: 'WhatsApp',
              ),
            ),
            const SizedBox(height: 12),
            TuileContact(
              icon: Icons.email_outlined,
              label: l10n.shellContactEmail,
              value: kContactEmail,
              onTap: () => ouvrirLien(
                context,
                Uri.parse('mailto:$kContactEmail'),
                valeurACopier: kContactEmail,
                ceQuiNePeutPasSOuvrir: l10n.shellContactMailTarget,
              ),
            ),
          ],
        ),
      );
    }),
  );
}

/// Une ligne de la feuille : l'icône, le libellé, la valeur.
class TuileContact extends StatelessWidget {
  final IconData icon;
  final Color?   iconColor;
  final String   label;
  final String   value;
  final VoidCallback onTap;

  const TuileContact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary),
    title:    Text(label),
    subtitle: Text(value),
    onTap:    onTap,
    contentPadding: EdgeInsets.zero,
  );
}
