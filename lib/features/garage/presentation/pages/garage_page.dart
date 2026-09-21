import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';
import '../widgets/consumption_tile.dart';
import '../widgets/engine_prompt.dart';
import '../widgets/mileage_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/widgets/notification_icon_button.dart';
import '../../../../core/api/api_exception.dart';

class GaragePage extends ConsumerWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Invalider garageProvider dès que le client se connecte, pour ne pas
    // rester bloqué sur l'erreur 401 envoyée avant l'obtention du token.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isClient && !(prev?.isClient ?? false)) {
        ref.invalidate(garageProvider);
      }
    });

    // ── Staff → profil staff ─────────────────────────────────────────
    if (auth.isStaff) return _StaffProfilePage(auth: auth);

    // ── Non connecté → CTA connexion ─────────────────────────────────
    if (!auth.isClient) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.garage_outlined, size: 72,
                  color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text('Connectez-vous pour accéder à votre garage',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Retrouvez rapidement les pièces\ncompatibles avec vos véhicules.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login),
                label: const Text('Se connecter / S\'inscrire'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Client connecté → garage ──────────────────────────────────────
    // garageProvider est watché ICI SEULEMENT, après confirmation auth.isClient,
    // pour ne jamais déclencher GET /my/vehicles sans token Firebase.
    final garageAsync = ref.watch(garageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon garage'),
        centerTitle: false,
        actions: [
          const NotificationIconButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(garageProvider.notifier).refresh(),
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              child: Text(
                auth.displayName.isNotEmpty
                    ? auth.displayName[0].toUpperCase()
                    : 'C',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            tooltip: 'Mon compte',
            onPressed: () => _showAccountSheet(context, ref, auth),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/garage/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un véhicule'),
      ),

      body: garageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          error: messageFor(e),
          onRetry: () => ref.read(garageProvider.notifier).refresh(),
        ),
        data: (vehicles) => vehicles.isEmpty
            ? _EmptyGarage(onAdd: () => context.push('/garage/add'))
            : _VehicleList(vehicles: vehicles),
      ),
    );
  }

  void _showAccountSheet(BuildContext context, WidgetRef ref, AuthState auth) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                child: Text(
                  auth.displayName.isNotEmpty
                      ? auth.displayName[0].toUpperCase()
                      : 'C',
                ),
              ),
              title: Text(auth.displayName),
              subtitle: Text(auth.firebaseUser?.email ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Se déconnecter'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vous êtes déconnecté.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
                ref.read(authProvider.notifier).signOut();
              },
            ),

            // La suppression de compte doit être atteignable depuis
            // l'application : Google Play l'exige de toute application qui
            // permet d'en créer un, et un courriel au support ne suffit pas.
            //
            // Le rouge est réservé à cette ligne-là. « Se déconnecter » le
            // portait aussi, alors qu'elle se défait d'un geste : deux entrées
            // voisines de la même couleur, dont une seule est irréversible,
            // c'est une invitation à se tromper.
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Supprimer mon compte',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmerSuppression(context, ref, auth);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Demande confirmation, puis supprime le compte.
  ///
  /// La confirmation exige de saisir son adresse : un simple bouton
  /// « Confirmer » se tape par réflexe, et ce geste-ci ne se rattrape pas —
  /// les véhicules, leurs échéances et l'historique partent avec le compte.
  /// Recopier son adresse oblige à lire ce qu'on est en train de faire.
  Future<void> _confirmerSuppression(
    BuildContext context,
    WidgetRef ref,
    AuthState auth,
  ) async {
    final email = auth.firebaseUser?.email ?? '';

    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => _SuppressionDialog(email: email),
    );

    if (confirme != true || !context.mounted) return;

    final erreur = await ref.read(authProvider.notifier).deleteAccount();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erreur ?? 'Votre compte et vos données ont été supprimés.'),
        backgroundColor:
            erreur != null ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

/// Confirmation de suppression de compte.
///
/// Énumère ce qui disparaît plutôt que de demander « êtes-vous sûr ? » : la
/// question ne renseigne sur rien, la liste si.
class _SuppressionDialog extends StatefulWidget {
  const _SuppressionDialog({required this.email});

  final String email;

