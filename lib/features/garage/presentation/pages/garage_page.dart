import '../widgets/engine_details.dart';
import '../garage_labels.dart';
import '../../../../core/l10n/reference_labels.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/owned_vehicle.dart';
import '../../data/models/vehicle_check.dart';
import '../providers/garage_provider.dart';
import '../widgets/consumption_tile.dart';
import '../widgets/engine_prompt.dart';
import '../widgets/mileage_dialog.dart';
import '../widgets/vehicle_card_header.dart';
import '../widgets/garage_action_tiles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/client_account_sheet.dart';
import '../../../notifications/presentation/widgets/notification_icon_button.dart';
import '../../../../core/api/api_exception.dart';
import '../../../private_sales/data/private_listing_repository.dart';

class GaragePage extends ConsumerWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // ── Staff → profil staff ─────────────────────────────────────────
    if (auth.isStaff) return _StaffProfilePage(auth: auth);

    // ── Non connecté → CTA connexion ─────────────────────────────────
    if (!auth.isClient) {
      return Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.garage_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).garageSignInGarageTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).garageSignInGarageBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: Text(
                    AppLocalizations.of(context).garageSignInOrRegister,
                  ),
                ),
              ],
            ),
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
        title: Text(AppLocalizations.of(context).garageTitle),
        centerTitle: false,
        actions: [
          const NotificationIconButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(garageProvider.notifier).refresh(),
            tooltip: AppLocalizations.of(context).garageRefreshAction,
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
            tooltip: AppLocalizations.of(context).garageAccountTitle,
            onPressed: () => afficherFeuilleCompteClient(context, auth),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/garage/add');
        },
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).garageAddVehicleAction),
      ),

      body: garageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          error: messageFor(e, l10n: AppLocalizations.of(context)),
          onRetry: () => ref.read(garageProvider.notifier).refresh(),
        ),
        data: (vehicles) => vehicles.isEmpty
            ? _EmptyGarage(onAdd: () => context.push('/garage/add'))
            : _VehicleList(vehicles: vehicles),
      ),
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
    final id = vehicle.identity;
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    // ── Contrôle : l'état du dernier passage, s'il y en a un ──────────
    final lastCheck = vehicle.lastCheck;
    final checkStatus = lastCheck == null
        ? null
        : _lastCheckStatus(context, lastCheck);

    // ── Échéances : la plus proche, résumée dans la tuile ─────────────
    final next = vehicle.nextDeadline;
    final nextStatus = next == null ? null : _deadlineStatus(context, next);

    final engineSummary = engineDetailsSummary(context, vehicle);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Identité ──────────────────────────────────────────────
          VehicleCardHeader(
            vehicle: vehicle,
            trailing: _MoreMenu(vehicle: vehicle),
            tags: [
              if (id.engineType != null)
                _InfoChip(
                  Icons.local_gas_station_outlined,
                  referenceFuelLabel(id.engineTypeCode, id.engineType!, l10n),
                ),
              if (id.color != null)
                _InfoChip(
                  Icons.palette_outlined,
                  referenceColourLabel(id.color!, l10n),
                ),
              if (vehicle.compatibilityReady)
                _InfoChip(
                  Icons.verified_outlined,
                  l10n.garagePreciseCompatibility,
                  highlighted: true,
                ),
            ],
          ),

          // ── Motorisation manquante ────────────────────────────────
          //
          // Avant les actions qu'elle rend moins utiles : la liste des pièces
          // compatibles s'ouvrirait vide, sans rien dire.
          if (!vehicle.hasMotorisationData)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MissingEngineBanner(vehicle: vehicle),
            ),

          // ── Actions principales ───────────────────────────────────
          //
          // Le contrôle en premier : c'est la seule action de cette fiche qui
          // ait un déclencheur dans la vie réelle — on se la demande avant de
          // prendre la route. Les pièces ensuite : c'est ce qu'on vient
          // chercher dans une boutique de pièces.
          GarageSectionTitle(title: l10n.garageSectionMainActions),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GaragePrimaryActions(
              actions: [
                GarageAction(
                  key: Key('garage-action-check-${vehicle.id}'),
                  icon: Icons.checklist_rtl,
                  emphasis: GarageActionEmphasis.primary,
                  // Un libellé neutre, et non « Contrôle avant voyage » :
                  // l'écran propose aussi le contrôle de saison.
                  title: lastCheck == null
                      ? l10n.garageCheckVehicleAction
                      : l10n.garageRepeatCheckAction,
                  subtitle: checkStatus?.text ?? l10n.garageTileCheckSubtitle,
                  statusIcon: checkStatus?.icon,
                  statusColor: checkStatus?.color,
                  onTap: () => context.push(
                    '/garage/${vehicle.id}/check',
                    extra: vehicle,
                  ),
                ),
                GarageAction(
                  key: Key('garage-action-parts-${vehicle.id}'),
                  icon: Icons.settings_outlined,
                  emphasis: GarageActionEmphasis.secondary,
                  title: l10n.garageMatchingPartsTitle,
                  subtitle: l10n.garageTilePartsSubtitle,
                  onTap: () => context.push(
                    '/garage/${vehicle.id}/parts',
                    extra: vehicle,
                  ),
                ),
              ],
            ),
          ),

          // ── Gérer le véhicule ─────────────────────────────────────
          GarageSectionTitle(title: l10n.garageSectionManage),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GarageActionGrid(
              actions: [
                GarageAction(
                  key: Key('garage-action-mileage-${vehicle.id}'),
                  icon: Icons.speed,
                  title: l10n.garageTileMileageTitle,
                  subtitle: l10n.garageTileMileageSubtitle,
                  onTap: () => showMileageDialog(context, ref, vehicle),
                ),
                GarageAction(
                  key: Key('garage-action-deadlines-${vehicle.id}'),
                  icon: Icons.notifications_none,
                  title: l10n.garageTileDeadlinesTitle,
                  subtitle: next == null
                      ? l10n.garageTileDeadlinesSubtitle
                      : '${garageDeadlineLabel(l10n, next)} · '
                            '${garageDeadlineSummary(l10n, next)}',
                  statusIcon: nextStatus?.icon,
                  statusColor: nextStatus?.color,
                  onTap: () => _editDeadlines(context, ref, vehicle),
                ),
                GarageAction(
                  key: Key('garage-action-engine-${vehicle.id}'),
                  icon: Icons.build_outlined,
                  title: l10n.garageTileEngineTitle,
                  subtitle: engineSummary ?? l10n.garageTileEngineSubtitle,
                  onTap: () => showEngineDetailsDialog(context, vehicle),
                ),
                if (privateSalesEnabled)
                  GarageAction(
                    key: Key('garage-action-sell-${vehicle.id}'),
                    icon: Icons.sell_outlined,
                    title: l10n.garageTileSellTitle,
                    subtitle: l10n.garageTileSellSubtitle,
                    onTap: () => context.push('/sell', extra: vehicle),
                  ),
              ],
            ),
          ),

          // ── Échéances d'entretien ─────────────────────────────────
          //
          // Le bloc entier ouvre l'édition : c'est là que l'œil se pose quand
          // on veut corriger une date. Sans échéance suivie, la tuile
          // « Échéances » ci-dessus propose elle-même l'action.
          if (vehicle.deadlines.isNotEmpty) ...[
            GarageSectionTitle(
              title: l10n.garageMaintenanceTitle,
              trailing: TextButton(
                onPressed: () => _editDeadlines(context, ref, vehicle),
                child: Text(l10n.garageDeadlinesEditAction),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Material(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _editDeadlines(context, ref, vehicle),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final d in vehicle.deadlines)
                          _DeadlineRow(deadline: d),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── Consommation ──────────────────────────────────────────
          //
          // La cote officielle du moteur choisi, ou l'invitation à le
          // choisir, et le suivi des passages à la pompe.
          GarageSectionTitle(title: l10n.garageSectionConsumption),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: ConsumptionTile(vehicle: vehicle),
            ),
          ),
        ],
      ),
    );
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

    final error = await ref
        .read(garageProvider.notifier)
        .updateVehicle(vehicle.id, result);

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
  late DateTime? _insurance = widget.vehicle.insuranceExpiry;
  late final _serviceKmCtrl = TextEditingController(
    text: widget.vehicle.lastServiceMileageKm?.toString() ?? '',
  );
  late int? _interval = widget.vehicle.serviceIntervalKm;

  /// Intervalles courants. « Aucun » coupe le suivi kilométrique.
  static const _intervals = <int?>[null, 5000, 10000, 15000];

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
    final hasCurrent = widget.vehicle.mileageKm != null;

    if (!hasLastService && !hasCurrent) {
      return AppLocalizations.of(context).garageServiceMissingBoth;
    }
    if (!hasLastService) {
      return AppLocalizations.of(context).garageServiceMissingLastMileage;
    }
    if (!hasCurrent) {
      return AppLocalizations.of(context).garageServiceMissingCurrentMileage;
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
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).garageMaintenanceTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).garageMaintenanceReminders,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          _DateField(
            label: AppLocalizations.of(context).garageInspectionLabel,
            value: _inspection,
            format: _fmtDate,
            onPick: () => _pick(true),
            onClear: () => setState(() => _inspection = null),
          ),
          _DateField(
            label: AppLocalizations.of(context).garageInsuranceLabel,
            value: _insurance,
            format: _fmtDate,
            onPick: () => _pick(false),
            onClear: () => setState(() => _insurance = null),
          ),

          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).garageOilChangeLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _serviceKmCtrl,
            keyboardType: TextInputType.number,
            // Le message d'aide dépend de ce champ : il doit suivre la saisie,
            // pas attendre la fermeture de la feuille.
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(
                context,
              ).garageLastOilChangeMileage,
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
                  label: Text(
                    i == null
                        ? AppLocalizations.of(context).garageNoInterval
                        : AppLocalizations.of(context).commonMileageKm(
                            garageInteger(
                              AppLocalizations.of(context),
                              i,
                            ).replaceAll('\u00a0', ' '),
                          ),
                  ),
                  selected: _interval == i,
                  onSelected: (_) => setState(() => _interval = i),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Le calcul exige trois valeurs. Choisir un intervalle sans les
          // autres ne produisait aucun rappel, et aucun message : l'utilisateur
          // croyait avoir activé un suivi inexistant. On dit donc précisément
          // ce qui manque, au moment où il fait le choix.
          Builder(
            builder: (context) {
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
                          AppLocalizations.of(
                            context,
                          ).garageOilReminderMileageExplanation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: warn ? cs.error : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).commonCancel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context, {
                  'technical_inspection_expiry': _inspection
                      ?.toIso8601String()
                      .substring(0, 10),
                  'insurance_expiry': _insurance?.toIso8601String().substring(
                    0,
                    10,
                  ),
                  'last_service_mileage_km': int.tryParse(_serviceKmCtrl.text),
                  'service_interval_km': _interval,
                }),
                child: Text(AppLocalizations.of(context).catalogFeaturesSave),
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
            tooltip: AppLocalizations.of(context).garageClearAction,
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
              garageDeadlineLabel(AppLocalizations.of(context), deadline),
              // Le libelle suit la couleur du delai quand l'echeance est
              // depassee : « Assurance » en gris a cote d'un « Depassee de
              // 12 j » en rouge laissait croire a un detail de mise en forme.
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: deadline.overdue ? cs.error : cs.onSurfaceVariant,
                fontWeight: deadline.overdue
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            garageDeadlineSummary(AppLocalizations.of(context), deadline),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: deadline.overdue || soon
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un état à afficher devant un sous-titre : texte, icône et couleur.
typedef _Status = ({String text, IconData icon, Color color});

