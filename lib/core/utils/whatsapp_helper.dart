import 'package:url_launcher/url_launcher.dart';

import '../../features/cart/data/models/cart_item.dart';
import 'contact_info.dart';
import 'currency_format.dart';

// Le numéro vient désormais de contact_info.dart — il vivait ici en double,
// avec une valeur fictive différente de celle de main.dart.

/// Les cinq chaînes du message de commande, LUES DANS L'ÉCRAN.
///
/// ── LE DÉFAUT CORRIGÉ, ET POURQUOI IL A SURVÉCU À LA VAGUE 2 ──────────────
///
/// Le panier a été déclaré traduit alors que son ACTION PRINCIPALE ne l'était
/// pas : ce fichier composait un message entièrement français, sans aucun
/// paramètre de langue. Un client anglophone appuyait sur « Order via
/// WhatsApp » — libellé lu dans `cartOrderViaWhatsApp` — et envoyait à la
/// boutique :
///
///     *Demande de commande — AutoParc*
///     • 1× Tapis de sol → 18 000 FCFA
///     Sous-total HT : 18 000 FCFA
///     …
///     Merci de confirmer la disponibilité.
///
/// Le scanner de la vague 2 ne l'a pas vu parce qu'il parcourait
/// `lib/features/cart/` et que ce fichier vit dans `lib/core/utils/`. Le
/// montant, lui, suivait déjà la langue : `formatXof` lit un réglage de module
/// posé par `AutoParcApp.build`. Seules les phrases restaient.
///
/// ── POURQUOI UN PARAMÈTRE ET NON UNE LECTURE ICI ──────────────────────────
///
/// `buildWhatsAppMessage` n'a pas de `BuildContext` et ne doit pas en avoir :
/// c'est ce qui la rend vérifiable sans monter d'arbre de widgets — le même
/// arbitrage que `composerMessagePartage` dans `partage.dart`, qui porte sa
/// `mentionBoutique` en paramètre pour la même raison. `cart_page.dart` a un
/// contexte au point d'appel : il y lit déjà `cartWhatsAppMissing` juste
/// au-dessus.
class LibellesCommande {
  const LibellesCommande({
    required this.entete,
    required this.sousTotal,
    required this.taxe,
    required this.total,
    required this.pied,
  });

  /// La première ligne, en gras WhatsApp.
  final String entete;

  /// Les trois intitulés du décompte. Ce sont les MÊMES clés que le
  /// récapitulatif affiché à l'écran — `cartSubtotalExclTax`, `cartVat`,
  /// `cartTotalInclTax` —, et non des doublons : le message dit exactement ce
  /// que le client vient de lire, et les deux ne peuvent pas diverger.
  final String sousTotal;
  final String taxe;
  final String total;

  /// La dernière ligne : ce qu'on attend en retour.
  final String pied;
}

/// Compose le message WhatsApp à partir du panier.
///
/// L'ALIGNEMENT DES DEUX-POINTS EST CALCULÉ, et ce n'est pas de la coquetterie :
/// il était obtenu par des espaces écrites à la main dans « TVA           : »,
/// comptées sur la longueur de « Sous-total HT ». En anglais les trois
/// intitulés n'ont pas les mêmes longueurs — « Subtotal excl. VAT », « VAT »,
/// « Total incl. VAT » — et le décompte serait arrivé en escalier. Le
/// remplissage est donc pris sur le plus long des trois, quelle que soit la
/// langue.
///
/// L'ASTÉRISQUE DU TOTAL COÛTE UNE COLONNE, d'où le `largeur - 1`. Ce détail
/// d'un seul caractère est l'endroit où le passage aux `.arb` avait fait
/// BOUGER LE FRANÇAIS, ce qu'aucun lot de ce chantier n'a le droit de faire.
/// Mesuré sur les trois préfixes de ce message, de l'ouverture de la ligne au
/// deux-points inclus, contre la version d'avant la traduction :
///
///                           avant   après
///     « Sous-total HT : »      16      16
///     « TVA           : »      16      16
///     « *Total TTC    : »      16      17   ← un espace de plus
///
/// La version écrite à la main comptait l'astérisque dans les quatre espaces
/// de « *Total TTC    : » ; `padRight(largeur)` ne le comptait pas, et posait
/// treize caractères APRÈS lui. Le français du message gagnait donc un espace
/// sur sa ligne la plus lue — celle du montant à payer — sans que personne
/// l'ait décidé. « Le français ne bouge pas » est la promesse de ce chantier :
/// le `- 1` la tient, et il aligne aussi l'anglais, où « Total incl. VAT »
/// n'est pas le plus long des trois.
///
/// Ce que ça ne prétend pas : WhatsApp rend le message dans une police à
/// largeur VARIABLE, où aucun remplissage par espaces n'aligne quoi que ce
/// soit au pixel. L'alignement vaut sur le texte brut — presse-papier, SMS,
/// repli quand l'aperçu échoue — et reste une approximation dans la bulle.
/// Si [LibellesCommande.total] devenait un jour le plus long des trois, sa
/// ligne dépasserait d'un caractère : `padRight` ne tronque pas, et c'est le
/// bon sens de l'échec — un intitulé entier vaut mieux qu'une colonne.
String buildWhatsAppMessage(List<CartItem> items, LibellesCommande libelles) {
  final buf = StringBuffer()
    ..writeln(libelles.entete)
    ..writeln();

  for (final item in items) {
    // Le nom de l'article et sa référence viennent du serveur : ils restent
    // dans la langue qu'il envoie, comme partout ailleurs dans l'application.
    // « × » et « → » ne sont d'aucune langue.
    buf.writeln(
      '• ${item.quantity}× ${item.name}'
      '${item.sku != null ? ' (${item.sku})' : ''}'
      ' → ${formatXofShort(item.lineTotalHt)}',
    );
  }

  final totalHt = items.fold(0.0, (s, i) => s + i.lineTotalHt);
  final totalTtc = items.fold(0.0, (s, i) => s + i.lineTotalTtc);
  final tva = totalTtc - totalHt;

  final largeur = [libelles.sousTotal, libelles.taxe, libelles.total]
      .map((l) => l.length)
      .reduce((a, b) => a > b ? a : b);

  buf
    ..writeln()
    ..writeln('${libelles.sousTotal.padRight(largeur)} : ${formatXof(totalHt)}')
    ..writeln('${libelles.taxe.padRight(largeur)} : ${formatXof(tva)}')
    ..writeln(
      '*${libelles.total.padRight(largeur - 1)} : ${formatXof(totalTtc)}*',
    )
    ..writeln()
    ..write(libelles.pied);

  return buf.toString();
}

/// Ouvre WhatsApp avec le message pré-rempli.
/// Retourne `true` si l'app a pu être ouverte.
Future<bool> launchWhatsApp(
  List<CartItem> items,
  LibellesCommande libelles,
) async {
  final text = buildWhatsAppMessage(items, libelles);
  final encoded = Uri.encodeComponent(text);
  final uri = Uri.parse('https://wa.me/$kContactWhatsApp?text=$encoded');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
  }
  return false;
}