  @override
  State<_SuppressionDialog> createState() => _SuppressionDialogState();
}

class _SuppressionDialogState extends State<_SuppressionDialog> {
  final _saisie = TextEditingController();

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  bool get _correspond =>
      _saisie.text.trim().toLowerCase() == widget.email.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Supprimer mon compte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seront supprimés définitivement :'),
          const SizedBox(height: 8),
          const Text(
            '• vos véhicules et leurs échéances\n'
            '• vos demandes de recherche\n'
            '• vos notifications\n'
            '• votre compte de connexion',
          ),
          const SizedBox(height: 12),
          Text(
            'Les factures des commandes déjà honorées sont conservées, '
            'la comptabilité l\'impose.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text('Pour confirmer, saisissez ${widget.email} :'),
          const SizedBox(height: 8),
          TextField(
            controller: _saisie,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _correspond ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: const Text('Supprimer définitivement'),
        ),
      ],
    );
  }
}

// ── Liste des véhicules ───────────────────────────────────────────────

class _VehicleList extends ConsumerWidget {
  final List<OwnedVehicle> vehicles;
  const _VehicleList({required this.vehicles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: vehicles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _VehicleCard(vehicle: vehicles[i]),
    );
  }
}

// ── Carte véhicule ────────────────────────────────────────────────────

class _VehicleCard extends ConsumerWidget {
  final OwnedVehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final id = vehicle.identity;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──────────────────────────────────────────────
          ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(
                vehicle.displayName[0].toUpperCase(),
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              vehicle.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${id.fullName} · ${vehicle.year}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _MoreMenu(vehicle: vehicle),
          ),

          // ── Détails ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (vehicle.plateNumber != null)
                  _InfoChip(Icons.badge_outlined, vehicle.plateNumber!),
                if (vehicle.mileageKm != null)
                  _InfoChip(Icons.speed, '${_fmt(vehicle.mileageKm!)} km'),
                if (id.engineType != null)
                  _InfoChip(Icons.local_gas_station_outlined, id.engineType!),
                if (id.color != null)
                  _InfoChip(Icons.palette_outlined, id.color!),
                if (vehicle.compatibilityReady)
                  Chip(
                    avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
                    label: const Text('Compatibilité précise',
                        style: TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // ── Échéances d'entretien ─────────────────────────────────
          //
          // Le bloc entier ouvre l'édition : c'est là que l'œil se pose quand
          // on veut corriger une date, plutôt que dans un menu contextuel.
          // Quand rien n'est suivi, l'état vide propose lui-même l'action.
          if (vehicle.deadlines.isNotEmpty)
            InkWell(
              onTap: () => _editDeadlines(context, ref, vehicle),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final d in vehicle.deadlines)
                      _DeadlineRow(deadline: d),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _editDeadlines(context, ref, vehicle),
                  icon: const Icon(Icons.notifications_none, size: 18),
                  label: const Text('Suivre mes échéances'),
                ),
              ),
            ),

          // ── Consommation ──────────────────────────────────────────
          //
          // La cote officielle du moteur choisi, ou l'invitation à le
          // choisir. Elle se lit avec les échéances : c'est la même
          // question — ce que cette voiture coûte à faire rouler.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: ConsumptionTile(vehicle: vehicle),
          ),

          // ── Motorisation manquante ────────────────────────────────
          //
          // Juste au-dessus du bouton qu'elle rend inopérant : la liste des
          // pièces compatibles s'ouvrirait vide, sans rien dire.
          if (!vehicle.compatibilityReady)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: MissingEngineBanner(vehicle: vehicle),
            ),

          // ── Bouton pièces compatibles ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/garage/${vehicle.id}/parts',
                      extra: vehicle,
                    ),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('Pièces compatibles'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => showMileageDialog(context, ref, vehicle),
                  icon: const Icon(Icons.speed, size: 18),
                  label: const Text('Mettre à jour'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)} k';
    return n.toString();
  }

  Future<void> _editDeadlines(
    BuildContext context,
    WidgetRef ref,
    OwnedVehicle vehicle,
  ) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DeadlinesSheet(vehicle: vehicle),
    );

    if (result == null || !context.mounted) return;

    final error =
        await ref.read(garageProvider.notifier).updateVehicle(vehicle.id, result);

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

}

