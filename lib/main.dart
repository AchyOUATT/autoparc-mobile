import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/catalog/data/models/accessory.dart';
import 'features/catalog/data/models/part.dart';
import 'features/catalog/data/models/vehicle.dart';
import 'features/catalog/presentation/pages/accessory_detail_page.dart';
import 'features/catalog/presentation/pages/accessory_list_page.dart';
import 'features/catalog/presentation/pages/part_detail_page.dart';
import 'features/catalog/presentation/pages/part_list_page.dart';
import 'features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'features/catalog/presentation/pages/vehicle_list_page.dart';
import 'features/garage/data/models/owned_vehicle.dart';
import 'features/garage/presentation/pages/add_vehicle_to_garage_page.dart';
import 'features/garage/presentation/pages/compatible_parts_page.dart';
import 'features/garage/presentation/pages/garage_page.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/catalog/presentation/pages/add_part_page.dart';
import 'features/catalog/presentation/pages/add_accessory_page.dart';
import 'features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'features/needs/presentation/pages/submit_need_page.dart';
import 'features/needs/presentation/pages/needs_list_page.dart';
import 'features/needs/presentation/pages/client_needs_page.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'core/services/fcm_service.dart';
import 'core/api/api_client.dart';
import 'shared/presentation/pages/media_upload_page.dart';
import 'features/onboarding/data/onboarding_service.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/partners/data/models/partner.dart';
import 'features/partners/presentation/pages/partner_list_page.dart';
import 'features/partners/presentation/pages/partner_form_page.dart';
import 'core/providers/shell_scaffold_provider.dart';
import 'core/local/catalog_local_cache.dart';
import 'features/vehicles/presentation/providers/vehicle_refs_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase avant tout accès à FirebaseAuth.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[AutoParc] Firebase.initializeApp() échoué : $e');
  }

  // Vérifie si l'onboarding a déjà été vu.
  final onboardingDone = await OnboardingService.isDone();

  runApp(ProviderScope(child: AutoParcApp(onboardingDone: onboardingDone)));
}

// ── Routeur ────────────────────────────────────────────────────────

GoRouter _buildRouter({required bool onboardingDone}) => GoRouter(
  initialLocation: onboardingDone ? '/' : '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginPage(),
    ),

    // Shell avec NavigationBar (3 onglets catalogue)
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(path: '/',            builder: (_, __) => const VehicleListPage()),
        GoRoute(path: '/accessories', builder: (_, __) => const AccessoryListPage()),
        GoRoute(path: '/parts',       builder: (_, __) => const PartListPage()),
      ],
    ),

    // Garage — accessible depuis le menu, pas en onglet permanent
    GoRoute(path: '/garage', builder: (_, __) => const GaragePage()),

    // ── Panier ─────────────────────────────────────────────────────
    GoRoute(path: '/cart', builder: (_, __) => const CartPage()),

    // ── Routes statiques AVANT les routes paramétrées ──────────────
    GoRoute(path: '/vehicles/new',    builder: (_, __) => const VehicleRegisterPage()),
    GoRoute(path: '/parts/new',       builder: (_, __) => const AddPartPage()),
    GoRoute(path: '/accessories/new', builder: (_, __) => const AddAccessoryPage()),

    // ── Upload photos (staff) ──────────────────────────────────────
    GoRoute(
      path: '/media-upload',
      builder: (_, state) => MediaUploadPage(
        config: state.extra as MediaUploadConfig,
      ),
    ),
    GoRoute(path: '/garage/add',    builder: (_, __) => const AddVehicleToGaragePage()),

    // ── Partenaires (staff) ────────────────────────────────────────
    GoRoute(
      path: '/partners',
      builder: (_, __) => const PartnerListPage(),
    ),
    GoRoute(
      path: '/partners/new',
      builder: (_, __) => const PartnerFormPage(),
    ),
    GoRoute(
      path: '/partners/:id/edit',
      builder: (_, state) {
        final partner = state.extra as Partner?;
        return PartnerFormPage(existing: partner);
      },
    ),
    // Détail partenaire (réutilise le formulaire en mode lecture seule
    // — ou redirige vers /partners/:id/edit pour simplifier)
    GoRoute(
      path: '/partners/:id',
      redirect: (_, state) {
        // Redirige vers l'édition directement (la liste est le point d'entrée)
        return '/partners/${state.pathParameters['id']}/edit';
      },
    ),

    // ── Besoins clients ────────────────────────────────────────────
    GoRoute(
      path: '/needs/new',
      builder: (_, state) => const SubmitNeedPage(),
    ),
    // Route statique AVANT /needs/:id ou /needs (catch-all)
    GoRoute(
      path: '/needs/mine',
      builder: (_, __) => const ClientNeedsPage(),
    ),
    GoRoute(
      path: '/needs',
      builder: (_, __) => const NeedsListPage(),
    ),

    // ── Notifications ──────────────────────────────────────────────
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/garage/:id/parts',
      builder: (_, state) {
        final id      = int.parse(state.pathParameters['id']!);
        final vehicle = state.extra as OwnedVehicle?;
        return CompatiblePartsPage(ownedVehicleId: id, vehicle: vehicle);
      },
    ),

    // ── Pages de détail (sans NavigationBar) ────────────────────────
    GoRoute(
      path: '/vehicles/:id/edit',
      builder: (_, state) {
        final vehicle = state.extra as Vehicle?;
        return VehicleRegisterPage(existing: vehicle);
      },
    ),
    GoRoute(
      path: '/vehicles/:id',
      builder: (_, state) {
        final id      = int.parse(state.pathParameters['id']!);
        final vehicle = state.extra as Vehicle?;
        return VehicleDetailPage(vehicleId: id, initialVehicle: vehicle);
      },
    ),
    GoRoute(
      path: '/accessories/:id/edit',
      builder: (_, state) {
        final accessory = state.extra as Accessory?;
        return AddAccessoryPage(existing: accessory);
      },
    ),
    GoRoute(
      path: '/accessories/:id',
      builder: (_, state) {
        final id        = int.parse(state.pathParameters['id']!);
        final accessory = state.extra as Accessory?;
        return AccessoryDetailPage(accessoryId: id, initialAccessory: accessory);
      },
    ),
    GoRoute(
      path: '/parts/:id/edit',
      builder: (_, state) {
        final part = state.extra as Part?;
        return AddPartPage(existing: part);
      },
    ),
    GoRoute(
      path: '/parts/:id',
      builder: (_, state) {
        final id   = int.parse(state.pathParameters['id']!);
        final part = state.extra as Part?;
        return PartDetailPage(partId: id, initialPart: part);
      },
    ),
  ],
);

