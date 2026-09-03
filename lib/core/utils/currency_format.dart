import 'package:intl/intl.dart';

final _xofFull = NumberFormat.currency(
  locale:        'fr_FR',
  symbol:        'FCFA',
  decimalDigits: 0,
);

/// "3 500 000 FCFA"
String formatXof(double? amount) {
  if (amount == null) return '—';
  return _xofFull.format(amount.round());
}

/// Même résultat que [formatXof] — "3 500 000 FCFA".
/// Conservé pour compatibilité avec les sites d'appel existants.
String formatXofShort(double? amount) => formatXof(amount);
