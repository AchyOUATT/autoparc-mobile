import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/lien_externe.dart';
import '../../../core/widgets/product_gallery.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../inspections/presentation/staff_inspection_widgets.dart';
import '../data/private_listing_repository.dart';
import 'private_listing_detail.dart';
import 'private_listing_form.dart';
import 'private_listing_labels.dart';

class PrivateListingsPage extends ConsumerStatefulWidget {
  const PrivateListingsPage({super.key, this.mode = PrivateListingMode.browse});
  final PrivateListingMode mode;
  @override
  ConsumerState<PrivateListingsPage> createState() =>
      _PrivateListingsPageState();
}

class _PrivateListingsPageState extends ConsumerState<PrivateListingsPage> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  PrivateListingPage? _results;
  String? _error;
  String _search = '', _status = 'pending';
  int _page = 1, _generation = 0;
  bool _busy = false;
  PrivateListingRepository get _repo =>
      ref.read(privateListingRepositoryProvider);
  bool get _mine => widget.mode == PrivateListingMode.mine;
  bool get _review => widget.mode == PrivateListingMode.review;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  String _session(AuthState auth) =>
      '${auth.type}:${auth.firebaseUser?.uid}:${auth.staffUser?.id}';
  bool _allowed(AuthState auth) =>
      _review ? auth.canManageCatalog : !_mine || auth.isClient;

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!_allowed(auth)) return;
    final session = _session(auth);
    final generation = ++_generation;
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    try {
      final result = await _repo.list(
        widget.mode,
        page: _page,
        search: _search,
        status: _status,
      );
      if (mounted &&
          generation == _generation &&
          session == _session(ref.read(authProvider))) {
        setState(() => _results = result);
      }
    } catch (error) {
      if (mounted &&
          generation == _generation &&
          session == _session(ref.read(authProvider))) {
        setState(() => _error = messageFor(error, l10n: l10n));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _edit([PrivateListing? listing]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrivateListingForm(existing: listing),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openListing(PrivateListing listing) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PrivateListingDetail(
          listing: listing,
          publicListing: !_mine && !_review,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<bool> _confirm(String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(l10n.privateSalesConfirmRemovalBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.privateSalesConfirm),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = messageFor(error, l10n: l10n);
          _busy = false;
        });
      }
    }
  }

  /// Refuser une annonce, en disant au modérateur ce qu'on attend de lui.
  ///
  /// CE QUE CE DIALOGUE FAISAIT. Sous cinq signes utiles, le bouton ne faisait
  /// RIEN : pas de message, pas de fermeture, rien. Et le compteur de
  /// `maxLength` affichait « 4/2000 », ce qui disait l'inverse de la règle.
  /// Le réviseur touchait deux ou trois fois, puis signalait que la validation
  /// des annonces ne fonctionnait pas. C'est l'unique guichet de modération de
  /// cette boutique.
  ///
  /// Le patron est celui de `partner_applications_page.dart`, déjà publié : un
  /// `Form` avec un `validator`, et le message sous le champ. `counterText: ''`
  /// retire le compteur qui contredisait la règle, remplacé par un
  /// `helperText` qui la dit.
  Future<void> _reject(PrivateListing listing) async {
    final form = GlobalKey<FormState>();
    var draft = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.privateSalesRejectReasonTitle),
        content: Form(
          key: form,
          child: TextFormField(
            onChanged: (value) => draft = value,
            maxLength: 2000,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.privateSalesRejectReasonHint,
              helperText: l10n.privateSalesRejectReasonMinimumHint,
              counterText: '',
            ),
            validator: (value) => (value ?? '').trim().length < 5
                ? l10n.privateSalesRejectReasonTooShort
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, draft.trim());
              }
            },
            child: Text(l10n.privateSalesRejectAction),
          ),
        ],
      ),
    );
    // The dialog's route may still animate after completion; let it dispose its field first.
    if (reason != null && mounted) {
      await _run(
        () => _repo.review(
          listing.id,
          revision: listing.number('revision'),
          reason: reason,
        ),
      );
    }
  }

  /// Publier, c'est-a-dire : appeler le vendeur, puis l'affirmer.
  ///
  /// POURQUOI UNE BOITE PLUTOT QU'UN ENVOI DIRECT
  ///
  /// La verification par SMS prouvait la possession du numero par
  /// cryptographie. L'appel la prouve par un geste humain, et un geste n'a de
  /// valeur que s'il est demande explicitement. Le serveur refuse de publier
  /// sans l'affirmation ; cette boite est l'endroit ou on la donne, et elle
  /// porte la question a poser — sans elle, l'appel verifie un numero au lieu
  /// de verifier une annonce, ce qui ne protege personne.
  ///
  /// Quand la ligne porte deja un appel valable pour le numero courant, on
  /// publie sans rien redemander : le vendeur a seulement corrige son prix ou
  /// ses photos, et rappeler la meme personne a chaque retouche userait vite
  /// la file de moderation.
  Future<void> _publier(PrivateListing listing) async {
    if (listing.phoneVerified &&
        listing.verifiedPhone == listing.phoneClaimed) {
      await _run(
        () => _repo.review(listing.id, revision: listing.number('revision')),
      );

      return;
    }

    final numero = listing.phoneClaimed;
    if (numero.isEmpty) {
      setState(() => _error = l10n.privateSalesMissingPhonePublication);

      return;
    }

    var confirme = false;
    final publier = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.privateSalesCallSeller),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(numero, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(l10n.privateSalesCallCheckInstructions),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.call_outlined),
                label: Text(l10n.privateSalesDial),
                onPressed: () => ouvrirLien(
                  context,
                  Uri(scheme: 'tel', path: numero),
                  valeurACopier: numero,
                  ceQuiNePeutPasSOuvrir: l10n.shellContactDialerTarget,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: confirme,
                onChanged: (value) =>
                    setDialogState(() => confirme = value ?? false),
                title: Text(l10n.privateSalesCallConfirmed),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: confirme
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: Text(l10n.privateSalesPublish),
            ),
          ],
        ),
      ),
    );

    if (publier == true && mounted) {
      await _run(
        () => _repo.review(
          listing.id,
          revision: listing.number('revision'),
          phoneVerified: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (_session(previous ?? const AuthState()) != _session(next)) {
        ++_generation;
        setState(() {
          _results = null;
          _error = null;
          _page = 1;
        });
        if (_allowed(next)) _load();
      }
    });
    final title = _review
        ? l10n.privateSalesReviewTitle
        : _mine
        ? l10n.privateSalesMineTitle
        : l10n.privateSalesBrowseTitle;
    if (!_allowed(auth)) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: _review
              ? Text(l10n.privateSalesReviewAccessDenied)
              : FilledButton(
                  onPressed: () => context.push('/login'),
                  child: Text(l10n.privateSalesSignInManage),
                ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: l10n.privateSalesRefresh,
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          if (!_mine && !_review && auth.isClient)
            IconButton(
              tooltip: l10n.privateSalesMineTitle,
              icon: const Icon(Icons.list_alt),
              onPressed: () => context.push('/my-listings'),
            ),
        ],
      ),
      floatingActionButton: _review
          ? null
          : FloatingActionButton.extended(
              onPressed: _busy ? null : () => _edit(),
              icon: const Icon(Icons.sell_outlined),
              label: Text(l10n.privateSalesSellTitle),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            if (!_review && !_mine)
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.privateSalesSearchHint,
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) {
                  _search = value.trim();
                  _page = 1;
                  _load();
                },
              ),
            if (_review)
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: l10n.privateSalesReviewFilterLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text(l10n.privateSalesReviewFilterPending),
                  ),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text(l10n.privateSalesReviewFilterPublished),
                  ),
                  DropdownMenuItem(
                    value: 'rejected',
                    child: Text(l10n.privateSalesStatusRejected),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        _status = value!;
                        _page = 1;
                        _load();
                      },
              ),
            if (_mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(l10n.privateSalesOneActiveListingHint),
              ),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _load,
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_busy && _error == null && _results?.items.isEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  _mine
                      ? l10n.privateSalesEmptyMine
                      : _review
                      ? l10n.privateSalesEmptyReview
                      : l10n.privateSalesEmptyBrowse,
                  textAlign: TextAlign.center,
                ),
              ),
            for (final listing in _results?.items ?? <PrivateListing>[])
              _card(listing),
            if (_results != null && _results!.lastPage > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _busy || _page <= 1
                        ? null
                        : () {
                            _page--;
                            _load();
                          },
                    child: Text(l10n.privateSalesPrevious),
                  ),
                  Text(l10n.privateSalesPagination(_page, _results!.lastPage)),
                  TextButton(
                    onPressed: _busy || _page >= _results!.lastPage
                        ? null
                        : () {
                            _page++;
                            _load();
                          },
                    child: Text(l10n.privateSalesNext),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(PrivateListing listing) => Card(
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (listing.photoUrls.isNotEmpty)
          SizedBox(
            height: 180,
            child: ProductGallery(
              key: ValueKey(
                'private-photos:${listing.id}:${listing.photoUrls.join('|')}',
              ),
              urls: listing.photoUrls,
              titre: listing.title,
              fallback: const Center(
                child: Icon(Icons.directions_car_outlined),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(
                _mine || _review
                    ? privateListingStatusLabel(listing, l10n)
                    : l10n.privateSalesPrivateSeller,
              ),
            ),
          ),
        ),
        // The badge opens the public report, available only in browse mode.
        if (!_mine && !_review && listing.inspection != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StaffInspectionBadge(inspection: listing.inspection!),
            ),
          ),
        ListTile(
          title: Text(listing.title),
          subtitle: Text(
            '${formatXof(listing.number('price').toDouble())}\n${listing.number('year')} · ${listing.number('mileage_km')} km · ${listing.text('city')}',
          ),
          isThreeLine: true,
          onTap: () => _openListing(listing),
        ),
        if (listing.text('review_reason').isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.privateSalesReviewReason(listing.text('review_reason')),
            ),
          ),
        if (_mine && listing.editable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _edit(listing),
                  child: Text(l10n.privateSalesEdit),
                ),
                if (listing.status == 'published')
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            if (await _confirm(
                                  l10n.privateSalesConfirmSoldTitle,
                                ) &&
                                mounted) {
                              await _run(() async {
                                await _repo.action(listing.id, 'sold');
                              });
                            }
                          },
                    child: Text(l10n.privateSalesMarkSold),
                  ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (await _confirm(
                                l10n.privateSalesConfirmWithdrawTitle,
                              ) &&
                              mounted) {
                            await _run(() async {
                              await _repo.action(listing.id, 'withdraw');
                            });
                          }
                        },
                  child: Text(l10n.privateSalesWithdraw),
                ),
              ],
            ),
          ),
        if (_review)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                if (listing.status == 'pending')
                  FilledButton(
                    onPressed: _busy ? null : () => _publier(listing),
                    child: Text(l10n.privateSalesPublish),
                  ),
                if (const ['pending', 'published'].contains(listing.status))
                  OutlinedButton(
                    onPressed: _busy ? null : () => _reject(listing),
                    child: Text(l10n.privateSalesRejectAction),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