/// Le dernier contrôle, résumé pour la tuile « Contrôler » : ce qui reste à
/// reprendre, puis quand.
///
/// La même grammaire que les échéances — rouge quand c'est bloquant, orange
/// quand quelque chose reste à reprendre — parce que c'est la même question
/// posée autrement : qu'est-ce qui reste à faire sur ce véhicule.
_Status _lastCheckStatus(BuildContext context, LastCheck lastCheck) {
  final l10n = AppLocalizations.of(context);
  final cs = Theme.of(context).colorScheme;
  final aReprendre = lastCheck.aReprendre;

  final (Color couleur, IconData icone) = lastCheck.bloque
      ? (cs.error, Icons.report_outlined)
      : aReprendre > 0
      ? (const Color(0xFFB26A00), Icons.schedule)
      : (cs.primary, Icons.check_circle_outline);

  final resultat = aReprendre == 0
      ? l10n.garageCheckNothingToFix
      : aReprendre == 1
      ? l10n.garageCheckOnePointToFix
      : l10n.garageCheckPointsToFix(aReprendre.toString());

  return (
    text: l10n.garageTileCheckLastSubtitle(
      resultat,
      _quand(context, lastCheck.performedAt),
    ),
    icon: icone,
    color: couleur,
  );
}

/// L'échéance la plus proche, avec la couleur de son délai.
_Status _deadlineStatus(BuildContext context, VehicleDeadline deadline) {
  final cs = Theme.of(context).colorScheme;
  final soon =
      deadline.daysLeft != null && deadline.daysLeft! <= _DeadlineRow._soonDays;
  final (color, icon) = deadline.overdue
      ? (cs.error, Icons.error_outline)
      : soon
      ? (const Color(0xFFB26A00), Icons.schedule)
      : (cs.primary, Icons.check_circle_outline);
  return (text: '', icon: icon, color: color);
}