// ── Menu contextuel (éditer / supprimer) ─────────────────────────────

/// Saisie des échéances d'entretien.
///
/// Tout est facultatif : un propriétaire qui ne renseigne qu'une assurance ne
/// reçoit que ce rappel-là. Rien n'est donc obligatoire, et « Effacer » permet
/// de cesser d'être notifié sans supprimer le véhicule.
class _DeadlinesSheet extends StatefulWidget {
  final OwnedVehicle vehicle;
  const _DeadlinesSheet({required this.vehicle});

  @override
  State<_DeadlinesSheet> createState() => _DeadlinesSheetState();
}

class _DeadlinesSheetState extends State<_DeadlinesSheet> {
  late DateTime? _inspection = widget.vehicle.technicalInspectionExpiry;
  late DateTime? _insurance  = widget.vehicle.insuranceExpiry;
  late final _serviceKmCtrl = TextEditingController(
    text: widget.vehicle.lastServiceMileageKm?.toString() ?? '',
  );
  late int? _interval = widget.vehicle.serviceIntervalKm;

  /// Intervalles courants. « Aucun » coupe le suivi kilométrique.
  static const _intervals = [
    (value: null, label: 'Aucun'),
    (value: 5000, label: '5 000 km'),
    (value: 10000, label: '10 000 km'),
    (value: 15000, label: '15 000 km'),
  ];

  @override
  void dispose() {
    _serviceKmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(bool inspection) async {
    final now = DateTime.now();
    final current = inspection ? _inspection : _insurance;

    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      // Une date passée doit rester saisissable : un propriétaire dont la
      // visite est déjà expirée est précisément celui qu'il faut prévenir.
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );

    if (picked == null) return;
    setState(() => inspection ? _inspection = picked : _insurance = picked);
  }

  /// Ce qui empêche encore le rappel de vidange de fonctionner, ou `null` si
  /// tout est réuni. Le calcul côté serveur exige les trois valeurs : un
  /// intervalle, le kilométrage de la dernière vidange, et le kilométrage
  /// actuel du véhicule.
  String? _missingForService() {
    if (_interval == null) return null; // aucun suivi demandé

    final hasLastService = int.tryParse(_serviceKmCtrl.text) != null;
    final hasCurrent     = widget.vehicle.mileageKm != null;

    if (!hasLastService && !hasCurrent) {
      return 'Renseignez le kilométrage ci-dessus, ainsi que le kilométrage '
          'actuel du véhicule via « Mettre à jour ».';
    }
    if (!hasLastService) {
      return 'Renseignez le kilométrage de la dernière vidange ci-dessus.';
    }
    if (!hasCurrent) {
      return 'Renseignez le kilométrage actuel du véhicule via « Mettre à jour ».';
    }

    return null;
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Échéances d\'entretien',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Vous serez prévenu 30 jours avant, puis en cas de dépassement.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          _DateField(
            label: 'Visite technique',
            value: _inspection,
            format: _fmtDate,
            onPick: () => _pick(true),
            onClear: () => setState(() => _inspection = null),
          ),
          _DateField(
            label: 'Assurance',
            value: _insurance,
            format: _fmtDate,
            onPick: () => _pick(false),
            onClear: () => setState(() => _insurance = null),
          ),

          const SizedBox(height: 12),
          Text('Vidange',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            controller: _serviceKmCtrl,
            keyboardType: TextInputType.number,
            // Le message d'aide dépend de ce champ : il doit suivre la saisie,
            // pas attendre la fermeture de la feuille.
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Kilométrage de la dernière vidange',
              suffixText: 'km',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final i in _intervals)
                ChoiceChip(
                  label: Text(i.label),
                  selected: _interval == i.value,
                  onSelected: (_) => setState(() => _interval = i.value),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Le calcul exige trois valeurs. Choisir un intervalle sans les
          // autres ne produisait aucun rappel, et aucun message : l'utilisateur
          // croyait avoir activé un suivi inexistant. On dit donc précisément
          // ce qui manque, au moment où il fait le choix.
          Builder(builder: (context) {
            final missing = _missingForService();
            final warn = missing != null;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (warn) ...[
                  Icon(Icons.info_outline, size: 15, color: cs.error),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    missing ??
                        'Le rappel de vidange dépend du kilométrage que vous tenez à jour.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: warn ? cs.error : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context, {
                  'technical_inspection_expiry':
                      _inspection?.toIso8601String().substring(0, 10),
                  'insurance_expiry':
                      _insurance?.toIso8601String().substring(0, 10),
                  'last_service_mileage_km': int.tryParse(_serviceKmCtrl.text),
                  'service_interval_km': _interval,
                }),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Champ date en lecture seule : la saisie passe par le sélecteur, jamais au
/// clavier — un format tapé à la main est la première source d'erreur ici.
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String Function(DateTime) format;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.format,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.event, size: 18),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value == null ? label : '$label — ${format(value!)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (value != null)
          IconButton(
            tooltip: 'Effacer',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
          ),
      ],
    ),
  );
}

