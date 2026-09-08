import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/vehicle.dart';
import '../providers/catalog_providers.dart';
import '../../../../core/utils/contact_info.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../vehicles/data/vehicle_admin_repository.dart';
import '../../../vehicles/data/models/catalog_refs.dart';
import '../../../vehicles/presentation/widgets/vehicle_faults_section.dart';

// Séparateur de milliers à la française : « 246 965 km » plutôt que « 246965 ».
final _integer = NumberFormat.decimalPattern('fr_FR');
final _decimal = NumberFormat('#,##0.0', 'fr_FR');

// Ordre d'affichage et libellés des catégories de features
const _categoryLabels = <String, String>{
  'dotation':      'Dotation standard',
  'confort':       'Confort',
  'securite':      'Sécurité',
  'multimedia':    'Multimédia',
  'aide_conduite': 'Aides à la conduite',
  'autre':         'Autres',
};
// La dotation ferme la marche : cric, gilet, carnet d'entretien sont présents
// sur tout le parc et ne départagent aucun véhicule. Les équipements qui font
// choisir un acheteur passent devant.
const _categoryOrder = [
  'confort', 'securite', 'multimedia', 'aide_conduite', 'autre', 'dotation',
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
                      alignment: Alignment.center,
                      child: BrandLogo(slug: id.brandSlug, size: 96),
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
                    if (vehicle.combinedL100km != null)
                      ('Consommation', '${_decimal.format(vehicle.combinedL100km)} L/100 km'),
                  ]),
                  if (id.color != null)
                    _ColorRow(
                      name: id.color!,
                      hex: id.colorHex,
                      finish: id.colorFinish,
                    ),
                  _InfoGrid([('Référence', vehicle.reference)]),
                  const SizedBox(height: 20),

                  // ── État ────────────────────────────────────────
                  _SectionTitle('État'),
                  _InfoGrid([
                    ('Condition', _conditionLabel(c.condition)),
                    // Le kilométrage décrit l'usure : sa place est ici, aux
                    // côtés de la condition, plutôt que dans l'identité.
                    if (vehicle.mileageKm != null)
                      ('Kilométrage', '${_integer.format(vehicle.mileageKm)} km'),
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
      bottomNavigationBar: isStaff ? null : const _ActionBar(),
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
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        // Les deux actions ouvrent le même numéro commercial, par appel ou par
        // WhatsApp. Elles remplacent des boutons dont le `onPressed` était vide.
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:$kContactPhone')),
                icon:  const Icon(Icons.phone),
                label: const Text('Appeler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://wa.me/$kContactWhatsApp'),
                  mode: LaunchMode.externalApplication,
                ),
                icon:  const Icon(Icons.chat),
                label: const Text('WhatsApp'),
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

    // Tri alphabétique dans chaque catégorie : l'ordre naturel suivait les
    // identifiants en base, donc rien de repérable à l'œil.
    for (final list in grouped.values) {
      list.sort((a, b) => _sortKey(a.name).compareTo(_sortKey(b.name)));
    }

    // Catégories présentes, triées selon _categoryOrder (extras à la fin)
    final orderedKeys = [
      ..._categoryOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !_categoryOrder.contains(k)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Équipements'),
        for (final cat in orderedKeys) ...[
          const SizedBox(height: 14),
          _FeatureCategoryLabel(_categoryLabels[cat] ?? cat),
          // La dotation est une information de conformité, pas un argument de
          // vente : contour discret plutôt que pastille pleine.
          _FeaturePills(items: grouped[cat]!, outlined: cat == 'dotation'),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Clé de tri insensible aux accents.
///
/// `compareTo` compare des unités UTF-16 : « â » (U+00E2) y passe après « r »,
/// si bien que « Câbles de démarrage » se rangeait derrière « Cric ».
String _sortKey(String s) {
  const accents = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿœæ';
  const plain   = 'aaaaaceeeeiiiinooooouuuuyyoa';

  final out = StringBuffer();
  for (final char in s.toLowerCase().split('')) {
    final i = accents.indexOf(char);
    out.write(i == -1 ? char : plain[i]);
  }

  return out.toString();
}

/// Intitulé de sous-catégorie. Volontairement subordonné aux `_SectionTitle`
/// (« Véhicule », « Import »…) : « Confort » est une sous-partie du bloc
/// équipements, pas une section de même rang.
class _FeatureCategoryLabel extends StatelessWidget {
  final String text;
  const _FeatureCategoryLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      // Meme correction que les libelles de `_InfoRow` : ce sont des textes,
      // pas des bordures.
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    ),
  );
}

/// Pastilles d'équipement.
///
/// Plates et sans relief à dessein : elles ne sont pas cliquables, alors que
/// les `Chip` employées auparavant étaient quasi identiques aux `FilterChip`
/// de la page de recherche, qui le sont — on tapait dessus sans effet.
///
/// Aucune coche non plus : tout ce qui figure ici est présent, rien d'absent
/// n'est affiché, donc une icône de validation par ligne ne dirait rien et
/// suggérerait à tort qu'il existe des cases décochées.
class _FeaturePills extends StatelessWidget {
  final List<VehicleFeature> items;

  /// Contour seul au lieu d'un fond plein — réservé à la dotation.
  final bool outlined;

  const _FeaturePills({required this.items, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Le gris `surfaceContainerHighest` ne tenait pas sur ce fond quasi blanc :
    // 1,23:1 mesuré, soit une pastille invisible, alors que sa forme porte une
    // information — c'est elle qui sépare « Freins à disques avant » de
    // « Freins à disques 4 roues ». C'est la bordure qui assure désormais la
    // délimitation (3,23:1, au-dessus du seuil WCAG 1.4.11 de 3:1) ; le fond
    // reste discret pour que 26 étiquettes ne pèsent pas plus que le prix.
    final tint = cs.primary;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((f) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          // La dotation garde son statut de second rang par l'absence de fond,
          // pas par une bordure plus pâle qui la rendrait illisible.
          color: outlined ? null : tint.withValues(alpha: 0.12),
          border: Border.all(color: tint.withValues(alpha: 0.70)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          f.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: outlined ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
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
            // `outline` est un role de bordure : a 4,27:1 mesure, ces libelles
            // passaient sous le seuil AA de 4,5:1 pour du texte de 12sp.
            // `onSurfaceVariant` est le role prevu pour du texte secondaire.
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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

/// Ligne « Couleur », avec une pastille de la teinte réelle.
///
/// Le nom seul ne renseigne pas : « Bordeaux », « Gris titanium » ou
/// « Blanc nacré » ne se visualisent pas. La teinte vient de `colors.hex_code`
/// en base — jamais d'une correspondance devinée à partir du libellé, qui
/// serait fausse dès la première nuance inhabituelle.
class _ColorRow extends StatelessWidget {
  final String name;
  final String? hex;
  final String? finish;

  const _ColorRow({required this.name, this.hex, this.finish});

  Color? get _swatch {
    final raw = hex?.replaceFirst('#', '');
    if (raw == null || raw.length != 6) return null;
    final value = int.tryParse(raw, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  String get _label => switch (finish) {
    'metallise' => '$name (métallisé)',
    'nacre'     => '$name (nacré)',
    _           => name,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final swatch = _swatch;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              'Couleur',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (swatch != null) ...[
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: swatch,
                      borderRadius: BorderRadius.circular(3),
                      // Sans cette bordure, « Blanc » (#FFFFFF) serait
                      // invisible sur le fond quasi blanc de la page.
                      border: Border.all(color: cs.outline),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
