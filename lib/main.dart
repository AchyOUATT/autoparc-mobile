import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/l10n/langue.dart';
import 'core/l10n/tuile_langue.dart';
import 'core/theme/app_theme.dart';
import 'core/update/ecran_mise_a_jour.dart';
import 'core/utils/currency_format.dart';
import 'core/update/version_minimale.dart';
import 'core/utils/lien_externe.dart';
import 'core/widgets/navigation_bar_theme.dart';
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
import 'features/home/presentation/pages/home_page.dart';
import 'features/garage/data/models/owned_vehicle.dart';
import 'features/garage/presentation/pages/add_vehicle_to_garage_page.dart';
import 'features/garage/presentation/pages/compatible_parts_page.dart';
import 'features/garage/presentation/pages/fuel_fills_page.dart';
import 'features/garage/presentation/pages/vehicle_check_page.dart';
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
import 'core/utils/contact_info.dart';
import 'core/services/fcm_service.dart';
import 'core/api/api_client.dart';
import 'core/diagnostics/error_journal.dart';
import 'shared/presentation/pages/media_upload_page.dart';
import 'features/onboarding/data/onboarding_service.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/partners/data/models/partner.dart';
import 'features/partners/presentation/pages/partner_list_page.dart';
import 'features/partners/presentation/pages/partner_form_page.dart';
import 'features/partner_accounts/partner_accounts.dart';
import 'features/private_sales/data/private_listing_repository.dart';
import 'features/private_sales/presentation/private_listings_page.dart';
import 'features/private_sales/presentation/private_listing_form.dart';
import 'features/partner_accounts/presentation/partner_applications_page.dart';
import 'core/providers/shell_scaffold_provider.dart';
import 'core/local/catalog_local_cache.dart';
import 'features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'features/catalog/presentation/providers/catalog_providers.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Avant tout le reste : une erreur survenue pendant l'initialisation doit
  // être consignée comme les autres. Voir ErrorJournal — un écran rouge vu une
  // seule fois, impossible à reproduire, et dont la trace avait déjà été
  // écrasée dans le journal système quand il a fallu la lire.
  await ErrorJournal.installer();

  // Sélecteur de photos du système pour la galerie, sur toutes les versions
  // d'Android. Il ne donne à l'application que les images choisies et ne
  // demande aucune autorisation : c'est ce qui permet de se passer de
  // READ_MEDIA_IMAGES, que Google Play a refusée à la version 45. Sans ce
  // réglage, le greffon ne l'emploie d'office qu'à partir d'Android 16.
  final selecteurImages = ImagePickerPlatform.instance;
  if (selecteurImages is ImagePickerAndroid) {
    selecteurImages.useAndroidPhotoPicker = true;
  }

  // Initialise Firebase avant tout accès à FirebaseAuth.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[AutoParc] Firebase.initializeApp() échoué : $e');
  }

  // Le SDK Google veut être initialisé une fois, et une seule, avant tout
  // appel. Aucun identifiant n'est passé : `google-services.json` porte déjà
  // le client web dont le greffon a besoin pour obtenir un jeton d'identité,
  // et le renseigner ici en dupliquerait la source.
  //
  // Un échec n'arrête pas l'application : le catalogue se consulte sans
  // compte, et la connexion par email reste disponible.
  try {
    await GoogleSignIn.instance.initialize();
  } catch (e) {
    debugPrint('[AutoParc] GoogleSignIn.initialize() échoué : $e');
  }

  // Vérifie si l'onboarding a déjà été vu.
  final onboardingDone = await OnboardingService.isDone();

  // La langue est lue ICI, et pas dans un provider asynchrone, pour la même
  // raison que l'onboarding : les deux décident de ce que montre la PREMIÈRE
  // trame. Une lecture tardive ouvrirait l'application en français puis la
  // ferait sauter en anglais, à chaque lancement, pour tout utilisateur
  // anglophone. Les deux lectures tapent la même instance de
  // `SharedPreferences`, déjà chargée.
  final langue = await LangueService.lire();

  runApp(
    ProviderScope(
      overrides: [localeInitialeProvider.overrideWithValue(langue)],
      child: AutoParcApp(onboardingDone: onboardingDone),
    ),
  );
}

