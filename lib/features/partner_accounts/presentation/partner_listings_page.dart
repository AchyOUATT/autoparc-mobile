import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../data/lecture_json.dart' as json;
import '../data/partner_repository.dart';
import '../../catalog/data/models/vehicle.dart';
import '../../vehicles/presentation/pages/vehicle_form_mode.dart';
import '../../vehicles/presentation/pages/vehicle_register_page.dart';
import 'marge_recapitulatif.dart';
import 'partner_listing_form.dart';
import 'partner_media_page.dart';
import 'partner_session.dart';
import 'partner_localizations.dart';

class PartnerListingsPage extends ConsumerStatefulWidget {
  const PartnerListingsPage({super.key, required this.kind});
  final PartnerListingKind kind;
  @override
  ConsumerState<PartnerListingsPage> createState() =>
      _PartnerListingsPageState();
}

class _PartnerListingsPageState extends ConsumerState<PartnerListingsPage> {
  final _query = TextEditingController();
  PartnerListingPage? _page;
  Object? _error;
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(partnerRepositoryProvider)
          .listListings(widget.kind, page: page, query: _query.text);
      if (mounted)
        setState(() {
          _page = result;
          _loading = false;
        });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
      if (error is PartnerApiException && error.sessionRejected) {
        await ref.read(partnerSessionProvider.notifier).refresh();
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? listing]) async {
    final id = listing == null ? null : json.entier(listing['id']);
    if (listing != null && id == null) return _identifiantIllisible();

    try {
      final detail = id == null
          ? null
          : await ref.read(partnerRepositoryProvider).listing(widget.kind, id);
      if (!mounted) return;
      // ── UN VEHICULE PASSE PAR LE FORMULAIRE DU PERSONNEL ──────────────
      //
      // Le meme ecran, en mode partenaire. L'espace partenaire avait le sien,
      // de 441 lignes contre 1521, et neuf champs que le personnel
      // renseignait sans que le partenaire puisse meme les voir. L'ecart
      // n'etait pas une decision, c'etait une derive : deux ecrans ecrits
      // separement, que rien ne tenait synchronises.
      //
      // `VehicleFormMode.partenaire` retire les trois champs que le serveur
      // refuse — `deal_type`, `location_id`, `partner_id` — de la charge ET de
      // l'ecran. Voir ce mode pour le detail.
      //
      // Pieces et accessoires gardent `PartnerListingFormPage` : leur
      // formulaire du back-office n'est pas le meme ecran, et l'unifier est un
      // autre chantier.
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => widget.kind == PartnerListingKind.vehicles
              ? VehicleRegisterPage(
                  mode: VehicleFormMode.partenaire,
                  existing: detail == null ? null : Vehicle.fromJson(detail),
                )
              : PartnerListingFormPage(
                  kind: widget.kind,
                  initialListing: detail,
                ),
        ),
      );
      if (saved == true && mounted) await _load();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messageFor(error, l10n: AppLocalizations.of(context))),
        ),
      );
  }

  /// Quand l'identifiant d'une annonce est illisible, aucune action n'a de
  /// cible : on le DIT, au lieu de lever un `TypeError` dans le `build()`.
  ///
  /// Ce n'est pas defensif pour rien. Le serveur peut serialiser un entier en
  /// texte — c'est la faute qui avait fait tomber le catalogue entier, voir
  /// `data/lecture_json.dart`. Avant, `(item['id'] as num)` levait ICI, hors de
  /// tout try/catch, et l'ecran passait au rouge.
  void _identifiantIllisible() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).partnerAccountsListingIncomplete,
          ),
        ),
      );
    }
  }

  Future<void> _action(Map<String, dynamic> item, String action) async {
    if (_working) return;
    final id = json.entier(item['id']);
    if (id == null) return _identifiantIllisible();
    final repository = ref.read(partnerRepositoryProvider);
    if (action == 'edit') return _edit(item);
    if (action == 'photos') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PartnerMediaPage(
            kind: widget.kind,
            listingId: id,
            title: _title(item),
          ),
        ),
      );
      if (mounted) await _load(page: _page?.page ?? 1);
      return;
    }
    if (action == 'archive') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            AppLocalizations.of(context).partnerAccountsArchiveQuestion,
          ),
          content: Text(
            AppLocalizations.of(context).partnerAccountsArchiveDescription,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).partnerAccountsArchive),
            ),
          ],
        ),
      );
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
      switch (action) {
        case 'publish':
          await repository.publish(widget.kind, id, true);
        case 'unpublish':
          await repository.publish(widget.kind, id, false);
        case 'archive':
          await repository.archive(widget.kind, id);
        case 'availability':
          await repository.toggleAvailability(widget.kind, id);
        case 'stock':
          await repository.setStock(widget.kind, id, quantity!);
      }
      if (mounted) await _load(page: _page?.page ?? 1);
    } catch (error) {
      _showError(error);
      if (error is PartnerApiException && error.sessionRejected) {
        await ref.read(partnerSessionProvider.notifier).refresh();
        if (mounted) Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<int?> _stockDialog(Map<String, dynamic> item) async {
    final form = GlobalKey<FormState>();
    final input = TextEditingController(
      text: (item['stock'] as Map?)?['quantity']?.toString() ?? '0',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).partnerAccountsAdjustStock),
        content: Form(
          key: form,
          child: TextFormField(
            controller: input,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(
                context,
              ).partnerAccountsAvailableQuantity,
            ),
            validator: (value) {
              final quantity = int.tryParse(value ?? '');
              return quantity == null || quantity < 0 || quantity > 2147483647
                  ? AppLocalizations.of(context).partnerAccountsQuantityInvalid
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate())
                Navigator.pop(context, int.parse(input.text));
            },
            child: Text(AppLocalizations.of(context).partnerAccountsSave),
          ),
        ],
      ),
    );
    input.dispose();
    return value;
  }

  String _title(Map<String, dynamic> item) =>
      item['designation']?.toString() ??
      item['name']?.toString() ??
      AppLocalizations.of(context).partnerAccountsListingFallback;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        partnerInventoryTitle(AppLocalizations.of(context), widget.kind),
      ),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context).partnerAccountsRefresh,
          onPressed: _loading ? null : () => _load(page: _page?.page ?? 1),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _working ? null : () => _edit(),
      icon: const Icon(Icons.add),
      label: Text(AppLocalizations.of(context).partnerAccountsCreateListing),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _query,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(
                context,
              ).partnerAccountsSearchListings,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: AppLocalizations.of(context).partnerAccountsSearch,
                onPressed: () => _load(),
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ),
        if (_loading || _working) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                if (_error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            messageFor(
                              _error!,
                              l10n: AppLocalizations.of(context),
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          TextButton(
                            onPressed: _load,
                            child: Text(
                              AppLocalizations.of(context).commonRetry,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_loading &&
                    _error == null &&
                    (_page?.items.isEmpty ?? true))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          _query.text.trim().isEmpty
                              ? AppLocalizations.of(
                                  context,
                                ).partnerAccountsInventoryEmpty
                              : AppLocalizations.of(
                                  context,
                                ).partnerAccountsNoMatchingListings,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).partnerAccountsInventoryEmptyHelp,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => _edit(),
                          icon: const Icon(Icons.add),
                          label: Text(
                            AppLocalizations.of(
                              context,
                            ).partnerAccountsCreateFirstListing,
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final item in _page?.items ?? <Map<String, dynamic>>[])
                  _card(item),
                if ((_page?.lastPage ?? 1) > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: AppLocalizations.of(
                          context,
                        ).partnerAccountsPreviousPage,
                        onPressed: !_loading && _page!.page > 1
                            ? () => _load(page: _page!.page - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('${_page!.page} / ${_page!.lastPage}'),
                      IconButton(
                        tooltip: AppLocalizations.of(
                          context,
                        ).partnerAccountsNextPage,
                        onPressed: !_loading && _page!.page < _page!.lastPage
                            ? () => _load(page: _page!.page + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  /// « dont 450 000 de marge boutique (10 %) », ou rien.
  ///
  /// Rien quand l'annonce n'a pas de detail : celles d'avant la marge n'en
  /// ont pas, et leur prix EST celui que le vendeur a propose. Leur inventer
  /// une ligne a 0 % laisserait croire qu'un calcul a eu lieu.
  String? _margeDe(Map<String, dynamic> item) {
    final detail = item['partner_pricing'];
    if (detail is! Map) return null;

    final taux = double.tryParse('${detail['taux'] ?? 0}') ?? 0;
    final propose = double.tryParse(
      '${(detail['prix_proposes'] as Map?)?['sale_price'] ?? (detail['prix_proposes'] as Map?)?['selling_price'] ?? 0}',
    );
    final total = double.tryParse(
      '${(detail['total'] as Map?)?['sale_price'] ?? (detail['total'] as Map?)?['selling_price'] ?? 0}',
    );

    if (taux <= 0 || propose == null || total == null || total <= propose) {
      return null;
    }

    final ecart = (total - propose).round();
    final pourcentage = taux == taux.roundToDouble()
        ? '${taux.round()}'
        : '$taux';

    return AppLocalizations.of(context).partnerAccountsMarginIncluded(
      MargeRecapitulatif.formaterMontant(ecart),
      pourcentage,
    );
  }

  /// Un montant du serveur, lisible.
  ///
  /// Il arrive en « 4950000.00 » — un decimal serialise, parfois en CHAINE :
  /// c'est la faute qui avait fait tomber le catalogue entier. On le lit donc
  /// dans les deux formes, et on rend la valeur telle quelle si elle ne se
  /// lit pas, plutot que d'afficher « 0 » sur un prix qu'on n'a pas compris.
  String _montant(Object valeur) {
    final nombre = double.tryParse('$valeur');

    return nombre == null
        ? '$valeur'
        : MargeRecapitulatif.formaterMontant(nombre);
  }

  Widget _card(Map<String, dynamic> item) {
    final published = item['partner_published_at'] != null;
    final commercial =
        item['commercial'] as Map? ?? item['pricing'] as Map? ?? const {};
    final stock = item['stock'] as Map?;
    final price = commercial['sale_price'] ?? commercial['selling_price'];
    final marge = _margeDe(item);
    final media = partnerMaps(item['media']);
    final cover = media.isEmpty
        ? null
        : media
              .firstWhere(
                (photo) => photo['is_cover'] == true,
                orElse: () => media.first,
              )['url']
              ?.toString();
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
            leading: cover == null
                ? const Icon(Icons.photo_outlined, size: 36)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      cover,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                  ),
            title: Text(
              _title(item),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // ── CE PRIX EST LE PRIX PUBLIC, MARGE COMPRISE ────────────────
            //
            // La colonne porte le prix que l'acheteur voit, et non celui que le
            // vendeur a propose : c'est lui que le catalogue trie et filtre.
            // Sans la ligne ci-dessous, le vendeur relit un nombre qu'il n'a pas
            // tape et croit s'etre trompe — puis baisse son prix pour
            // « corriger », a chaque fois.
            //
            // Le taux vient de l'ANNONCE (`partner_pricing`), fige le jour de son
            // enregistrement, et non du reglage du jour : afficher « marge 30 % »
            // sur un prix calcule a 10 % serait faux.
            subtitle: Text(
              [
                if (price != null)
                  '${_montant(price)} ${commercial['currency'] ?? 'FCFA'}',
                ?marge,
                if (stock != null)
                  AppLocalizations.of(
                    context,
                  ).partnerAccountsStockSummary('${stock['quantity'] ?? '—'}'),
                if (commercial['availability'] == 'rent' ||
                    commercial['availability'] == 'both')
                  commercial['rental_daily_rate'] != null
                      ? AppLocalizations.of(context).partnerAccountsRentalDaily(
                          _montant(commercial['rental_daily_rate']),
                        )
                      : AppLocalizations.of(
                          context,
                        ).partnerAccountsRentalMonthly(
                          _montant(commercial['rental_monthly_rate'] ?? 0),
                        ),
              ].join('\n'),
            ),
            trailing: PopupMenuButton<String>(
              enabled: !_working,
              tooltip: AppLocalizations.of(
                context,
              ).partnerAccountsManageListing,
              onSelected: (action) => _action(item, action),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(AppLocalizations.of(context).catalogEditTooltip),
                ),
                PopupMenuItem(
                  value: 'photos',
                  child: Text(
                    AppLocalizations.of(context).partnerAccountsManagePhotos,
                  ),
                ),
                if (widget.kind != PartnerListingKind.vehicles) ...[
                  PopupMenuItem(
                    value: 'stock',
                    child: Text(
                      AppLocalizations.of(context).partnerAccountsAdjustStock,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'availability',
                    child: Text(
                      stock?['is_available'] == false
                          ? AppLocalizations.of(
                              context,
                            ).partnerAccountsMakeAvailable
                          : AppLocalizations.of(
                              context,
                            ).partnerAccountsMakeUnavailable,
                    ),
                  ),
                ],
                PopupMenuItem(
                  value: 'archive',
                  child: Text(
                    AppLocalizations.of(context).partnerAccountsArchive,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Chip(
                  avatar: Icon(
                    published
                        ? Icons.visibility_outlined
                        : Icons.edit_note_outlined,
                    size: 16,
                  ),
                  label: Text(
                    published
                        ? AppLocalizations.of(context).partnerAccountsPublished
                        : AppLocalizations.of(context).partnerAccountsDraft,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _working
                      ? null
                      : () =>
                            _action(item, published ? 'unpublish' : 'publish'),
                  icon: Icon(
                    published
                        ? Icons.visibility_off_outlined
                        : Icons.publish_outlined,
                  ),
                  label: Text(
                    published
                        ? AppLocalizations.of(context).partnerAccountsWithdraw
                        : AppLocalizations.of(context).partnerAccountsPublish,
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
