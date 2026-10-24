import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/partner_repository.dart';
import 'partner_listing_form.dart';
import 'partner_media_page.dart';
import 'partner_session.dart';

class PartnerListingsPage extends ConsumerStatefulWidget {
  const PartnerListingsPage({super.key, required this.kind});
  final PartnerListingKind kind;
  @override
  ConsumerState<PartnerListingsPage> createState() => _PartnerListingsPageState();
}

class _PartnerListingsPageState extends ConsumerState<PartnerListingsPage> {
  final _query = TextEditingController();
  PartnerListingPage? _page;
  String? _error;
  bool _loading = true;
  bool _working = false;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _query.dispose(); super.dispose(); }

  Future<void> _load({int page = 1}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ref.read(partnerRepositoryProvider).listListings(widget.kind, page: page, query: _query.text);
      if (mounted) setState(() { _page = result; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString(); _loading = false; });
      if (error is PartnerApiException && error.sessionRejected) {
        await ref.read(partnerSessionProvider.notifier).refresh();
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? listing]) async {
    try {
      final detail = listing == null ? null : await ref.read(partnerRepositoryProvider).listing(widget.kind, (listing['id'] as num).toInt());
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PartnerListingFormPage(kind: widget.kind, initialListing: detail)));
      if (saved == true && mounted) await _load();
    } catch (error) { _showError(error); }
  }

  void _showError(Object error) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _action(Map<String, dynamic> item, String action) async {
    if (_working) return;
    final id = (item['id'] as num).toInt();
    final repository = ref.read(partnerRepositoryProvider);
    if (action == 'edit') return _edit(item);
    if (action == 'photos') {
      await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => PartnerMediaPage(kind: widget.kind, listingId: id, title: _title(item))));
      if (mounted) await _load(page: _page?.page ?? 1);
      return;
    }
    if (action == 'archive') {
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Archiver cette annonce ?'), content: const Text('Elle sera retirée de votre inventaire et du catalogue public.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archiver'))],
      ));
      if (confirmed != true) return;
    }
    int? quantity;
    if (action == 'stock') {
      quantity = await _stockDialog(item);
      if (quantity == null) return;
    }
    if (!mounted) return;
    setState(() => _working = true);
    try {
      switch(action) {
        case 'publish': await repository.publish(widget.kind, id, true);
        case 'unpublish': await repository.publish(widget.kind, id, false);
        case 'archive': await repository.archive(widget.kind, id);
        case 'availability': await repository.toggleAvailability(widget.kind, id);
        case 'stock': await repository.setStock(widget.kind, id, quantity!);
      }
      if (mounted) await _load(page: _page?.page ?? 1);
    } catch (error) {
      _showError(error);
      if (error is PartnerApiException && error.sessionRejected) {
        await ref.read(partnerSessionProvider.notifier).refresh();
        if (mounted) Navigator.of(context).pop();
      }
    } finally { if (mounted) setState(() => _working = false); }
  }

  Future<int?> _stockDialog(Map<String, dynamic> item) async {
    final form = GlobalKey<FormState>();
    final input = TextEditingController(text: (item['stock'] as Map?)?['quantity']?.toString() ?? '0');
    final value = await showDialog<int>(context: context, builder: (context) => AlertDialog(
      title: const Text('Ajuster le stock'),
      content: Form(key: form, child: TextFormField(controller: input, autofocus: true, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Quantité disponible'), validator: (value) {
          final quantity = int.tryParse(value ?? '');
          return quantity == null || quantity < 0 || quantity > 2147483647 ? 'Indiquez une quantité valide.' : null;
        })),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(context, int.parse(input.text)); }, child: const Text('Enregistrer'))],
    ));
    input.dispose();
    return value;
  }

  String _title(Map<String, dynamic> item) => item['designation']?.toString() ?? item['name']?.toString() ?? 'Annonce';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Mes ${widget.kind.label.toLowerCase()}'), actions: [
      IconButton(tooltip: 'Actualiser', onPressed: _loading ? null : () => _load(page: _page?.page ?? 1), icon: const Icon(Icons.refresh)),
    ]),
    floatingActionButton: FloatingActionButton.extended(onPressed: _working ? null : () => _edit(), icon: const Icon(Icons.add), label: const Text('Créer une annonce')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _query, onSubmitted: (_) => _load(),
        decoration: InputDecoration(hintText: 'Rechercher dans mes annonces', prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder(),
          suffixIcon: IconButton(tooltip: 'Rechercher', onPressed: () => _load(), icon: const Icon(Icons.arrow_forward))))),
      if (_loading || _working) const LinearProgressIndicator(),
      Expanded(child: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), children: [
        if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          TextButton(onPressed: _load, child: const Text('Réessayer')),
        ]))),
        if (!_loading && _error == null && (_page?.items.isEmpty ?? true)) Padding(padding: const EdgeInsets.symmetric(vertical: 48), child: Column(children: [
          const Icon(Icons.inventory_2_outlined, size: 56), const SizedBox(height: 16),
          Text(_query.text.trim().isEmpty ? 'Votre inventaire commence ici' : 'Aucune annonce correspondante', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12), const Text('Créez votre annonce, ajoutez ses photos puis choisissez de la publier.', textAlign: TextAlign.center),
          const SizedBox(height: 20), FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Créer ma première annonce')),
        ])),
        for (final item in _page?.items ?? <Map<String, dynamic>>[]) _card(item),
        if ((_page?.lastPage ?? 1) > 1) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(tooltip: 'Page précédente', onPressed: !_loading && _page!.page > 1 ? () => _load(page: _page!.page - 1) : null, icon: const Icon(Icons.chevron_left)),
          Text('${_page!.page} / ${_page!.lastPage}'),
          IconButton(tooltip: 'Page suivante', onPressed: !_loading && _page!.page < _page!.lastPage ? () => _load(page: _page!.page + 1) : null, icon: const Icon(Icons.chevron_right)),
        ]),
      ]))),
    ]),
  );

  Widget _card(Map<String, dynamic> item) {
    final published = item['partner_published_at'] != null;
    final commercial = item['commercial'] as Map? ?? item['pricing'] as Map? ?? const {};
    final stock = item['stock'] as Map?;
    final price = commercial['sale_price'] ?? commercial['selling_price'];
    final media = partnerMaps(item['media']);
    final cover = media.isEmpty ? null : media.firstWhere((photo) => photo['is_cover'] == true, orElse: () => media.first)['url']?.toString();
    return Card(clipBehavior: Clip.antiAlias, margin: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ListTile(contentPadding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
        leading: cover == null ? const Icon(Icons.photo_outlined, size: 36) : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(cover, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined))),
        title: Text(_title(item), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text([if (price != null) '$price ${commercial['currency'] ?? 'FCFA'}',
          if (stock != null) 'Stock : ${stock['quantity'] ?? '—'}',
          if (commercial['availability'] == 'rent' || commercial['availability'] == 'both') 'Location : ${commercial['rental_daily_rate'] != null ? '${commercial['rental_daily_rate']} / jour' : '${commercial['rental_monthly_rate']} / mois'}'].join('\n')),
        trailing: PopupMenuButton<String>(enabled: !_working, tooltip: 'Gérer cette annonce', onSelected: (action) => _action(item, action), itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
          const PopupMenuItem(value: 'photos', child: Text('Gérer les photos')),
          if (widget.kind != PartnerListingKind.vehicles) ...[
            const PopupMenuItem(value: 'stock', child: Text('Ajuster le stock')),
            PopupMenuItem(value: 'availability', child: Text(stock?['is_available'] == false ? 'Rendre disponible' : 'Marquer indisponible')),
          ],
          const PopupMenuItem(value: 'archive', child: Text('Archiver')),
        ]),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Row(children: [
        Chip(avatar: Icon(published ? Icons.visibility_outlined : Icons.edit_note_outlined, size: 16), label: Text(published ? 'Publiée' : 'Brouillon')),
        const Spacer(),
        TextButton.icon(onPressed: _working ? null : () => _action(item, published ? 'unpublish' : 'publish'),
          icon: Icon(published ? Icons.visibility_off_outlined : Icons.publish_outlined), label: Text(published ? 'Retirer' : 'Publier')),
      ])),
    ]));
  }
}
