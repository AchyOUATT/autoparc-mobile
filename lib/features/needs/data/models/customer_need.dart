class CustomerNeed {
  final int id;
  final String type;        // 'vehicle' | 'part' | 'accessory'
  final String description;
  final double? budgetMax;
  final String currency;
  // Critères structurés — véhicule
  final int?    brandId;
  final String? brandName;
  final int?    vehicleModelId;
  final String? vehicleModelName;
  final String? vehicleType;
  final String? bodyStyle;
  final int?    yearMin;
  final int?    yearMax;
  // Critères structurés — pièce détachée
  final int?    partCategoryId;
  final String? partCategoryName;
  final String? oemNumber;
  // Critères structurés — accessoire
  final String? accessoryCategory;
  // Commun pièce + accessoire
  final int?    needManufacturerId;
  final String? needManufacturerName;
  // Contact
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String status;      // 'pending' | 'contacted' | 'fulfilled' | 'cancelled'
  final String statusLabel;
  final String? staffNotes;
  final DateTime? createdAt;

  const CustomerNeed({
    required this.id,
    required this.type,
    required this.description,
    this.budgetMax,
    required this.currency,
    this.brandId,
    this.brandName,
    this.vehicleModelId,
    this.vehicleModelName,
    this.vehicleType,
    this.bodyStyle,
    this.yearMin,
    this.yearMax,
    this.partCategoryId,
    this.partCategoryName,
    this.oemNumber,
    this.accessoryCategory,
    this.needManufacturerId,
    this.needManufacturerName,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    required this.status,
    required this.statusLabel,
    this.staffNotes,
    this.createdAt,
  });

  factory CustomerNeed.fromJson(Map<String, dynamic> j) => CustomerNeed(
    id:           j['id']           as int,
    type:         j['type']         as String,
    description:  j['description']  as String,
    budgetMax:    (j['budget_max'] as num?)?.toDouble(),
    currency:     j['currency']     as String? ?? 'XOF',
    brandId:             j['brand_id']              as int?,
    brandName:           j['brand_name']            as String?,
    vehicleModelId:      j['vehicle_model_id']      as int?,
    vehicleModelName:    j['vehicle_model_name']    as String?,
    vehicleType:         j['vehicle_type']          as String?,
    bodyStyle:           j['body_style']            as String?,
    yearMin:             j['year_min']              as int?,
    yearMax:             j['year_max']              as int?,
    partCategoryId:      j['part_category_id']      as int?,
    partCategoryName:    j['part_category_name']    as String?,
    oemNumber:           j['oem_number']            as String?,
    accessoryCategory:   j['accessory_category']    as String?,
    needManufacturerId:  j['need_manufacturer_id']  as int?,
    needManufacturerName:j['need_manufacturer_name'] as String?,
    contactName:  j['contact_name']  as String?,
    contactPhone: j['contact_phone'] as String?,
    contactEmail: j['contact_email'] as String?,
    status:       j['status']        as String,
    statusLabel:  j['status_label']  as String? ?? j['status'] as String,
    staffNotes:   j['staff_notes']   as String?,
    createdAt:    j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );

  static const typeLabels = {
    'vehicle':   'Véhicule',
    'part':      'Pièce détachée',
    'accessory': 'Accessoire',
  };

  static const accessoryCategoryLabels = {
    'esthetique': 'Esthétique',
    'confort':    'Confort',
    'securite':   'Sécurité',
    'multimedia': 'Multimédia',
    'utilitaire': 'Utilitaire',
  };

  static const statusColors = {
    'pending':   0xFFFFA000,   // orange
    'contacted': 0xFF1565C0,   // bleu
    'fulfilled': 0xFF2E7D32,   // vert
    'cancelled': 0xFF757575,   // gris
  };

  String get typeLabel => typeLabels[type] ?? type;
  int    get statusColor => statusColors[status] ?? 0xFF757575;
}
