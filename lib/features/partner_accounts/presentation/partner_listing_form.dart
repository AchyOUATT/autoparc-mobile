import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/partner_repository.dart';

/// Les annonces utilisent uniquement le client partenaire, y compris en edition.
class PartnerListingFormPage extends ConsumerStatefulWidget {
  const PartnerListingFormPage({
    super.key,
    required this.kind,
    this.initialListing,
  });

  final PartnerListingKind kind;
  final Map<String, dynamic>? initialListing;

  @override
  ConsumerState<PartnerListingFormPage> createState() =>
      _PartnerListingFormPageState();
}

class _PartnerListingFormPageState
    extends ConsumerState<PartnerListingFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _year = TextEditingController();
  final _salePrice = TextEditingController();
  final _dailyRate = TextEditingController();
  final _monthlyRate = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _sku = TextEditingController();
  final _manufacturerReference = TextEditingController();
  final _mileage = TextEditingController();
  PartnerReferences? _references;
  Object? _loadError;
  String? _saveError;
  bool _saving = false;
  bool _loadingDonors = false;
  String? _donorError;
  List<Map<String, dynamic>> _donors = [];
  bool _donorsLoaded = false;
  int? _brandId;
  int? _modelId;
  bool _vehicleIdentityChanged = false;
  int? _engineTypeId;
  int? _categoryId;
  int? _manufacturerId;
  int? _donorId;
  String _availability = 'sale';

  // ── LES QUATRE CHAMPS QUI RENDENT UNE ANNONCE TROUVABLE ─────────────────
  //
  // Ils partent NULS, et ce n'est pas un oubli. `vehicle_type` et
  // `registration_status` ont une valeur par defaut EN BASE — `passenger` et
  // `unregistered` — de sorte qu'une annonce qui ne les envoie pas n'est pas
  // « non classee » : elle est classee en silence, et possiblement a tort. Une
  // camionnette immatriculee se rangeait en voiture particuliere non
  // immatriculee, et les filtres publics `?vehicle_type=utility` et
  // `?registration_status=registered` ne la trouvaient jamais.
  //
  // Preselectionner ces valeurs dans le formulaire reproduirait exactement ce
  // defaut, en le faisant passer pour un choix du vendeur. On demande.
  String? _vehicleType;
  String? _registrationStatus;
  String? _bodyStyle;
  String? _condition;
  String _partType = 'aftermarket';
  String _partCondition = 'new';
  String _accessoryCategory = 'utilitaire';

  bool get _vehicle => widget.kind == PartnerListingKind.vehicles;
  bool get _part => widget.kind == PartnerListingKind.parts;
  bool get _editing => widget.initialListing != null;
  bool get _forSale => _availability != 'rent';
  bool get _forRent => _availability != 'sale';

  String get _kindName => switch (widget.kind) {
    PartnerListingKind.vehicles => 'véhicule',
    PartnerListingKind.parts => 'pièce',
    PartnerListingKind.accessories => 'accessoire',
  };

  String get _article => _part ? 'une' : 'un';

  static int? _id(dynamic value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');

  static Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};

  static String _text(dynamic value) => value?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    final listing = widget.initialListing ?? <String, dynamic>{};
    final identity = _map(listing['identity']);
    final commercial = _map(listing['commercial']);
    final pricing = _map(listing['pricing']);
    _name.text = _text(listing['name']);
    _description.text = _text(listing['description']);
    _year.text = _text(listing['manufacturing_year'] ?? identity['year']);
    _salePrice.text = _text(
      _vehicle ? commercial['sale_price'] : pricing['selling_price'],
    );
    _dailyRate.text = _text(commercial['rental_daily_rate']);
    _monthlyRate.text = _text(commercial['rental_monthly_rate']);
    _stock.text = _text(_map(listing['stock'])['quantity'] ?? 0);
    _sku.text = _text(listing['sku']);
    _manufacturerReference.text = _text(listing['manufacturer_reference']);
    _brandId = _id(listing['brand_id'] ?? identity['brand_id']);
    _modelId = _id(listing['vehicle_model_id'] ?? identity['vehicle_model_id']);
    _engineTypeId = _id(listing['engine_type_id'] ?? identity['engine_type_id']);
    _categoryId = _id(listing['category_id'] ?? _map(listing['category'])['id']);
    _manufacturerId = _id(listing['manufacturer_id']);
    _donorId = _id(listing['donor_vehicle_id']);
    _availability = _text(commercial['availability'] ?? 'sale');
    // `VehicleResource` rend `vehicle_type` et `body_style` en chaine nue,
    // `registration_status` en objet {value, label}, `condition` sous
    // `commercial` et le kilometrage sous `technical`.
    _vehicleType = _texteOuNul(listing['vehicle_type']);
    _registrationStatus = _texteOuNul(_map(listing['registration_status'])['value']);
    _bodyStyle = _texteOuNul(listing['body_style']);
    _condition = _texteOuNul(commercial['condition']);
    _mileage.text = _text(_map(listing['technical'])['mileage_km']);
    _partType = _text(listing['type'] ?? 'aftermarket');
    _partCondition = _text(listing['condition'] ?? 'new');
    _accessoryCategory = _text(
      _map(listing['category'])['value'] ??
          (listing['category'] is String ? listing['category'] : 'utilitaire'),
    );
    _loadReferences();
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _description, _year, _salePrice, _dailyRate, _monthlyRate,
      _stock, _sku, _manufacturerReference,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() => _loadError = null);
    try {
      final references = await ref.read(partnerRepositoryProvider).references();
      if (!mounted) return;
      setState(() => _references = references);
      if (_part && _partCondition == 'used') await _loadDonors();
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<void> _loadDonors() async {
    if (_donorsLoaded || _loadingDonors) return;
    setState(() { _loadingDonors = true; _donorError = null; });
    try {
      final donors = <Map<String, dynamic>>[];
      var page = 1;
      while (true) {
        final result = await ref.read(partnerRepositoryProvider)
            .listListings(PartnerListingKind.vehicles, page: page);
        donors.addAll(result.items);
        if (page >= result.lastPage) break;
        page++;
      }
      if (!mounted) return;
      if (_donorId == null && widget.initialListing?['donor_vehicle'] != null) {
        final matches = donors.where((item) =>
            item['reference'] == widget.initialListing!['donor_vehicle']).toList();
        if (matches.length == 1) _donorId = _id(matches.single['id']);
      }
      setState(() { _donors = donors; _donorsLoaded = true; });
    } catch (error) {
      if (mounted) setState(() => _donorError = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingDonors = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is PartnerApiException) {
      return error.fields.isEmpty ? error.message : error.fields.values.join('\n');
    }
    return 'Impossible de terminer la demande. Vérifiez votre connexion et réessayez.';
  }

  num? _number(TextEditingController controller) =>
      num.tryParse(controller.text.trim().replaceAll(',', '.'));

  String? _money(String? value, {bool isRequired = true}) {
    if ((value ?? '').trim().isEmpty) return isRequired ? 'Indiquez un prix.' : null;
    final number = num.tryParse(value!.trim().replaceAll(',', '.'));
    return number == null || !number.isFinite || number < 0
        ? 'Indiquez un montant positif ou nul.' : null;
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false) || _saving) return;
    if (_vehicle && _forRent && _number(_dailyRate) == null && _number(_monthlyRate) == null) {
      setState(() => _saveError = 'Indiquez au moins un tarif de location : par jour ou par mois.');
      return;
    }
    final data = <String, dynamic>{'description': _description.text.trim()};
    if (_vehicle) {
      data.addAll({
        'brand_id': _brandId,
        'vehicle_model_id': _modelId,
        'engine_type_id': _engineTypeId,
        'manufacturing_year': int.parse(_year.text.trim()),
        'vehicle_type': _vehicleType,
        'registration_status': _registrationStatus,
        'condition': _condition,
        'body_style': _bodyStyle,
        'availability': _availability,
        'sale_price': _forSale ? _number(_salePrice) : null,
        'rental_daily_rate': _forRent ? _number(_dailyRate) : null,
        'rental_monthly_rate': _forRent ? _number(_monthlyRate) : null,
        if (_vehicleIdentityChanged) ...{
          for (final field in [
            'trim_id', 'drivetrain_id', 'engine_code', 'engine_displacement_cc',
            'power_hp', 'power_kw', 'torque_nm', 'cylinders', 'gear_count',
            'consumption_urban', 'consumption_extra_urban', 'consumption_combined',
            'electric_consumption_kwh', 'battery_capacity_kwh', 'electric_range_km',
            'co2_g_km', 'fuel_tank_liters',
          ]) field: null,
        },
      });

      // ── LE KILOMETRAGE VA DANS LE BLOC QUI CORRESPOND AU STATUT ────────
      //
      // Le serveur ecrit l'un ou l'autre selon `registration_status`
      // (`syncTypeSpecificDetails`) : envoyer `registration` sur un vehicule
      // declare non immatricule serait ignore en silence, et le filtre
      // `?mileage_max=` ne trouverait toujours rien.
      //
      // Rien n'est envoye quand le champ est vide : cela veut dire « je ne
      // touche pas », et non « efface ce qui est enregistre ».
      final km = int.tryParse(_mileage.text.trim());
      if (km != null) {
        final immatricule = _registrationStatus == 'registered';
        data[immatricule ? 'registration' : 'import'] = <String, dynamic>{
          (immatricule ? 'mileage_km' : 'odometer_at_import_km'): km,
        };
      }
    } else {
      data.addAll({
        'name': _name.text.trim(),
        'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
        'selling_price': _number(_salePrice),
        'stock_quantity': int.parse(_stock.text.trim()),
        'manufacturer_id': _manufacturerId,
      });
      if (_part) {
        data.addAll({
          'part_category_id': _categoryId,
          'type': _partType,
          'condition': _partCondition,
          'manufacturer_reference': _manufacturerReference.text.trim(),
          'donor_vehicle_id': _partCondition == 'used' ? _donorId : null,
        });
      } else {
        data['category'] = _accessoryCategory;
      }
    }
    setState(() { _saving = true; _saveError = null; });
    try {
      await ref.read(partnerRepositoryProvider).saveListing(
        widget.kind, data, id: _id(widget.initialListing?['id']),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _saveError = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, dynamic>> _flattenCategories(List<Map<String, dynamic>> items) {
    final result = <Map<String, dynamic>>[];
    for (final item in items) {
      result.add(item);
      if (item['children'] is List) {
        result.addAll(_flattenCategories((item['children'] as List).map(_map).toList()));
      }
    }
    final seen = <int?>{};
    return result.where((item) => seen.add(_id(item['id']))).toList();
  }

  Widget _dropdown({
    required String label,
    required int? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<int?> onChanged,
    String Function(Map<String, dynamic>)? text,
    bool isRequired = true,
  }) {
    final values = items.map((item) => _id(item['id'])).toSet();
    return DropdownButtonFormField<int>(
      key: ValueKey('$label:${values.join(',')}:$value'),
      initialValue: values.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        if (!isRequired) const DropdownMenuItem<int>(value: null, child: Text('Non renseigné')),
        ...items.map((item) => DropdownMenuItem<int>(
          value: _id(item['id']),
          child: Text(text?.call(item) ?? _text(item['name'] ?? item['label']),
            overflow: TextOverflow.ellipsis),
        )),
      ],
      onChanged: _saving ? null : onChanged,
      validator: (selected) => isRequired && selected == null ? 'Choisissez une valeur.' : null,
    );
  }

  /// La valeur textuelle, ou `null` quand elle est absente ou vide.
  ///
  /// `_text` rend une chaîne vide pour un champ absent, ce qui conviendrait
  /// mal ici : vide passerait pour une réponse, alors que `null` dit « pas
  /// encore choisi » et fait mordre le validateur.
  String? _texteOuNul(Object? value) {
    final texte = _text(value);

    return texte.isEmpty ? null : texte;
  }

  /// Un choix parmi un énuméré du serveur, qui peut partir SANS sélection.
  ///
  /// C'est ce que [_choice] ne sait pas faire : il préselectionne toujours sa
  /// valeur courante. Pour les champs de classification, préselectionner
  /// reproduirait le défaut de la colonne en le faisant passer pour une
  /// réponse du vendeur.
  Widget _enum(String label, String? value, Map<String, String> choices,
      ValueChanged<String?> onChanged, {bool isRequired = true}) =>
      DropdownButtonFormField<String>(
        initialValue: choices.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: [
          if (!isRequired) const DropdownMenuItem<String>(value: null, child: Text('Non renseigné')),
          ...choices.entries.map((entry) => DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          )),
        ],
        onChanged: _saving ? null : onChanged,
        validator: (selected) => isRequired && selected == null ? 'Choisissez une valeur.' : null,
      );

  Widget _choice(String label, String value, Map<String, String> choices, ValueChanged<String> onChanged) =>
      _enum(label, value, choices, (selected) { if (selected != null) onChanged(selected); });

  Widget _field(String label, TextEditingController controller, {
    TextInputType? keyboardType, String? Function(String?)? validator, int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    enabled: !_saving,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) {
    final references = _references;
    return Scaffold(
      appBar: AppBar(title: Text('${_editing ? 'Modifier' : 'Ajouter'} $_article $_kindName')),
      body: references == null
          ? Center(child: _loadError == null
              ? const CircularProgressIndicator()
              : Padding(padding: const EdgeInsets.all(24), child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage(_loadError!)),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: _loadReferences,
                      icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
                  ],
                )))
          : Form(
              key: _form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _spaced([
                  Text(_editing ? 'Mettez à jour votre annonce.' : 'L’annonce sera créée en brouillon. Vous pourrez ensuite ajouter ses photos et la publier.',
                    style: Theme.of(context).textTheme.bodyMedium),
                  if (_vehicle) ..._vehicleFields(references) else ..._itemFields(references),
                  _field('Description', _description, maxLines: 4),
                  if (_saveError != null) Semantics(
                    liveRegion: true,
                    child: Text(_saveError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Enregistrement…' : _editing ? 'Enregistrer les modifications' : 'Enregistrer le brouillon'),
                  ),
                  ]),
                ),
              ),
            ),
    );
  }

  List<Widget> _spaced(List<Widget> children) => [
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) const SizedBox(height: 16), children[index],
    ],
  ];

  List<Widget> _vehicleFields(PartnerReferences references) => [
    _dropdown(label: 'Marque', value: _brandId, items: references.brands,
      onChanged: (value) => setState(() {
        if (_brandId != value) {
          _brandId = value;
          _modelId = null;
          _engineTypeId = null;
          _vehicleIdentityChanged = true;
        }
      })),
    _dropdown(label: 'Modèle et génération', value: _modelId,
      items: references.models.where((item) => _id(item['brand_id']) == _brandId).toList(),
      text: (item) => '${item['name']} ${item['generation'] ?? ''}'.trim(),
      onChanged: (value) => setState(() {
        if (_modelId != value) {
          _modelId = value;
          _engineTypeId = null;
          _vehicleIdentityChanged = true;
        }
      })),
    _dropdown(label: 'Motorisation', value: _engineTypeId, items: references.engineTypes,
      text: (item) => _text(item['label'] ?? item['name']),
      onChanged: (value) => setState(() => _engineTypeId = value)),
    _field('Année de fabrication', _year, keyboardType: TextInputType.number,
      validator: (value) {
        final year = int.tryParse(value?.trim() ?? '');
        return year == null || year < 1950 || year > DateTime.now().year
            ? 'Indiquez une année entre 1950 et ${DateTime.now().year}.' : null;
      }),
    // ── CE QUI REND L'ANNONCE TROUVABLE ──────────────────────────────────
    //
    // Le catalogue public filtre sur `vehicle_type`, `registration_status`,
    // `body_style`, `condition` et `mileage_max`. Sans ces réponses, une
    // annonce partenaire n'apparaissait dans AUCUN de ces filtres — et pire
    // pour les deux premiers, dont la colonne porte un défaut en base : elle y
    // apparaissait sous une classification FAUSSE. Une camionnette
    // immatriculée se rangeait en voiture particulière non immatriculée.
    _enum('Type de véhicule', _vehicleType, const {
      'passenger': 'Voiture particulière',
      'utility': 'Utilitaire',
      'heavy': 'Poids lourd ou engin',
    }, (value) => setState(() => _vehicleType = value)),
    _enum('Situation administrative', _registrationStatus, const {
      'unregistered': 'Non immatriculé (import)',
      'registered': 'Déjà immatriculé',
    }, (value) => setState(() => _registrationStatus = value)),
    _enum('État', _condition, const {
      'new': 'Neuf',
      'used': 'Occasion',
      'damaged': 'Accidenté',
      'for_parts': 'Pour pièces',
    }, (value) => setState(() => _condition = value)),
    _enum('Carrosserie', _bodyStyle, const {
      'sedan': 'Berline',
      'hatchback': 'Citadine (hayon)',
      'suv': 'SUV ou 4x4',
      'estate': 'Break',
      'coupe': 'Coupé',
      'convertible': 'Cabriolet',
      'pickup': 'Pick-up',
      'van': 'Fourgon',
      'minibus': 'Minibus',
      'bus': 'Bus',
      'truck': 'Camion',
      'other': 'Autre',
    }, (value) => setState(() => _bodyStyle = value), isRequired: false),
    _field('Kilométrage (km)', _mileage, keyboardType: TextInputType.number,
      validator: (value) {
        final texte = value?.trim() ?? '';
        if (texte.isEmpty) return null;
        final km = int.tryParse(texte);

        return km == null || km < 0 ? 'Indiquez un kilométrage valide.' : null;
      }),
    _choice('Proposition', _availability,
      const {'sale': 'Vente', 'rent': 'Location', 'both': 'Vente et location'},
      (value) => setState(() => _availability = value)),
    if (_forSale) _field('Prix de vente (FCFA)', _salePrice,
      keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _money),
    if (_forRent) ...[
      const Text('Renseignez un tarif par jour, un tarif mensuel, ou les deux.'),
      _field('Location par jour (FCFA)', _dailyRate,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) => _money(value, isRequired: false)),
      _field('Location par mois (FCFA)', _monthlyRate,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) => _money(value, isRequired: false)),
    ],
  ];

  List<Widget> _itemFields(PartnerReferences references) => [
    _field('Nom de l’article', _name,
      validator: (value) => (value ?? '').trim().isEmpty ? 'Indiquez un nom.' : null),
    if (_part) ...[
      _dropdown(label: 'Catégorie de pièce', value: _categoryId,
        items: _flattenCategories(references.partCategories),
        onChanged: (value) => setState(() => _categoryId = value)),
      _choice('Origine de la pièce', _partType, const {
        'oem': 'Constructeur (OEM)', 'oes': 'Équipementier (OES)',
        'aftermarket': 'Adaptable', 'salvage': 'Pièce de récupération',
      }, (value) => setState(() => _partType = value)),
      _choice('État', _partCondition, const {
        'new': 'Neuve', 'refurbished': 'Reconditionnée', 'used': 'D’occasion',
      }, (value) {
        setState(() => _partCondition = value);
        if (value == 'used') _loadDonors();
      }),
      if (_partCondition == 'used') ...[
        const Text('Une pièce d’occasion doit être rattachée à un véhicule donneur de votre propre inventaire.'),
        if (_loadingDonors) const LinearProgressIndicator()
        else if (_donorError != null) ...[
          Text(_donorError!),
          TextButton(onPressed: _loadDonors, child: const Text('Recharger les véhicules donneurs')),
        ] else if (_donorsLoaded && _donors.isEmpty)
          const Text('Ajoutez d’abord le véhicule donneur dans vos annonces de véhicules.'),
        _dropdown(label: 'Véhicule donneur', value: _donorId, items: _donors,
          text: (item) => _text(item['designation'] ?? item['reference'] ?? item['id']),
          onChanged: (value) => setState(() => _donorId = value)),
      ],
      _field('Référence fabricant (facultatif)', _manufacturerReference),
    ] else
      _choice('Catégorie d’accessoire', _accessoryCategory, const {
        'esthetique': 'Esthétique', 'confort': 'Confort', 'securite': 'Sécurité',
        'multimedia': 'Multimédia', 'utilitaire': 'Utilitaire',
      }, (value) => setState(() => _accessoryCategory = value)),
    _dropdown(label: 'Fabricant (facultatif)', value: _manufacturerId,
      items: references.manufacturers, isRequired: false,
      onChanged: (value) => setState(() => _manufacturerId = value)),
    _field('Référence interne / SKU (facultatif)', _sku),
    _field('Prix de vente (FCFA)', _salePrice,
      keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _money),
    _field('Quantité en stock', _stock, keyboardType: TextInputType.number,
      validator: (value) {
        final quantity = int.tryParse(value?.trim() ?? '');
        return quantity == null || quantity < 0 ? 'Indiquez un nombre entier positif ou nul.' : null;
      }),
  ];
}
