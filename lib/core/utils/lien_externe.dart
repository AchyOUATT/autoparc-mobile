import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Ouvre un lien hors de l'application, et le dit quand ça échoue.
///
/// Les appels se faisaient jusqu'ici en `onTap: () => launchUrl(...)`, sans
/// garde. Or `launchUrl` lève quand aucune application ne sait ouvrir le
/// lien, et une exception levée dans un rappel de `onTap` ne va nulle part :
/// le propriétaire touchait « Email », **rien ne se passait**, et il n'avait
/// aucun moyen de savoir pourquoi. C'est ce qui a été signalé sous la forme
/// « les utilisateurs ne peuvent pas nous contacter ».
///
/// La cause première était ailleurs — le manifeste Android ne déclarait pas
/// le schéma `mailto`, donc depuis Android 11 l'application ne voyait aucune
/// messagerie — mais l'absence de garde est ce qui a rendu la panne muette,
/// et c'est elle qui aurait caché la suivante.
///
/// Le repli n'est pas un message d'excuse : il copie la valeur. Quelqu'un
/// dont le téléphone n'a pas de client courriel peut encore coller l'adresse
/// ailleurs, et le numéro se compose à la main. Une impasse devient une
/// gêne.
Future<void> ouvrirLien(
  BuildContext context,
  Uri lien, {
  required String valeurACopier,

  /// Ce que l'appareil n'a pas su ouvrir, DÉJÀ TRADUIT par l'appelant.
  ///
  /// Un fragment et non une phrase : il s'insère dans `commonLinkUnavailable`
  /// (« Impossible d'ouvrir le composeur sur cet appareil. »), d'où l'article
  /// et la minuscule. Les quatre valeurs servies ont leur clé — voir
  /// `shellContactDialerTarget` et ses voisines ; seul « WhatsApp », nom de
  /// marque, reste en dur.
  required String ceQuiNePeutPasSOuvrir,
}) async {
  var ouvert = false;

  try {
    // externalApplication plutôt que le mode par défaut : on veut le
    // composeur, la messagerie ou WhatsApp, pas une vue web intégrée.
    ouvert = await launchUrl(lien, mode: LaunchMode.externalApplication);
  } catch (_) {
    // launchUrl lève sur un schéma que le système ne sait pas router. On ne
    // distingue pas ce cas d'un refus : les deux donnent la même impasse.
    ouvert = false;
  }

  if (ouvert || !context.mounted) return;

  await Clipboard.setData(ClipboardData(text: valeurACopier));

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        AppLocalizations.of(context).commonLinkUnavailable(
          ceQuiNePeutPasSOuvrir,
          valeurACopier,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
    ),
  );
}
