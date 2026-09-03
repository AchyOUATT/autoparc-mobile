import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepository(ref.read(apiClientProvider)),
);

/// Modèle léger d'un média retourné par l'API.
class MediaItem {
  final int id;
  final String url;
  final String collection;
  final bool isCover;
  final int position;
  final String? caption;
  final int? size;

  const MediaItem({
    required this.id,
    required this.url,
    required this.collection,
    required this.isCover,
    required this.position,
    this.caption,
    this.size,
  });

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
    id:         j['id'] as int,
    url:        j['url'] as String,
    collection: j['collection'] as String? ?? 'gallery',
    isCover:    j['is_cover'] as bool? ?? false,
    position:   j['position'] as int? ?? 0,
    caption:    j['caption'] as String?,
    size:       j['size'] as int?,
  );

  MediaItem copyWith({bool? isCover}) => MediaItem(
    id: id, url: url, collection: collection,
    isCover: isCover ?? this.isCover,
    position: position, caption: caption, size: size,
  );
}

enum MediaOwnerType { vehicle, part, accessory }

class MediaRepository {
  final ApiClient _client;
  const MediaRepository(this._client);

  String _mediaPath(MediaOwnerType type, int id) => switch (type) {
    MediaOwnerType.vehicle   => Endpoints.vehicleMedia(id),
    MediaOwnerType.part      => Endpoints.partMedia(id),
    MediaOwnerType.accessory => Endpoints.accessoryMedia(id),
  };

  String _reorderPath(MediaOwnerType type, int id) => switch (type) {
    MediaOwnerType.vehicle   => Endpoints.vehicleMediaReorder(id),
    MediaOwnerType.part      => Endpoints.partMediaReorder(id),
    MediaOwnerType.accessory => Endpoints.accessoryMediaReorder(id),
  };

  /// Récupère tous les médias d'une ressource.
  Future<List<MediaItem>> getMedia(MediaOwnerType type, int id) async {
    final json = await _client.get(_mediaPath(type, id));
    final list = json['data'] as List<dynamic>? ?? [];
    return list.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Upload plusieurs fichiers en une seule requête multipart.
  Future<List<MediaItem>> uploadPhotos(
    MediaOwnerType type,
    int id,
    List<String> filePaths, {
    String collection = 'gallery',
  }) async {
    final json = await _client.uploadFiles(
      _mediaPath(type, id),
      filePaths: filePaths,
      field: 'photos',
      extra: {'collection': collection},
    );
    final list = json['data'] as List<dynamic>? ?? [];
    return list.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Supprime un média.
  Future<void> deleteMedia(int mediaId) async {
    await _client.delete(Endpoints.mediaItem(mediaId));
  }

  /// Définit un média comme couverture.
  Future<MediaItem> setCover(int mediaId) async {
    final json = await _client.patch(Endpoints.mediaSetCover(mediaId));
    return MediaItem.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Réordonne les médias.
  Future<void> reorder(MediaOwnerType type, int id, List<int> orderedIds) async {
    await _client.patch(_reorderPath(type, id), data: {'ids': orderedIds});
  }
}
