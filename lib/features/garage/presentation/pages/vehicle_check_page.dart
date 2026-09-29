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

/// Le contrôle d'un véhicule du garage, quel qu'en soit le motif.
///
/// Un seul point d'entrée, et le choix du motif au premier écran : avant un
/// voyage, ou à l'entrée d'une saison. Cinq boutons « faire un contrôle » sur
/// une fiche de garage, c'est aucun bouton utilisé.
///
/// Cette page s'est d'abord appelée « avant voyage », et le bouton qui y menait
/// aussi. Le contrôle de saison s'y est ajouté sans que le nom suive : le
/// contenant portait alors le nom de l'un de ses contenus, et l'autre avait
/// l'air d'y être par erreur.
///
/// Trois étapes, et l'ordre a une raison. On demande d'abord le motif, puis —
/// pour un voyage seulement — la distance, qui change la liste : la
/// climatisation et les provisions n'apparaissent qu'au-delà d'un certain
/// trajet, et une vidange à deux cents kilomètres de son terme devient un défaut
/// si le trajet en fait trois cent soixante. Le compteur, lui, est demandé dans
/// tous les cas : c'est la seule occasion où quelqu'un se trouve devant son
/// tableau de bord avec l'application ouverte, et sans ce relevé le rappel de
/// vidange ne part jamais.
///
/// Vient ensuite la liste, composée par le serveur pour ce véhicule-là, chaque
/// point portant la raison chiffrée qui l'a fait apparaître. Puis le verdict, en
/// deux blocs : ce qui doit être réglé, et ce qui peut attendre.
///
/// Rien n'est calculé ici. Ni la liste, ni le verdict, ni les seuils : un seuil
/// recopié côté application finit par contredire le serveur, et le propriétaire
/// voit alors deux vérités pour une même voiture. C'est la règle que le projet
/// s'est déjà donnée pour les échéances.
class VehicleCheckPage extends ConsumerStatefulWidget {
  final int ownedVehicleId;

  /// Nul après un lien profond ou un rechargement à chaud : la page doit
  /// fonctionner sans, comme l'écran des pièces compatibles.
  final OwnedVehicle? vehicle;

  const VehicleCheckPage({
    super.key,
    required this.ownedVehicleId,
    this.vehicle,
  });

  @override
  ConsumerState<VehicleCheckPage> createState() => _VehicleCheckPageState();
}

enum _Etape { depart, liste, verdict }

class _VehicleCheckPageState extends ConsumerState<VehicleCheckPage> {
  _Etape _etape = _Etape.depart;

  /// Le contrôleur appartient à l'état, et se libère avec lui.
  ///
  /// Un contrôleur créé à l'extérieur du widget et libéré dès qu'une boîte de
  /// dialogue rendait la main a déjà valu un écran rouge intermittent à ce
  /// projet : la boîte s'animait encore, et son champ lisait un contrôleur
  /// détruit.
  final TextEditingController _kilometrage = TextEditingController();

  /// `trip` ou `seasonal`. Le défaut est le voyage : c'est le seul contrôle qui
  /// ait un déclencheur dans la vie réelle.
  String _motif = 'trip';

  /// Les contrôles que le serveur propose aujourd'hui. Le libellé du saisonnier
  /// dépend de la saison, donc du calendrier, qui n'est pas ici.
  List<CheckReasonOption> _types = const [];

  String _titre = 'Avant de partir';

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

  /// Le serveur a refusé la charge pour une raison que le réseau ne réglera
  /// pas : la garder en attente la ferait rejouer à chaque ouverture.
  bool _refusDefinitif = false;

  /// Le nombre de points que la liste comptait, y compris quand l'écran arrive
  /// au verdict par un renvoi, sans avoir recomposé la liste.
  int? _totalPoints;

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
    // Les deux se lisent AVANT toute tentative d'envoi. Un renvoi qui aboutit
    // mène droit au verdict sans que la liste ait été recomposée : si le nombre
    // de points n'a pas été relu d'abord, le même contrôle annonce moins de
    // choses selon le chemin par lequel on arrive à son verdict.
    final brouillon = await _brouillons.lireBrouillon(widget.ownedVehicleId);
    final enAttente = await _brouillons.lireEnAttente(widget.ownedVehicleId);

