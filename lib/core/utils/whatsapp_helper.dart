import 'package:url_launcher/url_launcher.dart';

import '../../features/cart/data/models/cart_item.dart';
import 'currency_format.dart';

/// Numéro WhatsApp du service commercial AutoParc (format international sans +).
/// À remplacer par le vrai numéro avant la mise en production.
const _shopWhatsAppPhone = '22600000000';

/// Compose le message WhatsApp à partir du panier.
String buildWhatsAppMessage(List<CartItem> items) {
  final buf = StringBuffer()
    ..writeln('*Demande de commande — AutoParc*')
    ..writeln();

  for (final item in items) {
    buf.writeln(
      '• ${item.quantity}× ${item.name}'
      '${item.sku != null ? ' (${item.sku})' : ''}'
      ' → ${formatXofShort(item.lineTotalHt)}',
    );
  }

  final totalHt  = items.fold(0.0, (s, i) => s + i.lineTotalHt);
  final totalTtc = items.fold(0.0, (s, i) => s + i.lineTotalTtc);
  final tva      = totalTtc - totalHt;

  buf
    ..writeln()
    ..writeln('Sous-total HT : ${formatXof(totalHt)}')
    ..writeln('TVA           : ${formatXof(tva)}')
    ..writeln('*Total TTC    : ${formatXof(totalTtc)}*')
    ..writeln()
    ..write('Merci de confirmer la disponibilité.');

  return buf.toString();
}

/// Ouvre WhatsApp avec le message pré-rempli.
/// Retourne `true` si l'app a pu être ouverte.
Future<bool> launchWhatsApp(List<CartItem> items) async {
  final text    = buildWhatsAppMessage(items);
  final encoded = Uri.encodeComponent(text);
  final uri     = Uri.parse('https://wa.me/$_shopWhatsAppPhone?text=$encoded');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
  }
  return false;
}