// ── Routeur ────────────────────────────────────────────────────────

GoRouter _buildRouter({required bool onboardingDone}) => GoRouter(
  initialLocation: onboardingDone ? '/' : '/onboarding',
  routes: [
    if (privateSalesEnabled) ...[
      GoRoute(path: '/private-listings', builder: (_, __) => const PrivateListingsPage()),
      GoRoute(path: '/my-listings', builder: (_, __) => const PrivateListingsPage(mode: PrivateListingMode.mine)),
      GoRoute(path: '/private-listing-reviews', builder: (_, __) => const PrivateListingsPage(mode: PrivateListingMode.review)),
      GoRoute(path: '/sell', builder: (_, state) => PrivateListingForm(vehicle: state.extra is OwnedVehicle ? state.extra as OwnedVehicle : null)),
    ],
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: '/partner',
      builder: (_, __) => const PartnerAccountPage(),
    ),
    GoRoute(
      path: '/partner-applications',
      builder: (_, __) => const PartnerApplicationsPage(),
    ),

    // Shell avec NavigationBar (3 onglets catalogue)
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(path: '/',            builder: (_, __) => const HomePage()),
        // La recherche véhicules quitte la racine : elle sert l'acheteur de
        // passage, quand l'accueil sert le propriétaire, qui lui revient.
        GoRoute(path: '/vehicles',    builder: (_, __) => const VehicleListPage()),
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
        // Catégorie passée en requête, et non par `extra` : on arrive ici
        // depuis un contrôle avant voyage, dont `extra` porte déjà le véhicule.
        final params  = state.uri.queryParameters;
        return CompatiblePartsPage(
          ownedVehicleId: id,
          vehicle: vehicle,
          categoryId: int.tryParse(params['category_id'] ?? ''),
          categoryLabel: params['category_label'],
        );
      },
    ),

    // Contrôle avant voyage. La liste n'est pas embarquée : le serveur la
    // compose pour ce véhicule et ce trajet.
    GoRoute(
      path: '/garage/:id/check',
      builder: (_, state) {
        final id      = int.parse(state.pathParameters['id']!);
        final vehicle = state.extra as OwnedVehicle?;
        return VehicleCheckPage(ownedVehicleId: id, vehicle: vehicle);
      },
    ),

    // Passages à la pompe. L'écran sert surtout à corriger : une faute de
    // frappe sur le compteur fausse les deux intervalles qui l'encadrent, et
    // seule la suppression de la ligne rend la moyenne juste.
    GoRoute(
      path: '/garage/:id/fuel',
      builder: (_, state) {
        final id      = int.parse(state.pathParameters['id']!);
        final vehicle = state.extra as OwnedVehicle?;
        return FuelFillsPage(ownedVehicleId: id, vehicle: vehicle);
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

/// La racine de l'application.
///
/// ── POURQUOI ELLE EST DEVENUE UN `ConsumerStatefulWidget` ───────────────────
///
/// Elle était sans état, et son `build` fabriquait un `GoRouter` NEUF à chaque
/// passage. Tant que rien ne la faisait reconstruire, cela ne se voyait pas —
/// c'est d'ailleurs la raison écrite dans [_PorteMiseAJour] pour y avoir mis le
/// `ref.watch` du verdict de mise à jour plutôt qu'ici.
///
/// La langue, elle, DOIT être observée à ce niveau : c'est le `MaterialApp` qui
/// porte `locale`. Avec l'ancienne forme, changer de langue aurait reconstruit
/// un routeur neuf, donc ramené l'utilisateur à `initialLocation` : on touche
/// « English » au fond du tiroir et on ressort sur l'accueil, panier perdu. Le
/// routeur est donc construit UNE FOIS, dans `initState`, et le `build` ne fait
/// plus que l'habiller.
class AutoParcApp extends ConsumerStatefulWidget {
  final bool onboardingDone;
  const AutoParcApp({super.key, required this.onboardingDone});

  @override
  ConsumerState<AutoParcApp> createState() => _AutoParcAppState();
}

class _AutoParcAppState extends ConsumerState<AutoParcApp> {
  late final GoRouter _routeur = _buildRouter(
    onboardingDone: widget.onboardingDone,
  );

  @override
  Widget build(BuildContext context) {
    final langue = ref.watch(langueProvider);

    // Le format des montants est accordé ICI, dans le `build` du parent, et
    // non dans chaque page : Flutter construit un parent avant ses enfants,
    // donc tout prix formaté pendant cette trame emploie la même locale que
    // `Localizations.localeOf`. Voir core/utils/currency_format.dart.
    definirLocaleMontants(langue);

    return _PorteMiseAJour(
      langue: langue,
      enfant: MaterialApp.router(
        title: 'AutoParc',
        debugShowCheckedModeBanner: false,
        routerConfig: _routeur,
        theme: themeAutoParc(Brightness.light),
        darkTheme: themeAutoParc(Brightness.dark),
        locale: langue,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

/// Interpose l'écran bloquant au-dessus de tout, routeur compris.
///
/// Trois façons de brancher ce contrôle se présentaient : une redirection
/// `go_router`, une route poussée sur le navigateur, ou le remplacement pur
/// et simple de l'arbre. C'est la troisième qui est retenue, parce que c'est
/// la seule qui ne laisse aucune prise : une redirection se contourne dès
/// qu'une route n'y passe pas — les boîtes de dialogue et les feuilles
/// modales sont déjà empilées quand elle s'évalue —, et une route poussée se
/// dépile. Ici le routeur n'est pas masqué, il n'existe plus : il n'y a
/// littéralement plus d'écran dessous.
///
/// C'est aussi pourquoi `ref.watch` est ici et non dans [AutoParcApp] : le
/// verdict ne doit pas faire reconstruire le parent, dont le `build`
/// fabrique un `GoRouter` neuf à chaque passage.
///
/// Tant que le verdict n'est pas tombé — et c'est le cas de tout démarrage,
/// le serveur mettant couramment vingt-cinq secondes à se réveiller —
/// l'application fonctionne normalement. On ne fait patienter personne
/// devant un écran vide pour un contrôle de version : `asData` est nul
/// pendant le chargement comme en cas d'erreur, et les deux laissent passer.
class _PorteMiseAJour extends ConsumerWidget {
  final Widget enfant;

  /// La langue active, PASSÉE et non relue.
  ///
  /// Ce widget remplace l'arbre entier : son `MaterialApp` doit porter les
  /// mêmes délégués et la même `locale` que celui qu'il écarte, sinon le bouton
  /// « Mettre à jour » reviendrait en français pour un utilisateur qui a choisi
  /// l'anglais — et sur un écran bloquant, dont on ne sort pas. Elle est passée
  /// par le parent, qui l'observe déjà : un second `ref.watch` sur le même
  /// provider ne ferait que dupliquer l'abonnement.
  final Locale langue;

  const _PorteMiseAJour({required this.enfant, required this.langue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verdict = ref.watch(verdictMiseAJourProvider).asData?.value;

    if (verdict == null || !verdict.exigee) return enfant;

    return MaterialApp(
      title: 'AutoParc',
      debugShowCheckedModeBanner: false,
      theme: themeAutoParc(Brightness.light),
      darkTheme: themeAutoParc(Brightness.dark),
      locale: langue,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: EcranMiseAJour(
        message: verdict.message,
        urlStore: verdict.urlStore,
      ),
    );
  }
}

// Coordonnées de contact : voir core/utils/contact_info.dart.

// ── Shell avec NavigationBar + Drawer ─────────────────────────────

class _AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  /// Les quatre onglets : chemin et icône seulement.
  ///
  /// L'INTITULÉ N'EST PLUS ICI, et c'est ce qui permet au tuple de rester
  /// `const` : un libellé traduit se lit dans le `BuildContext`, donc à la
  /// construction, et non à la compilation. Il est pris dans [_libelles], dans
  /// le même ordre.
  static const _tabs = [
    (path: '/',            icon: Icons.home_outlined),
    (path: '/vehicles',    icon: Icons.directions_car_outlined),
    (path: '/accessories', icon: Icons.tune_outlined),
    (path: '/parts',       icon: Icons.settings_outlined),
  ];

  /// Les intitulés des quatre onglets, dans l'ordre de [_tabs].
  ///
  /// Les mêmes clés que les tuiles « Parcourir » de l'accueil et que les titres
  /// des pages : le code demandait déjà que les trois coïncident, une clé
  /// partagée l'impose. Voir lib/l10n/CONVENTION.md.
  static List<String> _libelles(AppLocalizations l10n) => [
    l10n.commonHome,
    l10n.commonVehicles,
    l10n.commonAccessories,
    l10n.commonParts,
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

              // Rappels d'entretien : même aiguillage que depuis la liste des
              // notifications. Une vidange se règle en achetant des pièces, une
              // assurance ou une visite technique en saisissant la nouvelle
              // date au garage.
              case 'maintenance_service':
                final ownedId =
                    int.tryParse(data['owned_vehicle_id']?.toString() ?? '');
                context.push(
                    ownedId != null ? '/garage/$ownedId/parts' : '/garage');
              case 'maintenance_technical_inspection':
              case 'maintenance_insurance':
                context.push('/garage');

              // Surconsommation : directement l'historique des pleins du
              // véhicule nommé, et non le garage entier. Le payload porte
              // `owned_vehicle_id` en entier, il était ignoré ; sur un parc de
              // quatre voitures, le propriétaire atterrissait sur une liste et
              // devait retrouver lui-même celle dont l'alerte parlait. C'est
              // aussi l'écran où une saisie fautive se supprime, cause la plus
              // fréquente d'une hausse soudaine, et d'où l'on rejoint le
              // catalogue de pièces que le message annonce.
              //
              // Nom distinct de `ownedId` plus haut : les cas d'un `switch`
              // partagent une seule portée, et deux `final ownedId` dans le
              // même aiguillage ne compilent pas.
              case 'fuel_anomaly':
                final vehiculeSuivi =
                    int.tryParse(data['owned_vehicle_id']?.toString() ?? '');
                context.push(vehiculeSuivi != null
                    ? '/garage/$vehiculeSuivi/fuel'
                    : '/garage');

              default:
                context.push('/notifications');
            }
          }
          ref.invalidate(unreadCountProvider);
        },
      );
    });
  }

  /// Vrai tant que la demande de confirmation est affichee.
  ///
  /// Sans ce verrou, deux appuis rapides sur Retour empilent deux boites de
  /// dialogue : la premiere reponse n'en ferme qu'une, et l'application a
  /// l'air bloquee derriere la seconde.
  bool _sortieEnCours = false;

  /// Demande confirmation avant de fermer l'application.
  ///
  /// Les quatre onglets sont navigues avec `go`, qui remplace la destination
  /// au lieu de l'empiler : depuis n'importe lequel d'entre eux il n'y a rien
  /// a depiler, et le Retour d'Android fermait l'application d'un coup, sans
  /// rien demander. Un panier a moitie rempli disparaissait sur un appui
  /// involontaire.
  Future<void> _confirmerSortie() async {
    if (_sortieEnCours) return;
    _sortieEnCours = true;

    final l10n = AppLocalizations.of(context);

    final quitter = await showDialog<bool>(
      context: context,
      builder: (contexteDialogue) => AlertDialog(
        title: Text(l10n.shellExitTitle),
        content: Text(l10n.shellExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexteDialogue, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexteDialogue, true),
            child: Text(l10n.shellExitConfirm),
          ),
        ],
      ),
    );

    _sortieEnCours = false;
    if (quitter == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = ref.watch(shellScaffoldKeyProvider);
    final location    = GoRouterState.of(context).uri.path;
    final tabIndex    = _tabs.indexWhere((t) => t.path == location).clamp(0, _tabs.length - 1);
    final libelles    = _libelles(AppLocalizations.of(context));

    // canPop: false intercepte le Retour systeme pour tout le shell.
    //
    // Le tiroir lateral doit etre traite a la main. Il s'ouvre en posant une
    // entree d'historique locale sur la route, et on pourrait croire que
    // Flutter la depile en premier ; c'est l'inverse. ModalRoute.popDisposition
    // consulte les PopScope avant d'appeler super, donc notre canPop: false
    // gagne : mesure faite, le Retour affichait « Quitter AutoParc ? » par
    // dessus le tiroir reste ouvert. On referme donc le tiroir nous-memes, et
    // on ne propose de quitter que s'il etait deja ferme.
    //
    // Les boites de dialogue et les feuilles modales, elles, sont de vraies
    // routes empilees au dessus du shell : leur Retour ne descend jamais
    // jusqu'ici.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        final etatScaffold = scaffoldKey.currentState;
        if (etatScaffold != null && etatScaffold.isDrawerOpen) {
          etatScaffold.closeDrawer();
          return;
        }

        _confirmerSortie();
      },
      child: Scaffold(
        key: scaffoldKey,
        drawer: const AppDrawer(),
        body: widget.child,
        // L'habillage ET la borne d'échelle de texte sont dans
        // `BarreNavigationPrincipale` : « Accessoires » se cassait sur deux
        // lignes à 320 points et à l'échelle 1,3, et la coque de mesure des
        // tests reproduisait ce `Theme` à la main sans pouvoir reproduire le
        // reste. Le widget est la source unique des deux.
        bottomNavigationBar: BarreNavigationPrincipale(
          selectedIndex: tabIndex,
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          destinations: [
            for (var i = 0; i < _tabs.length; i++)
              NavigationDestination(
                icon:         Icon(_tabs[i].icon),
                selectedIcon: Icon(_tabs[i].icon),
                label:        libelles[i],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer latéral ────────────────────────────────────────────────

/// Public, et non privé, pour être montable dans un banc.
///
/// C'est le seul moyen d'éprouver l'en-tête du tiroir — la ligne « session à
/// confirmer » comprise — sans bâtir toute la coque de l'application.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _close(BuildContext context) => Navigator.pop(context);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth   = ref.watch(authProvider);
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final cs     = Theme.of(context).colorScheme;
    final l10n   = AppLocalizations.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [

          // ── En-tête compte ──────────────────────────────────────
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: cs.primary),
            accountName: Text(
              auth.isAuthenticated ? auth.displayName : l10n.shellAccountGuest,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // ── LA LIGNE « SESSION A CONFIRMER » ────────────────────────
            //
            // Le démarrage est désormais OPTIMISTE : l'application s'ouvre sur
            // ce que le coffre contient, sans attendre le réseau, et une
            // vérification confirme ensuite. Pendant ce court intervalle,
            // l'état affiché est une hypothèse — et si le coffre vient d'une
            // version antérieure il n'a pas de profil, donc pas de rôle, donc
            // aucune tuile du personnel.
            //
            // Cette ligne est ce qui empêche l'employé de conclure qu'il a
            // perdu ses droits. Elle disparaît dès la confirmation.
            //
            // Elle REMPLACE la ligne du rôle au lieu de s'y ajouter, et c'est
            // une mesure qui l'a décidé : en seconde ligne, l'en-tête — dont
            // la hauteur est fixe — débordait de 2 pixels dès un grossissement
            // de texte x1.5 (`indicateur_session_test.dart`). Rogner la police
            // aurait déplacé le problème d'une échelle.
            //
            // Le remplacement dit d'ailleurs plus juste : tant que la
            // vérification n'a pas répondu, le rôle affiché est une hypothèse
            // lue au coffre, et il est VIDE quand cette session vient d'une
            // version antérieure. Annoncer l'attente vaut mieux qu'annoncer un
            // rôle dont on n'est pas sûr.
            accountEmail: auth.sessionAConfirmer
                ? Text(
                    l10n.shellSessionToConfirm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    // Le rôle vient du serveur : « admin », « vendeur »… Il
                    // n'est pas traduit par ce lot, et la phrase qui l'encadre
                    // l'est — c'est le même partage que partout ailleurs dans
                    // ce lot, et il est écrit dans lib/l10n/CONVENTION.md.
                    auth.isStaff  ? l10n.shellAccountStaff(auth.staffUser?.role ?? '') :
                    auth.isClient ? (auth.firebaseUser?.email ?? '') :
                    l10n.shellAccountNotSignedIn,
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
            if (auth.canManagePartners) _DrawerTile(
              icon: Icons.how_to_reg_outlined,
              label: 'Validation des partenaires',
              onTap: () { _close(context); context.push('/partner-applications'); },
            ),
            _DrawerTile(
              icon: Icons.list_alt_outlined,
              label: l10n.shellClientNeeds,
              onTap: () { _close(context); context.push('/needs'); },
            ),
            _DrawerTile(
              icon: Icons.handshake_outlined,
              label: l10n.shellPartners,
              onTap: () { _close(context); context.push('/partners'); },
            ),
            _DrawerTile(
              icon: Icons.notifications_outlined,
              label: l10n.shellNotifications,
              badge: unread,
              onTap: () { _close(context); context.push('/notifications'); },
            ),
            const Divider(),
            _DrawerTile(
              icon: Icons.sync,
              label: l10n.shellRefreshCatalog,
              onTap: () async {
                _close(context);
                await ref.read(catalogLocalCacheProvider).clear();
                ref.invalidate(catalogRefsProvider);
                ref.invalidate(countriesProvider);
                ref.invalidate(partCategoriesProvider);
                // L'occupation des catégories n'est pas sur le disque — elle
                // suit le stock — mais le provider peut être vivant derrière ce
                // tiroir. Ce bouton doit tout rafraîchir, pas presque tout.
                ref.invalidate(categoriesAvecPiecesProvider);
                ref.invalidate(categoriesAccessoiresOccupeesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.shellCatalogRefreshed),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            _DrawerTile(
              icon: Icons.logout,
              label: l10n.shellSignOut,
              color: cs.error,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.shellSignedOut),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
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
            if (privateSalesEnabled) _DrawerTile(
              icon: Icons.sell_outlined, label: 'Mes annonces',
              onTap: () { _close(context); context.push('/my-listings'); },
            ),
            _DrawerTile(
              icon: Icons.garage_outlined,
              label: l10n.shellMyGarage,
              onTap: () { _close(context); context.push('/garage'); },
            ),
            _DrawerTile(
              icon: Icons.list_alt_outlined,
              label: l10n.shellMyNeeds,
              onTap: () { _close(context); context.push('/needs/mine'); },
            ),
            _DrawerTile(
              icon: Icons.phone_outlined,
              label: l10n.shellContact,
              onTap: () {
                _close(context);
                _showContactSheet(context);
              },
            ),
            const Divider(),
            _DrawerTile(
              icon: Icons.logout,
              label: l10n.shellSignOut,
              color: cs.error,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.shellSignedOut),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
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
            if (privateSalesEnabled) _DrawerTile(
              icon: Icons.directions_car_outlined, label: 'Voitures de particuliers',
              onTap: () { _close(context); context.push('/private-listings'); },
            ),
            _DrawerTile(
              icon: Icons.login,
              label: l10n.shellSignIn,
              onTap: () { _close(context); context.push('/login'); },
            ),
          ],

          // ════════════════════════════════════════════════════════
          // RÉGLAGES — communs aux trois états
          // ════════════════════════════════════════════════════════
          //
          // IL N'Y A PAS D'ÉCRAN DE RÉGLAGES DANS CETTE APPLICATION. Vérifié
          // avant d'en poser un : aucune route, aucune page, et le seul endroit
          // où un réglage d'application ait jamais vécu est ce tiroir — c'est
          // lui qui porte « Rafraîchir le catalogue ». Un écran de réglages
          // neuf pour une seule ligne aurait ajouté une route, un titre et une
          // barre de titre à traduire, pour cacher d'un niveau le réglage que
          // l'on veut justement qu'un anglophone trouve.
          //
          // Posé APRÈS les blocs par rôle, donc après « Se déconnecter », et
          // séparé : la langue n'appartient à aucun compte. Un même téléphone
          // passe du personnel au client sans que le choix de langue n'ait à
          // suivre, et le mettre dans un bloc conditionnel l'aurait fait
          // disparaître pour les deux autres états.
          const Divider(),

          // ── ESPACE PARTENAIRE : SOUS INTERRUPTEUR DISTANT ────────────
          //
          // Cette tuile n'avait AUCUNE condition, et c'était un problème
          // d'ordre de livraison plutôt que de rôle. Elle est posée après les
          // blocs par rôle, au même rang que la langue, parce qu'un partenaire
          // n'est ni `isStaff` ni `isClient` : il a sa propre session, et c'est
          // par ici qu'il s'inscrit et se connecte. La gater sur un rôle
          // l'enfermerait donc dehors et supprimerait l'inscription en
          // libre-service.
          //
          // L'interrupteur vient du SERVEUR, et il le faut : cette application
          // n'a ni configuration distante ni constante de compilation, de sorte
          // qu'une fois publiée, rien dans le téléphone ne permettait plus de
          // masquer cette entrée. Le drapeau voyage sur `GET /api/app/version`,
          // la seule réponse lue avant tout affichage.
          //
          // Fermé tant qu'on n'en sait rien — lecture en cours, réseau coupé,
          // ou serveur antérieur au champ. Mieux vaut une entrée absente
          // qu'une entrée qui mène à un refus.
          //
          // Ce n'est pas la sécurité : le serveur rend 503 sur tout le groupe
          // de routes partenaire, y compris aux binaires qui ignorent ce champ.
          // Ceci n'évite que l'entrée morte.
          if (ref.watch(espacePartenaireOuvertProvider)) _DrawerTile(
            icon: Icons.storefront_outlined,
            label: 'Espace partenaire',
            onTap: () { _close(context); context.push('/partner'); },
          ),
          const TuileLangue(),
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
      builder: (contexteFeuille) {
        final l10n = AppLocalizations.of(contexteFeuille);

        return Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shellContact,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _ContactTile(
              icon: Icons.phone_outlined,
              label: l10n.shellContactPhone,
              value: kContactPhoneDisplay,
              onTap: () => ouvrirLien(
                context,
                Uri.parse('tel:$kContactPhone'),
                valeurACopier: kContactPhoneDisplay,
                ceQuiNePeutPasSOuvrir: l10n.shellContactDialerTarget,
              ),
            ),
            const SizedBox(height: 12),
            _ContactTile(
              icon: Icons.chat_outlined,
              iconColor: const Color(0xFF25D366),
              label: 'WhatsApp',
              value: kContactPhoneDisplay,
              onTap: () => ouvrirLien(
                context,
                Uri.parse('https://wa.me/$kContactWhatsApp'),
                valeurACopier: kContactPhoneDisplay,
                // « WhatsApp » reste en dur, et n'a pas de clé : c'est un nom
                // de marque, identique dans les deux langues, et lui donner une
                // clé inviterait un traducteur à le traduire.
                ceQuiNePeutPasSOuvrir: 'WhatsApp',
              ),
            ),
            const SizedBox(height: 12),
            _ContactTile(
              icon: Icons.email_outlined,
              label: l10n.shellContactEmail,
              value: kContactEmail,
              onTap: () => ouvrirLien(
                context,
                Uri.parse('mailto:$kContactEmail'),
                valeurACopier: kContactEmail,
                ceQuiNePeutPasSOuvrir: l10n.shellContactMailTarget,
              ),
            ),
          ],
        ),
      );
      },
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
