import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/part.dart';
import '../../data/models/part_category.dart';
import '../../data/models/manufacturer.dart';
import '../providers/catalog_providers.dart';
import '../widgets/fitments_section.dart';
import '../../../vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../../shared/presentation/pages/media_upload_page.dart';
import '../../../../shared/data/media_repository.dart';

// ── Constantes métier ─────────────────────────────────────────────────

const _types = [
  (value: 'oem',         label: 'OEM'),
  (value: 'oes',         label: 'OES'),
  (value: 'aftermarket', label: 'Aftermarket'),
  (value: 'salvage',     label: 'Occasion'),
];

const _conditions = [
  (value: 'new',         label: 'Neuve'),
  (value: 'refurbished', label: 'Reconditionnée'),
  (value: 'used',        label: 'D\'occasion'),
];

// ════════════════════════════════════════════════════════════════════

class AddPartPage extends ConsumerStatefulWidget {
  final Part? existing; // null → création, non-null → édition
  const AddPartPage({super.key, this.existing});

  @override
  ConsumerState<AddPartPage> createState() => _AddPartPageState();
}

class _AddPartPageState extends ConsumerState<AddPartPage> {
  final _formKey = GlobalKey<FormState>();

  // Identification
  final _nameCtrl = TextEditingController();
  final _skuCtrl  = TextEditingController();
  String _type      = 'aftermarket';
  String _condition = 'new';

  // Classification
  PartCategory? _category;
  Manufacturer? _manufacturer;
  bool _dropdownsInitialized = false; // pré-remplissage dropdowns (mode édition)

  // Prix (sans TVA)
  final _priceCtrl = TextEditingController();
  final _costCtrl  = TextEditingController();

  // Stock
  final _stockCtrl    = TextEditingController(text: '0');
  final _alertCtrl    = TextEditingController(text: '5');
  final _locationCtrl = TextEditingController(); // emplacement physique (étagère, tiroir)
  int? _selectedLocationId;                      // agence / showroom (FK)

  // (description et garantie supprimées — gérées après création si besoin)

  // Compatibilités véhicules
  List<FitmentEntry> _fitments = [];

  bool _saving = false;

