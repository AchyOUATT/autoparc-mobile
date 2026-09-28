import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../data/check_draft_store.dart';
import '../../data/garage_repository.dart';
import '../../data/models/owned_vehicle.dart';
import '../../data/models/vehicle_check.dart';
import '../providers/garage_provider.dart';

/// Le contrôle avant voyage.
///
/// Trois étapes, et l'ordre a une raison. On demande d'abord la distance et le
/// compteur : la distance change la liste — la climatisation et les provisions
/// n'apparaissent qu'au-delà d'un certain trajet, et une vidange à deux cents
/// kilomètres de son terme devient un défaut si le trajet en fait trois cent
/// soixante. Le compteur, lui, est la contrepartie discrète de la fonction :
/// c'est la seule occasion où quelqu'un se trouve devant son tableau de bord
/// avec l'application ouverte, et sans ce relevé le rappel de vidange ne part
/// jamais.
///
/// Vient ensuite la liste, composée par le serveur pour ce véhicule-là, chaque
/// point portant la raison chiffrée qui l'a fait apparaître. Puis le verdict, en
/// deux blocs : ce qui doit être réglé avant de partir, et ce qui peut attendre.
///
/// Rien n'est calculé ici. Ni la liste, ni le verdict, ni les seuils : un seuil
/// recopié côté application finit par contredire le serveur, et le propriétaire
/// voit alors deux vérités pour une même voiture. C'est la règle que le projet
/// s'est déjà donnée pour les échéances.
class PreTripCheckPage extends ConsumerStatefulWidget {
  final int ownedVehicleId;

  /// Nul après un lien profond ou un rechargement à chaud : la page doit
  /// fonctionner sans, comme l'écran des pièces compatibles.
  final OwnedVehicle? vehicle;

  const PreTripCheckPage({
    super.key,
    required this.ownedVehicleId,
    this.vehicle,
  });

  @override
  ConsumerState<PreTripCheckPage> createState() => _PreTripCheckPageState();
}

enum _Etape { depart, liste, verdict }

class _PreTripCheckPageState extends ConsumerState<PreTripCheckPage> {
  _Etape _etape = _Etape.depart;

  /// Le contrôleur appartient à l'état, et se libère avec lui.
  ///
  /// Un contrôleur créé à l'extérieur du widget et libéré dès qu'une boîte de
  /// dialogue rendait la main a déjà valu un écran rouge intermittent à ce
  /// projet : la boîte s'animait encore, et son champ lisait un contrôleur
  /// détruit.
  final TextEditingController _kilometrage = TextEditingController();

  int? _distanceKm;
  CheckTemplate? _liste;
  final Map<String, String> _reponses = {};
  String _reference = '';

  VehicleCheck? _resultat;
  bool _chargement = false;
  bool _envoi = false;
  String? _erreur;

  /// Un contrôle terminé dont l'envoi n'est pas passé.
  bool _enAttente = false;

  CheckDraftStore get _brouillons => ref.read(checkDraftStoreProvider);

  @override
  void initState() {
    super.initState();
    _reprendre();
  }

  @override
  void dispose() {
    _kilometrage.dispose();
    super.dispose();
  }

  // ── Reprise : brouillon et envoi en attente ─────────────────────

  /// Au premier affichage : rejouer un envoi resté en attente, sinon reprendre
  /// un brouillon.
  ///
  /// L'envoi passe avant le brouillon : un contrôle terminé qui n'est pas parti
  /// est plus précieux qu'un contrôle à moitié rempli, et le serveur reconnaît
  /// sa clé — un rejeu ne crée donc jamais un second passage.
  Future<void> _reprendre() async {
    final enAttente = await _brouillons.lireEnAttente(widget.ownedVehicleId);

    if (enAttente != null) {
      if (!mounted) return;
      setState(() => _enAttente = true);
      // Silencieux : c'est une reprise que personne n'a demandée. La bannière de
      // l'étape de départ dit déjà que le contrôle attend ; y ajouter un message
      // d'erreur le dirait deux fois.
      await _envoyerCharge(enAttente, silencieux: true);
      if (_resultat != null) return;
    }

    final brouillon = await _brouillons.lireBrouillon(widget.ownedVehicleId);
    if (!mounted || brouillon == null || brouillon.estVide) {
      _preremplirKilometrage();
      return;
    }

    setState(() {
      _distanceKm = brouillon.tripDistanceKm;
      _reponses.addAll(brouillon.answers);
      _kilometrage.text = brouillon.mileageKm?.toString() ?? '';
    });

    if (_distanceKm != null) {
      await _composer(reprise: true);
    }
  }

