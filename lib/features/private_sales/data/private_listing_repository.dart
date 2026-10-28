import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';

const privateSalesEnabled = bool.fromEnvironment('ENABLE_PRIVATE_SALES');

int readListingInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

class PrivateListing {
  const PrivateListing(this.fields);
  final Map<String, dynamic> fields;
  int get id => readListingInt(fields['id']);
  String text(String key) => fields[key]?.toString() ?? '';
  int number(String key) => readListingInt(fields[key]);
  String get title => text('title');
  String identityText(String key) {
    final identity = fields['vehicle_identity'];
    return identity is Map ? identity[key]?.toString() ?? '' : '';
  }

  String get status => text('status');

  /// Le numero SAISI par le vendeur, que le personnel appellera.
  String get phoneClaimed => text('phone_claimed');

  /// Le numero VERIFIE : vide tant que personne n'a appele. C'est lui,
  /// et lui seul, que les acheteurs voient.
  String get verifiedPhone => text('phone');

  /// Un appel a-t-il ete passe et consigne ?
  bool get phoneVerified => text('phone_verified_at').isNotEmpty;
  bool get editable =>
      const ['draft', 'pending', 'published', 'rejected'].contains(status);
  List<Map<String, dynamic>> get photos => (fields['photos'] as List? ?? [])
      .whereType<Map>()
      .map((photo) => Map<String, dynamic>.from(photo))
      .toList();
  String get statusLabel =>
      const {
        'draft': 'Brouillon',
        'pending': 'En cours de validation',
        'published': 'En ligne',
        'rejected': 'À corriger',
        'withdrawn': 'Retirée',
        'sold': 'Vendue',
      }[status] ??
      'Particulier';
}

class PrivateListingPage {
  const PrivateListingPage(this.items, {this.page = 1, this.lastPage = 1});
  factory PrivateListingPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map? ?? {};
    return PrivateListingPage(
      (json['data'] as List? ?? [])
          .whereType<Map>()
          .map((value) => PrivateListing(Map<String, dynamic>.from(value)))
          .toList(),
      page: readListingInt(meta['current_page']).clamp(1, 100000),
      lastPage: readListingInt(meta['last_page']).clamp(1, 100000),
    );
  }
  final List<PrivateListing> items;
  final int page;
  final int lastPage;
}

enum PrivateListingMode { browse, mine, review }

final privateListingRepositoryProvider = Provider<PrivateListingRepository>(
  (ref) => PrivateListingRepository(ref.read(apiClientProvider)),
);

class PrivateListingRepository {
  const PrivateListingRepository(this.client);
  final ApiClient client;
  static const minePath = '/my/private-listings';

  Future<PrivateListingPage> list(
    PrivateListingMode mode, {
    int page = 1,
    String search = '',
    String status = 'pending',
  }) async {
    final path = switch (mode) {
      PrivateListingMode.browse => '/private-listings',
      PrivateListingMode.mine => minePath,
      PrivateListingMode.review => '/private-listing-reviews',
    };
    return PrivateListingPage.fromJson(
      await client.get(
        path,
        params: {
          'page': page,
          if (mode == PrivateListingMode.browse) 'search': search,
          if (mode == PrivateListingMode.review) 'status': status,
        },
      ),
    );
  }

  Future<PrivateListing> get(int id) async =>
      _listing(await client.get('/private-listings/$id'));
  Future<PrivateListing> getOwned(int id) async =>
      _listing(await client.get('$minePath/$id'));
  Future<PrivateListing> save(Map<String, dynamic> fields, {int? id}) async =>
      _listing(
        id == null
            ? await client.post(minePath, data: fields)
            : await client.put('$minePath/$id', data: fields),
      );
  Future<PrivateListing> action(
    int id,
    String action, {
    Map<String, dynamic>? fields,
  }) async =>
      _listing(await client.post('$minePath/$id/$action', data: fields));
  Future<PrivateListing> upload(int id, List<XFile> files) async {
    final photos = await Future.wait(
      files.map((file) async => MapEntry(file.name, await file.readAsBytes())),
    );
    return _listing(
      await client.uploadBytes('$minePath/$id/photos', photos: photos),
    );
  }

  Future<void> deletePhoto(int id, int photo) =>
      client.delete('$minePath/$id/photos/$photo');
  /// Publie ou refuse une annonce.
  ///
  /// `phoneVerified` est l'affirmation du moderateur : « j'ai appele ce numero
  /// et la personne a confirme avoir depose cette annonce ». Le serveur
  /// l'exige pour publier, sauf si la ligne porte deja un appel valable pour
  /// le numero courant — voir `approve()` cote serveur.
  Future<void> review(
    int id, {
    required int revision,
    String? reason,
    bool phoneVerified = false,
  }) async {
    await client.post(
      '/private-listing-reviews/$id/${reason == null ? 'approve' : 'reject'}',
      data: {
        'revision': revision,
        'reason': ?reason,
        // La cle n'apparait QUE si l'affirmation est faite : une annonce
        // dont le numero est deja verifie se republie sans la porter, et la
        // charge dit alors exactement ce qui s'est passe.
        if (reason == null && phoneVerified) 'phone_verified': true,
      },
    );
  }

  PrivateListing _listing(Map<String, dynamic> json) =>
      PrivateListing(Map<String, dynamic>.from(json['data'] as Map));
}
