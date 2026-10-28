/// Le contact commercial AutoParc, commun aux appels et à WhatsApp.
class AutoParcContact {
  const AutoParcContact._(this.phone);

  static const fallback = AutoParcContact._('+22675570484');
  static final _internationalPhone = RegExp(r'^\+[1-9][0-9]{7,14}$');

  final String phone;

  /// Les séparateurs saisis par le responsable ne changent pas le numéro.
  static String normalize(String value) =>
      value.trim().replaceAll(RegExp(r'[\s().-]'), '');

  static bool isValid(String value) =>
      _internationalPhone.hasMatch(normalize(value));

  factory AutoParcContact.parse(String value) {
    final normalized = normalize(value);
    if (!_internationalPhone.hasMatch(normalized)) {
      throw const FormatException('Numéro de contact international invalide.');
    }
    return AutoParcContact._(normalized);
  }

  factory AutoParcContact.fromJson(Map<String, dynamic> json) {
    final phone = json['phone'];
    if (phone is! String) {
      throw const FormatException('Numéro de contact absent de la réponse.');
    }
    return AutoParcContact.parse(phone);
  }

  String get phoneDisplay {
    // Format familier au Burkina Faso ; les autres indicatifs restent intacts.
    if (phone.startsWith('+226') && phone.length == 12) {
      final national = phone.substring(4);
      return '+226 ${national.substring(0, 2)} ${national.substring(2, 4)} '
          '${national.substring(4, 6)} ${national.substring(6, 8)}';
    }
    return phone;
  }

  String get whatsappNumber => phone.substring(1);
  Uri get phoneUri => Uri(scheme: 'tel', path: phone);
  Uri get whatsappUri => Uri.https('wa.me', '/$whatsappNumber');

  @override
  bool operator ==(Object other) =>
      other is AutoParcContact && other.phone == phone;

  @override
  int get hashCode => phone.hashCode;
}