  void _preremplirKilometrage() {
    final connu = widget.vehicle?.mileageKm;
    if (connu != null && _kilometrage.text.isEmpty) {
      _kilometrage.text = connu.toString();
    }
  }

  Future<void> _sauverBrouillon() async {
    await _brouillons.enregistrerBrouillon(
      widget.ownedVehicleId,
      CheckDraft(
        tripDistanceKm: _distanceKm,
        mileageKm: _kilometrageSaisi,
        answers: Map.of(_reponses),
        savedAt: DateTime.now(),
      ),
    );
  }

  int? get _kilometrageSaisi => int.tryParse(_kilometrage.text.trim());

  // ── Composer la liste ───────────────────────────────────────────

  Future<void> _composer({bool reprise = false}) async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final liste = await ref.read(garageRepositoryProvider).checkTemplate(
            widget.ownedVehicleId,
            tripDistanceKm: _distanceKm,
          );

      if (!mounted) return;

      setState(() {
        _liste = liste;
        _chargement = false;
        _etape = _Etape.liste;

        // Une clé par contrôle, stable d'un envoi à l'autre : c'est elle qui
        // rend un rejeu sans danger.
        if (_reference.isEmpty) _reference = _uuidV4();

        // Une réponse à un point qui n'est plus demandé ne compte plus. Sans cet
        // élagage, changer de distance après avoir répondu laisserait un
        // compteur à « 14/12 » et enverrait des réponses à des points que
        // l'écran n'a pas montrés.
        final demandes = liste.items.map((i) => i.code).toSet();
        _reponses.removeWhere((code, _) => !demandes.contains(code));

        // Le serveur propose un état pour ce qu'il sait déjà — une assurance
        // expirée, une vidange dépassée. On ne l'impose pas : une réponse déjà
        // donnée dans un brouillon garde la main.
        for (final item in liste.items) {
          if (item.prefillStatus != null && !_reponses.containsKey(item.code)) {
            _reponses[item.code] = item.prefillStatus!;
          }
        }
      });

