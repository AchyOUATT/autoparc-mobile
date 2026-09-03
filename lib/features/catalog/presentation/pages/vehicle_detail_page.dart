import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/vehicle.dart';
import '../providers/catalog_providers.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../vehicles/data/vehicle_admin_repository.dart';
import '../../../vehicles/data/models/catalog_refs.dart';
import '../../../vehicles/presentation/widgets/vehicle_faults_section.dart';

// Ordre d'affichage et libellés des catégories de features
const _categoryLabels = <String, String>{
  'dotation':      'Dotation standard',
  'confort':       'Confort',
  'securite':      'Sécurité',
  'multimedia':    'Multimédia',
  'aide_conduite': 'Aides à la conduite',
  'autre':         'Autres',
};
const _categoryOrder = [
  'dotation', 'confort', 'securite', 'multimedia', 'aide_conduite', 'autre',
];

class VehicleDetailPage extends ConsumerWidget {
  final int vehicleId;

  /// Données passées depuis la liste (évite un aller-retour réseau pour l'affichage initial).
  final Vehicle? initialVehicle;

  const VehicleDetailPage({
    super.key,
    required this.vehicleId,
    this.initialVehicle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si on a les données de la liste, on les affiche immédiatement.
    // On lance quand même un fetch de détail en parallèle (pour avoir les médias complets, etc.)
    final detailAsync = ref.watch(vehicleDetailProvider(vehicleId));

    final vehicle = detailAsync.valueOrNull ?? initialVehicle;

    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text(e.toString())),
          data:    (_) => const SizedBox.shrink(),
        ),
      );
    }

    return _VehicleDetailView(vehicle: vehicle);
  }
}

class _VehicleDetailView extends ConsumerWidget {
  final Vehicle vehicle;
  const _VehicleDetailView({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id      = vehicle.identity;
    final c       = vehicle.commercial;
    final isStaff = ref.watch(authProvider).isStaff;
    final cs      = Theme.of(context).colorScheme;

    Future<void> deleteVehicle() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Supprimer ce véhicule ?'),
          content: Text('« ${id.fullName} » sera supprimé définitivement.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      try {
        await ref.read(vehicleAdminRepositoryProvider).deleteVehicle(vehicle.id);
        ref.invalidate(vehicleListProvider);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: cs.error),
          );
        }
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Photo hero ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            actions: isStaff
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Modifier',
                      onPressed: () => context
                          .push('/vehicles/${vehicle.id}/edit', extra: vehicle)
                          .then((_) => ref.invalidate(
                              vehicleDetailProvider(vehicle.id))),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: cs.error),
                      tooltip: 'Supprimer',
                      onPressed: deleteVehicle,
                    ),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                id.fullName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              background: vehicle.mediaUrls.isEmpty
                  ? Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.directions_car,
                        size: 80,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    )
                  : Image.network(vehicle.mediaUrls.first, fit: BoxFit.cover),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Prix ───────────────────────────────────────
                  _PriceSection(commercial: c),
                  const SizedBox(height: 20),

                  // ── Identité ────────────────────────────────────
                  _SectionTitle('Véhicule'),
                  _InfoGrid([
                    if (id.brand    != null) ('Marque',       id.brand),
                    if (id.model    != null) ('Modèle',       id.model),
                    if (id.year     != null) ('Année',        '${id.year}'),
                    if (id.trim     != null) ('Finition',     id.trim!),
                    if (id.engineType != null) ('Motorisation', id.engineType!),
                    if (id.drivetrain != null) ('Transmission', id.drivetrain!),
                    if (id.color    != null) ('Couleur',      id.color!),
                    ('Référence',  vehicle.reference),
                  ]),
                  const SizedBox(height: 20),

                  // ── État ────────────────────────────────────────
                  _SectionTitle('État'),
                  _InfoGrid([
                    ('Condition', _conditionLabel(c.condition)),
                    ('Statut',    c.status),
                    if (vehicle.faultsCount > 0)
                      ('Pannes déclarées', '${vehicle.faultsCount}'),
                  ]),
                  const SizedBox(height: 20),

                  // ── Import (si non immatriculé) ─────────────────
                  if (vehicle.isImported && vehicle.import_ != null) ...[
                    _SectionTitle('Import'),
                    _ImportSection(import_: vehicle.import_!),
                    const SizedBox(height: 20),
                  ],

                  // ── Localisation ────────────────────────────────
                  if (c.site != null) ...[
                    _SectionTitle('Localisation'),
                    _InfoRow('Agence', c.site!),
                    const SizedBox(height: 20),
                  ],

                  // ── Équipements & dotation ──────────────────────
                  if (vehicle.features.isNotEmpty) ...[
                    const Divider(height: 32),
                    _FeaturesSection(features: vehicle.features),
                  ],

                  // ── Partenaire source (staff seulement) ─────────
                  if (isStaff && c.partner != null) ...[
                    const Divider(height: 32),
                    _PartnerCard(partner: c.partner!),
                  ],

                  // ── Pannes (staff seulement) ────────────────────
                  if (isStaff) ...[
                    const Divider(height: 32),
                    VehicleFaultsSection(vehicleId: vehicle.id),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 80), // padding sous le bouton flottant
                ],
              ),
            ),
          ),
        ],
      ),

      // ── FAB staff : gérer les équipements ─────────────────────
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.checklist_outlined),
              label: const Text('Équipements'),
              onPressed: () => _manageFeatures(context, ref),
            )
          : null,

      // ── Barre d'action (clients uniquement) ───────────────────
      bottomNavigationBar: isStaff ? null : _ActionBar(commercial: c),
    );
  }

  Future<void> _manageFeatures(BuildContext context, WidgetRef ref) async {
    final refs = ref.read(catalogRefsProvider).valueOrNull;
    if (refs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données de référence non chargées, réessayez.')),
      );
      return;
    }

    final initialSelected = vehicle.features.map((f) => f.id).toSet();

    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FeaturePickerSheet(
        allFeatures: refs.features,
        initialSelected: initialSelected,
      ),
    );

    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(vehicleAdminRepositoryProvider)
          .syncVehicleFeatures(vehicle.id, result.toList());
      ref.invalidate(vehicleDetailProvider(vehicle.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Équipements mis à jour ✓')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _conditionLabel(String condition) => switch (condition) {
    'new'     => 'Neuf',
    'used'    => 'Occasion',
    'damaged' => 'Accidenté',
    _         => condition,
  };
}

