import 'package:url_launcher/url_launcher.dart';

import '../../features/cart/data/models/cart_item.dart';
import 'contact_info.dart';
import 'currency_format.dart';

// Le numéro vient désormais de contact_info.dart — il vivait ici en double,
// avec une valeur fictive différente de celle de main.dart.

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
  final uri     = Uri.parse('https://wa.me/$kContactWhatsApp?text=$encoded');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
  }
  return false;
}