      if (!reprise) _preremplirKilometrage();
      await _sauverBrouillon();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = messageFor(e);
      });
    }
  }

  // ── Envoyer ─────────────────────────────────────────────────────

  Map<String, dynamic> _charge() => {
    'client_reference': _reference,
    if (_distanceKm != null) 'trip_distance_km': _distanceKm,
    if (_kilometrageSaisi != null) 'mileage_km': _kilometrageSaisi,

    // La date du contrôle, et non celle de l'envoi : un contrôle rempli hier
    // soir dans une cour sans réseau part ce matin, et l'historique doit dire
    // hier soir. Sans elle, le serveur daterait le passage du moment où le
    // réseau est revenu.
    'performed_at': DateTime.now().toUtc().toIso8601String(),

    'answers': _reponses.entries
        .map((e) => {'item_code': e.key, 'status': e.value})
        .toList(),
  };

  Future<void> _envoyer() async {
    final charge = _charge();

    // Mise en attente AVANT l'envoi, pas après l'échec : si l'application est
    // tuée pendant la requête — ce qui arrive sur un téléphone à mémoire juste —
    // le contrôle est déjà à l'abri.
    await _brouillons.mettreEnAttente(widget.ownedVehicleId, charge);
    await _envoyerCharge(charge);
  }

  Future<void> _envoyerCharge(Map<String, dynamic> charge, {bool silencieux = false}) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      final resultat = await ref
          .read(garageRepositoryProvider)
          .submitCheck(widget.ownedVehicleId, charge);

      await _brouillons.effacerEnAttente(widget.ownedVehicleId);
      await _brouillons.effacerBrouillon(widget.ownedVehicleId);

      if (!mounted) return;

      setState(() {
        _resultat = resultat;
        _envoi = false;
        _enAttente = false;
        _etape = _Etape.verdict;
      });

      // Le kilométrage relevé a bougé côté serveur, et avec lui l'échéance de
      // vidange : la fiche du garage doit le refléter sans que l'utilisateur
      // ait à tirer la liste pour la rafraîchir.
      await ref.read(garageProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _enAttente = true;
        // « Une erreur est survenue. Réessayez. » serait ici un mensonge par
        // omission : le contrôle n'est pas perdu, et il n'y a rien à refaire.
        // Quelqu'un qui croit avoir perdu un quart d'heure de travail ne
        // recommence pas.
        _erreur = silencieux
            ? null
            : 'Envoi impossible pour le moment : ${messageFor(e)}\n'
                'Le contrôle est gardé sur ce téléphone et repartira dès que le réseau revient.';
      });
    }
  }

  // ── Construction ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final nom = widget.vehicle?.displayName ?? 'Mon véhicule';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _etape == _Etape.verdict ? 'Contrôle terminé' : 'Avant de partir',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          if (_etape == _Etape.liste && _liste != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_reponses.length}/${_liste!.items.length}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
        ],
      ),
      body: switch (_etape) {
        _Etape.depart => _Depart(
            nom: nom,
            distanceKm: _distanceKm,
            kilometrage: _kilometrage,
            chargement: _chargement,
            erreur: _erreur,
            enAttente: _enAttente,
            onDistance: (km) => setState(() => _distanceKm = km),
            onComposer: _composer,
          ),
        _Etape.liste => _Liste(
            liste: _liste!,
            distanceKm: _distanceKm,
            reponses: _reponses,
            envoi: _envoi,
            erreur: _erreur,
            onReponse: (code, etat) {
              setState(() => _reponses[code] = etat);
              _sauverBrouillon();
            },
            // Un brouillon repris ramène directement à la liste : sans ce
            // retour, le trajet choisi la veille serait définitif, et la liste
            // resterait composée pour un voyage qu'on ne fait plus.
            onModifierTrajet: () => setState(() => _etape = _Etape.depart),
            onTerminer: _envoyer,
          ),
        _Etape.verdict => _Verdict(
            resultat: _resultat!,
            total: _liste?.items.length,
            ownedVehicleId: widget.ownedVehicleId,
            vehicle: widget.vehicle,
          ),
      },
    );
  }
}

/// Un identifiant de contrôle, au format que le serveur valide.
///
/// Écrit à la main plutôt qu'avec un paquet : c'est le seul endroit du projet
/// qui en a besoin, et une dépendance de plus se paie à chaque montée de version.
String _uuidV4() {
  final alea = Random.secure();
  final octets = List<int>.generate(16, (_) => alea.nextInt(256));
  octets[6] = (octets[6] & 0x0f) | 0x40; // version 4
  octets[8] = (octets[8] & 0x3f) | 0x80; // variante
  String bloc(int debut, int fin) => octets
      .sublist(debut, fin)
      .map((o) => o.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${bloc(0, 4)}-${bloc(4, 6)}-${bloc(6, 8)}-${bloc(8, 10)}-${bloc(10, 16)}';
}

// ── Étape 1 : le départ ───────────────────────────────────────────────

class _Depart extends StatelessWidget {
  final String nom;
  final int? distanceKm;
  final TextEditingController kilometrage;
  final bool chargement;
  final String? erreur;
  final bool enAttente;
  final ValueChanged<int?> onDistance;
  final VoidCallback onComposer;

  const _Depart({
    required this.nom,
    required this.distanceKm,
    required this.kilometrage,
    required this.chargement,
    required this.erreur,
    required this.enAttente,
    required this.onDistance,
    required this.onComposer,
  });

  /// Des distances qui parlent plutôt que des paliers ronds : « la ville » et
  /// « une autre région » se choisissent sans calculer.
  static const List<({String libelle, int km})> _trajets = [
    (libelle: 'En ville', km: 30),
    (libelle: 'Une centaine de km', km: 100),
    (libelle: 'Une autre ville', km: 250),
    (libelle: 'Une autre région', km: 400),
    (libelle: 'Un autre pays', km: 800),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (enAttente)
          Card(
            color: cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, color: cs.onErrorContainer, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Un contrôle rempli n'est pas encore parti. Il repartira dès que le réseau revient.",
                      style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),

        Text(nom, style: tt.titleMedium),
        const SizedBox(height: 4),
        Text(
          'La liste dépend du trajet : un aller-retour en ville et une descente de quatre cents kilomètres ne demandent pas la même chose.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 20),

        Text('Où vas-tu ?', style: tt.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final trajet in _trajets)
              ChoiceChip(
                label: Text('${trajet.libelle} · ${trajet.km} km'),
                selected: distanceKm == trajet.km,
                onSelected: (_) => onDistance(trajet.km),
              ),
          ],
        ),

        const SizedBox(height: 24),
        Text('Kilométrage au compteur', style: tt.titleSmall),
        const SizedBox(height: 4),
        Text(
          "Tu es devant le tableau de bord : c'est le moment. Sans ce relevé, le rappel de vidange ne peut pas partir.",
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: kilometrage,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixText: 'km',
            isDense: true,
          ),
        ),

        if (erreur != null) ...[
          const SizedBox(height: 16),
          Text(erreur!, style: tt.bodySmall?.copyWith(color: cs.error)),
        ],

        const SizedBox(height: 28),
        FilledButton.icon(
          // Sans distance, la liste ne serait pas composée mais générique :
          // le bouton attend donc ce choix.
          onPressed: distanceKm == null || chargement ? null : onComposer,
          icon: chargement
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.checklist_rtl),
          label: Text(chargement ? 'Composition…' : 'Voir ce qu\'il faut vérifier'),
        ),
      ],
    );
  }
}