// ── Section prix ───────────────────────────────────────────────────

class _PriceSection extends StatelessWidget {
  final VehicleCommercial commercial;
  const _PriceSection({required this.commercial});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (commercial.isForSale && commercial.salePrice != null) ...[
            Row(
              children: [
                const Icon(Icons.sell, size: 18),
                const SizedBox(width: 6),
                Text(
                  formatXof(commercial.salePrice),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                if (commercial.priceNegotiable) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Négociable', style: TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ],
          if (commercial.isForRent && commercial.rentalDailyRate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.key, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${formatXofShort(commercial.rentalDailyRate)} / jour',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.secondary,
                  ),
                ),
              ],
            ),
            if (commercial.rentalDeposit != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 24),
                child: Text(
                  'Caution : ${formatXof(commercial.rentalDeposit)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Section import ─────────────────────────────────────────────────

class _ImportSection extends StatelessWidget {
  final VehicleImport import_;
  const _ImportSection({required this.import_});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (import_.originCountry != null)
          _InfoRow('Origine', import_.originCountry!),
        if (import_.portOfEntry != null)
          _InfoRow('Port d\'entrée', import_.portOfEntry!),
        if (import_.odometerAtImportKm != null)
          _InfoRow('Kilométrage import', '${import_.odometerAtImportKm} km'),
        _InfoRow(
          'Dédouané',
          import_.customsCleared ? '✓ Oui' : '⏳ En attente',
        ),
        if (import_.isRightHandDrive)
          _InfoRow('Conduite', 'Droite (RHD)'),
      ],
    );
  }
}

