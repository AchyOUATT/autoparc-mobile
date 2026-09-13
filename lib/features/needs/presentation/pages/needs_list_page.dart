import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_need.dart';
import '../../data/needs_repository.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/api/api_exception.dart';

// ── Providers ─────────────────────────────────────────────────────────

final _needsFilterProvider = StateProvider<({String? type, String? status})>(
  (_) => (type: null, status: 'pending'),
);

final _needsProvider = FutureProvider.autoDispose<List<CustomerNeed>>((ref) {
  final filter = ref.watch(_needsFilterProvider);
  return ref.read(needsRepositoryProvider).getNeeds(
    type:   filter.type,
    status: filter.status,
  );
});

// ════════════════════════════════════════════════════════════════════

class NeedsListPage extends ConsumerWidget {
  const NeedsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAsync = ref.watch(_needsProvider);
    final filter     = ref.watch(_needsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Besoins clients'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_needsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(filter: filter),
          Expanded(
            child: needsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 48),
                    const SizedBox(height: 12),
                    Text(messageFor(e), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(_needsProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (needs) => needs.isEmpty
                  ? _EmptyView(status: filter.status)
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: needs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => _NeedCard(
                        need: needs[i],
                        onUpdated: () => ref.invalidate(_needsProvider),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barre de filtres ──────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  final ({String? type, String? status}) filter;
  const _FilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void setStatus(String? v) {
      final cur = ref.read(_needsFilterProvider);
      ref.read(_needsFilterProvider.notifier).state = (type: cur.type, status: v);
    }

    void setType(String? v) {
      final cur = ref.read(_needsFilterProvider);
      ref.read(_needsFilterProvider.notifier).state = (type: v, status: cur.status);
    }

    const statuses = [
      (value: 'pending',   label: 'En attente'),
      (value: 'contacted', label: 'Contacté'),
      (value: 'fulfilled', label: 'Satisfait'),
      (value: 'cancelled', label: 'Annulé'),
    ];

    const types = [
      (value: 'vehicle',   label: 'Véhicule'),
      (value: 'part',      label: 'Pièce'),
      (value: 'accessory', label: 'Accessoire'),
    ];

    return Column(
      children: [
        // Statut
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: filter.status == null,
                onSelected: (_) => setStatus(null),
              ),
              const SizedBox(width: 6),
              ...statuses.map((s) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(s.label),
                  selected: filter.status == s.value,
                  onSelected: (_) =>
                      setStatus(filter.status == s.value ? null : s.value),
                ),
              )),
            ],
          ),
        ),
        // Type
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              FilterChip(
                label: const Text('Tous types'),
                selected: filter.type == null,
                onSelected: (_) => setType(null),
              ),
              const SizedBox(width: 6),
              ...types.map((t) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(t.label),
                  selected: filter.type == t.value,
                  onSelected: (_) =>
                      setType(filter.type == t.value ? null : t.value),
                ),
              )),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

// ── Carte d'un besoin ─────────────────────────────────────────────────

class _NeedCard extends StatelessWidget {
  final CustomerNeed need;
  final VoidCallback onUpdated;
  const _NeedCard({required this.need, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(need.statusColor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──────────────────────────────────────────────
            Row(
              children: [
                // Badge type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    need.typeLabel,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(120)),
                  ),
                  child: Text(
                    need.statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                ),
                const Spacer(),
                if (need.createdAt != null)
                  Text(
                    _formatDate(need.createdAt!),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Description ──────────────────────────────────────────
            Text(need.description),

            // ── Budget ───────────────────────────────────────────────
            if (need.budgetMax != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  'Budget max : ${formatXof(need.budgetMax!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 8),

            // ── Contact ───────────────────────────────────────────────
            if (need.contactName != null || need.contactPhone != null ||
                need.contactEmail != null) ...[
              const Divider(height: 16),
              if (need.contactName != null)
                _ContactRow(Icons.person_outline, need.contactName!),
              if (need.contactPhone != null)
                _ContactRow(Icons.phone_outlined, need.contactPhone!),
              if (need.contactEmail != null)
                _ContactRow(Icons.email_outlined, need.contactEmail!),
            ] else ...[
              const Divider(height: 16),
              Text(
                'Aucun contact renseigné',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],

            // ── Notes staff ───────────────────────────────────────────
            if (need.staffNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '📝 ${need.staffNotes!}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Bouton mise à jour statut ─────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _showUpdateSheet(context),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UpdateStatusSheet(need: need, onUpdated: onUpdated),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return "Aujourd'hui ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

// ── Sheet mise à jour statut ──────────────────────────────────────────

class _UpdateStatusSheet extends ConsumerStatefulWidget {
  final CustomerNeed need;
  final VoidCallback onUpdated;
  const _UpdateStatusSheet({required this.need, required this.onUpdated});

  @override
  ConsumerState<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<_UpdateStatusSheet> {
  late String _status;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.need.status;
    _notesCtrl.text = widget.need.staffNotes ?? '';
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(needsRepositoryProvider).updateStatus(
        widget.need.id,
        status:     _status,
        staffNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      widget.onUpdated();
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
    const statuses = [
      (value: 'pending',   label: 'En attente',  color: 0xFFFFA000),
      (value: 'contacted', label: 'Contacté',    color: 0xFF1565C0),
      (value: 'fulfilled', label: 'Satisfait',   color: 0xFF2E7D32),
      (value: 'cancelled', label: 'Annulé',      color: 0xFF757575),
    ];

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
          Text('Mettre à jour le statut',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Sélecteur de statut
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses.map((s) {
              final selected = _status == s.value;
              final col = Color(s.color);
              return ChoiceChip(
                label: Text(s.label),
                selected: selected,
                selectedColor: col.withAlpha(50),
                side: selected ? BorderSide(color: col) : null,
                labelStyle: selected
                    ? TextStyle(color: col, fontWeight: FontWeight.bold)
                    : null,
                onSelected: (_) => setState(() => _status = s.value),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes internes (optionnel)',
              border: OutlineInputBorder(),
              hintText: 'Ex. : Client rappelé le 02/09, devis envoyé…',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

// ── Vue vide ──────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String? status;
  const _EmptyView({this.status});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 64,
            color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(
          status == 'pending'
              ? 'Aucun besoin en attente'
              : 'Aucun besoin trouvé',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text('Les besoins soumis par les clients\napparaîtront ici.',
            textAlign: TextAlign.center),
      ],
    ),
  );
}