// ── Étape 2 : la liste ────────────────────────────────────────────────

class _Liste extends StatelessWidget {
  final CheckTemplate liste;
  final int? distanceKm;
  final Map<String, String> reponses;
  final bool envoi;
  final String? erreur;
  final void Function(String code, String etat) onReponse;
  final VoidCallback onModifierTrajet;
  final VoidCallback onTerminer;

  const _Liste({
    required this.liste,
    required this.distanceKm,
    required this.reponses,
    required this.envoi,
    required this.erreur,
    required this.onReponse,
    required this.onModifierTrajet,
    required this.onTerminer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final groupes = liste.parCategorie;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text(
                '${liste.items.length} points pour ce véhicule et ce trajet. Ils ne sont pas les mêmes pour tous : chacun dit pourquoi il est là.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onModifierTrajet,
                  icon: const Icon(Icons.edit_road, size: 16),
                  label: Text(distanceKm == null
                      ? 'Choisir le trajet'
                      : 'Trajet de $distanceKm km · Modifier'),
                ),
              ),
              const SizedBox(height: 8),

              for (final entree in groupes.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Text(
                    entree.key.toUpperCase(),
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                for (final item in entree.value)
                  _PointDeControle(
                    item: item,
                    etat: reponses[item.code],
                    onEtat: (etat) => onReponse(item.code, etat),
                  ),
                const SizedBox(height: 12),
              ],

              if (erreur != null)
                Card(
                  color: cs.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      erreur!,
                      style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Le bouton reste visible : sur une liste de quinze points, remonter
        // chercher le bouton en bas de page est ce qui fait abandonner.
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton.icon(
            onPressed: reponses.isEmpty || envoi ? null : onTerminer,
            icon: envoi
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all),
            label: Text(envoi ? 'Enregistrement…' : 'Terminer le contrôle'),
          ),
        ),
      ],
    );
  }
}

class _PointDeControle extends StatelessWidget {
  final CheckItem item;
  final String? etat;
  final ValueChanged<String> onEtat;