    if (!mounted) return;

    if (brouillon != null) {
      _totalPoints = brouillon.itemsCount;

      // La clé du contrôle en cours est relue avec ses réponses, et non
      // refabriquée. Sans cela, une relance de l'application en produisait une
      // neuve : si le premier envoi avait atteint le serveur sans que la réponse
      // revienne, un second « Terminer » enregistrait un deuxième passage — la
      // chose même que la clé existe pour empêcher.
      final cle = brouillon.clientReference;
      if (cle != null && cle.isNotEmpty) _reference = cle;
    }

    if (enAttente != null) {
      setState(() => _enAttente = true);
      await _envoyerCharge(enAttente);
      if (_resultat != null) return;
    }

    if (!mounted || brouillon == null || brouillon.estVide) {
      _preremplirKilometrage();
      await _chargerTypes();
      return;
    }

    setState(() {
      _distanceKm = brouillon.tripDistanceKm;
      _motif = brouillon.reason ?? 'trip';
      _reponses.addAll(brouillon.answers);
      _kilometrage.text = brouillon.mileageKm?.toString() ?? '';
    });

    // Après un refus définitif, le kilométrage est peut-être la cause : on reste
    // à l'étape de départ, où le champ est atteignable, au lieu de rouvrir une
    // liste dont le bouton renverra la même charge refusée.
    if (!_refusDefinitif && (_distanceKm != null || _motif != 'trip')) {
      await _composer(reprise: true);
    } else {
      await _chargerTypes();
    }
  }

  /// Demande au serveur quels contrôles ont un sens aujourd'hui.
  ///
  /// Sans réseau, on garde le choix par défaut plutôt que de bloquer l'écran :
  /// le contrôle avant voyage est le seul qui ne dépende d'aucun calendrier, et
  /// c'est celui qu'on vient faire neuf fois sur dix.
  Future<void> _chargerTypes() async {
    if (_types.isNotEmpty) return;

    try {
      final modele = await ref
          .read(garageRepositoryProvider)
          .checkTemplate(widget.ownedVehicleId);

      if (!mounted) return;

      setState(() {
        _types = modele.availableReasons;
        if (_kilometrage.text.isEmpty && modele.mileageKm != null) {
          _kilometrage.text = modele.mileageKm.toString();
        }
      });
    } catch (_) {
      // Silencieux : rien n'est perdu, et l'écran reste utilisable.
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
        clientReference: _reference.isEmpty ? null : _reference,
        itemsCount: _liste?.items.length ?? _totalPoints,
        reason: _motif,
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
            tripDistanceKm: _motif == 'trip' ? _distanceKm : null,
            reason: _motif,
          );

      if (!mounted) return;

      setState(() {
        _liste = liste;
        _titre = liste.title;
        if (liste.availableReasons.isNotEmpty) _types = liste.availableReasons;
        _totalPoints = liste.items.length;
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
    'reason': _motif,
    if (_motif == 'trip' && _distanceKm != null) 'trip_distance_km': _distanceKm,
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

  Future<void> _envoyerCharge(Map<String, dynamic> charge) async {
    setState(() {
      _envoi = true;
      _erreur = null;
      _refusDefinitif = false;
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
        _refusDefinitif = false;
        _etape = _Etape.verdict;
      });

      // Le kilométrage relevé a bougé côté serveur, et avec lui l'échéance de
      // vidange : la fiche du garage doit le refléter sans que l'utilisateur
      // ait à tirer la liste pour la rafraîchir.
      await ref.read(garageProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;

      // Un refus du serveur ne passera jamais, quel que soit le réseau : le
      // garder en attente le ferait rejouer à chaque ouverture de l'écran, avec
      // un message promettant un envoi qui n'aboutira pas. Seule une panne de
      // transport mérite d'être gardée.
      final definitif = e is ApiException &&
          !e.isNetworkFailure &&
          (e.isValidation || e.isForbidden || e.isNotFound);

      if (definitif) {
        await _brouillons.effacerEnAttente(widget.ownedVehicleId);
      }

      if (!mounted) return;

      setState(() {
        _envoi = false;
        _enAttente = !definitif;
        _refusDefinitif = definitif;

        // « Une erreur est survenue. Réessayez. » serait ici un mensonge par
        // omission : le contrôle n'est pas perdu, et il n'y a rien à refaire.
        // Quelqu'un qui croit avoir perdu un quart d'heure de travail ne
        // recommence pas.
        _erreur = definitif
            ? "Le contrôle n'a pas été accepté : ${messageFor(e)}\n"
                'Corrige la saisie, puis termine à nouveau.'
            : 'Envoi impossible pour le moment : ${messageFor(e)}\n'
                'Le contrôle est gardé sur ce téléphone et repartira dès que le réseau revient.';

        // Le champ du kilométrage n'est atteignable qu'à l'étape de départ, et
        // c'est la saisie la plus probablement en cause.
        if (definitif) _etape = _Etape.depart;
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
          // Le titre suit l'étape. À l'étape de choix il reste neutre : il y
          // affichait le titre du contrôle précédemment composé, donc
          // « Contrôle d'hivernage » au moment même où l'on venait en changer.
          // Une fois la liste composée, le titre vient du serveur — il dépend
          // de la saison, donc d'un calendrier qui n'est pas découpé ici.
          switch (_etape) {
            _Etape.depart => 'Contrôler mon véhicule',
            _Etape.liste => _titre,
            _Etape.verdict => 'Contrôle terminé',
          },
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
            types: _types,
            motif: _motif,
            onMotif: (motif) => setState(() => _motif = motif),
            distanceKm: _distanceKm,
            kilometrage: _kilometrage,
            chargement: _chargement,
            erreur: _erreur,
            // La bannière ne s'affiche que faute de message : les deux disent la
            // même chose, et un écran qui se répète se lit moins bien qu'un
            // écran qui dit une fois.
            enAttente: _enAttente && _erreur == null,
            onDistance: (km) => setState(() => _distanceKm = km),
            onComposer: _composer,
          ),
        _Etape.liste => _Liste(
            liste: _liste!,
            motif: _motif,
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
            total: _totalPoints,
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
  final List<CheckReasonOption> types;
  final String motif;
  final ValueChanged<String> onMotif;
  final int? distanceKm;
  final TextEditingController kilometrage;
  final bool chargement;
  final String? erreur;
  final bool enAttente;
  final ValueChanged<int?> onDistance;
  final VoidCallback onComposer;

  const _Depart({
    required this.nom,
    required this.types,
    required this.motif,
    required this.onMotif,
    required this.distanceKm,
    required this.kilometrage,
    required this.chargement,
    required this.erreur,
    required this.enAttente,
    required this.onDistance,
    required this.onComposer,
  });

  bool get _voyage => motif == 'trip';

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
        const SizedBox(height: 16),

        // ── Quel contrôle ? ───────────────────────────────────────
        //
        // Un seul point d'entrée, et le choix ici plutôt que deux boutons sur
        // la fiche du garage : cinq boutons « faire un contrôle » sur une
        // carte, et aucun n'est utilisé.
        if (types.length > 1) ...[
          for (final type in types)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChoixMotif(
                type: type,
                choisi: type.value == motif,
                onChoisir: () => onMotif(type.value),
              ),
            ),
          const SizedBox(height: 12),
        ],

        // ── La distance, pour un voyage seulement ─────────────────
        //
        // Un contrôle de saison ne va nulle part : lui demander une distance
        // n'aurait aucun sens, et le bouton ne l'attend donc pas.
        if (_voyage) ...[
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
        ],

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
          // Sept chiffres : le serveur refuse au-delà de deux millions de
          // kilomètres, et un chiffre de trop faisait partir une charge que le
          // serveur refusait sans que la cause soit évidente.
          maxLength: 7,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixText: 'km',
            isDense: true,
            counterText: '',
          ),
        ),

        if (erreur != null) ...[
          const SizedBox(height: 16),
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

        const SizedBox(height: 28),
        FilledButton.icon(
          // Sans distance, la liste d'un voyage ne serait pas composée mais
          // générique : le bouton attend donc ce choix. Un contrôle de saison,
          // lui, tient sa composition de la saison.
          onPressed: (_voyage && distanceKm == null) || chargement ? null : onComposer,
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
  final String motif;
  final int? distanceKm;
  final Map<String, String> reponses;
  final bool envoi;
  final String? erreur;
  final void Function(String code, String etat) onReponse;
  final VoidCallback onModifierTrajet;
  final VoidCallback onTerminer;

  const _Liste({
    required this.liste,
    required this.motif,
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
              // En tête, et non en fin de liste : sur quinze points, un message
              // rendu après le dernier ne se voit pas — l'échec d'envoi passait
              // donc inaperçu, alors que c'est le moment où il compte le plus.
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

              // La phrase suit le motif : un contrôle de saison n'a pas de
              // trajet, et ses points ne portent pas de raison individuelle —
              // c'est la saison qui les commande, et le titre l'annonce déjà.
              Text(
                motif == 'trip'
                    ? '${liste.items.length} points pour ce véhicule et ce trajet. Ils ne sont pas les mêmes pour tous : chacun dit pourquoi il est là.'
                    : '${liste.items.length} points à vérifier une fois avant la saison, pas à chaque trajet.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onModifierTrajet,
                  icon: Icon(
                    motif == 'trip' ? Icons.edit_road : Icons.swap_horiz,
                    size: 16,
                  ),
                  label: Text(switch ((motif, distanceKm)) {
                    ('trip', null) => 'Choisir le trajet',
                    ('trip', final km) => 'Trajet de $km km · Modifier',
                    _ => 'Changer de contrôle',
                  }),
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
                // Trois segments sur la largeur d'un téléphone laissent environ
                // cent points à chacun : « Rien à signaler » y passait à la
                // ligne et se faisait rogner en plein mot. Les libellés tiennent
                // désormais sur une ligne, et l'ellipse rattrape le jour où une
                // police plus large ou un texte agrandi les dépasserait — un
                // libellé tronqué proprement se lit encore, un libellé coupé en
                // deux ne se lit plus.
                segments: const [
                  ButtonSegment(value: 'ok', label: _Segment('Correct')),
                  ButtonSegment(value: 'watch', label: _Segment('À surveiller')),
                  ButtonSegment(value: 'bad', label: _Segment('Défaut')),
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

/// Une carte de choix du type de contrôle.
///
/// Le libellé et la phrase viennent du serveur — « Contrôle d'hivernage », « La
/// poussière et la chaleur : ce qui compte est de respirer et de refroidir » —
/// parce qu'ils dépendent de la saison en cours.
class _ChoixMotif extends StatelessWidget {
  final CheckReasonOption type;
  final bool choisi;
  final VoidCallback onChoisir;

  const _ChoixMotif({
    required this.type,
    required this.choisi,
    required this.onChoisir,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onChoisir,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: choisi ? cs.secondaryContainer : null,
          border: Border.all(
            color: choisi ? cs.secondary : cs.outlineVariant,
            width: choisi ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              choisi ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: choisi ? cs.secondary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: tt.titleSmall?.copyWith(
                      color: choisi ? cs.onSecondaryContainer : null,
                    ),
                  ),
                  if (type.hint.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      type.hint,
                      style: tt.bodySmall?.copyWith(
                        color: choisi ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « 345 900 » plutôt que « 345900 » : un compteur se lit par tranches de trois,
/// comme partout ailleurs dans l'application.
String _kilometres(int valeur) {
  final chiffres = valeur.toString();
  final tampon = StringBuffer();

  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) tampon.write(' ');
    tampon.write(chiffres[i]);
  }

  return tampon.toString();
}

/// Le libellé d'un segment : une ligne, quitte à être tronqué par une ellipse.
class _Segment extends StatelessWidget {
  final String texte;
  const _Segment(this.texte);

  @override
  Widget build(BuildContext context) => Text(
    texte,
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
  );
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
                'Compteur relevé : ${_kilometres(resultat.mileageKm!)} km',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],

        if (bloquants.isNotEmpty) ...[
          const SizedBox(height: 20),
          // « À régler » et non « À régler avant de partir » : la carte du
          // verdict vient de le dire, et l'écran le répétait trois fois.
          _Titre(texte: 'À régler', couleur: cs.error),
          for (final point in bloquants)
            _PointAReprendre(
              point: point,
              ownedVehicleId: ownedVehicleId,
              vehicle: vehicle,
            ),
        ],

        if (aSurveiller.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Titre(texte: 'Peut attendre', couleur: cs.primary),
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
