import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/lien_externe.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/private_listing_repository.dart';
import 'private_listing_detail.dart';
import 'private_listing_form.dart';

class PrivateListingsPage extends ConsumerStatefulWidget {
  const PrivateListingsPage({super.key, this.mode = PrivateListingMode.browse});
  final PrivateListingMode mode;
  @override
  ConsumerState<PrivateListingsPage> createState() =>
      _PrivateListingsPageState();
}

class _PrivateListingsPageState extends ConsumerState<PrivateListingsPage> {
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
        setState(() => _error = messageFor(error));
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

  Future<bool> _confirm(String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: const Text(
            'L’annonce ne sera plus visible par les acheteurs.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
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
          _error = messageFor(error);
          _busy = false;
        });
      }
    }
  }

  Future<void> _reject(PrivateListing listing) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motif à communiquer au vendeur'),
        content: TextField(
          controller: controller,
          maxLength: 2000,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Expliquez ce qui doit être corrigé.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 5) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Refuser / retirer'),
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
    if (listing.phoneVerified && listing.verifiedPhone == listing.phoneClaimed) {
      await _run(
        () => _repo.review(listing.id, revision: listing.number('revision')),
      );

      return;
    }

    final numero = listing.phoneClaimed;
    if (numero.isEmpty) {
      setState(
        () => _error =
            'Cette annonce n’indique aucun numéro : elle ne peut pas être '
            'publiée. Refusez-la en demandant au vendeur de le renseigner.',
      );

      return;
    }

    var confirme = false;
    final publier = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Appeler le vendeur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(numero, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Demandez-lui si c’est bien LUI qui a déposé cette annonce — '
                'pas seulement si le numéro est le sien.',
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.call_outlined),
                label: const Text('Composer'),
                onPressed: () => ouvrirLien(
                  context,
                  Uri(scheme: 'tel', path: numero),
                  valeurACopier: numero,
                  ceQuiNePeutPasSOuvrir: 'le composeur',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: confirme,
                onChanged: (value) =>
                    setDialogState(() => confirme = value ?? false),
                title: const Text(
                  'J’ai appelé ce numéro et le vendeur a confirmé avoir '
                  'déposé cette annonce.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: confirme
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Publier'),
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
        ? 'Valider les annonces'
        : _mine
        ? 'Mes annonces'
        : 'Voitures de particuliers';
    if (!_allowed(auth)) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: _review
              ? const Text('Accès réservé au personnel chargé du catalogue.')
              : FilledButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Se connecter pour gérer mes annonces'),
                ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          if (!_mine && !_review && auth.isClient)
            IconButton(
              tooltip: 'Mes annonces',
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
              label: const Text('Vendre ma voiture'),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            if (!_review && !_mine)
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Chercher une voiture ou une ville',
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
                decoration: const InputDecoration(
                  labelText: 'État des annonces',
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('En attente')),
                  DropdownMenuItem(value: 'published', child: Text('Publiées')),
                  DropdownMenuItem(
                    value: 'rejected',
                    child: Text('À corriger'),
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
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Une annonce en cours gratuite. Retirez-la ou marquez-la vendue pour en créer une autre.',
                ),
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
                        child: const Text('Réessayer'),
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
                      ? 'Votre première annonce commence ici.'
                      : _review
                      ? 'Aucune annonce à examiner.'
                      : 'Aucune annonce pour le moment.',
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
                    child: const Text('Précédent'),
                  ),
                  Text('$_page / ${_results!.lastPage}'),
                  TextButton(
                    onPressed: _busy || _page >= _results!.lastPage
                        ? null
                        : () {
                            _page++;
                            _load();
                          },
                    child: const Text('Suivant'),
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
        if (listing.photos.isNotEmpty)
          Image.network(
            '${listing.photos.first['url']}',
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(
              height: 80,
              child: Icon(Icons.directions_car_outlined),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(
                _mine || _review ? listing.statusLabel : 'Particulier',
              ),
            ),
          ),
        ),
        ListTile(
          title: Text(listing.title),
          subtitle: Text(
            '${formatXof(listing.number('price').toDouble())}\n${listing.number('year')} · ${listing.number('mileage_km')} km · ${listing.text('city')}',
          ),
          isThreeLine: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => PrivateListingDetail(
                listing: listing,
                publicListing: !_mine && !_review,
              ),
            ),
          ),
        ),
        if (listing.text('review_reason').isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('À corriger : ${listing.text('review_reason')}'),
          ),
        if (_mine && listing.editable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _edit(listing),
                  child: const Text('Modifier / compléter'),
                ),
                if (listing.status == 'published')
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            if (await _confirm('Marquer ce véhicule vendu ?') &&
                                mounted) {
                              await _run(() async {
                                await _repo.action(listing.id, 'sold');
                              });
                            }
                          },
                    child: const Text('Marquer vendu'),
                  ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (await _confirm('Retirer cette annonce ?') &&
                              mounted) {
                            await _run(() async {
                              await _repo.action(listing.id, 'withdraw');
                            });
                          }
                        },
                  child: const Text('Retirer'),
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
                    child: const Text('Publier'),
                  ),
                if (const ['pending', 'published'].contains(listing.status))
                  OutlinedButton(
                    onPressed: _busy ? null : () => _reject(listing),
                    child: const Text('Refuser / retirer'),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
