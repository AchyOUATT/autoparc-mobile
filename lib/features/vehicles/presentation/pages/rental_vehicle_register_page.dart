import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/l10n/reference_labels.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/data/media_repository.dart';
import '../../../../shared/presentation/pages/media_upload_page.dart';
import '../../../catalog/data/models/vehicle.dart';
import '../../../catalog/presentation/catalog_reference_labels.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../partner_accounts/data/partner_repository.dart' as espace;
import '../../../partner_accounts/presentation/marge_recapitulatif.dart';
import '../../../partner_accounts/presentation/partner_session.dart' as espace;
import '../../data/models/catalog_refs.dart';
import '../../data/vehicle_admin_repository.dart';
import '../providers/vehicle_refs_provider.dart';
import '../widgets/transmission_selector.dart';
import '../widgets/vehicle_reference_dropdown.dart';
import 'vehicle_form_mode.dart';

/// The rental offer asks for its identity and rates in one short form.
/// Existing administrative, sales and technical details are kept by omission.
class RentalVehicleRegisterPage extends ConsumerStatefulWidget {
  const RentalVehicleRegisterPage({
    super.key,
    this.existing,
    this.mode = VehicleFormMode.personnel,
  });

  final Vehicle? existing;
  final VehicleFormMode mode;

  @override
  ConsumerState<RentalVehicleRegisterPage> createState() =>
      _RentalVehicleRegisterPageState();
}

