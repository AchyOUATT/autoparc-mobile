import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/widgets/notification_icon_button.dart';

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
          error: e.toString(),
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
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Se déconnecter',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).signOut();
              },
            ),
          ],
        ),
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
                  onPressed: () => _editMileage(context, ref, vehicle),
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

  Future<void> _editMileage(
    BuildContext context,
    WidgetRef ref,
    OwnedVehicle vehicle,
  ) async {
    final ctrl = TextEditingController(
      text: vehicle.mileageKm?.toString() ?? '',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mettre à jour'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Kilométrage actuel',
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'mileage_km': int.tryParse(ctrl.text) ?? vehicle.mileageKm,
            }),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    ctrl.dispose();

    if (result != null && context.mounted) {
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
}

// ── Menu contextuel (éditer / supprimer) ─────────────────────────────

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
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
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
