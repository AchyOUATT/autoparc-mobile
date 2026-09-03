import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../vehicles/data/models/catalog_refs.dart';

/// Un fitment = compatibilité déclarée entre une pièce/accessoire et un modèle.
class FitmentEntry {
  final BrandRef  brand;
  final ModelRef  model;
  final TrimRef?  trim;
  final int?      yearFrom;
  final int?      yearTo;
  final String?   position; // pour les pièces uniquement

  const FitmentEntry({
    required this.brand,
    required this.model,
    this.trim,
    this.yearFrom,
    this.yearTo,
    this.position,
  });

  /// Libellé affiché dans la liste.
  String get label {
    final buf = StringBuffer('${brand.name} ${model.displayName}');
    if (trim != null) buf.write(' · ${trim!.name}');
    if (yearFrom != null && yearTo != null) {
      buf.write(' ($yearFrom – $yearTo)');
    } else if (yearFrom != null) {
      buf.write(' (depuis $yearFrom)');
    } else if (yearTo != null) {
      buf.write(' (jusqu\'à $yearTo)');
    }
    if (position != null && position!.isNotEmpty) {
      buf.write(' · ${position!}');
    }
    return buf.toString();
  }

  /// Payload JSON pour l'API.
  Map<String, dynamic> toJson() => {
    'vehicle_model_id': model.id,
    if (trim     != null) 'trim_id':   trim!.id,
    if (yearFrom != null) 'year_from': yearFrom,
    if (yearTo   != null) 'year_to':   yearTo,
    if (position != null && position!.isNotEmpty) 'position': position,
  };
}

// ════════════════════════════════════════════════════════════════════
// Widget principal
// ════════════════════════════════════════════════════════════════════

/// Section "Compatibilités véhicules" — réutilisable dans les formulaires
/// de pièces détachées et d'accessoires.
class FitmentsSection extends StatefulWidget {
  final CatalogRefs refs;
  final bool showPosition; // true pour les pièces, false pour les accessoires
  final void Function(List<FitmentEntry>) onChanged;

  const FitmentsSection({
    super.key,
    required this.refs,
    required this.onChanged,
    this.showPosition = false,
  });

  @override
  State<FitmentsSection> createState() => _FitmentsSectionState();
}

class _FitmentsSectionState extends State<FitmentsSection> {
  final List<FitmentEntry> _entries = [];

  void _add(FitmentEntry entry) {
    setState(() => _entries.add(entry));
    widget.onChanged(List.unmodifiable(_entries));
  }

  void _remove(int index) {
    setState(() => _entries.removeAt(index));
    widget.onChanged(List.unmodifiable(_entries));
  }

  Future<void> _openAddSheet() async {
    final entry = await showModalBottomSheet<FitmentEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FitmentSheet(
        refs: widget.refs,
        showPosition: widget.showPosition,
      ),
    );
    if (entry != null) _add(entry);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Liste des fitments ajoutés ────────────────────────────
        if (_entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.directions_car_outlined,
                    size: 32, color: cs.outline),
                const SizedBox(height: 8),
                Text(
                  'Aucune compatibilité déclarée',
                  style: TextStyle(color: cs.outline),
                ),
                const SizedBox(height: 4),
                Text(
                  'La pièce sera trouvable uniquement par SKU.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: cs.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final e = _entries[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      e.brand.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(e.label, style: const TextStyle(fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _remove(i),
                    color: cs.error,
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 10),

        // ── Bouton Ajouter ────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: _openAddSheet,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter une compatibilité'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Bottom sheet de saisie d'un fitment
// ════════════════════════════════════════════════════════════════════

class _FitmentSheet extends StatefulWidget {
  final CatalogRefs refs;
  final bool showPosition;

  const _FitmentSheet({required this.refs, required this.showPosition});

