import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';

import '../data/partner_repository.dart';
import 'champs_de_promotion.dart';
import 'marge_recapitulatif.dart';
import 'partner_session.dart';

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
  final _salePrice = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _sku = TextEditingController();
  final _manufacturerReference = TextEditingController();
  PartnerReferences? _references;
  Object? _loadError;
  Object? _saveError;
  bool _saving = false;
  bool _loadingDonors = false;
  Object? _donorError;
  List<Map<String, dynamic>> _donors = [];
  bool _donorsLoaded = false;
  int? _categoryId;
  int? _manufacturerId;
  int? _donorId;
  String _partType = 'aftermarket';
  String _partCondition = 'new';
  String _accessoryCategory = 'utilitaire';

  /// La promotion en cours de saisie. Vide = pas de promotion.
  PromotionSaisie _promotion = const PromotionSaisie();

  bool get _part => widget.kind == PartnerListingKind.parts;
  bool get _editing => widget.initialListing != null;

  static int? _id(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static String _text(dynamic value) => value?.toString() ?? '';

  @override
  void initState() {
    super.initState();

    // ── CET ECRAN NE SERT PLUS LES VEHICULES ──────────────────────────────
    //
    // Un vehicule passe par `VehicleRegisterPage` en mode partenaire : le meme
    // formulaire que le personnel, moins les trois champs que le serveur lui
    // refuse. C'est `partner_listings_page.dart` qui aiguille.
    //
    // La branche vehicule vivait ici en double, et c'est la derive que
    // l'unification a supprimee. L'assertion empeche de la reconstituer par un
    // appel distrait : sans elle, un `kind: vehicles` afficherait un
    // formulaire de piece sans qu'un mot ne soit dit.
    assert(
      widget.kind != PartnerListingKind.vehicles,
      'Un vehicule partenaire passe par VehicleRegisterPage(mode: partenaire).',
    );

    final listing = widget.initialListing ?? <String, dynamic>{};
    final pricing = _map(listing['pricing']);
    _name.text = _text(listing['name']);
    _description.text = _text(listing['description']);
    _salePrice.text = _text(pricing['selling_price']);
    _stock.text = _text(_map(listing['stock'])['quantity'] ?? 0);
    _sku.text = _text(listing['sku']);
    _manufacturerReference.text = _text(listing['manufacturer_reference']);
    _categoryId = _id(
      listing['category_id'] ?? _map(listing['category'])['id'],
    );
    _manufacturerId = _id(listing['manufacturer_id']);
    _donorId = _id(listing['donor_vehicle_id']);
    // La promotion enregistree, s'il y en a une. Le bloc `deal` n'est rendu
    // que pendant la fenetre : une promotion finie ne revient donc pas, et
    // c'est exact — il n'y a plus rien a modifier.
    final promotion = _map(listing['deal']);
    if (promotion['price'] != null) {
      _promotion = PromotionSaisie(
        prix: num.tryParse('${promotion['price']}'),
        debut: DateTime.tryParse('${promotion['starts_at']}')?.toLocal(),
        fin: DateTime.tryParse('${promotion['ends_at']}')?.toLocal(),
      );
    }
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
      _name,
      _description,
      _salePrice,
      _stock,
      _sku,
      _manufacturerReference,
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
    setState(() {
      _loadingDonors = true;
      _donorError = null;
    });
    try {
      final donors = <Map<String, dynamic>>[];
      var page = 1;
      while (true) {
        final result = await ref
            .read(partnerRepositoryProvider)
            .listListings(PartnerListingKind.vehicles, page: page);
        donors.addAll(result.items);
        if (page >= result.lastPage) break;
        page++;
      }
      if (!mounted) return;
      if (_donorId == null && widget.initialListing?['donor_vehicle'] != null) {
        final matches = donors
            .where(
              (item) =>
                  item['reference'] == widget.initialListing!['donor_vehicle'],
            )
            .toList();
        if (matches.length == 1) _donorId = _id(matches.single['id']);
      }
      setState(() {
        _donors = donors;
        _donorsLoaded = true;
      });
    } catch (error) {
      if (mounted) setState(() => _donorError = error);
    } finally {
      if (mounted) setState(() => _loadingDonors = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is PartnerApiException) {
      return error.fields.isEmpty
          ? messageFor(error.message, l10n: AppLocalizations.of(context))
          : error.fields.values
                .map(
                  (message) =>
                      messageFor(message, l10n: AppLocalizations.of(context)),
                )
                .join('\n');
    }
    return AppLocalizations.of(context).partnerAccountsRequestFailed;
  }

  num? _number(TextEditingController controller) =>
      num.tryParse(controller.text.trim().replaceAll(',', '.'));

  String? _money(String? value) {
    if ((value ?? '').trim().isEmpty)
      return AppLocalizations.of(context).partnerAccountsPriceRequired;
    final number = num.tryParse(value!.trim().replaceAll(',', '.'));
    return number == null || !number.isFinite || number < 0
        ? AppLocalizations.of(context).partnerAccountsMoneyInvalid
        : null;
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false) || _saving) return;
    final data = <String, dynamic>{
      'description': _description.text.trim(),
      'name': _name.text.trim(),
      'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
      'selling_price': _number(_salePrice),
      'stock_quantity': int.parse(_stock.text.trim()),
      'manufacturer_id': _manufacturerId,
    };
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

    // ── LA PROMOTION NE PART QUE QUAND ELLE EXISTE ────────────────────
    //
    // `deal_price` a null RETIRE la promotion, ce qui doit rester possible
    // sans attendre sa date de fin. Mais a la CREATION, envoyer null sur
    // une annonce qui n'en a jamais eu ferait partir trois champs vides
    // pour rien — et le serveur exige les deux bornes des qu'il y a un
    // prix, donc la distinction compte.
    if (_promotion.active) {
      data['deal_price'] = _promotion.prix;
      data['deal_starts_at'] = _promotion.debut?.toIso8601String();
      data['deal_ends_at'] = _promotion.fin?.toIso8601String();
    } else if (_editing) {
      data['deal_price'] = null;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await ref
          .read(partnerRepositoryProvider)
          .saveListing(
            widget.kind,
            data,
            id: _id(widget.initialListing?['id']),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _saveError = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, dynamic>> _flattenCategories(
    List<Map<String, dynamic>> items,
  ) {
    final result = <Map<String, dynamic>>[];
    for (final item in items) {
      result.add(item);
      if (item['children'] is List) {
        result.addAll(
          _flattenCategories((item['children'] as List).map(_map).toList()),
        );
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        if (!isRequired)
          DropdownMenuItem<int>(
            value: null,
            child: Text(
              AppLocalizations.of(context).partnerAccountsNotProvided,
            ),
          ),
        ...items.map(
          (item) => DropdownMenuItem<int>(
            value: _id(item['id']),
            child: Text(
              text?.call(item) ?? _text(item['name'] ?? item['label']),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: _saving ? null : onChanged,
      validator: (selected) => isRequired && selected == null
          ? AppLocalizations.of(context).partnerAccountsChoiceRequired
          : null,
    );
  }

  /// Un choix parmi un énuméré du serveur, toujours préselectionné.
  ///
  /// Chacun de ces champs part sur une vraie réponse — « adaptable »,
  /// « neuve », « utilitaire » — et non sur un défaut de colonne qui se
  /// ferait passer pour un choix du vendeur.
  Widget _choice(
    String label,
    String value,
    Map<String, String> choices,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: choices.containsKey(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: choices.entries
        .map(
          (entry) => DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: _saving
        ? null
        : (selected) {
            if (selected != null) onChanged(selected);
          },
    validator: (selected) => selected == null
        ? AppLocalizations.of(context).partnerAccountsChoiceRequired
        : null,
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    enabled: !_saving,
    keyboardType: keyboardType,
    maxLines: maxLines,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) {
    final references = _references;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _part
              ? (_editing
                    ? AppLocalizations.of(context).partnerAccountsEditPart
                    : AppLocalizations.of(context).partnerAccountsAddPart)
              : (_editing
                    ? AppLocalizations.of(context).partnerAccountsEditAccessory
                    : AppLocalizations.of(context).partnerAccountsAddAccessory),
        ),
      ),
      body: references == null
          ? Center(
              child: _loadError == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_errorMessage(_loadError!)),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loadReferences,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              AppLocalizations.of(context).commonRetry,
                            ),
                          ),
                        ],
                      ),
                    ),
            )
          : Form(
              key: _form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _spaced([
                    Text(
                      _editing
                          ? AppLocalizations.of(
                              context,
                            ).partnerAccountsEditListingHelp
                          : AppLocalizations.of(
                              context,
                            ).partnerAccountsNewListingHelp,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    ..._itemFields(references),
                    ChampsDePromotion(
                      prixNormal: _number(_salePrice),
                      plafondPourcentage:
                          ref
                              .watch(partnerSessionProvider)
                              .profile
                              ?.plafondRemisePourcentage ??
                          0,
                      valeur: _promotion,
                      onChanged: (valeur) =>
                          setState(() => _promotion = valeur),
                    ),
                    _field(
                      AppLocalizations.of(context).catalogSectionDescription,
                      _description,
                      maxLines: 4,
                    ),
                    if (_saveError != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _errorMessage(_saveError!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving
                            ? AppLocalizations.of(context).partnerAccountsSaving
                            : _editing
                            ? AppLocalizations.of(
                                context,
                              ).partnerAccountsSaveChanges
                            : AppLocalizations.of(
                                context,
                              ).partnerAccountsSaveDraft,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }

  List<Widget> _spaced(List<Widget> children) => [
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) const SizedBox(height: 16),
      children[index],
    ],
  ];

  List<Widget> _itemFields(PartnerReferences references) => [
    _field(
      AppLocalizations.of(context).partnerAccountsItemName,
      _name,
      validator: (value) => (value ?? '').trim().isEmpty
          ? AppLocalizations.of(context).partnerAccountsNameRequired
          : null,
    ),
    if (_part) ...[
      _dropdown(
        label: AppLocalizations.of(context).partnerAccountsPartCategory,
        value: _categoryId,
        items: _flattenCategories(references.partCategories),
        onChanged: (value) => setState(() => _categoryId = value),
      ),
      _choice(
        AppLocalizations.of(context).partnerAccountsPartOrigin,
        _partType,
        {
          'oem': AppLocalizations.of(context).partnerAccountsPartOem,
          'oes': AppLocalizations.of(context).partnerAccountsPartOes,
          'aftermarket': AppLocalizations.of(
            context,
          ).partnerAccountsPartAftermarket,
          'salvage': AppLocalizations.of(context).partnerAccountsPartSalvage,
        },
        (value) => setState(() => _partType = value),
      ),
      _choice(
        AppLocalizations.of(context).partnerAccountsCondition,
        _partCondition,
        {
          'new': AppLocalizations.of(context).partnerAccountsConditionNew,
          'refurbished': AppLocalizations.of(
            context,
          ).partnerAccountsConditionRefurbished,
          'used': AppLocalizations.of(context).partnerAccountsConditionUsed,
        },
        (value) {
          setState(() => _partCondition = value);
          if (value == 'used') _loadDonors();
        },
      ),
      if (_partCondition == 'used') ...[
        Text(AppLocalizations.of(context).partnerAccountsDonorRequiredHelp),
        if (_loadingDonors)
          const LinearProgressIndicator()
        else if (_donorError != null) ...[
          Text(_errorMessage(_donorError!)),
          TextButton(
            onPressed: _loadDonors,
            child: Text(
              AppLocalizations.of(context).partnerAccountsReloadDonors,
            ),
          ),
        ] else if (_donorsLoaded && _donors.isEmpty)
          Text(AppLocalizations.of(context).partnerAccountsDonorsEmpty),
        _dropdown(
          label: AppLocalizations.of(context).partnerAccountsDonorVehicle,
          value: _donorId,
          items: _donors,
          text: (item) =>
              _text(item['designation'] ?? item['reference'] ?? item['id']),
          onChanged: (value) => setState(() => _donorId = value),
        ),
      ],
      _field(
        AppLocalizations.of(
          context,
        ).partnerAccountsManufacturerReferenceOptional,
        _manufacturerReference,
      ),
    ] else
      _choice(
        AppLocalizations.of(context).partnerAccountsAccessoryCategory,
        _accessoryCategory,
        {
          'esthetique': AppLocalizations.of(
            context,
          ).catalogAccessoryCategoryStyling,
          'confort': AppLocalizations.of(
            context,
          ).catalogAccessoryCategoryComfort,
          'securite': AppLocalizations.of(
            context,
          ).catalogAccessoryCategorySafety,
          'multimedia': AppLocalizations.of(
            context,
          ).catalogAccessoryCategoryMultimedia,
          'utilitaire': AppLocalizations.of(
            context,
          ).catalogAccessoryCategoryUtility,
        },
        (value) => setState(() => _accessoryCategory = value),
      ),
    _dropdown(
      label: AppLocalizations.of(context).partnerAccountsManufacturerOptional,
      value: _manufacturerId,
      items: references.manufacturers,
      isRequired: false,
      onChanged: (value) => setState(() => _manufacturerId = value),
    ),
    _field(AppLocalizations.of(context).partnerAccountsSkuOptional, _sku),
    _field(
      AppLocalizations.of(context).partnerAccountsSalePrice,
      _salePrice,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: _money,
      onChanged: (_) => setState(() {}),
    ),
    MargeRecapitulatif(
      prixPropose: _number(_salePrice),
      pourcentage:
          ref.watch(partnerSessionProvider).profile?.margePourcentage ?? 0,
    ),
    _field(
      AppLocalizations.of(context).partnerAccountsStockQuantity,
      _stock,
      keyboardType: TextInputType.number,
      validator: (value) {
        final quantity = int.tryParse(value?.trim() ?? '');
        return quantity == null || quantity < 0
            ? AppLocalizations.of(context).partnerAccountsStockInvalid
            : null;
      },
    ),
  ];
}
