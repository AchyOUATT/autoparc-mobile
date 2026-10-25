import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../data/lecture_json.dart' as json;
import '../data/partner_repository.dart';

class PartnerMediaPage extends ConsumerStatefulWidget {
  const PartnerMediaPage({super.key, required this.kind, required this.listingId, required this.title});
  final PartnerListingKind kind;
  final int listingId;
  final String title;
  @override
  ConsumerState<PartnerMediaPage> createState() => _PartnerMediaPageState();
}

class _PartnerMediaPageState extends ConsumerState<PartnerMediaPage> {
  List<Map<String, dynamic>> _photos = [];
  bool _busy = true;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final photos = await ref.read(partnerRepositoryProvider).media(widget.kind, widget.listingId);
      if (mounted) setState(() { _photos = photos; _error = null; _busy = false; });
    } catch (error) { if (mounted) setState(() { _error = messageFor(error); _busy = false; }); }
  }
  Future<void> _run(Future<void> Function() action) async {
    setState(() { _busy = true; _error = null; });
    try { await action(); await _load(); }
    catch (error) { if (mounted) setState(() { _busy = false; _error = messageFor(error); }); }
  }

  /// Les quatre réglages sont ceux du dépôt du personnel
  /// (`shared/presentation/pages/media_upload_page.dart`), et ils y sont
  /// longuement justifiés : sans `maxWidth`/`maxHeight`, le décodage d'une
  /// prise de téléphone pleine résolution dépasse `heapgrowthlimit` sur les
  /// appareils d'API 24-25 — OutOfMemoryError certain sur la fourchette basse
  /// du parc visé.
  ///
  /// Ce chemin-ci était le SEUL de l'application à ne pas les poser. Outre le
  /// risque mémoire, les plafonds PHP du serveur sont dimensionnés sur cette
  /// réduction : `upload_max_filesize = 9M` et `post_max_size = 24M`
  /// (`docker/php/depot-de-photos.ini`), calculés pour dix photos réduites.
  /// Dix prises pleine résolution dépassent le second et l'envoi entier est
  /// refusé.
  ///
  /// Le `limit: 10` est celui du serveur — `MediaController::MAX_PHOTOS`. Le
  /// contrôle explicite qui suit reste utile : `limit` n'est pas honoré par
  /// toutes les implémentations de plateforme, et un refus du serveur coûte un
  /// aller-retour là où un message local ne coûte rien.
  Future<void> _upload() async {
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
        limit: 10,
      );
      if (!mounted || files.isEmpty) return;
      if (files.length > 10) { setState(() => _error = 'Sélectionnez au plus 10 photos par envoi.'); return; }
      await _run(() => ref.read(partnerRepositoryProvider).uploadPhotos(widget.kind, widget.listingId, files));
    } catch (error) { if (mounted) setState(() => _error = messageFor(error)); }
  }
  Future<void> _move(int index, int offset) => _run(() {
    final ids = _photos.map((photo) => json.entier(photo['id'])).whereType<int>().toList();
    final id = ids.removeAt(index);
    ids.insert(index + offset, id);
    return ref.read(partnerRepositoryProvider).reorderMedia(widget.kind, widget.listingId, ids);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Photos de l’annonce')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : _upload, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Ajouter des photos')),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
      Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8), const Text('JPEG, PNG ou WebP. Choisissez une couverture et ordonnez votre galerie.'),
      if (_busy) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LinearProgressIndicator()),
      if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)), TextButton(onPressed: _load, child: const Text('Réessayer'))]))),
      if (!_busy && _photos.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: Text('Ajoutez les premières photos de votre annonce.'))),
      for (var index = 0; index < _photos.length; index++) _photo(index),
    ]),
  );

  /// Une photo de la galerie.
  ///
  /// `id` est lu TOLÉREMMENT, et son absence désactive les actions au lieu de
  /// faire tomber l'écran. Cette branche est atteignable : le serveur peut
  /// sérialiser l'identifiant en texte — c'est la faute qui avait déjà fait
  /// tomber le catalogue entier, voir `data/lecture_json.dart`. On montre
  /// alors la photo, qu'on sait afficher, et on retire les boutons qui
  /// auraient besoin de l'identifiant.
  Widget _photo(int index) {
    final photo = _photos[index];
    final id = json.entier(photo['id']);
    return Card(clipBehavior: Clip.antiAlias, child: Column(children: [
      Image.network(photo['url'].toString(), height: 200, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox(height: 120, child: Center(child: Icon(Icons.broken_image_outlined)))),
      Row(children: [
        Expanded(child: TextButton.icon(onPressed: _busy || id == null || photo['is_cover'] == true ? null : () => _run(() => ref.read(partnerRepositoryProvider).setCover(id)),
          icon: Icon(photo['is_cover'] == true ? Icons.star : Icons.star_outline), label: Text(photo['is_cover'] == true ? 'Couverture' : 'En couverture'))),
        IconButton(tooltip: 'Déplacer avant', onPressed: _busy || index == 0 ? null : () => _move(index, -1), icon: const Icon(Icons.arrow_upward)),
        IconButton(tooltip: 'Déplacer après', onPressed: _busy || index == _photos.length - 1 ? null : () => _move(index, 1), icon: const Icon(Icons.arrow_downward)),
        IconButton(tooltip: 'Supprimer la photo', onPressed: _busy || id == null ? null : () async {
          final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Supprimer cette photo ?'),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer'))]));
          if (confirmed == true && mounted) await _run(() => ref.read(partnerRepositoryProvider).deleteMedia(id));
        }, icon: const Icon(Icons.delete_outline)),
      ]),
    ]));
  }
}