  @override
  State<_FitmentSheet> createState() => _FitmentSheetState();
}

class _FitmentSheetState extends State<_FitmentSheet> {
  BrandRef?  _brand;
  ModelRef?  _model;
  TrimRef?   _trim;
  final _yearFromCtrl = TextEditingController();
  final _yearToCtrl   = TextEditingController();
  final _posCtrl      = TextEditingController();

  @override
  void dispose() {
    _yearFromCtrl.dispose();
    _yearToCtrl.dispose();
    _posCtrl.dispose();
    super.dispose();
  }

  List<ModelRef> get _models =>
      _brand == null ? [] : widget.refs.modelsForBrand(_brand!.id);

  List<TrimRef> get _trims =>
      _model == null ? [] : widget.refs.trimsForModel(_model!.id);

  void _confirm() {
    if (_model == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un modèle.')),
      );
      return;
    }

    final entry = FitmentEntry(
      brand:    _brand!,
      model:    _model!,
      trim:     _trim,
      yearFrom: int.tryParse(_yearFromCtrl.text),
      yearTo:   int.tryParse(_yearToCtrl.text),
      position: widget.showPosition ? _posCtrl.text.trim() : null,
    );

    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final brands = widget.refs.brands.where((b) => b.isActive).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Compatibilité véhicule',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // ── Marque ───────────────────────────────────────────────
          DropdownButtonFormField<BrandRef>(
            value: _brand,
            decoration: const InputDecoration(
              labelText: 'Marque *',
              prefixIcon: Icon(Icons.directions_car_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            isExpanded: true,
            hint: const Text('Sélectionner…'),
            items: brands.map((b) => DropdownMenuItem(
              value: b,
              child: Text(b.name),
            )).toList(),
            onChanged: (b) => setState(() {
              _brand = b;
              _model = null;
              _trim  = null;
            }),
          ),
          const SizedBox(height: 12),

          // ── Modèle ───────────────────────────────────────────────
          DropdownButtonFormField<ModelRef>(
            value: _model,
            decoration: InputDecoration(
              labelText: 'Modèle *',
              prefixIcon: const Icon(Icons.car_repair),
              border: const OutlineInputBorder(),
              isDense: true,
              helperText: _brand == null ? 'Choisir d\'abord une marque' : null,
            ),
            isExpanded: true,
            hint: const Text('Sélectionner…'),
            items: _models.map((m) => DropdownMenuItem(
              value: m,
              child: Text(m.displayName),
            )).toList(),
            onChanged: _brand == null ? null : (m) => setState(() {
              _model = m;
              _trim  = null;
            }),
          ),
          const SizedBox(height: 12),

          // ── Finition (optionnel) ─────────────────────────────────
          if (_trims.isNotEmpty) ...[
            DropdownButtonFormField<TrimRef>(
              value: _trim,
              decoration: const InputDecoration(
                labelText: 'Finition (optionnel)',
                prefixIcon: Icon(Icons.tune),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              isExpanded: true,
              hint: const Text('Toutes finitions'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Toutes finitions —')),
                ..._trims.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.name),
                )),
              ],
              onChanged: (t) => setState(() => _trim = t),
            ),
            const SizedBox(height: 12),
          ],

          // ── Années ───────────────────────────────────────────────
          Row(children: [
            Expanded(child: TextFormField(
              controller: _yearFromCtrl,
              decoration: const InputDecoration(
                labelText: 'Année de',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            )),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(
              controller: _yearToCtrl,
              decoration: const InputDecoration(
                labelText: 'Année à',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            )),
          ]),

          // ── Position (pièces seulement) ──────────────────────────
          if (widget.showPosition) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _posCtrl,
              decoration: const InputDecoration(
                labelText: 'Position (optionnel)',
                prefixIcon: Icon(Icons.location_searching),
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Ex. Avant gauche, Côté moteur…',
              ),
            ),
          ],

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter cette compatibilité'),
          ),
        ],
      ),
    );
  }
}
