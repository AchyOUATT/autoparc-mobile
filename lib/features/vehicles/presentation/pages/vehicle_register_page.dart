import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/catalog_refs.dart';
import '../providers/vehicle_refs_provider.dart';
import '../../data/vehicle_admin_repository.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../shared/presentation/pages/media_upload_page.dart';
import '../../../../shared/data/media_repository.dart';
import '../../../../features/catalog/data/models/vehicle.dart';
import '../../../../features/catalog/presentation/providers/catalog_providers.dart';
import '../../../../features/partners/data/models/partner.dart';
import '../../../../features/partners/data/partner_repository.dart';

// ── Provider partenaires pour le formulaire ──────────────────────
final _vehiclePartnersProvider =
    FutureProvider.autoDispose<List<Partner>>((ref) async {
  final page = await ref.read(partnerRepositoryProvider).getPartners(perPage: 200);
  return page.data;
});

// ════════════════════════════════════════════════════════════════════
// Page
// ════════════════════════════════════════════════════════════════════

class VehicleRegisterPage extends ConsumerStatefulWidget {
  final Vehicle? existing; // null → création, non-null → édition
  const VehicleRegisterPage({super.key, this.existing});

  @override
  ConsumerState<VehicleRegisterPage> createState() =>
      _VehicleRegisterPageState();
}

