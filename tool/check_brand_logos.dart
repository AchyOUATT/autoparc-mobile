// Compare le contenu de assets/brands/ à la liste des marques de l'API.
//
// Usage :
//   dart run tool/check_brand_logos.dart
//   dart run tool/check_brand_logos.dart http://127.0.0.1:8000/api
//
// La liste vient de l'API plutôt que d'être figée ici : ajouter une marque en
// base la fait apparaître dans le rapport sans toucher à ce script.

import 'dart:convert';
import 'dart:io';

const _defaultApi = 'http://127.0.0.1:8000/api';
const _dir = 'assets/brands';

Future<void> main(List<String> args) async {
  final api = args.isNotEmpty ? args.first : _defaultApi;

  final List<dynamic> brands;
  try {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('$api/catalog/brands'));
    final res = await req.close();
    if (res.statusCode != 200) {
      stderr.writeln('L\'API a repondu HTTP ${res.statusCode} sur $api/catalog/brands');
      exit(1);
    }
    final body = jsonDecode(await res.transform(utf8.decoder).join());
    brands = (body is Map && body['data'] is List) ? body['data'] as List : body as List;
    client.close();
  } on SocketException {
    stderr.writeln('API injoignable sur $api — demarrez le backend (php artisan serve).');
    exit(1);
  }

  final expected = <String, String>{
    for (final b in brands)
      if (b['slug'] != null) b['slug'] as String: (b['name'] ?? b['slug']) as String,
  };

  final present = <String, String>{};
  final dir = Directory(_dir);
  if (dir.existsSync()) {
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      final dot = name.lastIndexOf('.');
      if (dot <= 0) continue;
      final ext = name.substring(dot + 1).toLowerCase();
      if (ext != 'svg' && ext != 'png') continue;
      present[name.substring(0, dot)] = name;
    }
  }

  final missing = expected.keys.where((s) => !present.containsKey(s)).toList()..sort();
  final extra   = present.keys.where((s) => !expected.containsKey(s)).toList()..sort();

  stdout.writeln('${present.length - extra.length} / ${expected.length} logos en place\n');

  if (missing.isNotEmpty) {
    stdout.writeln('Manquants (${missing.length}) :');
    for (final s in missing) {
      stdout.writeln('  $s.svg${' ' * (20 - s.length).clamp(1, 20)}${expected[s]}');
    }
    stdout.writeln();
  }

  if (extra.isNotEmpty) {
    stdout.writeln('Fichiers sans marque correspondante — nom errone ?');
    for (final s in extra) {
      stdout.writeln('  ${present[s]}');
    }
    stdout.writeln();
  }

  if (missing.isEmpty && extra.isEmpty) {
    stdout.writeln('Rien a signaler.');
  }

  exit(missing.isEmpty && extra.isEmpty ? 0 : 1);
}