/// Une date relative : « hier » se situe sans calculer, « 14/09 » non.
String _quand(BuildContext context, DateTime? date) {
  final l10n = AppLocalizations.of(context);
  if (date == null) return l10n.garageRecentlyLower;

  final jours = DateTime.now().difference(date).inDays;

  return switch (jours) {
    <= 0 => l10n.garageTodayLower,
    1 => l10n.garageYesterdayLower,
    < 7 => l10n.garageDaysAgoLower(jours.toString()),
    < 14 => l10n.garageLastWeekLower,
    < 60 => l10n.garageWeeksAgoLower((jours / 7).round().toString()),
    _ => l10n.garageMonthsAgoLower((jours / 30).round().toString()),
  };
}

class _MoreMenu extends ConsumerWidget {
  final OwnedVehicle vehicle;
  const _MoreMenu({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).garageVehicleMoreActions,
      onSelected: (action) async {
        if (action == 'edit') {
          if (context.mounted) {
            await context.push('/garage/${vehicle.id}/edit', extra: vehicle);
          }
          return;
        }
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
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(AppLocalizations.of(context).garageEditVehicleAction),
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 0,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text(
              AppLocalizations.of(context).garageRemoveVehicleAction,
              style: TextStyle(color: Colors.red),
            ),
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
          title: Text(AppLocalizations.of(context).garageRemoveVehicleTitle),
          content: Text(
            AppLocalizations.of(
              context,
            ).garageRemoveVehicleBody((name).toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).garageRemoveAction),
            ),
          ],
        ),
      );
}

