import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/reference_labels.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/data/media_repository.dart';
import '../../../../shared/presentation/pages/media_upload_page.dart';
import '../../../catalog/data/models/vehicle.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../partner_accounts/data/partner_repository.dart' as espace;
import '../../../partner_accounts/presentation/marge_recapitulatif.dart';
import '../../../partner_accounts/presentation/partner_session.dart' as espace;
import '../../data/models/catalog_refs.dart';
import '../../data/vehicle_admin_repository.dart';
import '../providers/vehicle_refs_provider.dart';
import '../widgets/equipment_details_section.dart';
import '../widgets/vehicle_reference_dropdown.dart';
import 'equipment_documents_page.dart';
import 'vehicle_form_mode.dart';

/// A machine can be registered with its declared identity and one price.
/// Optional measurements stay independent from road-vehicle specifications.
class EquipmentRegisterPage extends ConsumerStatefulWidget {
  const EquipmentRegisterPage({
    super.key,
    this.existing,
    this.mode = VehicleFormMode.personnel,
    this.initialAvailability = 'rent',
  });

  final Vehicle? existing;
  final VehicleFormMode mode;
  final String initialAvailability;

  @override
  ConsumerState<EquipmentRegisterPage> createState() =>
      _EquipmentRegisterPageState();
}

class _EquipmentRegisterPageState extends ConsumerState<EquipmentRegisterPage> {
  static const _types = [
    'agricultural_tractor',
    'aerial_platform',
    'excavator',
    'backhoe_loader',
    'loader',
    'telehandler',
    'forklift',
    'generator',
    'other',
  ];
  static const _textDetails = [
    'brand_label',
    'model_label',
    'serial_number',
    'registration_number',
    'park_number',
    'hour_reading_date',
    'attachments',
    'engine_serial_number',
  ];
  static const _numberDetails = [
    'operating_hours',
    'odometer_km',
    'power_kw',
    'rated_load_kg',
    'working_height_m',
    'outreach_m',
    'lift_height_m',
    'operating_weight_kg',
    'bucket_capacity_m3',
    'pto_rpm',
  ];
  final _formKey = GlobalKey<FormState>();
  final _identityExpansion = ExpansibleController();
  final _technicalExpansion = ExpansibleController();
  final _attachmentsExpansion = ExpansibleController();
  final _year = TextEditingController();
  final _sale = TextEditingController();
  final _daily = TextEditingController();
  final _weekly = TextEditingController();
  final _monthly = TextEditingController();
  final _deposit = TextEditingController();
  final _site = TextEditingController();
  final _description = TextEditingController();
  final _details = <String, TextEditingController>{};
  final _initialPrices = <String, num?>{};
  Map<String, dynamic> _initialDetails = {};
  String? _type;
  int? _brandId;
  int? _modelId;
  int? _fuelId;
  int? _locationId;
  String? _transmission;
  String? _cabin;
  bool? _quickCoupler;
  bool _freeBrand = false;
  bool _freeModel = false;
  bool _refsInitialized = false;
  bool _saving = false;

