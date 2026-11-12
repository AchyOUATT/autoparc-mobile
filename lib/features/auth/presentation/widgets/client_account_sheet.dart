import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

/// Ouvre la feuille « Mon compte » du client : déconnexion et suppression.
///
/// Même feuille depuis le menu principal et depuis la pastille du garage, pour
/// que la suppression — exigée par Google Play — reste atteignable sans
/// dupliquer le parcours de confirmation.
void afficherFeuilleCompteClient(BuildContext context, AuthState auth) {
  // Le tiroir peut déjà être refermé : son `context` et son `ref` ne
  // survivent pas. On retient le navigateur racine, le messager et le
  // `ProviderContainer` — encore montés au-dessus du tiroir — pour la
  // feuille, le dialogue de confirmation et les SnackBar.
  final racine = Navigator.of(context, rootNavigator: true).context;
  final messager = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context);

  showModalBottomSheet<void>(
    context: racine,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (feuille) => ClientAccountSheet(
      auth: auth,
      onSignOut: () {
        messager.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(racine).garageSignedOut),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(feuille);
        container.read(authProvider.notifier).signOut();
      },
      onDelete: () {
        Navigator.pop(feuille);
        confirmerSuppressionCompteClient(racine, container, auth);
      },
    ),
  );
}

/// Demande confirmation, puis supprime le compte client.
///
/// La confirmation exige de saisir son adresse : un simple bouton
/// « Confirmer » se tape par réflexe, et ce geste-ci ne se rattrape pas —
/// les véhicules, leurs échéances et l'historique partent avec le compte.
/// Recopier son adresse oblige à lire ce qu'on est en train de faire.
Future<void> confirmerSuppressionCompteClient(
  BuildContext context,
  ProviderContainer container,
  AuthState auth,
) async {
  final email = auth.firebaseUser?.email ?? '';

  final confirme = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => ClientAccountDeletionDialog(email: email),
  );

  if (confirme != true || !context.mounted) return;

  final erreur = await container.read(authProvider.notifier).deleteAccount();

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        erreur ?? AppLocalizations.of(context).garageAccountDeleted,
      ),
      backgroundColor: erreur != null
          ? Theme.of(context).colorScheme.error
          : null,
    ),
  );
}

/// Feuille du compte client : identité, déconnexion, suppression.
class ClientAccountSheet extends StatelessWidget {
  const ClientAccountSheet({
    super.key,
    required this.auth,
    required this.onSignOut,
    required this.onDelete,
  });

  final AuthState auth;
  final VoidCallback onSignOut;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            title: Text(AppLocalizations.of(context).garageSignOutAction),
            onTap: onSignOut,
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
            title: Text(
              AppLocalizations.of(context).garageDeleteAccountTitle,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Confirmation de suppression de compte.
///
/// Énumère ce qui disparaît plutôt que de demander « êtes-vous sûr ? » : la
/// question ne renseigne sur rien, la liste si.
class ClientAccountDeletionDialog extends StatefulWidget {
  const ClientAccountDeletionDialog({super.key, required this.email});

  final String email;

  @override
  State<ClientAccountDeletionDialog> createState() =>
      _ClientAccountDeletionDialogState();
}

class _ClientAccountDeletionDialogState
    extends State<ClientAccountDeletionDialog> {
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
      title: Text(AppLocalizations.of(context).garageDeleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).garageAccountDeletionListTitle),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).garageAccountDeletionList),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).garageInvoicesRetained,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(
              context,
            ).garageDeleteAccountConfirmText((widget.email).toString()),
          ),
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
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
        FilledButton(
          onPressed: _correspond ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: Text(AppLocalizations.of(context).garageDeletePermanently),
        ),
      ],
    );
  }
}