/// Une ligne d'échéance : visite technique, assurance ou vidange.
///
/// Trois états seulement — dépassée, proche, lointaine — parce qu'un
/// propriétaire n'a besoin que de savoir s'il doit agir maintenant, bientôt,
/// ou pas encore. Le rouge est réservé au dépassement : s'il servait aussi
/// pour « dans trois semaines », il cesserait d'alerter.
class _DeadlineRow extends StatelessWidget {
  final VehicleDeadline deadline;
  const _DeadlineRow({required this.deadline});

  /// En deçà, l'échéance mérite d'être signalée.
  static const _soonDays = 30;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final soon = deadline.daysLeft != null && deadline.daysLeft! <= _soonDays;

    final (color, icon) = deadline.overdue
        ? (cs.error, Icons.error_outline)
        : soon
            ? (const Color(0xFFB26A00), Icons.schedule)
            : (cs.onSurfaceVariant, Icons.check_circle_outline);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              deadline.label,
              // Le libelle suit la couleur du delai quand l'echeance est
              // depassee : « Assurance » en gris a cote d'un « Depassee de
              // 12 j » en rouge laissait croire a un detail de mise en forme.
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: deadline.overdue ? cs.error : cs.onSurfaceVariant,
                fontWeight:
                    deadline.overdue ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            deadline.summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight:
                  deadline.overdue || soon ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenu extends ConsumerWidget {
  final OwnedVehicle vehicle;
  const _MoreMenu({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) async {
        if (action == 'delete') {
          final confirm = await _confirmDelete(context, vehicle.displayName);
          if (confirm == true && context.mounted) {
            final error = await ref
                .read(garageProvider.notifier)
                .deleteVehicle(vehicle.id);
            if (error != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.red),
              );
            }
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Retirer du garage', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 0,
          ),
        ),
      ],
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Retirer du garage ?'),
          content: Text('$name sera retiré de votre garage. Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Retirer'),
            ),
          ],
        ),
      );
}

// ── Chip d'info ───────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 14),
    label: Text(label, style: const TextStyle(fontSize: 12)),
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
  );
}

// ── États vide / erreur ───────────────────────────────────────────────

class _EmptyGarage extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGarage({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.garage_outlined, size: 80,
            color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(
          'Votre garage est vide',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajoutez vos véhicules pour retrouver\nrapidement les pièces compatibles.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un véhicule'),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off, size: 48),
        const SizedBox(height: 12),
        Text(error, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    ),
  );
}

// ── Page profil staff ─────────────────────────────────────────────────

class _StaffProfilePage extends ConsumerWidget {
  final AuthState auth;
  const _StaffProfilePage({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs   = Theme.of(context).colorScheme;
    final user = auth.staffUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: cs.primaryContainer,
              child: Text(
                auth.displayName.isNotEmpty
                    ? auth.displayName[0].toUpperCase()
                    : 'S',
                style: TextStyle(
                  fontSize: 32,
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(auth.displayName,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          if (user?.email != null)
            Center(
              child: Text(user!.email,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: cs.outline)),
            ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: Text(user?.role ?? 'Staff'),
              avatar: const Icon(Icons.shield_outlined, size: 16),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Déconnexion
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vous êtes déconnecté.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
              ref.read(authProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Se déconnecter',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