// ── Barre d'actions ────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final VehicleCommercial commercial;
  const _ActionBar({required this.commercial});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            // Bouton secondaire : contact
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon:  const Icon(Icons.phone),
                label: const Text('Contacter'),
              ),
            ),
            const SizedBox(width: 12),

            // Bouton principal : acheter ou louer
            if (commercial.isForSale)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon:  const Icon(Icons.handshake),
                  label: const Text('Acheter'),
                ),
              )
            else if (commercial.isForRent)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon:  const Icon(Icons.key),
                  label: const Text('Réserver'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Picker équipements (bottom sheet staff) ────────────────────────

class _FeaturePickerSheet extends StatefulWidget {
  final List<FeatureRef> allFeatures;
  final Set<int> initialSelected;
  const _FeaturePickerSheet({
    required this.allFeatures,
    required this.initialSelected,
  });

  @override
  State<_FeaturePickerSheet> createState() => _FeaturePickerSheetState();
}

class _FeaturePickerSheetState extends State<_FeaturePickerSheet> {
  late final Set<int> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Regrouper par catégorie dans l'ordre défini
    final grouped = <String, List<FeatureRef>>{};
    for (final f in widget.allFeatures) {
      final cat = f.category ?? 'autre';
      grouped.putIfAbsent(cat, () => []).add(f);
    }
    final orderedKeys = [
      ..._categoryOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !_categoryOrder.contains(k)),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // ── Poignée + titre ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.checklist_outlined),
                    const SizedBox(width: 10),
                    Text('Équipements du véhicule',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    _saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : FilledButton(
                            onPressed: () => Navigator.pop(context, _selected),
                            child: const Text('Enregistrer'),
                          ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Liste avec cases à cocher ──────────────────────────
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              children: [
                for (final cat in orderedKeys) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      _categoryLabels[cat] ?? cat,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cat == 'dotation'
                            ? Colors.amber.shade700
                            : cs.primary,
                      ),
                    ),
                  ),
                  for (final f in grouped[cat]!)
                    CheckboxListTile(
                      dense: true,
                      value: _selected.contains(f.id),
                      title: Text(f.name),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) => setState(() {
                        if (v == true) _selected.add(f.id);
                        else           _selected.remove(f.id);
                      }),
                    ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section équipements ────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final List<VehicleFeature> features;
  const _FeaturesSection({required this.features});

  @override
  Widget build(BuildContext context) {
    // Regrouper par catégorie dans l'ordre défini
    final grouped = <String, List<VehicleFeature>>{};
    for (final f in features) {
      grouped.putIfAbsent(f.category, () => []).add(f);
    }

    // Catégories présentes, triées selon _categoryOrder (extras à la fin)
    final orderedKeys = [
      ..._categoryOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !_categoryOrder.contains(k)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cat in orderedKeys) ...[
          const SizedBox(height: 16),
          _SectionTitle(_categoryLabels[cat] ?? cat),
          if (cat == 'dotation')
            _DotationGrid(items: grouped[cat]!)
          else
            _FeatureChips(items: grouped[cat]!),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Dotation (triangle, cric…) : grille avec icône de présence bien visible.
class _DotationGrid extends StatelessWidget {
  final List<VehicleFeature> items;
  const _DotationGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.12),
            border: Border.all(color: Colors.amber.shade400, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 15, color: Colors.amber.shade700),
              const SizedBox(width: 5),
              Text(
                f.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Autres catégories (confort, sécurité…) : chips simples.
class _FeatureChips extends StatelessWidget {
  final List<VehicleFeature> items;
  const _FeatureChips({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items.map((f) => Chip(
        label: Text(f.name, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        backgroundColor: cs.surfaceContainerHighest,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      )).toList(),
    );
  }
}

// ── Carte partenaire source (staff) ───────────────────────────────

class _PartnerCard extends StatelessWidget {
  final VehiclePartner partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Partenaire source',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: cs.secondaryContainer,
              child: Text(
                partner.companyName[0].toUpperCase(),
                style: TextStyle(color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(partner.companyName),
            subtitle: partner.contactName != null
                ? Text(partner.contactName!)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // WhatsApp
                IconButton(
                  icon: const Icon(Icons.chat_outlined, size: 20),
                  color: const Color(0xFF25D366),
                  tooltip: 'WhatsApp',
                  onPressed: () {
                    final n = (partner.whatsapp ?? partner.phone)
                        .replaceAll(RegExp(r'[^\d+]'), '');
                    launchUrl(Uri.parse('https://wa.me/$n'));
                  },
                ),
                // Appel
                IconButton(
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  color: cs.primary,
                  tooltip: 'Appeler',
                  onPressed: () =>
                      launchUrl(Uri.parse('tel:${partner.phone}')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers UI ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

class _InfoGrid extends StatelessWidget {
  final List<(String, String?)> items;
  const _InfoGrid(this.items);

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((e) => e.$2 != null).toList();
    return Column(
      children: filtered.map((e) => _InfoRow(e.$1, e.$2!)).toList(),
    );
  }
}