  AppLocalizations get l10n => AppLocalizations.of(context);
  bool get _editing => widget.existing != null;
  String get _availability =>
      widget.existing?.commercial.availability ?? widget.initialAvailability;
  bool get _forSale => _availability == 'sale' || _availability == 'both';
  bool get _forRent => _availability != 'sale';
  Map<String, TextEditingController> get _priceControllers => {
    if (_forSale) 'sale_price': _sale,
    if (_forRent) ...{
      'rental_daily_rate': _daily,
      'rental_weekly_rate': _weekly,
      'rental_monthly_rate': _monthly,
      'rental_deposit': _deposit,
    },
  };

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _initialDetails = existing?.equipmentDetails.toJson() ?? {};
    for (final field in [..._textDetails, ..._numberDetails]) {
      final value = _initialDetails[field];
      _details[field] = TextEditingController(
        text: value is num ? _amountText(value) : value?.toString() ?? '',
      );
    }
    if (existing == null) return;
    _type = existing.equipmentType;
    _brandId = existing.brandId;
    _modelId = existing.vehicleModelId;
    _freeBrand = _brandId == null;
    _freeModel = _modelId == null;
    _fuelId = existing.engineTypeId;
    _locationId = existing.commercial.locationId;
    _year.text = existing.identity.year?.toString() ?? '';
    _transmission = existing.equipmentDetails.transmission;
    _cabin = existing.equipmentDetails.cabin;
    _quickCoupler = existing.equipmentDetails.quickCoupler;
    _site.text = existing.commercial.site ?? '';
    _description.text = existing.description ?? '';
    final publicPrices = <String, num?>{
      'sale_price': existing.commercial.salePrice,
      'rental_daily_rate': existing.commercial.rentalDailyRate,
      'rental_weekly_rate': existing.commercial.rentalWeeklyRate,
      'rental_monthly_rate': existing.commercial.rentalMonthlyRate,
      'rental_deposit': existing.commercial.rentalDeposit,
    };
    for (final entry in _priceControllers.entries) {
      final value = widget.mode.estPartenaire
          ? existing.proposedPriceExcludingCommission(entry.key) ??
                publicPrices[entry.key]
          : publicPrices[entry.key];
      _initialPrices[entry.key] = value;
      entry.value.text = _amountText(value);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _year,
      _sale,
      _daily,
      _weekly,
      _monthly,
      _deposit,
      _site,
      _description,
      ..._details.values,
    ]) {
      controller.dispose();
    }
    _identityExpansion.dispose();
    _technicalExpansion.dispose();
    _attachmentsExpansion.dispose();
    super.dispose();
  }

  static String _amountText(num? amount) => amount == null
      ? ''
      : amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toString();

  static String? _text(String value) =>
      value.trim().isEmpty ? null : value.trim();

  static num? _number(String value, {bool money = false}) {
    final text = value.replaceAll(RegExp(r'[\s\u00a0\u202f]'), '');
    final pattern = money ? r'^\d+(?:[.,]\d{1,2})?$' : r'^\d+(?:[.,]\d+)?$';
    if (!RegExp(pattern).hasMatch(text)) return null;
    final number = num.tryParse(text.replaceAll(',', '.'));
    return number != null && number.isFinite && number >= 0 ? number : null;
  }

  bool get _usesFreeModel => _freeBrand || _freeModel || _models.isEmpty;
  List<ModelRef> _models = [];

  Set<String> get _visibleDetails => {
    'brand_label',
    'model_label',
    'serial_number',
    'registration_number',
    'park_number',
    'engine_serial_number',
    'operating_hours',
    'hour_reading_date',
    'odometer_km',
    'transmission',
    'cabin',
    'quick_coupler',
    'attachments',
    if (const ['agricultural_tractor', 'generator', 'other'].contains(_type))
      'power_kw',
    if (const [
      'aerial_platform',
      'loader',
      'telehandler',
      'forklift',
      'other',
    ].contains(_type))
      'rated_load_kg',
    if (const ['aerial_platform', 'other'].contains(_type)) 'working_height_m',
    if (const ['aerial_platform', 'telehandler', 'other'].contains(_type))
      'outreach_m',
    if (const ['telehandler', 'forklift', 'other'].contains(_type))
      'lift_height_m',
    if (const [
      'excavator',
      'backhoe_loader',
      'loader',
      'other',
    ].contains(_type))
      'operating_weight_kg',
    if (const [
      'excavator',
      'backhoe_loader',
      'loader',
      'other',
    ].contains(_type))
      'bucket_capacity_m3',
    if (const ['agricultural_tractor', 'other'].contains(_type)) 'pto_rpm',
  };

  void _initializeRefs(CatalogRefs refs) {
    if (_refsInitialized) return;
    _refsInitialized = true;
    if (refs.brands.where((b) => b.isActive).isEmpty && _brandId == null) {
      _freeBrand = true;
    }
  }

  Map<String, dynamic> _payload() {
    final existing = widget.existing;
    final detailChanges = <String, dynamic>{};
    for (final field in _visibleDetails) {
      dynamic value;
      if (field == 'brand_label') {
        value = _freeBrand ? _text(_details[field]!.text) : null;
      } else if (field == 'model_label') {
        value = _usesFreeModel ? _text(_details[field]!.text) : null;
      } else if (field == 'transmission') {
        value = _transmission;
      } else if (field == 'cabin') {
        value = _cabin;
      } else if (field == 'quick_coupler') {
        value = _quickCoupler;
      } else if (_numberDetails.contains(field)) {
        value = _number(_details[field]!.text);
        if (field == 'pto_rpm') value = (value as num?)?.toInt();
      } else {
        value = _text(_details[field]!.text);
      }
      if (_editing ? value != _initialDetails[field] : value != null) {
        detailChanges[field] = value;
      }
    }
    final year = int.tryParse(_year.text.trim());
    final site = _text(_site.text);
    final description = _text(_description.text);
    return {
      'asset_kind': 'equipment',
      'equipment_type': _type,
      'brand_id': _freeBrand ? null : _brandId,
      'vehicle_model_id': _usesFreeModel ? null : _modelId,
      if (!_editing || year != existing!.identity.year)
        'manufacturing_year': year,
      if (!_editing && _fuelId != null ||
          _editing && _fuelId != existing!.engineTypeId)
        'engine_type_id': _fuelId,
      if (!_editing) ...{'availability': _availability, 'currency': 'XOF'},
      if (detailChanges.isNotEmpty) 'equipment_details': detailChanges,
      for (final entry in _priceControllers.entries)
        if (_editing
            ? _number(entry.value.text, money: true) !=
                  _initialPrices[entry.key]
            : _number(entry.value.text, money: true) != null)
          entry.key: _number(entry.value.text, money: true),
      if (_editing
          ? site != _text(existing!.commercial.site ?? '')
          : site != null)
        'site': site,
      if (_editing
          ? description != _text(existing!.description ?? '')
          : description != null)
        'description': description,
      if (widget.mode.peutChoisirLaBoutique &&
          (_editing
              ? _locationId != existing!.commercial.locationId
              : _locationId != null))
        'location_id': _locationId,
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    final invalid = _formKey.currentState?.validateGranularly();
    if (invalid == null) return;
    if (invalid.isNotEmpty) {
      _identityExpansion.expand();
      _technicalExpansion.expand();
      _attachmentsExpansion.expand();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !invalid.first.mounted) return;
        Scrollable.ensureVisible(
          invalid.first.context,
          alignment: .1,
          duration: const Duration(milliseconds: 250),
        );
      });
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = _payload();
      final existing = widget.existing;
      if (widget.mode.estPartenaire) {
        await ref
            .read(espace.partnerRepositoryProvider)
            .saveListing(
              espace.PartnerListingKind.vehicles,
              payload,
              id: existing?.id,
            );
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      final repository = ref.read(vehicleAdminRepositoryProvider);
      final saved = existing == null
          ? await repository.createVehicle(payload)
          : await repository.updateVehicle(existing.id, payload);
      if (!mounted) return;
      ref.invalidate(vehicleListProvider);
      if (existing != null) {
        ref.invalidate(vehicleDetailProvider(existing.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vehiclesUpdated)));
        context.pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vehiclesCreated)));
        context.pushReplacement(
          '/media-upload',
          extra: MediaUploadConfig(
            type: MediaOwnerType.vehicle,
            id: saved.id,
            title: saved.identity.fullName,
          ),
        );
      }
    } on espace.PartnerApiException catch (error) {
      if (mounted) {
        _showError(
          error.fields.isEmpty ? error.message : error.fields.values.join('\n'),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showError(
          error.errors?.isNotEmpty == true
              ? error.errors!.values
                    .map(
                      (value) =>
                          value is List ? value.join('\n') : value.toString(),
                    )
                    .join('\n')
              : messageFor(error, l10n: l10n),
        );
      }
    } catch (error) {
      if (mounted) _showError(messageFor(error, l10n: l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.vehiclesSaveFailed),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.vehiclesOk),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _editing
            ? l10n.equipmentEditTitle
            : _forSale && !_forRent
            ? l10n.equipmentCreateSaleTitle
            : l10n.equipmentCreateRentalTitle,
      ),
      actions: [
        if (_editing && widget.mode.peutChoisirLaBoutique)
          IconButton(
            tooltip: l10n.vehiclesPhotos,
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: _saving
                ? null
                : () => context.push(
                    '/media-upload',
                    extra: MediaUploadConfig(
                      type: MediaOwnerType.vehicle,
                      id: widget.existing!.id,
                      title: widget.existing!.identity.fullName,
                    ),
                  ),
          ),
      ],
    ),
    body: ref
        .watch(catalogRefsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(messageFor(error, l10n: l10n)),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(catalogRefsProvider),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
          data: _buildForm,
        ),
  );

  Widget _buildForm(CatalogRefs refs) {
    _initializeRefs(refs);
    final brands = <int, String>{
      for (final brand in refs.brands.where((b) => b.isActive))
        brand.id: brand.name,
      if (_brandId != null &&
          !refs.brands.any((b) => b.id == _brandId && b.isActive))
        _brandId!: widget.existing?.identity.brand ?? '',
      -1: l10n.equipmentBrandNotListed,
    };
    _models = refs.vehicleModels
        .where(
          (model) =>
              model.isActive &&
              model.brandId == _brandId &&
              model.equipmentCategory == _type,
        )
        .toList();
    final existing = widget.existing;
    if (existing != null &&
        _modelId == existing.vehicleModelId &&
        _brandId == existing.brandId &&
        _type == existing.equipmentType &&
        !_models.any((model) => model.id == _modelId) &&
        _modelId != null) {
      _models.insert(
        0,
        ModelRef(
          id: _modelId!,
          brandId: _brandId!,
          name: existing.identity.model,
          equipmentCategory: _type,
        ),
      );
    }
    final models = <int, String>{
      for (final model in _models) model.id: model.name,
      -1: l10n.equipmentModelNotListed,
    };
    final fuels = <int, String>{
      -1: l10n.equipmentFuelNone,
      for (final fuel in refs.engineTypes)
        fuel.id: referenceFuelLabel(fuel.code, fuel.label, l10n),
      if (_fuelId != null &&
          !refs.engineTypes.any((fuel) => fuel.id == _fuelId))
        _fuelId!: existing?.identity.engineType ?? l10n.equipmentUnknown,
    };
    final locations = <int, String>{
      -1: l10n.vehiclesNoneOptional,
      for (final location in refs.locations)
        location.id: location.city.isEmpty
            ? location.name
            : '${location.name} — ${location.city}',
      if (_locationId != null &&
          !refs.locations.any((location) => location.id == _locationId))
        _locationId!:
            existing?.commercial.locationName ?? l10n.equipmentUnknown,
    };
    final currency = existing?.commercial.currency ?? 'XOF';
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.equipmentFormIntro),
                _section(l10n.equipmentIdentityTitle),
                VehicleReferenceDropdown<String>(
                  key: const ValueKey('equip-type'),
                  label: l10n.equipmentTypeLabel,
                  items: _types,
                  value: _type,
                  itemLabel: (type) => equipmentTypeLabel(type, l10n),
                  enabled: !_saving,
                  validator: (value) =>
                      value == null ? l10n.equipmentTypeRequired : null,
                  onChanged: (value) => setState(() {
                    if (value == _type) return;
                    _type = value;
                    _modelId = null;
                    _freeModel = false;
                    _details['model_label']!.clear();
                  }),
                ),
                _gap,
                VehicleReferenceDropdown<int>(
                  key: const ValueKey('equip-brand'),
                  label: l10n.vehiclesBrandLabel,
                  items: brands.keys.toList(),
                  value: _freeBrand ? -1 : _brandId,
                  itemLabel: (id) => brands[id]!,
                  enabled: !_saving,
                  validator: (value) =>
                      value == null ? l10n.vehiclesBrandRequired : null,
                  onChanged: (id) => setState(() {
                    _freeBrand = id == -1;
                    _brandId = _freeBrand ? null : id;
                    _modelId = null;
                    _freeModel = false;
                    _details['model_label']!.clear();
                  }),
                ),
                if (_freeBrand) ...[
                  _gap,
                  _detailText(
                    'brand_label',
                    l10n.equipmentBrandLabel,
                    required: true,
                  ),
                ],
                _gap,
                if (!_freeBrand && _models.isNotEmpty)
                  KeyedSubtree(
                    key: ValueKey('equipment-model-$_type-$_brandId'),
                    child: VehicleReferenceDropdown<int>(
                      key: const ValueKey('equip-model'),
                      label: l10n.vehiclesModelLabel,
                      items: models.keys.toList(),
                      value: _freeModel ? -1 : _modelId,
                      itemLabel: (id) => models[id]!,
                      enabled: !_saving,
                      validator: (value) =>
                          value == null ? l10n.vehiclesModelRequired : null,
                      onChanged: (id) => setState(() {
                        _freeModel = id == -1;
                        _modelId = _freeModel ? null : id;
                      }),
                    ),
                  ),
                if (_usesFreeModel) ...[
                  _detailText(
                    'model_label',
                    l10n.equipmentModelLabel,
                    required: true,
                  ),
                ],
                _gap,
                TextFormField(
                  key: const ValueKey('equip-year'),
                  controller: _year,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.equipmentYearLabel,
                  ),
                  validator: (value) {
                    if (_text(value ?? '') == null) return null;
                    final year = int.tryParse(value!.trim());
                    return year == null ||
                            year < 1950 ||
                            year > DateTime.now().year
                        ? l10n.vehiclesYearRangeInvalid(DateTime.now().year)
                        : null;
                  },
                ),
                _gap,
                VehicleReferenceDropdown<int>(
                  key: const ValueKey('equip-fuel'),
                  label: l10n.equipmentFuelLabel,
                  items: fuels.keys.toList(),
                  value: _fuelId ?? -1,
                  itemLabel: (id) => fuels[id]!,
                  enabled: !_saving,
                  onChanged: (id) =>
                      setState(() => _fuelId = id == -1 ? null : id),
                ),
                _section(l10n.equipmentPricesTitle),
                if (_forSale) ...[
                  _moneyField(
                    'equip-sale-price',
                    l10n.vehiclesSalePriceLabel,
                    _sale,
                    currency,
                    sale: true,
                  ),
                  _margin(_sale, 'sale_price'),
                  _gap,
                ],
                if (_forRent) ...[
                  Text(l10n.rentalVehicleRateRequired),
                  _gap,
                  _moneyField(
                    'equip-daily',
                    l10n.vehiclesDailyRateLabel,
                    _daily,
                    currency,
                    rate: true,
                  ),
                  _margin(_daily, 'rental_daily_rate'),
                  _gap,
                  _moneyField(
                    'equip-weekly',
                    l10n.vehiclesWeeklyRateLabel,
                    _weekly,
                    currency,
                    rate: true,
                  ),
                  _margin(_weekly, 'rental_weekly_rate'),
                  _gap,
                  _moneyField(
                    'equip-monthly',
                    l10n.vehiclesMonthlyRateLabel,
                    _monthly,
                    currency,
                    rate: true,
                  ),
                  _margin(_monthly, 'rental_monthly_rate'),
                  _gap,
                ],
                ExpansionTile(
                  key: const ValueKey('equip-optional-identity'),
                  controller: _identityExpansion,
                  maintainState: true,
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.equipmentOptionalIdentity),
                  children: [
                    _gap,
                    _detailText('serial_number', l10n.equipmentSerialNumber),
                    _gap,
                    _detailText(
                      'registration_number',
                      l10n.equipmentRegistrationNumber,
                    ),
                    _gap,
                    _detailText('park_number', l10n.equipmentParkNumber),
                    _gap,
                    _detailText(
                      'engine_serial_number',
                      l10n.equipmentEngineSerialNumber,
                    ),
                    _gap,
                  ],
                ),
                ExpansionTile(
                  key: const ValueKey('equip-optional-technical'),
                  controller: _technicalExpansion,
                  maintainState: true,
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.equipmentOptionalTechnical),
                  children: _technicalFields(),
                ),
                ExpansionTile(
                  key: const ValueKey('equip-optional-attachments'),
                  controller: _attachmentsExpansion,
                  maintainState: true,
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.equipmentOptionalAttachments),
                  children: [
                    _gap,
                    _detailText(
                      'attachments',
                      l10n.equipmentAttachments,
                      multiline: true,
                    ),
                    _gap,
                    if (_forRent) ...[
                      _moneyField(
                        'equip-deposit',
                        l10n.vehiclesDepositLabel,
                        _deposit,
                        currency,
                      ),
                      _margin(_deposit, 'rental_deposit'),
                      _gap,
                    ],
                    if (widget.mode.peutChoisirLaBoutique &&
                        locations.length > 1) ...[
                      VehicleReferenceDropdown<int>(
                        key: const ValueKey('equip-location'),
                        label: l10n.vehiclesBranchLabel,
                        items: locations.keys.toList(),
                        value: _locationId ?? -1,
                        itemLabel: (id) => locations[id]!,
                        enabled: !_saving,
                        onChanged: (id) =>
                            setState(() => _locationId = id == -1 ? null : id),
                      ),
                      _gap,
                    ],
                    TextFormField(
                      key: const ValueKey('equip-site'),
                      controller: _site,
                      enabled: !_saving,
                      decoration: InputDecoration(
                        labelText: l10n.rentalVehiclePickupPlace,
                      ),
                    ),
                    _gap,
                    TextFormField(
                      key: const ValueKey('equip-description'),
                      controller: _description,
                      enabled: !_saving,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: l10n.catalogSectionDescription,
                      ),
                    ),
                    _gap,
                  ],
                ),
                const SizedBox(height: 24),
                if (_editing) ...[
                  OutlinedButton.icon(
                    key: const ValueKey('equip-documents'),
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EquipmentDocumentsPage(
                                vehicleId: widget.existing!.id,
                                mode: widget.mode,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.folder_outlined),
                    label: Text(l10n.equipmentDocuments),
                  ),
                  _gap,
                ] else ...[
                  Text(l10n.equipmentDocumentAfterSaveHint),
                  _gap,
                ],
                FilledButton.icon(
                  key: const ValueKey('equip-save'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(l10n.equipmentSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _gap = SizedBox(height: 16);
  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _detailText(
    String field,
    String label, {
    bool required = false,
    bool multiline = false,
  }) => TextFormField(
    key: ValueKey('equip-${field.replaceAll('_', '-')}'),
    controller: _details[field],
    enabled: !_saving,
    minLines: multiline ? 2 : 1,
    maxLines: multiline ? 5 : 1,
    decoration: InputDecoration(labelText: label, errorMaxLines: 4),
    validator: (value) {
      final text = _text(value ?? '');
      final maxLength = switch (field) {
        'model_label' => 200,
        'registration_number' || 'park_number' => 50,
        'attachments' => 2000,
        _ => 100,
      };
      if (required && text == null) {
        return field == 'brand_label'
            ? l10n.vehiclesBrandRequired
            : l10n.vehiclesModelRequired;
      }
      if (text != null && text.length > maxLength) {
        return l10n.heavyConfigurationTextTooLong(maxLength);
      }
      return null;
    },
  );

  Widget _detailNumber(String field, String label) => TextFormField(
    key: ValueKey(
      field == 'working_height_m'
          ? 'equip-working-height'
          : 'equip-${field.replaceAll('_', '-')}',
    ),
    controller: _details[field],
    enabled: !_saving,
    keyboardType: TextInputType.numberWithOptions(decimal: field != 'pto_rpm'),
    decoration: InputDecoration(labelText: label, errorMaxLines: 4),
    validator: (value) {
      if (_text(value ?? '') == null) return null;
      final number = _number(value!);
      return number == null ||
              (field == 'pto_rpm' && number != number.truncateToDouble())
          ? l10n.equipmentValueInvalid
          : null;
    },
  );

  List<Widget> _technicalFields() {
    final labels = <String, String>{
      'operating_hours': l10n.equipmentOperatingHours,
      'odometer_km': l10n.equipmentOdometerKm,
      'power_kw': l10n.equipmentPowerKw,
      'rated_load_kg': l10n.equipmentRatedLoadKg,
      'working_height_m': l10n.equipmentWorkingHeightM,
      'outreach_m': l10n.equipmentOutreachM,
      'lift_height_m': l10n.equipmentLiftHeightM,
      'operating_weight_kg': l10n.equipmentOperatingWeightKg,
      'bucket_capacity_m3': l10n.equipmentBucketCapacityM3,
      'pto_rpm': l10n.equipmentPtoRpm,
    };
    return [
      _gap,
      _detailNumber('operating_hours', labels['operating_hours']!),
      _gap,
      TextFormField(
        key: const ValueKey('equip-hour-reading-date'),
        controller: _details['hour_reading_date'],
        enabled: !_saving,
        keyboardType: TextInputType.datetime,
        decoration: InputDecoration(
          labelText: l10n.equipmentHourReadingDate,
          errorMaxLines: 4,
        ),
        validator: (value) {
          final text = _text(value ?? '');
          if (text == null) return null;
          final date = DateTime.tryParse(text);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          return !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
                  date == null ||
                  date.toIso8601String().substring(0, 10) != text ||
                  date.isAfter(today)
              ? l10n.equipmentDateInvalid
              : null;
        },
      ),
      _gap,
      for (final field in labels.keys.where(
        (field) =>
            field != 'operating_hours' && _visibleDetails.contains(field),
      )) ...[_detailNumber(field, labels[field]!), _gap],
      _optionalEnum(
        'equip-transmission',
        l10n.equipmentTransmission,
        const ['mechanical', 'hydrostatic', 'powershift', 'electric', 'other'],
        _transmission,
        (value) => equipmentTransmissionLabel(value, l10n),
        (value) => setState(() => _transmission = value),
      ),
      _gap,
      _optionalEnum(
        'equip-cabin',
        l10n.equipmentCabin,
        const ['open', 'closed', 'air_conditioned'],
        _cabin,
        (value) => equipmentCabinLabel(value, l10n),
        (value) => setState(() => _cabin = value),
      ),
      _gap,
      _optionalEnum(
        'equip-quick-coupler',
        l10n.equipmentQuickCoupler,
        const ['yes', 'no'],
        _quickCoupler == null
            ? null
            : _quickCoupler!
            ? 'yes'
            : 'no',
        (value) => value == 'yes' ? l10n.equipmentYes : l10n.equipmentNo,
        (value) => setState(
          () => _quickCoupler = value == null ? null : value == 'yes',
        ),
      ),
      _gap,
    ];
  }

  Widget _optionalEnum(
    String key,
    String label,
    List<String> options,
    String? value,
    String Function(String) itemLabel,
    ValueChanged<String?> onChanged,
  ) => VehicleReferenceDropdown<String>(
    key: ValueKey(key),
    label: label,
    items: [
      '',
      ...options,
      if (value != null && !options.contains(value)) value,
    ],
    value: value ?? '',
    enabled: !_saving,
    itemLabel: (value) =>
        value.isEmpty ? l10n.equipmentUnknown : itemLabel(value),
    onChanged: (value) => onChanged(value == '' ? null : value),
  );

  Widget _moneyField(
    String key,
    String label,
    TextEditingController controller,
    String currency, {
    bool rate = false,
    bool sale = false,
  }) => TextFormField(
    key: ValueKey(key),
    controller: controller,
    enabled: !_saving,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      suffixText: currency,
      errorMaxLines: 4,
    ),
    onChanged: (_) => setState(() {}),
    validator: (value) {
      final text = _text(value ?? '');
      if (text != null && _number(text, money: true) == null) {
        return l10n.vehiclesAmountInvalid;
      }
      if (sale && text == null) return l10n.equipmentSalePriceRequired;
      if (rate &&
          [_daily, _weekly, _monthly].every((c) => _text(c.text) == null)) {
        return l10n.rentalVehicleRateRequired;
      }
      return null;
    },
  );

  Widget _margin(TextEditingController controller, String field) {
    if (!widget.mode.estPartenaire ||
        (_editing &&
            _number(controller.text, money: true) == _initialPrices[field])) {
      return const SizedBox.shrink();
    }
    final rate =
        ref.watch(espace.partnerSessionProvider).profile?.margePourcentage ?? 0;
    return MargeRecapitulatif(
      prixPropose: _number(controller.text, money: true),
      pourcentage: rate,
      libelle: field == 'sale_price'
          ? l10n.vehiclesBuyerPriceLabel
          : l10n.vehiclesBuyerRateLabel,
    );
  }
}
