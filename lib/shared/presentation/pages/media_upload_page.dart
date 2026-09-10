import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/catalog_image.dart';
import '../../data/media_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Config passée via GoRouter `extra`
// ─────────────────────────────────────────────────────────────────────────────

class MediaUploadConfig {
  final MediaOwnerType type;
  final int id;
  final String title; // "Véhicule Toyota Corolla", "Pièce Plaquette de frein"…

  const MediaUploadConfig({
    required this.type,
    required this.id,
    required this.title,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class MediaUploadPage extends ConsumerStatefulWidget {
  final MediaUploadConfig config;
  const MediaUploadPage({super.key, required this.config});

  @override
  ConsumerState<MediaUploadPage> createState() => _MediaUploadPageState();
}

class _MediaUploadPageState extends ConsumerState<MediaUploadPage> {
  final _picker = ImagePicker();

  List<MediaItem> _uploaded = [];   // médias déjà sur le serveur
  bool _loading   = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  MediaRepository get _repo => ref.read(mediaRepositoryProvider);
  MediaOwnerType  get _type => widget.config.type;
  int             get _id   => widget.config.id;

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getMedia(_type, _id);
      if (mounted) setState(() => _uploaded = list);
    } catch (_) {
      // silencieux — liste vide
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Sélection & upload ───────────────────────────────────────────

  Future<void> _pickAndUpload(ImageSource source) async {
    List<XFile> files;

    if (source == ImageSource.gallery) {
      files = await _picker.pickMultiImage(imageQuality: 85, limit: 10);
    } else {
      final f = await _picker.pickImage(source: source, imageQuality: 85);
      files = f != null ? [f] : [];
    }

    if (files.isEmpty || !mounted) return;

    setState(() => _uploading = true);
    try {
      final newItems = await _repo.uploadPhotos(
        _type,
        _id,
        files.map((f) => f.path).toList(),
      );
      if (mounted) {
        setState(() => _uploaded = [..._uploaded, ...newItems]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newItems.length} photo(s) ajoutée(s).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Suppression ──────────────────────────────────────────────────

  Future<void> _delete(MediaItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette photo ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _repo.deleteMedia(item.id);
      if (mounted) setState(() => _uploaded.remove(item));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Couverture ───────────────────────────────────────────────────

  Future<void> _setCover(MediaItem item) async {
    if (item.isCover) return;
    try {
      await _repo.setCover(item.id);
      if (mounted) {
        setState(() {
          _uploaded = _uploaded.map((m) => m.copyWith(isCover: m.id == item.id)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── UI ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Photos', style: TextStyle(fontSize: 16)),
            Text(
              widget.config.title,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Terminer'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Barre d'upload ───────────────────────────────────
                _UploadBar(
                  uploading: _uploading,
                  onGallery: () => _pickAndUpload(ImageSource.gallery),
                  onCamera:  () => _pickAndUpload(ImageSource.camera),
                ),

                // ── Grille des photos ────────────────────────────────
                Expanded(
                  child: _uploaded.isEmpty
                      ? _EmptyState(onAdd: () => _pickAndUpload(ImageSource.gallery))
                      : _PhotoGrid(
                          items: _uploaded,
                          onDelete: _delete,
                          onSetCover: _setCover,
                        ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre d'actions upload
// ─────────────────────────────────────────────────────────────────────────────

class _UploadBar extends StatelessWidget {
  final bool uploading;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  const _UploadBar({required this.uploading, required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: uploading ? null : onGallery,
              icon: uploading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: Text(uploading ? 'Envoi…' : 'Galerie'),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: uploading ? null : onCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Caméra'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grille de photos
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<MediaItem> items;
  final Future<void> Function(MediaItem) onDelete;
  final Future<void> Function(MediaItem) onSetCover;
  const _PhotoGrid({required this.items, required this.onDelete, required this.onSetCover});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _PhotoTile(
        item: items[i],
        onDelete: () => onDelete(items[i]),
        onSetCover: () => onSetCover(items[i]),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onDelete;
  final VoidCallback onSetCover;
  const _PhotoTile({required this.item, required this.onDelete, required this.onSetCover});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CatalogImage(
            url: item.url,
            // Pendant le chargement, un aplat neutre : afficher l'icône
            // « image cassée » avant même l'échec ferait croire à un média
            // corrompu alors qu'il arrive.
            whileLoading: ColoredBox(color: cs.surfaceContainerHighest),
            fallback: Container(
              color: cs.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),

        // Badge couverture
        if (item.isCover)
          Positioned(
            bottom: 6, left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 10, color: cs.onPrimary),
                  const SizedBox(width: 3),
                  Text('Cover',
                    style: TextStyle(fontSize: 9, color: cs.onPrimary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        // Bouton couverture (si pas encore cover)
        if (!item.isCover)
          Positioned(
            bottom: 6, left: 6,
            child: GestureDetector(
              onTap: onSetCover,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.star_outline, size: 14, color: Colors.white),
              ),
            ),
          ),

        // Bouton supprimer
        Positioned(
          top: 6, right: 6,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// État vide
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('Aucune photo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Appuyez sur "Galerie" pour ajouter des photos.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Ajouter des photos'),
          ),
        ],
      ),
    );
  }
}
