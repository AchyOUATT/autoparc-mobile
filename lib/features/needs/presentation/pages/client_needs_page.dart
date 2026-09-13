import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/customer_need.dart';
import '../../data/needs_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/api/api_exception.dart';

// ── Provider ──────────────────────────────────────────────────────

final _myNeedsProvider =
    FutureProvider.autoDispose<List<CustomerNeed>>((ref) {
  final uid = ref.watch(authProvider).firebaseUser?.uid;
  if (uid == null) return Future.value([]);
  return ref.read(needsRepositoryProvider).getMyNeeds(uid);
});

// ════════════════════════════════════════════════════════════════════

class ClientNeedsPage extends ConsumerWidget {
  const ClientNeedsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAsync = ref.watch(_myNeedsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes besoins'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_myNeedsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/needs/new').then(
          (_) => ref.invalidate(_myNeedsProvider),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau besoin'),
      ),
      body: needsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 12),
              Text(messageFor(e), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(_myNeedsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (needs) => needs.isEmpty
            ? _EmptyView(onAdd: () => context.push('/needs/new').then(
                (_) => ref.invalidate(_myNeedsProvider),
              ))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                itemCount: needs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _NeedCard(need: needs[i]),
              ),
      ),
    );
  }
}

// ── Carte d'un besoin (vue client — lecture seule) ────────────────

class _NeedCard extends StatelessWidget {
  final CustomerNeed need;
  const _NeedCard({required this.need});

  @override
  Widget build(BuildContext context) {
    final cs          = Theme.of(context).colorScheme;
    final statusColor = Color(need.statusColor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── En-tête : statut + date ─────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(120)),
                  ),
                  child: Text(
                    need.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (need.createdAt != null)
                  Text(
                    _formatDate(need.createdAt!),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Description ─────────────────────────────────────────
            Text(
              need.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // ── Critères structurés ─────────────────────────────────
            if (need.brandName != null || need.vehicleModelName != null ||
                need.bodyStyle != null || need.yearMin != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (need.brandName != null)
                    _Chip(need.brandName!),
                  if (need.vehicleModelName != null)
                    _Chip(need.vehicleModelName!),
                  if (need.bodyStyle != null)
                    _Chip(_bodyLabel(need.bodyStyle!)),
                  if (need.yearMin != null && need.yearMax != null)
                    _Chip('${need.yearMin} – ${need.yearMax}'),
                  if (need.yearMin != null && need.yearMax == null)
                    _Chip('À partir de ${need.yearMin}'),
                ],
              ),
            ],

            // ── Budget ──────────────────────────────────────────────
            if (need.budgetMax != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  'Budget : ${formatXof(need.budgetMax!)}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ]),
            ],

            // ── Réponse de l'équipe (staff_notes) ───────────────────
            if (need.staffNotes != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.primary.withAlpha(60)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.support_agent_outlined,
                        size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        need.staffNotes!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7)  return 'Il y a ${diff.inDays} jours';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  }

  String _bodyLabel(String v) => const {
    'sedan': 'Berline', 'hatchback': 'Compacte', 'suv': 'SUV',
    'estate': 'Break', 'coupe': 'Coupé', 'convertible': 'Cabriolet',
    'pickup': 'Pick-up', 'van': 'Camionnette', 'minibus': 'Minibus',
    'bus': 'Bus', 'truck': 'Camion',
  }[v] ?? v;
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
  );
}

// ── Vue vide ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('Aucun besoin déposé',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Exprimez votre recherche — nous vous\n'
            'contacterons dès qu\'une offre correspond.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Exprimer un besoin'),
          ),
        ],
      ),
    ),
  );
}
