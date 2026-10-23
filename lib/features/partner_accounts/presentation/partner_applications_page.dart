import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class PartnerApplicationsPageData {
  const PartnerApplicationsPageData({required this.accounts, required this.page, required this.lastPage, required this.total});
  final List<Map<String, dynamic>> accounts;
  final int page;
  final int lastPage;
  final int total;
}

typedef PartnerApplicationsQuery = ({String status, int page});

final partnerApplicationsProvider = FutureProvider.autoDispose
    .family<PartnerApplicationsPageData, PartnerApplicationsQuery>((ref, query) async {
      final response = await ref.read(apiClientProvider).get(
        '/partner-applications',
        params: {'status': query.status, 'page': query.page, 'per_page': 25},
      );
      final accounts = (response['data'] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
      final meta = response['meta'] as Map? ?? const {};
      return PartnerApplicationsPageData(accounts: accounts,
        page: (meta['current_page'] as num?)?.toInt() ?? query.page,
        lastPage: (meta['last_page'] as num?)?.toInt() ?? query.page,
        total: (meta['total'] as num?)?.toInt() ?? accounts.length);
    });

class PartnerApplicationsPage extends ConsumerStatefulWidget {
  const PartnerApplicationsPage({super.key});

  @override
  ConsumerState<PartnerApplicationsPage> createState() =>
      _PartnerApplicationsPageState();
}

class _PartnerApplicationsPageState
    extends ConsumerState<PartnerApplicationsPage> {
  String _status = 'pending';
  int _page = 1;
  int? _reviewing;

  PartnerApplicationsQuery get _query => (status: _status, page: _page);

  Future<void> _refresh() async {
    final provider = partnerApplicationsProvider(_query);
    ref.invalidate(provider);
    try { await ref.read(provider.future); } catch (_) { /* Provider displays the error and retry action. */ }
  }

  static const _labels = {
    'pending': 'En attente',
    'approved': 'Approuvés',
    'rejected': 'Refusés',
    'suspended': 'Suspendus',
  };

  Future<void> _review(Map<String, dynamic> account, String action) async {
    if (!ref.read(authProvider).canManagePartners || _reviewing != null) return;
    String? reason;
    if (action != 'approve') {
      var draft = '';
      final form = GlobalKey<FormState>();
      reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(action == 'reject' ? 'Refuser la demande' : 'Suspendre le compte'),
          content: Form(
            key: form,
            child: TextFormField(
              onChanged: (value) => draft = value,
              maxLength: 2000,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Motif communiqué au partenaire'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Précisez le motif de cette décision.'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(dialogContext, draft.trim());
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
      if (reason == null || !mounted) return;
    }

    if (!ref.read(authProvider).canManagePartners) return;

    setState(() => _reviewing = account['id'] as int);
    try {
      await ref.read(apiClientProvider).post(
        '/partner-applications/${account['id']}/$action',
        data: {if (reason != null) 'review_reason': reason},
      );
      if (!mounted) return;
      ref.invalidate(partnerApplicationsProvider);
      if (mounted) {
        setState(() => _page = 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Décision enregistrée.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageFor(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _reviewing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Validation des partenaires')),
      body: auth.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !auth.canManagePartners
          ? const Center(child: Text('Accès réservé aux responsables.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Demandes'),
                    items: _labels.entries.map((entry) => DropdownMenuItem(
                      value: entry.key, child: Text(entry.value),
                    )).toList(),
                    onChanged: _reviewing != null ? null : (value) {
                      if (value != null) setState(() { _status = value; _page = 1; });
                    },
                  ),
                ),
                Expanded(
                  child: ref.watch(partnerApplicationsProvider(_query)).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(messageFor(error)),
                        TextButton(
                          onPressed: _refresh,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    )),
                    data: (result) => Column(children: [
                      Expanded(child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            if (result.accounts.isEmpty) const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Center(child: Text('Aucune demande dans cette catégorie.')),
                            ),
                            for (final account in result.accounts) _card(account),
                          ],
                        ),
                      )),
                      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Column(children: [
                        Text('Page ${result.page} / ${result.lastPage} · ${result.total} demande(s)'),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          TextButton.icon(key: const Key('partner-applications-previous'),
                            onPressed: result.page > 1 && _reviewing == null ? () => setState(() => _page = result.page - 1) : null,
                            icon: const Icon(Icons.chevron_left), label: const Text('Précédent')),
                          TextButton.icon(key: const Key('partner-applications-next'),
                            onPressed: result.page < result.lastPage && _reviewing == null ? () => setState(() => _page = result.page + 1) : null,
                            icon: const Icon(Icons.chevron_right), label: const Text('Suivant')),
                        ]),
                      ])),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card(Map<String, dynamic> account) {
    final user = account['user'] as Map<String, dynamic>?;
    final busy = _reviewing != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(account['company_name'] as String, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(account['contact_name'] as String),
          Text(account['phone'] as String),
          if (user?['email'] != null) Text(user!['email'] as String),
          if (account['review_reason'] != null) ...[
            const SizedBox(height: 8),
            Text('Motif : ${account['review_reason']}'),
          ],
          const SizedBox(height: 12),
          if (_reviewing == account['id']) const LinearProgressIndicator(),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (_status != 'approved') FilledButton.icon(
              onPressed: busy ? null : () => _review(account, 'approve'),
              icon: const Icon(Icons.check),
              label: Text(_status == 'suspended' ? 'Réactiver' : 'Approuver'),
            ),
            if (_status == 'pending') OutlinedButton(
              onPressed: busy ? null : () => _review(account, 'reject'),
              child: const Text('Refuser'),
            ),
            if (_status == 'approved') OutlinedButton(
              onPressed: busy ? null : () => _review(account, 'suspend'),
              child: const Text('Suspendre'),
            ),
          ]),
        ]),
      ),
    );
  }
}