// ── App ────────────────────────────────────────────────────────────

class AutoParcApp extends StatelessWidget {
  final bool onboardingDone;
  const AutoParcApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AutoParc',
      debugShowCheckedModeBanner: false,
      routerConfig: _buildRouter(onboardingDone: onboardingDone),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A3C5E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A3C5E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}

// ── Coordonnées de contact (à adapter) ────────────────────────────
const _kContactPhone    = '+226 70 00 00 00';
const _kContactWhatsApp = '+226 70 00 00 00';
const _kContactEmail    = 'contact@autoparc.com';

// ── Shell avec NavigationBar + Drawer ─────────────────────────────

class _AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  static const _tabs = [
    (path: '/',            icon: Icons.directions_car_outlined, label: 'Véhicules'),
    (path: '/accessories', icon: Icons.tune_outlined,           label: 'Accessoires'),
    (path: '/parts',       icon: Icons.settings_outlined,       label: 'Pièces'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmAppService.instance.initialize(
        apiClient: ref.read(apiClientProvider),
        onTap: (data) {
          final type      = data['type'] as String? ?? '';
          final vehicleId = int.tryParse(data['vehicle_id']?.toString() ?? '');
          if (mounted) {
            switch (type) {
              case 'new_need':
              case 'need_status_update':
                context.push('/notifications');
              case 'vehicle_match':
                if (vehicleId != null) context.push('/vehicles/$vehicleId');
              default:
                context.push('/notifications');
            }
          }
          ref.invalidate(unreadCountProvider);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = ref.watch(shellScaffoldKeyProvider);
    final location    = GoRouterState.of(context).uri.path;
    final tabIndex    = _tabs.indexWhere((t) => t.path == location).clamp(0, _tabs.length - 1);

    return Scaffold(
      key: scaffoldKey,
      drawer: const _AppDrawer(),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs.map((t) => NavigationDestination(
          icon:  Icon(t.icon),
          label: t.label,
        )).toList(),
      ),
    );
  }
}

// ── Drawer latéral ────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  void _close(BuildContext context) => Navigator.pop(context);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth   = ref.watch(authProvider);
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final cs     = Theme.of(context).colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [

          // ── En-tête compte ──────────────────────────────────────
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: cs.primary),
            accountName: Text(
              auth.isAuthenticated ? auth.displayName : 'Visiteur',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              auth.isStaff  ? 'Personnel — ${auth.staffUser?.role ?? ''}' :
              auth.isClient ? (auth.firebaseUser?.email ?? '') :
              'Non connecté',
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: cs.onPrimary.withAlpha(40),
              child: Text(
                auth.isAuthenticated && auth.displayName.isNotEmpty
                    ? auth.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimary,
                ),
              ),
            ),
          ),

          // ════════════════════════════════════════════════════════
          // STAFF
          // ════════════════════════════════════════════════════════
          if (auth.isStaff) ...[
            _DrawerTile(
              icon: Icons.list_alt_outlined,
              label: 'Besoins clients',
              onTap: () { _close(context); context.push('/needs'); },
            ),
            _DrawerTile(
              icon: Icons.handshake_outlined,
              label: 'Partenaires',
              onTap: () { _close(context); context.push('/partners'); },
            ),
            _DrawerTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              badge: unread,
              onTap: () { _close(context); context.push('/notifications'); },
            ),
            const Divider(),
            _DrawerTile(
              icon: Icons.sync,
              label: 'Rafraîchir le catalogue',
              onTap: () async {
                _close(context);
                await ref.read(catalogLocalCacheProvider).clear();
                ref.invalidate(catalogRefsProvider);
                ref.invalidate(countriesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Catalogue mis à jour'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            _DrawerTile(
              icon: Icons.logout,
              label: 'Se déconnecter',
              color: cs.error,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vous êtes déconnecté.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
                _close(context);
                ref.read(authProvider.notifier).signOut();
              },
            ),
          ],

          // ════════════════════════════════════════════════════════
          // CLIENT FIREBASE
          // ════════════════════════════════════════════════════════
          if (auth.isClient) ...[
            _DrawerTile(
              icon: Icons.garage_outlined,
              label: 'Mon Garage',
              onTap: () { _close(context); context.push('/garage'); },
            ),
            _DrawerTile(
              icon: Icons.list_alt_outlined,
              label: 'Mes besoins',
              onTap: () { _close(context); context.push('/needs/mine'); },
            ),
            _DrawerTile(
              icon: Icons.phone_outlined,
              label: 'Nous contacter',
              onTap: () {
                _close(context);
                _showContactSheet(context);
              },
            ),
            const Divider(),
            _DrawerTile(
              icon: Icons.logout,
              label: 'Se déconnecter',
              color: cs.error,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vous êtes déconnecté.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
                _close(context);
                ref.read(authProvider.notifier).signOut();
              },
            ),
          ],

          // ════════════════════════════════════════════════════════
          // ANONYME
          // ════════════════════════════════════════════════════════
          if (!auth.isAuthenticated) ...[
            _DrawerTile(
              icon: Icons.login,
              label: 'Se connecter',
              onTap: () { _close(context); context.push('/login'); },
            ),
          ],
        ],
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nous contacter',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _ContactTile(
              icon: Icons.phone_outlined,
              label: 'Téléphone',
              value: _kContactPhone,
              onTap: () => launchUrl(Uri.parse('tel:$_kContactPhone')),
            ),
            const SizedBox(height: 12),
            _ContactTile(
              icon: Icons.chat_outlined,
              iconColor: const Color(0xFF25D366),
              label: 'WhatsApp',
              value: _kContactWhatsApp,
              onTap: () {
                final n = _kContactWhatsApp.replaceAll(RegExp(r'[^\d+]'), '');
                launchUrl(Uri.parse('https://wa.me/$n'));
              },
            ),
            const SizedBox(height: 12),
            _ContactTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _kContactEmail,
              onTap: () => launchUrl(Uri.parse('mailto:$_kContactEmail')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tuile drawer ──────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  final int    badge;
  final Color? color;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effective = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: badge > 0
          ? Badge(label: Text('$badge'), child: Icon(icon, color: effective))
          : Icon(icon, color: effective),
      title: Text(label, style: TextStyle(color: effective)),
      onTap: onTap,
    );
  }
}

// ── Tuile contact ─────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color?   iconColor;
  final String   label;
  final String   value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary),
    title:    Text(label),
    subtitle: Text(value),
    onTap:    onTap,
    contentPadding: EdgeInsets.zero,
  );
}
