import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/vehicle_fault.dart';
import '../../data/vehicle_fault_repository.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/api/api_exception.dart';

// ── Provider ──────────────────────────────────────────────────────────

final _faultsProvider = FutureProvider.autoDispose
    .family<List<VehicleFault>, int>((ref, vehicleId) {
  return ref.read(vehicleFaultRepositoryProvider).getFaults(vehicleId);
});

// ════════════════════════════════════════════════════════════════════
// Section principale (intégrée dans la fiche véhicule — staff only)
// ════════════════════════════════════════════════════════════════════

class VehicleFaultsSection extends ConsumerWidget {
  final int vehicleId;

  const VehicleFaultsSection({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faultsAsync = ref.watch(_faultsProvider(vehicleId));
    // Tout le personnel consulte les pannes ; seuls le mecanicien et la
    // direction en declarent.
    final canDeclare  = ref.watch(authProvider).canManageFaults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre + bouton ajouter ────────────────────────────────
        Row(
          children: [
            Text(
              'Pannes déclarées',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (canDeclare)
              FilledButton.tonalIcon(
                onPressed: () => _openAddSheet(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Déclarer'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Contenu ───────────────────────────────────────────────
        faultsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(messageFor(e))),
                TextButton(
                  onPressed: () => ref.invalidate(_faultsProvider(vehicleId)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
          data: (faults) => faults.isEmpty
              ? _EmptyFaults(
                  onAdd: () => _openAddSheet(context, ref),
                  canDeclare: canDeclare,
                )
              : Column(
                  children: faults
                      .map((f) => _FaultCard(
                            fault: f,
                            vehicleId: vehicleId,
                            onChanged: () =>
                                ref.invalidate(_faultsProvider(vehicleId)),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddFaultSheet(
        vehicleId: vehicleId,
        onSaved: () => ref.invalidate(_faultsProvider(vehicleId)),
      ),
    );
  }
}

// ── Carte d'une panne ─────────────────────────────────────────────────

class _FaultCard extends ConsumerWidget {
  final VehicleFault fault;
  final int vehicleId;
  final VoidCallback onChanged;

  const _FaultCard({
    required this.fault,
    required this.vehicleId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severityColor = Color(fault.severityColor);
    final isOpen = fault.isOpen;
    final canManage = ref.watch(authProvider).canManageFaults;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bande de sévérité ──────────────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fault.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              _Chip(fault.categoryLabel,
                                  Theme.of(context).colorScheme.secondaryContainer),
                              _Chip(fault.severityLabel,
                                  severityColor.withAlpha(40),
                                  textColor: severityColor),
                              _Chip(fault.statusLabel,
                                  Theme.of(context).colorScheme.surfaceContainerHigh),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ── Menu actions ────────────────────────────
                    // Resoudre et supprimer sont des ecritures : le menu
                    // disparait pour qui ne les a pas.
                    if (canManage)
                    PopupMenuButton<String>(
                      onSelected: (v) =>
                          _handleAction(context, ref, v),
                      itemBuilder: (_) => [
                        if (isOpen)
                          const PopupMenuItem(
                            value: 'resolve',
                            child: ListTile(
                              leading: Icon(Icons.check_circle_outline),
                              title: Text('Résoudre'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline, color: Colors.red),
                            title: Text('Supprimer',
                                style: TextStyle(color: Colors.red)),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Flags ─────────────────────────────────────────
                if (fault.isSafetyCritical || fault.affectsDrivability ||
                    fault.disclosedToBuyer) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (fault.isSafetyCritical)
                        _IconFlag(Icons.warning_amber, 'Sécurité', Colors.red),
                      if (fault.affectsDrivability)
                        _IconFlag(Icons.directions_car_outlined,
                            'Conduite affectée', Colors.orange),
                      if (fault.disclosedToBuyer)
                        _IconFlag(Icons.visibility_outlined,
                            'Divulguée acheteur', Colors.blue),
                    ],
                  ),
                ],

                // ── Description ───────────────────────────────────
                if (fault.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    fault.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // ── Coûts / kilométrage ───────────────────────────
                if (fault.estimatedRepairCost != null ||
                    fault.mileageAtDetectionKm != null) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      if (fault.mileageAtDetectionKm != null) ...[
                        const Icon(Icons.speed, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${fault.mileageAtDetectionKm} km',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (fault.estimatedRepairCost != null) ...[
                        const Icon(Icons.build_outlined, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          'Estimé : ${formatXof(fault.estimatedRepairCost)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (fault.actualRepairCost != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.check, size: 13,
                            color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Réel : ${formatXof(fault.actualRepairCost)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.green),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    if (action == 'resolve') {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _ResolveFaultSheet(
          fault: fault,
          vehicleId: vehicleId,
          onResolved: onChanged,
        ),
      );
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Supprimer cette panne ?'),
          content: Text(fault.title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        try {
          await ref
              .read(vehicleFaultRepositoryProvider)
              .deleteFault(vehicleId, fault.id);
          onChanged();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(messageFor(e)),
                  backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }
}

// ── Badges ────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color? textColor;

  const _Chip(this.label, this.bg, {this.textColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),
  );
}

class _IconFlag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IconFlag(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500)),
    ],
  );
}

// ── Vue vide ──────────────────────────────────────────────────────────

class _EmptyFaults extends StatelessWidget {
  final VoidCallback onAdd;

  /// Faux pour un role qui consulte sans pouvoir declarer : inutile de lui
  /// demander une action dont le bouton a disparu.
  final bool canDeclare;

  const _EmptyFaults({required this.onAdd, required this.canDeclare});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(Icons.check_circle_outline,
            size: 40, color: Colors.green.shade400),
        const SizedBox(height: 8),
        const Text('Aucune panne déclarée',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          canDeclare
              ? 'Déclarez les défauts connus pour informer les acheteurs.'
              : 'Ce véhicule ne présente aucun défaut connu.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════════
// Sheet — Déclarer une panne
// ════════════════════════════════════════════════════════════════════

class _AddFaultSheet extends ConsumerStatefulWidget {
  final int vehicleId;
  final VoidCallback onSaved;

  const _AddFaultSheet({required this.vehicleId, required this.onSaved});

  @override
  ConsumerState<_AddFaultSheet> createState() => _AddFaultSheetState();
}

class _AddFaultSheetState extends ConsumerState<_AddFaultSheet> {
  final _formKey      = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _codeCtrl     = TextEditingController();
  final _costCtrl     = TextEditingController();
  final _mileCtrl     = TextEditingController();
  final _reporterCtrl = TextEditingController();
  final _dateCtrl     = TextEditingController();

  String _category = 'engine';
  String _severity = 'moderate';

  bool _affectsDrivability = false;
  bool _isSafetyCritical   = false;
  bool _disclosedToBuyer   = true; // par défaut divulguée

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _descCtrl, _codeCtrl, _costCtrl,
      _mileCtrl, _reporterCtrl, _dateCtrl,
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'category':           _category,
      'title':              _titleCtrl.text.trim(),
      'severity':           _severity,
      'affects_drivability': _affectsDrivability,
      'is_safety_critical':  _isSafetyCritical,
      'disclosed_to_buyer':  _disclosedToBuyer,
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      if (_codeCtrl.text.trim().isNotEmpty) 'code': _codeCtrl.text.trim(),
      if (_costCtrl.text.trim().isNotEmpty)
        'estimated_repair_cost':
            double.parse(_costCtrl.text.replaceAll(' ', '')),
      if (_mileCtrl.text.trim().isNotEmpty)
        'mileage_at_detection_km': int.parse(_mileCtrl.text),
      if (_reporterCtrl.text.trim().isNotEmpty)
        'reported_by': _reporterCtrl.text.trim(),
      if (_dateCtrl.text.isNotEmpty) 'detected_at': _dateCtrl.text,
    };

    try {
      await ref
          .read(vehicleFaultRepositoryProvider)
          .createFault(widget.vehicleId, payload);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
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
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.6,
      expand: false,
      builder: (_, scrollCtrl) => Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Poignée ───────────────────────────────────────────
            const SizedBox(height: 12),
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text('Déclarer une panne',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Corps scrollable ──────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  // Titre obligatoire
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Titre *',
                      hintText: 'Ex. : Fuite d\'huile moteur',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Le titre est obligatoire'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // Catégorie
                  _label(context, 'Catégorie *'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    isExpanded: true,
                    items: faultCategories
                        .map((c) => DropdownMenuItem(
                              value: c.value,
                              child: Text(c.label),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 16),

                  // Sévérité
                  _label(context, 'Sévérité *'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: faultSeverities.map((s) {
                      final selected = _severity == s.value;
                      final col = Color(s.color);
                      return ChoiceChip(
                        label: Text(s.label),
                        selected: selected,
                        selectedColor: col.withAlpha(50),
                        side: selected ? BorderSide(color: col) : null,
                        labelStyle: selected
                            ? TextStyle(
                                color: col, fontWeight: FontWeight.bold)
                            : null,
                        onSelected: (_) =>
                            setState(() => _severity = s.value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Flags
                  SwitchListTile(
                    title: const Text('Affecte la conduite'),
                    subtitle: const Text('Le véhicule est difficile ou dangereux à conduire'),
                    value: _affectsDrivability,
                    onChanged: (v) => setState(() => _affectsDrivability = v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  SwitchListTile(
                    title: const Text('Critique pour la sécurité'),
                    value: _isSafetyCritical,
                    onChanged: (v) => setState(() => _isSafetyCritical = v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  SwitchListTile(
                    title: const Text('Divulguée à l\'acheteur'),
                    subtitle: const Text('Cette panne est mentionnée dans l\'annonce'),
                    value: _disclosedToBuyer,
                    onChanged: (v) => setState(() => _disclosedToBuyer = v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),

                  const Divider(height: 24),

                  // Description
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optionnel)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      hintText: 'Détails sur la panne, symptômes, conditions…',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Code OBD
                  TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Code OBD (optionnel)',
                      hintText: 'Ex. : P0301',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  ),
                  const SizedBox(height: 12),

                  // Date de détection
                  TextFormField(
                    controller: _dateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Date de détection (optionnel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event_outlined),
                      hintText: 'AAAA-MM-JJ',
                    ),
                    readOnly: true,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) {
                        _dateCtrl.text =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Kilométrage
                  TextFormField(
                    controller: _mileCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kilométrage à la détection (optionnel)',
                      border: OutlineInputBorder(),
                      suffixText: 'km',
                      prefixIcon: Icon(Icons.speed_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),

                  // Coût estimé
                  TextFormField(
                    controller: _costCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Coût estimé de réparation (optionnel)',
                      border: OutlineInputBorder(),
                      prefixText: 'XOF ',
                      suffixText: 'FCFA',
                      prefixIcon: Icon(Icons.build_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                    ],
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        if (double.tryParse(v.replaceAll(' ', '')) == null) {
                          return 'Montant invalide';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Signalé par
                  TextFormField(
                    controller: _reporterCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Signalé par (optionnel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Nom du technicien ou du client',
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // ── Bouton enregistrer ────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                20, 8, 20,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Enregistrer la panne'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.bold),
  );
}

// ════════════════════════════════════════════════════════════════════
// Sheet — Résoudre une panne
// ════════════════════════════════════════════════════════════════════

class _ResolveFaultSheet extends ConsumerStatefulWidget {
  final VehicleFault fault;
  final int vehicleId;
  final VoidCallback onResolved;

  const _ResolveFaultSheet({
    required this.fault,
    required this.vehicleId,
    required this.onResolved,
  });

  @override
  ConsumerState<_ResolveFaultSheet> createState() =>
      _ResolveFaultSheetState();
}

class _ResolveFaultSheetState extends ConsumerState<_ResolveFaultSheet> {
  final _costCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  bool _saving    = false;

  @override
  void initState() {
    super.initState();
    // Préremplir le coût estimé si disponible
    if (widget.fault.estimatedRepairCost != null) {
      _costCtrl.text =
          widget.fault.estimatedRepairCost!.toStringAsFixed(0);
    }
    // Date d'aujourd'hui par défaut
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() => _saving = true);
    try {
      await ref.read(vehicleFaultRepositoryProvider).resolveFault(
        widget.vehicleId,
        widget.fault.id,
        actualRepairCost: _costCtrl.text.trim().isNotEmpty
            ? double.parse(_costCtrl.text.replaceAll(' ', ''))
            : null,
        repairedAt: _dateCtrl.text.isNotEmpty ? _dateCtrl.text : null,
      );
      widget.onResolved();
      if (mounted) Navigator.pop(context);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 16, 20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Résoudre : ${widget.fault.title}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date de réparation
          TextFormField(
            controller: _dateCtrl,
            decoration: const InputDecoration(
              labelText: 'Date de réparation',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.event_outlined),
            ),
            readOnly: true,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (d != null) {
                _dateCtrl.text =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              }
            },
          ),
          const SizedBox(height: 12),

          // Coût réel
          TextFormField(
            controller: _costCtrl,
            decoration: const InputDecoration(
              labelText: 'Coût réel de réparation (optionnel)',
              border: OutlineInputBorder(),
              prefixText: 'XOF ',
              suffixText: 'FCFA',
              prefixIcon: Icon(Icons.receipt_outlined),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
            ],
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _saving ? null : _resolve,
            icon: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: const Text('Marquer comme réparée'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}