class _VehicleRegisterPageState extends ConsumerState<VehicleRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _submitting = false;
  bool _refsInitialized = false; // pré-sélection refs (mode édition)

  Vehicle? get _existing => widget.existing;

  // ── Step 0 — Type & Identification ───────────────────────────────
  String  _vehicleType = 'passenger'; // 'passenger' | 'utility' | 'heavy'
  String? _bodyStyle;                 // 'sedan' | 'suv' | 'pickup' | …
  final _vinCtrl   = TextEditingController();
  final _plateCtrl = TextEditingController(); // plaque (optionnel)

  // ── Step 2 — Identité ──────────────────────────────────────────────
  BrandRef? _brand;
  ModelRef? _model;
  TrimRef?  _trim;
  ColorRef? _color;
  final _yearCtrl = TextEditingController();

  // ── Step 3 — Technique ─────────────────────────────────────────────
  EngineTypeRef? _engineType;
  DrivetrainRef? _drivetrain;
  String _transmission = 'automatic'; // 'manual' | 'automatic' | 'cvt'
  final _powerCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '5');
  final _doorsCtrl = TextEditingController(text: '4');
  final Set<int> _selectedFeatureIds = {}; // IDs des équipements sélectionnés

  // ── Step 4 — Commercial ────────────────────────────────────────────
  String _condition    = 'used';   // 'new' | 'used' | 'damaged'
  String _availability = 'sale';   // 'sale' | 'rent' | 'both'

  /// Mise en avant commerciale. Chaîne vide = aucune promotion : le
  /// `_ChoiceGroup` exige une valeur non nulle, on la traduit en `null` au
  /// moment de l'envoi.
  String _dealType = '';
  bool   _negotiable   = false;
  int?   _selectedPartnerId;
  final _salePriceCtrl       = TextEditingController();
  final _rentalDailyCtrl     = TextEditingController();
  final _rentalDepositCtrl   = TextEditingController();
  final _mileageCtrl         = TextEditingController();
  final _siteCtrl            = TextEditingController();
  LocationRef? _selectedLocation;   // agence / showroom structuré
  final _descriptionCtrl     = TextEditingController();


  @override
  void initState() {
    super.initState();
    final e = _existing;
    if (e != null) {
      _vehicleType  = e.vehicleType;
      _bodyStyle    = e.bodyStyle;
      _vinCtrl.text = e.vin ?? '';
      if (e.identity.year != null) _yearCtrl.text = e.identity.year.toString();
      _condition    = e.commercial.condition;
      _availability = e.commercial.availability;
      _negotiable   = e.commercial.priceNegotiable;
      _dealType     = e.commercial.dealType ?? '';
      if (e.commercial.salePrice != null)
        _salePriceCtrl.text = _fmtPrice(e.commercial.salePrice!);
      if (e.commercial.rentalDailyRate != null)
        _rentalDailyCtrl.text = _fmtPrice(e.commercial.rentalDailyRate!);
      if (e.commercial.rentalDeposit != null)
        _rentalDepositCtrl.text = _fmtPrice(e.commercial.rentalDeposit!);
      if (e.commercial.site != null) _siteCtrl.text = e.commercial.site!;
      _selectedFeatureIds.addAll(e.features.map((f) => f.id));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _vinCtrl, _plateCtrl, _yearCtrl, _powerCtrl, _seatsCtrl, _doorsCtrl,
      _salePriceCtrl, _rentalDailyCtrl, _rentalDepositCtrl, _mileageCtrl,
      _siteCtrl, _descriptionCtrl,
    ]) c.dispose();
    super.dispose();
  }

  // ── Soumission ─────────────────────────────────────────────────────

  // ── Validation par étape ──────────────────────────────────────────

  /// Retourne un message d'erreur si l'étape courante est incomplète, null sinon.
  String? _validateCurrentStep() {
    switch (_step) {
      case 1: // Identité
        if (_brand == null) return 'Veuillez sélectionner une marque.';
        if (_model == null) return 'Veuillez sélectionner un modèle.';
        if (_yearCtrl.text.trim().isEmpty) return 'Veuillez saisir l\'année de fabrication.';
        final y = int.tryParse(_yearCtrl.text);
        if (y == null || y < 1950 || y > DateTime.now().year) {
          return 'Année invalide (1950–${DateTime.now().year}).';
        }
      case 2: // Technique
        if (_engineType == null) return 'Veuillez sélectionner le type de motorisation.';
      case 3: // Commercial
        final forSale = _availability == 'sale' || _availability == 'both';
        final forRent = _availability == 'rent' || _availability == 'both';
        if (forSale && _salePriceCtrl.text.trim().isEmpty) {
          return 'Le prix de vente est obligatoire.';
        }
        if (forRent && _rentalDailyCtrl.text.trim().isEmpty) {
          return 'Le tarif journalier est obligatoire.';
        }
    }
    return null;
  }

  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Appelé par le bouton Suivant / Enregistrer du Stepper.
  Future<void> _onContinue(CatalogRefs refs) async {
    // Avancer d'une étape → valider uniquement l'étape courante
    if (_step < 3) {
      final error = _validateCurrentStep();
      if (error != null) {
        _snackError(error);
        return;
      }
      setState(() => _step++);
      return;
    }

    // Dernière étape → valider le dernier bloc puis soumettre
    final error = _validateCurrentStep();
    if (error != null) {
      _snackError(error);
      return;
    }

    await _submit(refs);
  }

  // ── Soumission ─────────────────────────────────────────────────────

  Future<void> _submit(CatalogRefs refs) async {
    setState(() => _submitting = true);

    try {
      final payload  = _buildPayload();
      final repo     = ref.read(vehicleAdminRepositoryProvider);
      final existing = _existing;
      final Vehicle vehicle;

      if (existing != null) {
        vehicle = await repo.updateVehicle(existing.id, payload);
      } else {
        vehicle = await repo.createVehicle(payload);
      }

      if (mounted) {
        ref.invalidate(vehicleListProvider);
        if (existing != null) {
          ref.invalidate(vehicleDetailProvider(vehicle.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Véhicule mis à jour ✓'),
                backgroundColor: Colors.green),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Véhicule enregistré — ajoutez des photos !'),
              backgroundColor: Colors.green,
            ),
          );
          context.pushReplacement(
            '/media-upload',
            extra: MediaUploadConfig(
              type:  MediaOwnerType.vehicle,
              id:    vehicle.id,
              title: vehicle.identity.fullName,
            ),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        final msg = e.errors?.entries
            .map((entry) => '${entry.key} : ${entry.value.first}')
            .join('\n') ??
            e.message;
        _showErrors(msg);
      }
    } catch (e) {
      if (mounted) _showErrors('Erreur inattendue : $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    final bool forSale   = _availability == 'sale' || _availability == 'both';
    final bool forRent   = _availability == 'rent' || _availability == 'both';
    final bool hasPlate  = _plateCtrl.text.trim().isNotEmpty;
    final int? mileage   = _mileageCtrl.text.isNotEmpty
        ? int.tryParse(_mileageCtrl.text)
        : null;

    return <String, dynamic>{
      'vehicle_type':       _vehicleType,
      if (_bodyStyle != null) 'body_style': _bodyStyle,
      if (_vinCtrl.text.trim().isNotEmpty)   'vin':          _vinCtrl.text.trim(),
      if (hasPlate) 'plate_number': _plateCtrl.text.trim(),
      'brand_id':           _brand!.id,
      'vehicle_model_id':   _model!.id,
      if (_trim != null)       'trim_id':      _trim!.id,
      if (_color != null)      'color_id':     _color!.id,
      'manufacturing_year': int.parse(_yearCtrl.text),
      'engine_type_id':     _engineType!.id,
      if (_drivetrain != null) 'drivetrain_id': _drivetrain!.id,
      'transmission':       _transmission,
      if (_powerCtrl.text.isNotEmpty) 'power_hp': int.parse(_powerCtrl.text),
      if (_seatsCtrl.text.isNotEmpty) 'seats':    int.parse(_seatsCtrl.text),
      if (_doorsCtrl.text.isNotEmpty) 'doors':    int.parse(_doorsCtrl.text),
      'condition':          _condition,
      'availability':       _availability,
      'price_negotiable':   _negotiable,
      // Explicitement null quand aucune promotion : c'est ce qui permet d'en
      // retirer une à l'édition.
      'deal_type':          _dealType.isEmpty ? null : _dealType,
      if (forSale && _salePriceCtrl.text.trim().isNotEmpty)
        'sale_price': int.parse(_salePriceCtrl.text.replaceAll(RegExp(r'\s'), '')),
      if (forRent && _rentalDailyCtrl.text.trim().isNotEmpty)
        'rental_daily_rate': int.parse(_rentalDailyCtrl.text.replaceAll(RegExp(r'\s'), '')),
      if (forRent && _rentalDepositCtrl.text.trim().isNotEmpty)
        'rental_deposit': int.parse(_rentalDepositCtrl.text.replaceAll(RegExp(r'\s'), '')),
      if (_siteCtrl.text.isNotEmpty) 'site': _siteCtrl.text.trim(),
      if (_descriptionCtrl.text.isNotEmpty) 'description': _descriptionCtrl.text.trim(),
      'currency':           'XOF',
      if (_selectedFeatureIds.isNotEmpty) 'features': _selectedFeatureIds.toList(),
      if (_selectedLocation  != null) 'location_id': _selectedLocation!.id,
      if (_selectedPartnerId != null) 'partner_id':  _selectedPartnerId,
      // Kilométrage → sous-objet selon le statut du véhicule
      // - avec plaque  : registered → registration.mileage_km
      // - sans plaque  : import     → import.odometer_at_import_km
      if (mileage != null && hasPlate)
        'registration': {'mileage_km': mileage},
      if (mileage != null && !hasPlate)
        'import': {'odometer_at_import_km': mileage},
    };
  }

  void _showErrors(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon:    const Icon(Icons.error_outline, color: Colors.red),
        title:   const Text('Erreur serveur'),
        content: SingleChildScrollView(child: Text(msg)),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final refsAsync = ref.watch(catalogRefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing != null ? 'Modifier le véhicule' : 'Enregistrer un véhicule'),
        centerTitle: false,
      ),
      body: refsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _LoadingError(error: e.toString(),
            onRetry: () => ref.invalidate(catalogRefsProvider)),
        data: _buildForm,
      ),
    );
  }

  Widget _buildForm(CatalogRefs refs) {
    // ── Pré-sélection des dropdowns en mode édition ──────────────────
    final e = _existing;
    if (e != null && !_refsInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final id = e.identity;
        final brand = refs.brands
            .where((b) => b.name == id.brand)
            .cast<BrandRef?>().firstOrNull;
        final model = brand != null
            ? refs.modelsForBrand(brand.id)
                .where((m) => m.name == id.model)
                .cast<ModelRef?>().firstOrNull
            : null;
        final trim = (model != null && id.trim != null)
            ? refs.trimsForModel(model.id)
                .where((t) => t.name == id.trim)
                .cast<TrimRef?>().firstOrNull
            : null;
        final color = id.color != null
            ? refs.colors
                .where((c) => c.name == id.color)
                .cast<ColorRef?>().firstOrNull
            : null;
        final engine = id.engineType != null
            ? refs.engineTypes
                .where((et) => et.label == id.engineType)
                .cast<EngineTypeRef?>().firstOrNull
            : null;
        final drive = id.drivetrain != null
            ? refs.drivetrains
                .where((d) => d.label == id.drivetrain)
                .cast<DrivetrainRef?>().firstOrNull
            : null;
        final loc = e.commercial.locationId != null
            ? refs.locations
                .where((l) => l.id == e.commercial.locationId)
                .cast<LocationRef?>().firstOrNull
            : null;
        setState(() {
          _brand            = brand;
          _model            = model;
          _trim             = trim;
          _color            = color;
          _engineType       = engine;
          _drivetrain       = drive;
          _selectedLocation = loc;
          _refsInitialized  = true;
        });
      });
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _step,
            type: StepperType.vertical,
            onStepContinue: () => _onContinue(refs),
            onStepCancel: () {
              if (_step > 0) setState(() => _step--);
            },
            controlsBuilder: (context, details) =>
                _StepControls(details: details, isLast: _step == 3, submitting: _submitting),
            steps: [
              _buildStep1(),
              _buildStep2(refs),
              _buildStep3(refs),
              _buildStep4(refs),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 0 — Type & Identification ───────────────────────────────

  Step _buildStep1() => Step(
    title: const Text('Type de véhicule'),
    subtitle: Text(switch (_vehicleType) {
      'utility' => 'Utilitaire',
      'heavy'   => 'Poids lourd',
      _         => 'Particulier',
    }),
    isActive: _step >= 0,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Type de véhicule ──────────────────────────────────────
        Text(
          'Catégorie',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        _ChoiceGroup<String>(
          options: const [
            (value: 'passenger', label: 'Particulier'),
            (value: 'utility',   label: 'Utilitaire'),
            (value: 'heavy',     label: 'Poids lourd'),
          ],
          selected: _vehicleType,
          onChanged: (v) => setState(() => _vehicleType = v),
        ),
        const SizedBox(height: 16),

        // ── Carrosserie ───────────────────────────────────────────
        DropdownButtonFormField<String>(
          value: _bodyStyle,
          decoration: const InputDecoration(
            labelText: 'Carrosserie *',
            hintText: 'Berline, SUV, Pickup…',
            prefixIcon: Icon(Icons.directions_car_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'sedan',       child: Text('Berline')),
            DropdownMenuItem(value: 'hatchback',   child: Text('Citadine / Hayon')),
            DropdownMenuItem(value: 'suv',         child: Text('SUV / 4×4')),
            DropdownMenuItem(value: 'estate',      child: Text('Break')),
            DropdownMenuItem(value: 'coupe',       child: Text('Coupé')),
            DropdownMenuItem(value: 'convertible', child: Text('Cabriolet')),
            DropdownMenuItem(value: 'pickup',      child: Text('Pickup')),
            DropdownMenuItem(value: 'van',         child: Text('Fourgonnette')),
            DropdownMenuItem(value: 'minibus',     child: Text('Minibus')),
            DropdownMenuItem(value: 'bus',         child: Text('Bus / Car')),
            DropdownMenuItem(value: 'truck',       child: Text('Camion')),
            DropdownMenuItem(value: 'other',       child: Text('Autre')),
          ],
          onChanged: (v) => setState(() => _bodyStyle = v),
          validator: (v) => v == null ? 'Sélectionne un type de carrosserie' : null,
        ),
        const SizedBox(height: 16),

        // ── VIN ───────────────────────────────────────────────────
        TextFormField(
          controller: _vinCtrl,
          decoration: const InputDecoration(
            labelText: 'VIN (optionnel)',
            hintText: 'WVWZZZ1KZ8W000001',
            helperText: '17 caractères — numéro de châssis international',
            prefixIcon: Icon(Icons.qr_code_2),
          ),
          maxLength: 17,
          textCapitalization: TextCapitalization.characters,
          validator: (v) {
            if (v != null && v.isNotEmpty && v.length != 17) {
              return 'Le VIN doit faire exactement 17 caractères.';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),

        // ── Plaque d'immatriculation ──────────────────────────────
        TextFormField(
          controller: _plateCtrl,
          decoration: const InputDecoration(
            labelText: 'Plaque d\'immatriculation (optionnel)',
            hintText: 'Ex. : AA 1234 BF',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
      ],
    ),
  );

  // ── Step 2 — Identité ─────────────────────────────────────────────

  Step _buildStep2(CatalogRefs refs) {
    final models = _brand != null ? refs.modelsForBrand(_brand!.id) : <ModelRef>[];
    final trims  = _model != null ? refs.trimsForModel(_model!.id)  : <TrimRef>[];

    return Step(
      title: const Text('Identité'),
      subtitle: _brand != null ? Text(_model?.displayName ?? _brand!.name) : null,
      isActive: _step >= 1,
      content: Column(
        children: [
          // Marque
          _RefDropdown<BrandRef>(
            label: 'Marque *',
            items: refs.brands.where((b) => b.isActive).toList(),
            value: _brand,
            itemLabel: (b) => b.name,
            onChanged: (b) => setState(() { _brand = b; _model = null; _trim = null; }),
            validator: (v) => v == null ? 'Marque obligatoire' : null,
          ),
          const SizedBox(height: 12),

          // Modèle
          _RefDropdown<ModelRef>(
            label: 'Modèle *',
            items: models,
            value: _model,
            itemLabel: (m) => m.displayName,
            onChanged: (m) => setState(() {
              _model = m;
              _trim  = null;
              if (m == null) return;

              // Carrosserie : valeur DB ou inférence depuis body_type
              final style = m.inferredBodyStyle;
              if (style != null) _bodyStyle = style;

              // Type de véhicule : valeur DB en priorité, sinon inférence
              final vtype = m.resolvedVehicleType;
              if (vtype != null) _vehicleType = vtype;

              // Transmission : valeur DB uniquement
              if (m.defaultTransmission != null) _transmission = m.defaultTransmission!;

              // Places et portes : valeur DB uniquement
              if (m.defaultSeats != null) _seatsCtrl.text = m.defaultSeats.toString();
              if (m.defaultDoors != null) _doorsCtrl.text = m.defaultDoors.toString();

              // Puissance : valeur DB uniquement (indicative)
              if (m.defaultPowerHp != null) _powerCtrl.text = m.defaultPowerHp.toString();
            }),
            validator: (v) => v == null ? 'Modèle obligatoire' : null,
            enabled: _brand != null,
          ),
          const SizedBox(height: 12),

          // Finition (optionnel)
          if (trims.isNotEmpty) ...[
            _RefDropdown<TrimRef>(
              label: 'Finition',
              items: trims,
              value: _trim,
              itemLabel: (t) => t.name,
              onChanged: (t) => setState(() => _trim = t),
              enabled: _model != null,
            ),
            const SizedBox(height: 12),
          ],

          // Année
          TextFormField(
            controller: _yearCtrl,
            decoration: const InputDecoration(
              labelText: 'Année de fabrication *',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Année obligatoire';
              final y = int.tryParse(v);
              if (y == null || y < 1950 || y > DateTime.now().year) {
                return 'Année invalide (1950–${DateTime.now().year})';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Couleur
          _RefDropdown<ColorRef>(
            label: 'Couleur',
            items: refs.colors,
            value: _color,
            itemLabel: (c) => c.name,
            itemLeading: (c) => c.hexCode != null
                ? Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: _hexColor(c.hexCode!),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  )
                : null,
            onChanged: (c) => setState(() => _color = c),
          ),
        ],
      ),
    );
  }

  // ── Step 3 — Technique ────────────────────────────────────────────

  Step _buildStep3(CatalogRefs refs) => Step(
    title: const Text('Caractéristiques techniques'),
    isActive: _step >= 2,
    content: Column(
      children: [
        // Motorisation
        _RefDropdown<EngineTypeRef>(
          label: 'Type de motorisation *',
          items: refs.engineTypes,
          value: _engineType,
          itemLabel: (e) => e.label,
          onChanged: (e) => setState(() => _engineType = e),
          validator: (v) => v == null ? 'Motorisation obligatoire' : null,
        ),
        const SizedBox(height: 12),

        // Transmission
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Transmission',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 6),
        _ChoiceGroup<String>(
          options: const [
            (value: 'manual',    label: 'Manuelle'),
            (value: 'automatic', label: 'Automatique'),
            (value: 'cvt',       label: 'CVT'),
          ],
          selected: _transmission,
          onChanged: (v) => setState(() => _transmission = v),
        ),
        const SizedBox(height: 16),

        // Transmission séquentielle
        _RefDropdown<DrivetrainRef>(
          label: 'Transmission des roues',
          items: refs.drivetrains,
          value: _drivetrain,
          itemLabel: (d) => d.label,
          onChanged: (d) => setState(() => _drivetrain = d),
        ),
        const SizedBox(height: 12),

        // Puissance / places / portes
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _powerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Puissance (ch)',
                  suffixText: 'ch',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _seatsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Places',
                  suffixText: 'p',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _doorsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Portes',
                  suffixText: 'p',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
              ),
            ),
          ],
        ),

        // ── Équipements / options ────────────────────────────────────
        if (refs.features.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Équipements & options',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Sélectionnez les équipements présents sur ce véhicule.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          // Tri des catégories dans l'ordre défini par _categoryOrder.
          ...(() {
            final map     = refs.featuresByCategory;
            final ordered = _categoryOrder
                .where(map.containsKey)
                .map((k) => MapEntry(k, map[k]!))
                .toList();
            // Catégories inconnues à la fin (ex. : ajouts futurs côté serveur).
            final extra = map.entries
                .where((e) => !_categoryOrder.contains(e.key))
                .toList();
            return [...ordered, ...extra];
          })().map((entry) => _FeatureCategorySection(
            category:           entry.key,
            features:           entry.value,
            selectedFeatureIds: _selectedFeatureIds,
            onToggle: (id, selected) => setState(() {
              if (selected) {
                _selectedFeatureIds.add(id);
              } else {
                _selectedFeatureIds.remove(id);
              }
            }),
          )),
        ],
      ],
    ),
  );

  // ── Step 4 — Commercial ───────────────────────────────────────────

  Step _buildStep4(CatalogRefs refs) {
    final forSale = _availability == 'sale' || _availability == 'both';
    final forRent = _availability == 'rent' || _availability == 'both';

    return Step(
      title: const Text('Informations commerciales'),
      isActive: _step >= 3,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Condition
          Text('État du véhicule',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          _ChoiceGroup<String>(
            options: const [
              (value: 'new',     label: 'Neuf'),
              (value: 'used',    label: 'Occasion'),
              (value: 'damaged', label: 'Endommagé'),
            ],
            selected: _condition,
            onChanged: (v) => setState(() {
              _condition = v;
              if (v == 'new') _mileageCtrl.clear();
            }),
          ),
          const SizedBox(height: 16),

          // Kilométrage (uniquement pour occasion / endommagé)
          if (_condition != 'new') ...[
            TextFormField(
              controller: _mileageCtrl,
              decoration: const InputDecoration(
                labelText: 'Kilométrage',
                suffixText: 'km',
                hintText: '85 000',
                prefixIcon: Icon(Icons.speed_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Disponibilité
          Text('Disponible pour',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          _ChoiceGroup<String>(
            options: const [
              (value: 'sale', label: 'Vente'),
              (value: 'rent', label: 'Location'),
              (value: 'both', label: 'Vente & Location'),
            ],
            selected: _availability,
            onChanged: (v) => setState(() => _availability = v),
          ),
          const SizedBox(height: 16),

          // Mise en avant commerciale
          Text('Mise en avant',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          _ChoiceGroup<String>(
            options: const [
              (value: '',           label: 'Aucune'),
              (value: 'good_deal',  label: 'Bonne affaire'),
              (value: 'flash_sale', label: 'Vente flash'),
              (value: 'clearance',  label: 'Déstockage'),
            ],
            selected: _dealType,
            onChanged: (v) => setState(() => _dealType = v),
          ),
          const SizedBox(height: 16),

          // Prix de vente
          if (forSale) ...[
            TextFormField(
              controller: _salePriceCtrl,
              decoration: const InputDecoration(
                labelText: 'Prix de vente *',
                suffixText: 'FCFA',
                hintText: '15 000 000',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorFormatter()],
              validator: (v) {
                if (forSale && (v == null || v.trim().isEmpty)) {
                  return 'Prix de vente obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],

          // Tarifs location
          if (forRent) ...[
            TextFormField(
              controller: _rentalDailyCtrl,
              decoration: const InputDecoration(
                labelText: 'Tarif journalier *',
                suffixText: 'FCFA/j',
                hintText: '25 000',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorFormatter()],
              validator: (v) {
                if (forRent && (v == null || v.trim().isEmpty)) {
                  return 'Tarif journalier obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rentalDepositCtrl,
              decoration: const InputDecoration(
                labelText: 'Caution',
                suffixText: 'FCFA',
                hintText: '100 000',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorFormatter()],
            ),
            const SizedBox(height: 12),
          ],

          // Prix négociable
          SwitchListTile(
            title: const Text('Prix négociable'),
            value: _negotiable,
            onChanged: (v) => setState(() => _negotiable = v),
            contentPadding: EdgeInsets.zero,
          ),

          // ── Localisation / agence ────────────────────────────────
          if (refs.locations.isNotEmpty) ...[
            _RefDropdown<LocationRef>(
              label: 'Agence / Showroom',
              items: refs.locations,
              value: _selectedLocation,
              itemLabel: (l) => l.displayLabel,
              itemLeading: (l) => Icon(Icons.location_on_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary),
              onChanged: (l) => setState(() => _selectedLocation = l),
            ),
            const SizedBox(height: 12),
          ] else ...[
            // Fallback texte libre si aucune location configurée
            TextFormField(
              controller: _siteCtrl,
              decoration: const InputDecoration(
                labelText: 'Site / Agence',
                hintText: 'Ex. : Showroom Ouagadougou Nord',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Partenaire fournisseur ───────────────────────────────
          const SizedBox(height: 4),
          const Divider(),
          const SizedBox(height: 4),
          Text('Fournisseur / Partenaire source',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('Source du véhicule (importateur, enchère, concessionnaire partenaire…)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          ref.watch(_vehiclePartnersProvider).when(
            loading: () => const LinearProgressIndicator(),
            error:   (_, __) => const Text('Impossible de charger les partenaires.'),
            data: (partners) => DropdownButtonFormField<int?>(
              value: _selectedPartnerId,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Aucun (optionnel)',
                prefixIcon: Icon(Icons.handshake_outlined),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Aucun')),
                ...partners.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.displayName,
                      overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: (v) => setState(() => _selectedPartnerId = v),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Détails supplémentaires sur le véhicule…',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            maxLength: 2000,
          ),
        ],
      ),
    );
  }

  // ── Utilitaires ───────────────────────────────────────────────────

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ════════════════════════════════════════════════════════════════════
// Widgets génériques réutilisables dans le formulaire
// ════════════════════════════════════════════════════════════════════

class _RefDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) itemLabel;
  final Widget? Function(T)? itemLeading;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const _RefDropdown({
    required this.label,
    required this.items,
    required this.value,
    required this.itemLabel,
    required this.onChanged,
    this.itemLeading,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    decoration: InputDecoration(labelText: label),
    hint: Text(enabled ? 'Sélectionner…' : 'Choisir d\'abord la valeur précédente'),
    isExpanded: true,
    items: items.map((item) {
      final leading = itemLeading?.call(item);
      return DropdownMenuItem<T>(
        value: item,
        child: leading != null
            ? Row(children: [leading, const SizedBox(width: 8), Expanded(child: Text(itemLabel(item), overflow: TextOverflow.ellipsis))])
            : Text(itemLabel(item), overflow: TextOverflow.ellipsis),
      );
    }).toList(),
    onChanged: enabled ? onChanged : null,
    validator: validator,
  );
}

// ── Contrôles du Stepper ────────────────────────────────────────────

class _StepControls extends StatelessWidget {
  final ControlsDetails details;
  final bool isLast;
  final bool submitting;

  const _StepControls({
    required this.details,
    required this.isLast,
    required this.submitting,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Row(
      children: [
        FilledButton(
          onPressed: submitting ? null : details.onStepContinue,
          child: submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isLast ? 'Enregistrer' : 'Suivant'),
        ),
        const SizedBox(width: 12),
        if (details.stepIndex > 0)
          OutlinedButton(
            onPressed: details.onStepCancel,
            child: const Text('Retour'),
          ),
      ],
    ),
  );
}

// ── Section équipements par catégorie ───────────────────────────────

/// Labels lisibles pour les catégories de features.
const _categoryLabels = <String, String>{
  'dotation':       'Dotation standard',
  'confort':        'Confort',
  'securite':       'Sécurité',
  'multimedia':     'Multimédia',
  'aide_conduite':  'Aides à la conduite',
  'autre':          'Autres',
};

/// Ordre d'affichage des catégories dans le formulaire.
const _categoryOrder = [
  'dotation', 'confort', 'securite', 'multimedia', 'aide_conduite', 'autre',
];

class _FeatureCategorySection extends StatelessWidget {
  final String category;
  final List<FeatureRef> features;
  final Set<int> selectedFeatureIds;
  final void Function(int id, bool selected) onToggle;

  const _FeatureCategorySection({
    required this.category,
    required this.features,
    required this.selectedFeatureIds,
    required this.onToggle,
  });

  bool get _isDotation => category == 'dotation';

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final label = _categoryLabels[category] ?? category;
    final color = _isDotation ? Colors.amber.shade700 : cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête de catégorie ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              if (_isDotation) ...[
                Icon(Icons.warning_amber_rounded, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              if (_isDotation) ...[
                const SizedBox(width: 6),
                Text(
                  '— cochez ce qui est présent',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: features.map((f) {
            final isSelected = selectedFeatureIds.contains(f.id);
            return FilterChip(
              label: Text(f.name),
              selected: isSelected,
              selectedColor: _isDotation
                  ? Colors.amber.shade100
                  : null,
              checkmarkColor: _isDotation ? Colors.amber.shade800 : null,
              onSelected: (v) => onToggle(f.id, v),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Groupe de choix (remplace SegmentedButton sur petits écrans) ────
//
// Wrap + ChoiceChip : chaque chip prend sa largeur naturelle et passe
// à la ligne si besoin, sans rétrécir les autres.

class _ChoiceGroup<T> extends StatelessWidget {
  final List<({T value, String label})> options;
  final T selected;
  final void Function(T) onChanged;

  const _ChoiceGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: options.map((opt) => ChoiceChip(
      label: Text(opt.label),
      selected: selected == opt.value,
      onSelected: (_) => onChanged(opt.value),
    )).toList(),
  );
}

// ── Formateur : séparateur de milliers (espace) ─────────────────────

/// Formate un montant en entier avec séparateurs de milliers (espace).
/// Ex. : 15000000 → "15 000 000"
String _fmtPrice(double value) {
  final digits = value.toStringAsFixed(0);
  final buf = StringBuffer();
  final len = digits.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    final buf = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write(' '); // espace fine insécable
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

// ── État de chargement en erreur ────────────────────────────────────

class _LoadingError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _LoadingError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56),
          const SizedBox(height: 12),
          Text('Impossible de charger les référentiels :\n$error',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}
