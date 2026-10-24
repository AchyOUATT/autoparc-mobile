import 'package:equatable/equatable.dart';

/// Public business contact attached to a partner's listing.
class ProductSeller extends Equatable {
  final int id;
  final String companyName;
  final String phone;
  final String? whatsapp;

  const ProductSeller({
    required this.id,
    required this.companyName,
    required this.phone,
    this.whatsapp,
  });

  factory ProductSeller.fromJson(Map<String, dynamic> json) => ProductSeller(
    id: json['id'] as int,
    companyName: json['company_name'] as String,
    phone: json['phone'] as String? ?? '',
    whatsapp: json['whatsapp'] as String?,
  );

  Uri? get telephoneUri {
    final number = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return number.contains(RegExp(r'[0-9]'))
        ? Uri(scheme: 'tel', path: number)
        : null;
  }

  String? get whatsappNumber {
    final contact = whatsapp?.trim();
    final number = (contact == null || contact.isEmpty ? phone : contact)
        .replaceAll(RegExp(r'\D'), '');
    return number.isEmpty ? null : number;
  }

  Uri? get whatsappUri => whatsappNumber == null
      ? null
      : Uri.https('wa.me', '/$whatsappNumber');

  @override
  List<Object?> get props => [id, companyName, phone, whatsapp];
}