class _RentalVehicleRegisterPageState
    extends ConsumerState<RentalVehicleRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _optionalExpansion = ExpansibleController();
  final _year = TextEditingController();
  final _seats = TextEditingController();
  final _daily = TextEditingController();
  final _weekly = TextEditingController();
  final _monthly = TextEditingController();
  final _deposit = TextEditingController();
  final _site = TextEditingController();
  final _description = TextEditingController();

  BrandRef? _brand;
  ModelRef? _model;
  EngineTypeRef? _fuel;
  LocationRef? _location;
  String? _transmission;
  bool _refsInitialized = false;
  bool _saving = false;
  num? _initialDaily;
  num? _initialWeekly;
  num? _initialMonthly;
  num? _initialDeposit;
  final _selectedFeatureIds = <int>{};
  final _initialFeatureIds = <int>{};

  AppLocalizations get l10n => AppLocalizations.of(context);
  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;

    _year.text = existing.identity.year?.toString() ?? '';
    _seats.text = existing.seats?.toString() ?? '';
    _transmission = existing.transmission;
    _site.text = existing.commercial.site ?? '';
    _description.text = existing.description ?? '';
    _selectedFeatureIds.addAll(existing.features.map((feature) => feature.id));
    _initialFeatureIds.addAll(_selectedFeatureIds);
    num? originalPrice(String field, num? publicPrice) =>
        widget.mode.estPartenaire
        ? existing.proposedPriceExcludingCommission(field) ?? publicPrice
        : publicPrice;
    _initialDaily = originalPrice(
      'rental_daily_rate',
      existing.commercial.rentalDailyRate,
    );
    _initialMonthly = originalPrice(
      'rental_monthly_rate',
      existing.commercial.rentalMonthlyRate,
    );
    _initialWeekly = originalPrice(
      'rental_weekly_rate',
      existing.commercial.rentalWeeklyRate,
    );
    _initialDeposit = originalPrice(
      'rental_deposit',
      existing.commercial.rentalDeposit,
    );
    _daily.text = _amountText(_initialDaily);
    _weekly.text = _amountText(_initialWeekly);
    _monthly.text = _amountText(_initialMonthly);
    _deposit.text = _amountText(_initialDeposit);
  }

  @override
  void dispose() {
    for (final controller in [
      _year,
      _seats,
      _daily,
      _weekly,
      _monthly,
      _deposit,
      _site,
      _description,
    ]) {
      controller.dispose();
    }
    _optionalExpansion.dispose();
    super.dispose();
  }

  static String _amountText(num? amount) {
    if (amount == null) return '';
    return amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
  }

  static num? _amount(String text) {
    final value = text.replaceAll(RegExp(r'[\s\u00a0\u202f]'), '');
    if (!RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(value)) return null;
    final amount = num.tryParse(value.replaceAll(',', '.'));
    return amount != null && amount.isFinite ? amount : null;
  }

  static String? _optionalText(String text) {
    final value = text.trim();
    return value.isEmpty ? null : value;
  }

  void _initializeRefs(CatalogRefs refs) {
    if (_refsInitialized) return;
    _refsInitialized = true;
    final existing = widget.existing;
    if (existing == null) return;

    _brand = refs.brands.where((b) => b.id == existing.brandId).firstOrNull;
    if (_brand == null && existing.brandId != null) {
      _brand = BrandRef(
        id: existing.brandId!,
        name: existing.identity.brand,
        isActive: false,
      );
    }
    _model = refs.vehicleModels
        .where(
          (m) => m.id == existing.vehicleModelId && m.brandId == _brand?.id,
        )
        .firstOrNull;
    if (_model == null && existing.vehicleModelId != null && _brand != null) {
      _model = ModelRef(
        id: existing.vehicleModelId!,
        brandId: _brand!.id,
        name: existing.identity.model,
        generation: existing.identity.generation,
        isActive: false,
      );
    }
    _fuel = refs.engineTypes
        .where((f) => f.id == existing.engineTypeId)
        .firstOrNull;
    if (_fuel == null && existing.engineTypeId != null) {
      _fuel = EngineTypeRef(
        id: existing.engineTypeId!,
        code: existing.identity.engineTypeCode ?? '',
        label: existing.identity.engineType ?? l10n.vehiclesEngineTypeLabel,
        usesFuel: true,
        usesBattery: false,
      );
    }
    if (widget.mode.peutChoisirLaBoutique) {
      final locationId = existing.commercial.locationId;
      _location = refs.locations.where((l) => l.id == locationId).firstOrNull;
      if (_location == null && locationId != null) {
        _location = LocationRef(
          id: locationId,
          name: existing.commercial.locationName ?? l10n.vehiclesBranchLabel,
          city: existing.commercial.locationCity ?? '',
        );
      }
    }
  }

  Map<String, dynamic> _payload() {
    final existing = widget.existing;
    final modelChanged =
        existing != null &&
        (_brand!.id != existing.brandId ||
            _model!.id != existing.vehicleModelId);
    final fuelChanged = existing != null && _fuel!.id != existing.engineTypeId;
    final daily = _amount(_daily.text);
    final weekly = _amount(_weekly.text);
    final monthly = _amount(_monthly.text);
    final deposit = _amount(_deposit.text);
    final seats = int.tryParse(_seats.text.trim());
    final site = _optionalText(_site.text);
    final description = _optionalText(_description.text);
    return {
      'brand_id': _brand!.id,
      'vehicle_model_id': _model!.id,
      'manufacturing_year': int.parse(_year.text.trim()),
      'engine_type_id': _fuel!.id,
      if (!_editing) ...{'availability': 'rent', 'currency': 'XOF'},
      if (!_editing || modelChanged) ...{
        if (_model!.resolvedVehicleType != null)
          'vehicle_type': _model!.resolvedVehicleType,
        if (_editing || _model!.inferredBodyStyle != null)
          'body_style': _model!.inferredBodyStyle,
      },
      if (modelChanged || fuelChanged) ...{
        'trim_id': null,
        'engine_code': null,
        'power_hp': null,
        'power_kw': null,
        'engine_displacement_cc': null,
        'cylinders': null,
        'torque_nm': null,
        'gear_count': null,
        'consumption_urban': null,
        'consumption_extra_urban': null,
        'consumption_combined': null,
        'electric_consumption_kwh': null,
        'battery_capacity_kwh': null,
        'electric_range_km': null,
      },
      if (modelChanged) ...{'drivetrain_id': null, 'heavy_configuration': null},
      if ((!_editing && _transmission != null) ||
          (_editing && _transmission != existing!.transmission))
        'transmission': _transmission,
      if ((!_editing && seats != null) ||
          (_editing && seats != existing!.seats))
        'seats': seats,
      if ((!_editing && daily != null) || (_editing && daily != _initialDaily))
        'rental_daily_rate': daily,
      if ((!_editing && weekly != null) ||
          (_editing && weekly != _initialWeekly))
        'rental_weekly_rate': weekly,
      if ((!_editing && monthly != null) ||
          (_editing && monthly != _initialMonthly))
        'rental_monthly_rate': monthly,
      if ((!_editing && deposit != null) ||
          (_editing && deposit != _initialDeposit))
        'rental_deposit': deposit,
      if ((!_editing && site != null) ||
          (_editing && site != _optionalText(existing!.commercial.site ?? '')))
        'site': site,
      if ((!_editing && description != null) ||
          (_editing &&
              description != _optionalText(existing!.description ?? '')))
        'description': description,
      if (widget.mode.peutChoisirLaBoutique &&
          ((!_editing && _location != null) ||
              (_editing && _location?.id != existing!.commercial.locationId)))
        'location_id': _location?.id,
      if ((!_editing && _selectedFeatureIds.isNotEmpty) ||
          (_editing && !setEquals(_selectedFeatureIds, _initialFeatureIds)))
        'features': _selectedFeatureIds.toList()..sort(),
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    final invalidFields = _formKey.currentState?.validateGranularly();
    if (invalidFields == null) return;
    if (invalidFields.isNotEmpty) {
      // Optional does not mean that a malformed entered value can be saved.
      // Reopen the group so a deposit error cannot remain hidden.
      _optionalExpansion.expand();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !invalidFields.first.mounted) return;
        Scrollable.ensureVisible(
          invalidFields.first.context,
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
        _editing ? l10n.rentalVehicleEditTitle : l10n.rentalVehicleCreateTitle,
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
    final brands = refs.brands.where((b) => b.isActive).toList();
    if (_brand != null && !brands.any((b) => b.id == _brand!.id)) {
      brands.insert(0, _brand!);
    }
    final models = _brand == null
        ? <ModelRef>[]
        : refs.modelsForBrand(_brand!.id);
    if (_model != null && !models.any((m) => m.id == _model!.id)) {
      models.insert(0, _model!);
    }
    final fuels = [...refs.engineTypes];
    if (_fuel != null && !fuels.any((f) => f.id == _fuel!.id)) {
      fuels.insert(0, _fuel!);
    }
    final locations = [...refs.locations];
    if (_location != null && !locations.any((l) => l.id == _location!.id)) {
      locations.insert(0, _location!);
    }
    final currency = widget.existing?.commercial.currency ?? 'XOF';
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
    Widget spacing() => const SizedBox(height: 16);
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
                Text(l10n.rentalVehicleIntro),
                section(l10n.rentalVehicleIdentityTitle),
                VehicleReferenceDropdown<BrandRef>(
                  key: const ValueKey('rental-brand'),
                  label: l10n.vehiclesBrandLabel,
                  items: brands,
                  value: _brand,
                  itemLabel: (b) => b.name,
                  enabled: !_saving,
                  validator: (value) =>
                      value == null ? l10n.vehiclesBrandRequired : null,
                  onChanged: (value) => setState(() {
                    if (value?.id == _brand?.id) return;
                    _brand = value;
                    _model = null;
                    _fuel = null;
                  }),
                ),
                spacing(),
                VehicleReferenceDropdown<ModelRef>(
                  key: const ValueKey('rental-model'),
                  label: l10n.vehiclesModelLabel,
                  items: models,
                  value: _model,
                  itemLabel: (model) => referenceModelDisplayName(model, l10n),
                  enabled: !_saving && _brand != null,
                  validator: (value) =>
                      value == null ? l10n.vehiclesModelRequired : null,
                  onChanged: (value) => setState(() {
                    if (value?.id == _model?.id) return;
                    _model = value;
                    _fuel = null;
                  }),
                ),
                spacing(),
                TextFormField(
                  key: const ValueKey('rental-year'),
                  controller: _year,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: l10n.vehiclesManufactureYearLabel,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.vehiclesYearRequired;
                    }
                    final year = int.tryParse(value.trim());
                    return year == null ||
                            year < 1950 ||
                            year > DateTime.now().year
                        ? l10n.vehiclesYearRangeInvalid(DateTime.now().year)
                        : null;
                  },
                ),
                spacing(),
                VehicleReferenceDropdown<EngineTypeRef>(
                  key: const ValueKey('rental-fuel'),
                  label: l10n.vehiclesEngineTypeLabel,
                  items: fuels,
                  value: _fuel,
                  itemLabel: (fuel) =>
                      referenceFuelLabel(fuel.code, fuel.label, l10n),
                  enabled: !_saving,
                  validator: (value) =>
                      value == null ? l10n.vehiclesEngineTypeRequired : null,
                  onChanged: (value) => setState(() => _fuel = value),
                ),
                spacing(),
                TransmissionSelector(
                  key: const ValueKey('rental-transmission'),
                  label: l10n.vehiclesTransmissionLabel,
                  value: _transmission,
                  enabled: !_saving,
                  onChanged: (value) => setState(() => _transmission = value),
                ),
                spacing(),
                TextFormField(
                  key: const ValueKey('rental-seats'),
                  controller: _seats,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.catalogFieldSeats,
                    helperText: l10n.rentalVehicleOptionalHint,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final seats = int.tryParse(value.trim());
                    return seats == null || seats < 1 || seats > 70
                        ? l10n.rentalVehicleSeatsInvalid
                        : null;
                  },
                ),
                section(l10n.rentalVehicleRatesTitle),
                Text(l10n.rentalVehicleRateRequired),
                spacing(),
                _moneyField(
                  'rental-daily',
                  l10n.vehiclesDailyRateLabel,
                  _daily,
                  currency,
                  rate: true,
                ),
                _margin(_daily, _initialDaily),
                spacing(),
                _moneyField(
                  'rental-weekly',
                  l10n.vehiclesWeeklyRateLabel,
                  _weekly,
                  currency,
                  rate: true,
                ),
                _margin(_weekly, _initialWeekly),
                spacing(),
                _moneyField(
                  'rental-monthly',
                  l10n.vehiclesMonthlyRateLabel,
                  _monthly,
                  currency,
                  rate: true,
                ),
                _margin(_monthly, _initialMonthly),
                const SizedBox(height: 24),
                _equipment(refs),
                ExpansionTile(
                  key: const ValueKey('rental-optional'),
                  controller: _optionalExpansion,
                  maintainState: true,
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.rentalVehicleOptionalTitle),
                  children: [
                    const SizedBox(height: 16),
                    _moneyField(
                      'rental-deposit',
                      l10n.vehiclesDepositLabel,
                      _deposit,
                      currency,
                    ),
                    spacing(),
                    if (widget.mode.peutChoisirLaBoutique &&
                        locations.isNotEmpty) ...[
                      VehicleReferenceDropdown<LocationRef>(
                        key: const ValueKey('rental-location'),
                        label: l10n.vehiclesBranchLabel,
                        items: locations,
                        value: _location,
                        itemLabel: (location) => location.city.isEmpty
                            ? location.name
                            : '${location.name} — ${location.city}',
                        enabled: !_saving,
                        onChanged: (value) => setState(() => _location = value),
                      ),
                      spacing(),
                    ],
                    TextFormField(
                      key: const ValueKey('rental-site'),
                      controller: _site,
                      enabled: !_saving,
                      decoration: InputDecoration(
                        labelText: l10n.rentalVehiclePickupPlace,
                        helperText: l10n.rentalVehiclePickupPlaceHelp,
                        helperMaxLines: 4,
                      ),
                    ),
                    spacing(),
                    TextFormField(
                      key: const ValueKey('rental-description'),
                      controller: _description,
                      enabled: !_saving,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: l10n.catalogSectionDescription,
                        hintText: l10n.vehiclesDescriptionHint,
                        helperText: l10n.rentalVehicleOtherEquipmentHelp,
                        helperMaxLines: 6,
                      ),
                    ),
                    spacing(),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('rental-save'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(l10n.rentalVehicleSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _moneyField(
    String key,
    String label,
    TextEditingController controller,
    String currency, {
    bool rate = false,
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
      final text = (value ?? '').trim();
      if (text.isNotEmpty && _amount(text) == null) {
        return l10n.vehiclesAmountInvalid;
      }
      if (rate &&
          _daily.text.trim().isEmpty &&
          _weekly.text.trim().isEmpty &&
          _monthly.text.trim().isEmpty) {
        return l10n.rentalVehicleRateRequired;
      }
      return null;
    },
  );

  Widget _equipment(CatalogRefs refs) {
    final features = <int, FeatureRef>{
      for (final feature in widget.existing?.features ?? <VehicleFeature>[])
        feature.id: FeatureRef(
          id: feature.id,
          name: feature.name,
          category: feature.category,
        ),
      for (final feature in refs.features) feature.id: feature,
    };
    if (features.isEmpty) return const SizedBox.shrink();
    final groups = <String, List<FeatureRef>>{};
    for (final feature in features.values) {
      groups.putIfAbsent(feature.category ?? 'autre', () => []).add(feature);
    }
    final labels = {
      'dotation': l10n.vehiclesFeatureStandard,
      'confort': l10n.vehiclesFeatureComfort,
      'securite': l10n.vehiclesFeatureSafety,
      'multimedia': l10n.vehiclesFeatureMultimedia,
      'aide_conduite': l10n.vehiclesFeatureDriverAssistance,
      'autre': l10n.vehiclesFeatureOther,
    };
    return ExpansionTile(
      key: const ValueKey('rental-equipment'),
      maintainState: true,
      tilePadding: EdgeInsets.zero,
      title: Text(l10n.rentalVehicleEquipmentTitle),
      children: [
        Text(l10n.rentalVehicleEquipmentHelp),
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                labels[group.key] ?? group.key,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          for (final feature in group.value)
            CheckboxListTile(
              key: ValueKey('rental-feature-${feature.id}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(catalogFeatureLabel(feature.name, l10n)),
              value: _selectedFeatureIds.contains(feature.id),
              onChanged: _saving
                  ? null
                  : (selected) => setState(() {
                      if (selected == true) {
                        _selectedFeatureIds.add(feature.id);
                      } else {
                        _selectedFeatureIds.remove(feature.id);
                      }
                    }),
            ),
        ],
      ],
    );
  }

  Widget _margin(TextEditingController controller, num? initialAmount) {
    if (!widget.mode.estPartenaire) return const SizedBox.shrink();
    if (_editing && _amount(controller.text) == initialAmount) {
      // An untouched rate is omitted from PATCH and keeps its saved margin.
      return const SizedBox.shrink();
    }
    final rate =
        ref.watch(espace.partnerSessionProvider).profile?.margePourcentage ?? 0;
    return MargeRecapitulatif(
      prixPropose: _amount(controller.text),
      pourcentage: rate,
      libelle: l10n.vehiclesBuyerRateLabel,
    );
  }
}
