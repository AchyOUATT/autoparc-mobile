import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
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

List<({String value, String label, IconData icon})> _categories(
  AppLocalizations l10n,
) => [
  (
    value: 'esthetique',
    label: l10n.catalogAccessoryCategoryStyling,
    icon: Icons.auto_awesome,
  ),
  (
    value: 'confort',
    label: l10n.catalogAccessoryCategoryComfort,
    icon: Icons.airline_seat_recline_normal,
  ),
  (
    value: 'securite',
    label: l10n.catalogAccessoryCategorySafety,
    icon: Icons.shield_outlined,
  ),
  (
    value: 'multimedia',
    label: l10n.catalogAccessoryCategoryMultimedia,
    icon: Icons.speaker,
  ),
  (
    value: 'utilitaire',
    label: l10n.catalogAccessoryCategoryUtility,
    icon: Icons.build_outlined,
  ),
];

// ════════════════════════════════════════════════════════════════════

class AddAccessoryPage extends ConsumerStatefulWidget {
  final Accessory? existing; // null → création, non-null → édition
  const AddAccessoryPage({super.key, this.existing});

  @override
  ConsumerState<AddAccessoryPage> createState() => _AddAccessoryPageState();
}

class _AddAccessoryPageState extends ConsumerState<AddAccessoryPage> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  String? _category;
  Manufacturer? _manufacturer;
  bool _mfgInitialized = false; // pré-sélection fabricant (mode édition)

  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  final _stockCtrl = TextEditingController(text: '0');
  final _alertCtrl = TextEditingController();
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

    _nameCtrl.text = e.name;
    _skuCtrl.text = e.sku ?? '';
    _category = e.categoryValue;
    _priceCtrl.text = e.pricing.sellingPrice.toStringAsFixed(0);
    if (e.stock.quantity > 0) _stockCtrl.text = e.stock.quantity.toString();
    if (e.stock.alertThreshold > 0)
      _alertCtrl.text = e.stock.alertThreshold.toString();
    if (e.stock.location != null) _locationCtrl.text = e.stock.location!;

    _chargerCompatibilites(e);
  }

  /// Relit les compatibilités de l'accessoire avant de laisser y toucher.
  Future<void> _chargerCompatibilites(Accessory e) async {
    if (e.fitments != null) {
      setState(() => _fitments = _versEntrees(e.fitments!));
      return;
    }

    try {
      final complet = await ref
          .read(catalogRepositoryProvider)
          .getAccessory(e.id, forStaff: true);
      if (!mounted) return;
      setState(() => _fitments = _versEntrees(complet.fitments ?? const []));
    } catch (erreur) {
      if (!mounted) return;
      setState(() => _erreurFitments = erreur);
    }
  }

  List<FitmentEntry> _versEntrees(List<Map<String, dynamic>> brutes) {
    final refs = ref.read(catalogRefsProvider).valueOrNull;
    return brutes.map((j) => FitmentEntry.depuisJson(j, refs: refs)).toList();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _skuCtrl,
      _priceCtrl,
      _costCtrl,
      _stockCtrl,
      _alertCtrl,
      _locationCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.catalogAdminSelectCategory)));
      return;
    }

    // Voir AddPartPage._submit() : la clé n'est envoyée que si la liste est
    // connue. Omise, l'API laisse les compatibilités intactes, ce qui libère
    // le reste de la fiche au lieu d'en faire un cul-de-sac.
    final compatibilites = _fitments;

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      if (_skuCtrl.text.isNotEmpty) 'sku': _skuCtrl.text.trim(),
      'category': _category!,
      if (_manufacturer != null) 'manufacturer_id': _manufacturer!.id,
      'selling_price': double.parse(_priceCtrl.text.replaceAll(' ', '')),
      if (_costCtrl.text.isNotEmpty)
        'cost_price': double.parse(_costCtrl.text.replaceAll(' ', '')),
      if (_stockCtrl.text.isNotEmpty)
        'stock_quantity': int.parse(_stockCtrl.text),
      if (_alertCtrl.text.isNotEmpty)
        'stock_alert_threshold': int.parse(_alertCtrl.text),
      if (_locationCtrl.text.isNotEmpty)
        'storage_location': _locationCtrl.text.trim(),
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
        // Le premier article d'une catégorie doit y faire apparaître sa
        // pastille sans attendre une réouverture de l'application.
        ref.invalidate(categoriesAccessoiresOccupeesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing != null
                  ? l10n.catalogAdminAccessoryUpdated
                  : l10n.catalogAdminAccessoryCreated,
            ),
            backgroundColor: Colors.green,
          ),
        );
        if (existing != null) {
          context.pop();
        } else {
          context.pushReplacement(
            '/media-upload',
            extra: MediaUploadConfig(
              type: MediaOwnerType.accessory,
              id: accessory.id,
              title: accessory.name,
            ),
          );
        }
      }
    } catch (e, pile) {
      // Ce catch avalait tout sans rien en dire, et le message affiche est le
      // repli de messageFor — « Une erreur est survenue » —, celui qui ne se
      // declenche ni pour une ApiException ni pour une DioException. Autrement
      // dit : le serveur a repondu correctement, l'accessoire a bien ete cree,
      // et quelque chose a leve ensuite, dans le bloc de succes ci-dessus.
      //
      // Quatre « Camera de recul » ont ete creees ainsi le 2026-10-16, l'une
      // par tentative, chacune suivie d'un bandeau rouge. Sans cette trace, on
      // ne peut que deviner — et deviner a deja coute assez cher.
      debugPrint('[AddAccessory] echec : ${e.runtimeType} — $e');
      debugPrintStack(stackTrace: pile, maxFrames: 12);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messageFor(e, l10n: l10n)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final manufacturersAsync = ref.watch(manufacturersProvider);
    final refsAsync = ref.watch(catalogRefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existing != null
              ? l10n.catalogAdminEditAccessory
              : l10n.catalogAdminNewAccessory,
        ),
        centerTitle: false,
        actions: [
          // En modification seulement : a la creation, l'accessoire n'a pas
          // encore d'identifiant auquel rattacher une photo.
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: l10n.catalogPhotosTooltip,
              onPressed: () => context.push(
                '/media-upload',
                extra: MediaUploadConfig(
                  type: MediaOwnerType.accessory,
                  id: _existing!.id,
                  title: _existing!.name,
                ),
              ),
            ),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.catalogFeaturesSave),
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
            _SectionTitle(l10n.catalogAdminIdentification),
            _Field(
              ctrl: _nameCtrl,
              label: l10n.catalogAdminNameLabel,
              icon: Icons.label_outline,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.catalogAdminRequired
                  : null,
            ),
            _Field(
              ctrl: _skuCtrl,
              label: l10n.catalogAdminSkuLabel,
              icon: Icons.qr_code,
              hint: l10n.catalogAdminAccessorySkuHint,
            ),

            const SizedBox(height: 4),
            Text(
              l10n.catalogAdminCategoryLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _categories(l10n)
                  .map(
                    (cat) => ChoiceChip(
                      avatar: Icon(cat.icon, size: 16),
                      label: Text(cat.label),
                      selected: _category == cat.value,
                      onSelected: (_) => setState(() => _category = cat.value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),

            manufacturersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
              data: (mfgs) {
                if (!_mfgInitialized && _existing?.manufacturerId != null) {
                  final match = mfgs
                      .where((m) => m.id == _existing!.manufacturerId)
                      .cast<Manufacturer?>()
                      .firstOrNull;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted)
                      setState(() {
                        _manufacturer = match;
                        _mfgInitialized = true;
                      });
                  });
                }
                return _Dropdown<Manufacturer>(
                  label: l10n.catalogFieldManufacturer,
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
            _SectionTitle(l10n.catalogAdminPricing),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    ctrl: _priceCtrl,
                    label: l10n.catalogAdminSalePrice,
                    icon: Icons.sell_outlined,
                    keyboard: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return l10n.catalogAdminRequired;
                      if (double.tryParse(v.replaceAll(' ', '')) == null)
                        return l10n.catalogAdminInvalidNumber;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    ctrl: _costCtrl,
                    label: l10n.catalogAdminPurchasePrice,
                    icon: Icons.shopping_bag_outlined,
                    keyboard: TextInputType.number,
                    hint: l10n.catalogAdminOptional,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Stock ───────────────────────────────────────────────
            _SectionTitle(l10n.catalogAdminStock),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    ctrl: _stockCtrl,
                    label: l10n.catalogAdminInitialQuantity,
                    icon: Icons.inventory_2_outlined,
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    ctrl: _alertCtrl,
                    label: l10n.catalogAdminAlertThreshold,
                    icon: Icons.warning_amber_outlined,
                    keyboard: TextInputType.number,
                    hint: l10n.catalogAdminOptional,
                  ),
                ),
              ],
            ),
            _Field(
              ctrl: _locationCtrl,
              label: l10n.catalogAdminPhysicalLocation,
              icon: Icons.place_outlined,
              hint: l10n.catalogAdminLocationHint,
            ),
            // Agence / showroom (location structurée)
            refsAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (refs) => refs.locations.isEmpty
                  ? const SizedBox()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<int?>(
                        value: _selectedLocationId,
                        decoration: InputDecoration(
                          labelText: l10n.catalogAdminBranch,
                          prefixIcon: Icon(Icons.store_outlined),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.catalogAdminAllBranches),
                          ),
                          ...refs.locations.map(
                            (l) => DropdownMenuItem(
                              value: l.id,
                              child: Text(
                                l.displayLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedLocationId = v),
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // ── Compatibilités véhicules ────────────────────────────
            _SectionTitle(l10n.catalogAdminFitments),
            Text(
              l10n.catalogAdminAccessoryFitmentsHint,
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
                error: (e, _) => Text(
                  l10n.catalogAdminModelsLoadError(messageFor(e, l10n: l10n)),
                  style: const TextStyle(color: Colors.red),
                ),
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
        Text(
          text,
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
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
            DropdownMenuItem(value: null, child: Text(l10n.catalogAdminNone)),
          ...items.map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