// ── Chip d'info ───────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  const _InfoChip(this.icon, this.label, {this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final couleur = highlighted ? cs.onTertiaryContainer : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? cs.tertiaryContainer : null,
        borderRadius: BorderRadius.circular(8),
        border: highlighted ? null : Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: couleur),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: couleur),
            ),
          ),
        ],
      ),
    );
  }
}

// ── États vide / erreur ───────────────────────────────────────────────

class _EmptyGarage extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGarage({required this.onAdd});

  // SingleChildScrollView autour du Center : l'état vide reste centré quand il
  // tient, et devient défilable quand il ne tient plus. Sans lui, un écran de
  // 320 points avec les caractères grossis débordait par le bas — le bouton
  // « Ajouter un véhicule » passait sous le bord, et c'est la seule issue d'un
  // garage vide.
  //
  // Le retour à la ligne de la phrase était posé à la main (« retrouver\n
  // rapidement ») : il ignorait la largeur disponible. Laisser le texte se
  // replier tout seul, avec de la marge, vaut mieux qu'une coupure décidée
  // pour un écran qu'on ne connaît pas.
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.garage_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).garageEmptyTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).garageEmptyBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context).garageAddVehicleAction),
          ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  // Défilable pour la même raison que l'état vide, et plus encore : la
  // longueur du message n'est pas connue d'avance — c'est celui que le serveur
  // ou la couche réseau a renvoyé. Un message bavard poussait « Réessayer »
  // hors de l'écran, sur le seul écran où ce bouton est tout ce qui reste.
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).commonRetry),
          ),
        ],
      ),
    ),
  );
}

// ── Page profil staff ─────────────────────────────────────────────────

class _StaffProfilePage extends ConsumerWidget {
  final AuthState auth;
  const _StaffProfilePage({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = auth.staffUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).garageProfileTitle),
      ),
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
            child: Text(
              auth.displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (user?.email != null)
            Center(
              child: Text(
                user!.email,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.outline),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: Text(
                user?.role ?? AppLocalizations.of(context).garageStaffLabel,
              ),
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
                SnackBar(
                  content: Text(AppLocalizations.of(context).garageSignedOut),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
              ref.read(authProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(
              AppLocalizations.of(context).garageSignOutAction,
              style: TextStyle(color: Colors.red),
            ),
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
