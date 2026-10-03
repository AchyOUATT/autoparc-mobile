import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/accessory.dart';
import '../../data/models/manufacturer.dart';
import '../providers/catalog_providers.dart';
import '../widgets/fitments_section.dart';
import '../../../vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../../shared/presentation/pages/media_upload_page.dart';
import '../../../../shared/data/media_repository.dart';
import '../../../../core/api/api_exception.dart';

const _categories = [
  (value: 'esthetique',  label: 'Esthétique',   icon: Icons.auto_awesome),
  (value: 'confort',     label: 'Confort',       icon: Icons.airline_seat_recline_normal),
  (value: 'securite',    label: 'Sécurité',      icon: Icons.shield_outlined),
  (value: 'multimedia',  label: 'Multimédia',    icon: Icons.speaker),
  (value: 'utilitaire',  label: 'Utilitaire',    icon: Icons.build_outlined),
];

// ════════════════════════════════════════════════════════════════════

class AddAccessoryPage extends ConsumerStatefulWidget {
  final Accessory? existing; // null → création, non-null → édition
  const AddAccessoryPage({super.key, this.existing});

  @override
  ConsumerState<AddAccessoryPage> createState() => _AddAccessoryPageState();
}

class _AddAccessoryPageState extends ConsumerState<AddAccessoryPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl     = TextEditingController();
  final _skuCtrl      = TextEditingController();
  String? _category;
  Manufacturer? _manufacturer;
  bool _mfgInitialized = false; // pré-sélection fabricant (mode édition)

  final _priceCtrl    = TextEditingController();
  final _costCtrl     = TextEditingController();

  final _stockCtrl    = TextEditingController(text: '0');
  final _alertCtrl    = TextEditingController();
  final _locationCtrl = TextEditingController();
  int? _selectedLocationId;

  /// Voir `AddPartPage` : `null` veut dire « pas encore relues », et non
  /// « aucune ». Enregistrer sans les connaître les effacerait, le `PUT`
  /// remplaçant la liste entière.
  List<FitmentEntry>? _fitments;
  Object? _erreurFitments;
  bool _saving = false;

  Accessory? get _existing => (widget as AddAccessoryPage).existing;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    if (e == null) {
      _fitments = [];
      return;
    }

    _nameCtrl.text  = e.name;
    _skuCtrl.text   = e.sku ?? '';
    _category       = e.categoryValue;
    _priceCtrl.text = e.pricing.sellingPrice.toStringAsFixed(0);
    if (e.stock.quantity > 0) _stockCtrl.text = e.stock.quantity.toString();
    if (e.stock.alertThreshold > 0)
      _alertCtrl.text = e.stock.alertThreshold.toString();
    if (e.stock.location != null)
      _locationCtrl.text = e.stock.location!;

    _chargerCompatibilites(e);
  }

  /// Relit les compatibilités de l'accessoire avant de laisser y toucher.
  Future<void> _chargerCompatibilites(Accessory e) async {
    if (e.fitments != null) {
      setState(() => _fitments = _versEntrees(e.fitments!));
      return;
    }

    try {
      final complet = await ref.read(catalogRepositoryProvider).getAccessory(e.id);
      if (!mounted) return;
      setState(() => _fitments = _versEntrees(complet.fitments ?? const []));
    } catch (erreur) {
      if (!mounted) return;
      setState(() => _erreurFitments = erreur);
    }
  }

  List<FitmentEntry> _versEntrees(List<Map<String, dynamic>> brutes) {
    final refs = ref.read(catalogRefsProvider).valueOrNull;
    return brutes
        .map((j) => FitmentEntry.depuisJson(j, refs: refs))
        .toList();
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

    // Voir AddPartPage._submit() : la clé n'est envoyée que si la liste est
    // connue. Omise, l'API laisse les compatibilités intactes, ce qui libère
    // le reste de la fiche au lieu d'en faire un cul-de-sac.
    final compatibilites = _fitments;

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'name':     _nameCtrl.text.trim(),
      if (_skuCtrl.text.isNotEmpty) 'sku': _skuCtrl.text.trim(),
      'category': _category!,
      if (_manufacturer != null) 'manufacturer_id': _manufacturer!.id,
      'selling_price': double.parse(_priceCtrl.text.replaceAll(' ', '')),
      if (_costCtrl.text.isNotEmpty)
        'cost_price': double.parse(_costCtrl.text.replaceAll(' ', '')),
      if (_stockCtrl.text.isNotEmpty) 'stock_quantity': int.parse(_stockCtrl.text),
      if (_alertCtrl.text.isNotEmpty) 'stock_alert_threshold': int.parse(_alertCtrl.text),
      if (_locationCtrl.text.isNotEmpty) 'storage_location': _locationCtrl.text.trim(),
      if (_selectedLocationId != null) 'location_id': _selectedLocationId,
      'is_active': true,
      // Envoyée même vide quand elle est connue : sans quoi retirer la
      // dernière compatibilité d'un accessoire serait impossible.
      if (compatibilites != null)
        'fitments': compatibilites.map((f) => f.toJson()).toList(),
    };

    try {
      final repo = ref.read(catalogRepositoryProvider);
      final existing = _existing;
      final Accessory accessory;
      if (existing != null) {
        accessory = await repo.updateAccessory(existing.id, payload);
      } else {
        accessory = await repo.createAccessory(payload);
      }
      if (mounted) {
        ref.invalidate(accessoryListProvider);
        ref.invalidate(accessoryDetailProvider(accessory.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing != null
                ? 'Accessoire mis à jour.'
                : 'Accessoire enregistré — ajoutez des photos !'),
            backgroundColor: Colors.green,
          ),
        );
        if (existing != null) {
          context.pop();
        } else {
          context.pushReplacement(
            '/media-upload',
            extra: MediaUploadConfig(
              type:  MediaOwnerType.accessory,
              id:    accessory.id,
              title: accessory.name,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageFor(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manufacturersAsync = ref.watch(manufacturersProvider);
    final refsAsync          = ref.watch(catalogRefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing != null ? 'Modifier l\'accessoire' : 'Nouvel accessoire'),
        centerTitle: false,
        actions: [
          // En modification seulement : a la creation, l'accessoire n'a pas
          // encore d'identifiant auquel rattacher une photo.
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: 'Photos',
              onPressed: () => context.push(
                '/media-upload',
                extra: MediaUploadConfig(
                  type:  MediaOwnerType.accessory,
                  id:    _existing!.id,
                  title: _existing!.name,
                ),
              ),
            ),
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
              hint: 'Ex. ACC-EST-0012 (optionnel)',
            ),

            const SizedBox(height: 4),
            Text('Catégorie *', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _categories.map((cat) => ChoiceChip(
                avatar: Icon(cat.icon, size: 16),
                label: Text(cat.label),
                selected: _category == cat.value,
                onSelected: (_) => setState(() => _category = cat.value),
              )).toList(),
            ),
            const SizedBox(height: 14),

            manufacturersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
              data: (mfgs) {
                if (!_mfgInitialized && _existing?.manufacturerId != null) {
                  final match = mfgs.where((m) => m.id == _existing!.manufacturerId)
                      .cast<Manufacturer?>().firstOrNull;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() {
                      _manufacturer    = match;
                      _mfgInitialized  = true;
                    });
                  });
                }
                return _Dropdown<Manufacturer>(
                  label: 'Fabricant',
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
                hint: 'Optionnel',
              )),
            ]),
            _Field(
              ctrl: _locationCtrl,
              label: 'Emplacement physique',
              icon: Icons.place_outlined,
              hint: 'Ex. Vitrine 2, Rayon A',
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
              'Optionnel — déclarez les véhicules compatibles '
              'pour faciliter la recherche.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_erreurFitments != null)
              CompatibilitesIllisibles(erreur: _erreurFitments!)
            else if (_fitments == null)
              const LinearProgressIndicator()
            else
              refsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Impossible de charger les modèles : $e',
                    style: const TextStyle(color: Colors.red)),
                data: (refs) => FitmentsSection(
                  refs: refs,
                  showPosition: false,
                  initiales: _fitments!,
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