  Part? get _existing => (widget as AddPartPage).existing;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _skuCtrl.text  = e.sku ?? '';
      _type          = e.type;
      _condition     = e.condition;
      _priceCtrl.text = e.pricing.sellingPrice.toStringAsFixed(0);
      if (e.stock.quantity > 0) _stockCtrl.text = e.stock.quantity.toString();
      if (e.stock.alertThreshold > 0)
        _alertCtrl.text = e.stock.alertThreshold.toString();
      if (e.stock.location != null)
        _locationCtrl.text = e.stock.location!;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _skuCtrl, _priceCtrl, _costCtrl,
      _stockCtrl, _alertCtrl, _locationCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie.')),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'name':             _nameCtrl.text.trim(),
      if (_skuCtrl.text.isNotEmpty) 'sku': _skuCtrl.text.trim(),
      'type':             _type,
      'condition':        _condition,
      'part_category_id': _category!.id,
      if (_manufacturer != null) 'manufacturer_id': _manufacturer!.id,
      'selling_price': double.parse(_priceCtrl.text.replaceAll(' ', '')),
      if (_costCtrl.text.isNotEmpty)
        'cost_price': double.parse(_costCtrl.text.replaceAll(' ', '')),
      if (_stockCtrl.text.isNotEmpty) 'stock_quantity': int.parse(_stockCtrl.text),
      if (_alertCtrl.text.isNotEmpty) 'stock_alert_threshold': int.parse(_alertCtrl.text),
      if (_locationCtrl.text.isNotEmpty) 'storage_location': _locationCtrl.text.trim(),
      if (_selectedLocationId != null) 'location_id': _selectedLocationId,
      'is_active': true,
      if (_fitments.isNotEmpty)
        'fitments': _fitments.map((f) => f.toJson()).toList(),
    };

    try {
      final repo = ref.read(catalogRepositoryProvider);
      final existing = _existing;
      final Part part;
      if (existing != null) {
        part = await repo.updatePart(existing.id, payload);
      } else {
        part = await repo.createPart(payload);
      }
      if (mounted) {
        ref.invalidate(partListProvider);
        ref.invalidate(partDetailProvider(part.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing != null
                ? 'Pièce mise à jour.'
                : 'Pièce enregistrée — ajoutez des photos !'),
            backgroundColor: Colors.green,
          ),
        );
        if (existing != null) {
          context.pop();
        } else {
          context.pushReplacement(
            '/media-upload',
            extra: MediaUploadConfig(
              type:  MediaOwnerType.part,
              id:    part.id,
              title: part.name,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync    = ref.watch(partCategoriesProvider);
    final manufacturersAsync = ref.watch(manufacturersProvider);
    final refsAsync          = ref.watch(catalogRefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing != null ? 'Modifier la pièce' : 'Nouvelle pièce'),
        centerTitle: false,
        actions: [
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enregistrer'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Identification ──────────────────────────────────────
            _SectionTitle('Identification'),
            _Field(
              ctrl: _nameCtrl,
              label: 'Désignation *',
              icon: Icons.label_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            _Field(
              ctrl: _skuCtrl,
              label: 'SKU / Référence interne',
              icon: Icons.qr_code,
              hint: 'Ex. PDT-BRQ-0042 (optionnel)',
            ),

            // Type
            const SizedBox(height: 4),
            Text('Type *', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _types.map((t) => ChoiceChip(
                label: Text(t.label),
                selected: _type == t.value,
                onSelected: (_) => setState(() => _type = t.value),
              )).toList(),
            ),

            const SizedBox(height: 14),
            Text('État *', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _conditions.map((c) => ChoiceChip(
                label: Text(c.label),
                selected: _condition == c.value,
                onSelected: (_) => setState(() => _condition = c.value),
              )).toList(),
            ),

            const SizedBox(height: 24),

            // ── Classification ──────────────────────────────────────
            _SectionTitle('Classification'),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur : $e',
                  style: const TextStyle(color: Colors.red)),
              data: (cats) {
                // Pré-sélection en mode édition (une seule fois)
                if (!_dropdownsInitialized && _existing?.categoryId != null) {
                  final match = cats.where((c) => c.id == _existing!.categoryId)
                      .cast<PartCategory?>().firstOrNull;
                  if (match != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _category = match);
                    });
                  }
                }
                return _Dropdown<PartCategory>(
                  label: 'Catégorie *',
                  icon: Icons.category_outlined,
                  value: _category,
                  items: cats,
                  onChanged: (v) => setState(() => _category = v),
                  itemLabel: (c) => c.name,
                );
              },
            ),
            const SizedBox(height: 10),
            manufacturersAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (mfgs) {
                // Pré-sélection en mode édition (une seule fois)
                if (!_dropdownsInitialized && _existing?.manufacturerId != null) {
                  final match = mfgs.where((m) => m.id == _existing!.manufacturerId)
                      .cast<Manufacturer?>().firstOrNull;
                  if (match != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() {
                        _manufacturer = match;
                        _dropdownsInitialized = true;
                      });
                    });
                  } else {
                    _dropdownsInitialized = true;
                  }
                }
                return _Dropdown<Manufacturer>(
                  label: 'Fabricant / Équipementier',
                  icon: Icons.factory_outlined,
                  value: _manufacturer,
                  items: mfgs,
                  onChanged: (v) => setState(() => _manufacturer = v),
                  itemLabel: (m) => m.name,
                  nullable: true,
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Tarification ────────────────────────────────────────
            _SectionTitle('Tarification'),
            Row(children: [
              Expanded(child: _Field(
                ctrl: _priceCtrl,
                label: 'Prix de vente *',
                icon: Icons.sell_outlined,
                keyboard: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  if (double.tryParse(v.replaceAll(' ', '')) == null) return 'Nombre invalide';
                  return null;
                },
              )),
              const SizedBox(width: 12),
              Expanded(child: _Field(
                ctrl: _costCtrl,
                label: "Prix d'achat",
                icon: Icons.shopping_bag_outlined,
                keyboard: TextInputType.number,
                hint: 'Optionnel',
              )),
            ]),

            const SizedBox(height: 24),

            // ── Stock ───────────────────────────────────────────────
            _SectionTitle('Stock'),
            Row(children: [
              Expanded(child: _Field(
                ctrl: _stockCtrl,
                label: 'Quantité initiale',
                icon: Icons.inventory_2_outlined,
                keyboard: TextInputType.number,
              )),
              const SizedBox(width: 12),
              Expanded(child: _Field(
                ctrl: _alertCtrl,
                label: 'Seuil d\'alerte',
                icon: Icons.warning_amber_outlined,
                keyboard: TextInputType.number,
              )),
            ]),
            _Field(
              ctrl: _locationCtrl,
              label: 'Emplacement physique',
              icon: Icons.place_outlined,
              hint: 'Ex. Étagère B3, Tiroir 12',
            ),
            // Agence / showroom (location structurée)
            refsAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (refs) => refs.locations.isEmpty ? const SizedBox() : Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<int?>(
                  value: _selectedLocationId,
                  decoration: const InputDecoration(
                    labelText: 'Agence / Showroom',
                    prefixIcon: Icon(Icons.store_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Toutes agences —')),
                    ...refs.locations.map((l) => DropdownMenuItem(
                      value: l.id,
                      child: Text(l.displayLabel, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedLocationId = v),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Compatibilités véhicules ────────────────────────────
            _SectionTitle('Compatibilités véhicules'),
            Text(
              'Déclarez les véhicules compatibles pour permettre '
              'la recherche par modèle — même sans numéro OEM.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            refsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Impossible de charger les modèles : $e',
                  style: const TextStyle(color: Colors.red)),
              data: (refs) => FitmentsSection(
                refs: refs,
                showPosition: true,
                onChanged: (list) => setState(() => _fitments = list),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Widgets réutilisables ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(height: 8),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType keyboard;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: validator,
    ),
  );
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;
  final String Function(T) itemLabel;
  final bool nullable;

  const _Dropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
    this.nullable = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      isExpanded: true,
      items: [
        if (nullable)
          const DropdownMenuItem(value: null, child: Text('— Aucun —')),
        ...items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
        )),
      ],
      onChanged: onChanged,
    ),
  );
}
