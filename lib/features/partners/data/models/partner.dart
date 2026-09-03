import 'package:equatable/equatable.dart';

class Partner extends Equatable {
  final int id;
  final String companyName;
  final String? contactName;
  final String phone;
  final String? whatsapp;
  final String? email;
  final String? notes;
  final bool isActive;
  // Données du pivot (présentes quand chargé depuis un produit)
  final String? role;
  final String? pivotNotes;

  const Partner({
    required this.id,
    required this.companyName,
    this.contactName,
    required this.phone,
    this.whatsapp,
    this.email,
    this.notes,
    required this.isActive,
    this.role,
    this.pivotNotes,
  });

  factory Partner.fromJson(Map<String, dynamic> json) => Partner(
    id:           json['id']           as int,
    companyName:  json['company_name'] as String,
    contactName:  json['contact_name'] as String?,
    phone:        json['phone']        as String,
    whatsapp:     json['whatsapp']     as String?,
    email:        json['email']        as String?,
    notes:        json['notes']        as String?,
    isActive:     json['is_active']    as bool? ?? true,
    role:         json['role']         as String?,
    pivotNotes:   json['pivot_notes']  as String?,
  );

  Map<String, dynamic> toJson() => {
    'company_name': companyName,
    if (contactName != null) 'contact_name': contactName,
    'phone': phone,
    if (whatsapp != null) 'whatsapp': whatsapp,
    if (email != null) 'email': email,
    if (notes != null) 'notes': notes,
    'is_active': isActive,
  };

  Partner copyWith({
    String? companyName,
    String? contactName,
    String? phone,
    String? whatsapp,
    String? email,
    String? notes,
    bool? isActive,
  }) => Partner(
    id: id,
    companyName: companyName ?? this.companyName,
    contactName: contactName ?? this.contactName,
    phone: phone ?? this.phone,
    whatsapp: whatsapp ?? this.whatsapp,
    email: email ?? this.email,
    notes: notes ?? this.notes,
    isActive: isActive ?? this.isActive,
    role: role,
    pivotNotes: pivotNotes,
  );

  /// Affichage court : nom entreprise + interlocuteur si disponible.
  String get displayName => contactName != null
      ? '$companyName · $contactName'
      : companyName;

  @override
  List<Object?> get props => [id, companyName, phone];
}