  const _PointDeControle({
    required this.item,
    required this.etat,
    required this.onEtat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(item.title, style: tt.titleSmall)),
                if (item.estBloquant)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Icon(Icons.priority_high, size: 16, color: cs.error),
                  ),
              ],
            ),

            if (item.help != null) ...[
              const SizedBox(height: 4),
              Text(
                item.help!,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],

            // La raison est ce qui distingue une liste composée d'une liste
            // générique : « 190 000 km au compteur » convainc d'ouvrir le capot.
            if (item.reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final raison in item.reasons)
                    _Etiquette(texte: raison, couleur: cs.secondaryContainer,
                        surCouleur: cs.onSecondaryContainer),
                ],
              ),
            ],

            if (item.prefillReason != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    item.prefillStatus == 'bad'
                        ? Icons.error_outline
                        : Icons.info_outline,
                    size: 15,
                    color: item.prefillStatus == 'bad' ? cs.error : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.prefillReason!,
                      style: tt.bodySmall?.copyWith(
                        color: item.prefillStatus == 'bad'
                            ? cs.error
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity(horizontal: -2, vertical: -2),
                ),
                segments: const [
                  ButtonSegment(value: 'ok', label: Text('Rien à signaler')),
                  ButtonSegment(value: 'watch', label: Text('À surveiller')),
                  ButtonSegment(value: 'bad', label: Text('Défaut')),
                ],
                selected: etat == null ? const <String>{} : {etat!},
                emptySelectionAllowed: true,
                onSelectionChanged: (choix) {
                  if (choix.isNotEmpty) onEtat(choix.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiquette extends StatelessWidget {
  final String texte;
  final Color couleur;
  final Color surCouleur;

  const _Etiquette({
    required this.texte,
    required this.couleur,
    required this.surCouleur,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: couleur,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      texte,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: surCouleur),
    ),
  );
}

// ── Étape 3 : le verdict ──────────────────────────────────────────────

class _Verdict extends StatelessWidget {
  final VehicleCheck resultat;
  final int? total;
  final int ownedVehicleId;
  final OwnedVehicle? vehicle;

  const _Verdict({
    required this.resultat,
    required this.total,
    required this.ownedVehicleId,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bloquants = resultat.toFix.where((p) => p.blocking).toList();
    final aSurveiller = resultat.toFix.where((p) => !p.blocking).toList();

    final nonVerifies = total == null ? 0 : total! - resultat.checkedCount;

    final (Color fond, Color surFond, IconData icone) = switch (resultat.verdict.value) {
      'blocked' => (cs.errorContainer, cs.onErrorContainer, Icons.report_outlined),
      'clear' => (cs.secondaryContainer, cs.onSecondaryContainer, Icons.check_circle_outline),
      _ => (cs.tertiaryContainer, cs.onTertiaryContainer, Icons.info_outline),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: fond,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icone, color: surFond),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Le libellé et la phrase viennent du serveur : c'est là
                      // que la formulation est tenue. L'application n'a rien
                      // constaté, elle a posé des questions — elle ne peut donc
                      // pas dire que le véhicule est en bon état.
                      Text(
                        resultat.verdict.label,
                        style: tt.titleMedium?.copyWith(color: surFond),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resultat.verdict.detail,
                        style: tt.bodySmall?.copyWith(color: surFond),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (nonVerifies > 0) ...[
          const SizedBox(height: 8),
          Text(
            nonVerifies == 1
                ? "1 point n'a pas été vérifié."
                : "$nonVerifies points n'ont pas été vérifiés.",
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],

        if (resultat.mileageKm != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.speed, size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Compteur relevé : ${resultat.mileageKm} km',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],

        if (bloquants.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Titre(texte: 'À régler avant de partir', couleur: cs.error),
          for (final point in bloquants)
            _PointAReprendre(
              point: point,
              ownedVehicleId: ownedVehicleId,
              vehicle: vehicle,
            ),
        ],

        if (aSurveiller.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Titre(texte: 'Peut attendre le retour', couleur: cs.primary),
          for (final point in aSurveiller)
            _PointAReprendre(
              point: point,
              ownedVehicleId: ownedVehicleId,
              vehicle: vehicle,
            ),
        ],

        const SizedBox(height: 28),
        FilledButton(
          onPressed: () => context.pop(),
          child: const Text('Revenir au garage'),
        ),
      ],
    );
  }
}

class _Titre extends StatelessWidget {
  final String texte;
  final Color couleur;

  const _Titre({required this.texte, required this.couleur});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      texte.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: couleur,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _PointAReprendre extends StatelessWidget {
  final CheckPointToFix point;
  final int ownedVehicleId;
  final OwnedVehicle? vehicle;

  const _PointAReprendre({
    required this.point,
    required this.ownedVehicleId,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(point.title, style: tt.titleSmall),
            if (point.help != null) ...[
              const SizedBox(height: 4),
              Text(
                point.help!,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],

            // Un verdict qui compte sans dire quoi faire s'arrête à mi-chemin :
            // la catégorie est filtrée, pour ne pas ouvrir cinq cents pièces.
            if (point.partCategoryId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.push(
                    '/garage/$ownedVehicleId/parts?category_id=${point.partCategoryId}'
                    '&category_label=${Uri.encodeComponent(point.categoryLabel)}',
                    extra: vehicle,
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Voir les pièces'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
