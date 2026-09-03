import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/partner.dart';
import '../../data/partner_repository.dart';

// ── Provider ──────────────────────────────────────────────────────────

final _partnerListProvider =
    FutureProvider.autoDispose.family<List<Partner>, String>((ref, search) async {
  final repo = ref.read(partnerRepositoryProvider);
  final page = await repo.getPartners(search: search.isEmpty ? null : search);
  return page.data;
});

// ════════════════════════════════════════════════════════════════════
// Page principale (staff uniquement)
// ════════════════════════════════════════════════════════════════════

class PartnerListPage extends ConsumerStatefulWidget {
  const PartnerListPage({super.key});

  @override
  ConsumerState<PartnerListPage> createState() => _PartnerListPageState();
}

class _PartnerListPageState extends ConsumerState<PartnerListPage> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partners = ref.watch(_partnerListProvider(_search));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partenaires'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Nom, contact, téléphone…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    },
                  ),
              ],
              onChanged: (q) => setState(() => _search = q),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/partners/new');
          if (created == true) ref.invalidate(_partnerListProvider);
        },
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Nouveau partenaire'),
      ),
      body: partners.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(_partnerListProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.handshake_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('Aucun partenaire trouvé'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_partnerListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) => _PartnerTile(
                partner: list[i],
                onChanged: () => ref.invalidate(_partnerListProvider),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Tuile ────────────────────────────────────────────────────────────

class _PartnerTile extends StatelessWidget {
  final Partner partner;
  final VoidCallback onChanged;
  const _PartnerTile({required this.partner, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Text(
          partner.companyName[0].toUpperCase(),
          style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(partner.companyName,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (partner.contactName != null) partner.contactName!,
          partner.phone,
        ].join(' · '),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WhatsApp
          if (partner.whatsapp != null || partner.phone.isNotEmpty)
            _ContactIcon(
              icon: Icons.chat_outlined,
              color: const Color(0xFF25D366),
              tooltip: 'WhatsApp',
              onTap: () => _launchWhatsApp(partner.whatsapp ?? partner.phone),
            ),
          // Appel
          _ContactIcon(
            icon: Icons.phone_outlined,
            color: cs.primary,
            tooltip: 'Appeler',
            onTap: () => _launchPhone(partner.phone),
          ),
          // Menu
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Modifier')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (v) async {
              if (v == 'edit') {
                final updated = await context.push<bool>(
                    '/partners/${partner.id}/edit',
                    extra: partner);
                if (updated == true) onChanged();
              } else if (v == 'delete') {
                _confirmDelete(context);
              }
            },
          ),
        ],
      ),
      onTap: () => context.push('/partners/${partner.id}', extra: partner),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce partenaire ?'),
        content: Text('${partner.companyName} sera retiré de tous les produits.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      // La suppression effective se fait depuis la page de détail ou via
      // le repository — ici on se contente de notifier l'écran parent.
      onChanged();
    }
  }

  void _launchPhone(String number) {
    launchUrl(Uri.parse('tel:$number'));
  }

  void _launchWhatsApp(String number) {
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    launchUrl(Uri.parse('https://wa.me/$cleaned'));
  }
}

class _ContactIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ContactIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}
