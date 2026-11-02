import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/partner_repository.dart';
import 'partner_listings_page.dart';
import 'partner_notifications_page.dart';
import 'partner_session.dart';
import 'partner_localizations.dart';
import '../../../core/api/api_exception.dart';

class PartnerAccountPage extends ConsumerStatefulWidget {
  const PartnerAccountPage({super.key});
  @override
  ConsumerState<PartnerAccountPage> createState() => _PartnerAccountPageState();
}

class _PartnerAccountPageState extends ConsumerState<PartnerAccountPage> {
  final _form = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _register = false;
  bool _obscure = true;

  /// La forme d'une adresse, employée aux deux endroits où on en vérifie une.
  static final _adresse = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void dispose() {
    for (final controller in [
      _company,
      _contact,
      _email,
      _phone,
      _whatsapp,
      _password,
      _confirmation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final notifier = ref.read(partnerSessionProvider.notifier);
    if (_register) {
      await notifier.register({
        // Le champ vide ne part PAS comme nom : le serveur le refuserait en
        // `max:160` sans broncher, mais il l’enregistrerait comme une chaîne
        // vide si la couche de nettoyage du cadre venait à changer. « Absent »
        // et « vide » doivent arriver distinctement.
        if (_company.text.trim().isNotEmpty)
          'company_name': _company.text.trim(),
        'contact_name': _contact.text.trim(),
        // Même raison pour l’adresse : laissée vide, elle ne part pas.
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        if (_whatsapp.text.trim().isNotEmpty) 'whatsapp': _whatsapp.text.trim(),
        'password': _password.text, 'password_confirmation': _confirmation.text,
      });
    } else {
      await notifier.login(_email.text, _password.text);
    }
    if (mounted && ref.read(partnerSessionProvider).profile != null) {
      _password.clear();
      _confirmation.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(partnerSessionProvider);
    final profile = session.profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).partnerAccountsSpaceTitle),
        actions: [
          if (profile != null)
            IconButton(
              tooltip: AppLocalizations.of(context).shellSignOut,
              onPressed: session.loading
                  ? null
                  : ref.read(partnerSessionProvider.notifier).logout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: session.loading && profile == null
                ? const Center(child: CircularProgressIndicator())
                : profile != null
                ? _profile(context, profile, session)
                : session.deniedStatus != null
                ? _status(
                    context,
                    session.deniedStatus!,
                    session.reviewReason,
                    session,
                  )
                : _login(context, session),
          ),
        ),
      ),
    );
  }

  Widget _login(
    BuildContext context,
    PartnerSession session,
  ) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            _register
                ? AppLocalizations.of(context).partnerAccountsCompanyIntro
                : AppLocalizations.of(context).partnerAccountsActivityIntro,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _register
                ? AppLocalizations.of(context).partnerAccountsRegisterIntro
                : AppLocalizations.of(context).partnerAccountsLoginIntro,
          ),
          const SizedBox(height: 24),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(
                  AppLocalizations.of(context).partnerAccountsLoginTab,
                ),
              ),
              ButtonSegment(
                value: true,
                label: Text(
                  AppLocalizations.of(context).partnerAccountsRegisterTab,
                ),
              ),
            ],
            selected: {_register},
            onSelectionChanged: session.loading
                ? null
                : (value) => setState(() {
                    _register = value.first;
                    _form.currentState?.reset();
                  }),
          ),
          const SizedBox(height: 20),
          if (_register) ...[
            // ── LE NOM D’ENTREPRISE EST FACULTATIF ──────────────────────────
            //
            // Le vendeur type ici est un particulier ou un petit revendeur sans
            // raison sociale. L’exiger lui faisait inventer un nom, ou abandonner
            // l’inscription — et la seconde perte est muette.
            //
            // Le nom affiché sur l’annonce se replie alors sur celui du
            // responsable, côté SERVEUR
            // (`PartnerListingPresentation::seller()`), parce que les téléphones
            // déjà installés lisent ce champ en `String` nu.
            _field(
              _company,
              AppLocalizations.of(context).partnerAccountsCompanyOptional,
              'partner-company',
              required: false,
              icon: Icons.business_outlined,
              helper: AppLocalizations.of(
                context,
              ).partnerAccountsCompanyFallbackHelp,
            ),
            _field(
              _contact,
              AppLocalizations.of(context).partnerAccountsContactName,
              'partner-contact',
              icon: Icons.person_outline,
            ),
            _field(
              _phone,
              AppLocalizations.of(context).partnerAccountsBusinessPhone,
              'partner-phone',
              keyboard: TextInputType.phone,
              icon: Icons.phone_outlined,
            ),
            _field(
              _whatsapp,
              AppLocalizations.of(context).partnerAccountsWhatsappOptional,
              'partner-whatsapp',
              required: false,
              keyboard: TextInputType.phone,
              icon: Icons.chat_outlined,
            ),
          ],
          // ── À L’INSCRIPTION, L’ADRESSE EST FACULTATIVE ──────────────────────
          //
          // Elle ne servait qu’à se connecter : aucun courriel n’est envoyé nulle
          // part, toutes les notifications passent dans l’application. C’est le
          // numéro de téléphone qui identifie désormais un partenaire, et c’est
          // la seule chose que tout vendeur a.
          //
          // ── À LA CONNEXION, LE CHAMP ACCEPTE LES DEUX ───────────────────────
          //
          // Les partenaires inscrits avant ce changement ont une adresse et s’en
          // servent. Leur retirer ce choix les mettrait dehors ; le serveur
          // tranche sur la présence d’un « @ ».
          if (_register)
            _field(
              _email,
              AppLocalizations.of(context).partnerAccountsEmailOptional,
              'partner-email',
              required: false,
              keyboard: TextInputType.emailAddress,
              icon: Icons.alternate_email,
              helper: AppLocalizations.of(
                context,
              ).partnerAccountsPhoneLoginHelp,
              validator: (value) {
                final saisie = value?.trim() ?? '';
                if (saisie.isEmpty) return null;
                return _adresse.hasMatch(saisie)
                    ? null
                    : AppLocalizations.of(context).partnerAccountsInvalidEmail;
              },
            )
          else
            _field(
              _email,
              AppLocalizations.of(context).partnerAccountsLoginIdentifier,
              'partner-email',
              keyboard: TextInputType.text,
              icon: Icons.person_outline,
              validator: (value) {
                final saisie = value?.trim() ?? '';
                if (saisie.isEmpty)
                  return AppLocalizations.of(
                    context,
                  ).partnerAccountsIdentifierRequired;
                if (saisie.contains('@')) {
                  return _adresse.hasMatch(saisie)
                      ? null
                      : AppLocalizations.of(
                          context,
                        ).partnerAccountsInvalidEmail;
                }
                // Six chiffres : de quoi écarter une faute de frappe sans
                // refuser un format de numéro que personne n’a mesuré.
                return RegExp(r'\d').allMatches(saisie).length >= 6
                    ? null
                    : AppLocalizations.of(
                        context,
                      ).partnerAccountsIdentifierInvalid;
              },
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TextFormField(
              key: const Key('partner-password'),
              controller: _password,
              obscureText: _obscure,
              autofillHints: [
                _register ? AutofillHints.newPassword : AutofillHints.password,
              ],
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).authPassword,
                border: const OutlineInputBorder(),
                helperText: _register
                    ? AppLocalizations.of(context).partnerAccountsPasswordHelp
                    : null,
                suffixIcon: IconButton(
                  tooltip: _obscure
                      ? AppLocalizations.of(context).partnerAccountsShowPassword
                      : AppLocalizations.of(
                          context,
                        ).partnerAccountsHidePassword,
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return AppLocalizations.of(
                    context,
                  ).partnerAccountsPasswordRequired;
                if (_register &&
                    (value.length < 12 ||
                        !RegExp(r'[a-zA-Z]').hasMatch(value) ||
                        !RegExp(r'\d').hasMatch(value)))
                  return AppLocalizations.of(
                    context,
                  ).partnerAccountsPasswordInvalid;
                return null;
              },
            ),
          ),
          if (_register)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextFormField(
                key: const Key('partner-confirmation'),
                controller: _confirmation,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).authPasswordConfirm,
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value != _password.text
                    ? AppLocalizations.of(
                        context,
                      ).partnerAccountsPasswordMismatch
                    : null,
              ),
            ),
          if (session.error != null) _notice(context, session.error!),
          if (session.restoreFailed)
            TextButton.icon(
              onPressed: ref.read(partnerSessionProvider.notifier).restore,
              icon: const Icon(Icons.refresh),
              label: Text(
                AppLocalizations.of(context).partnerAccountsRestoreSession,
              ),
            ),
          FilledButton.icon(
            key: const Key('partner-submit'),
            onPressed: session.loading ? null : _submit,
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              _register
                  ? AppLocalizations.of(context).partnerAccountsRequestAccount
                  : AppLocalizations.of(context).shellSignIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).partnerAccountsPublishingAfterApproval,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    String key, {
    bool required = true,
    TextInputType? keyboard,
    IconData? icon,
    String? helper,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      key: Key(key),
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: keyboard == null
          ? TextCapitalization.words
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: icon == null ? null : Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (value) => required && (value?.trim().isEmpty ?? true)
              ? AppLocalizations.of(context).partnerAccountsRequiredField
              : null,
    ),
  );

  Widget _profile(
    BuildContext context,
    PartnerProfile profile,
    PartnerSession session,
  ) {
    if (!profile.approved)
      return _status(context, profile.status, profile.reviewReason, session);
    return RefreshIndicator(
      onRefresh: ref.read(partnerSessionProvider.notifier).refresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // CETTE PUCE VIENT DU COFFRE pendant la fenêtre optimiste : la page
          // s'ouvre sur le profil enregistré, sans attendre le réseau, et le
          // statut affiché peut donc être périmé d'une exécution. On le dit,
          // plutôt que d'annoncer « Compte approuvé » sur la foi d'un
          // enregistrement que rien n'a encore confirmé.
          //
          // Elle REMPLACE le libellé au lieu de s'y ajouter : la page est
          // éprouvée jusqu'à un fort grossissement de texte, et une ligne de
          // plus y coûterait de la hauteur pour rien.
          Align(
            alignment: Alignment.centerLeft,
            child: session.sessionAConfirmer
                ? Chip(
                    avatar: Icon(Icons.sync, size: 18),
                    label: Text(
                      AppLocalizations.of(
                        context,
                      ).partnerAccountsStatusUnconfirmed,
                    ),
                  )
                : Chip(
                    avatar: Icon(Icons.verified_outlined, size: 18),
                    label: Text(
                      AppLocalizations.of(
                        context,
                      ).partnerAccountsAccountApproved,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).partnerAccountsCreateListingHelp),
          const SizedBox(height: 24),
          for (final kind in PartnerListingKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  leading: Icon(switch (kind) {
                    PartnerListingKind.vehicles =>
                      Icons.directions_car_outlined,
                    PartnerListingKind.parts => Icons.build_outlined,
                    PartnerListingKind.accessories =>
                      Icons.shopping_bag_outlined,
                  }, size: 32),
                  title: Text(
                    partnerListingKindLabel(AppLocalizations.of(context), kind),
                  ),
                  subtitle: Text(
                    kind == PartnerListingKind.vehicles
                        ? AppLocalizations.of(
                            context,
                          ).partnerAccountsSaleAndRental
                        : AppLocalizations.of(
                            context,
                          ).partnerAccountsInventorySummary,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PartnerListingsPage(kind: kind),
                    ),
                  ),
                ),
              ),
            ),
          // ── LES DEMANDES CLIENTS TRANSMISES PAR LA BOUTIQUE ───────────────
          //
          // C'est le travail que le partenaire vient chercher : une demande
          // approuvée par le personnel lui parvient ici. La pastille porte le
          // nombre de non-lues, parce qu'une tuile muette ne se visite pas.
          //
          // Elle n'a PAS sa place dans la boucle au-dessus : les trois autres
          // mènent à un inventaire, celle-ci à une boîte aux lettres.
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                key: const Key('partner-tuile-demandes'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                leading: const Icon(Icons.campaign_outlined, size: 32),
                title: Text(
                  AppLocalizations.of(context).partnerAccountsCustomerRequests,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  ).partnerAccountsCustomerRequestsSubtitle,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final compte =
                            ref.watch(partnerUnreadCountProvider).valueOrNull ??
                            0;

                        // Rien plutôt qu'un « 0 » : une pastille à zéro attire l'œil
                        // sur une absence, et apprend à ne plus la regarder.
                        return compte == 0
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  key: const Key('partner-demandes-pastille'),
                                  visualDensity: VisualDensity.compact,
                                  label: Text('$compte'),
                                ),
                              );
                      },
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PartnerNotificationsPage(),
                  ),
                ),
              ),
            ),
          ),
          if (session.error != null) _notice(context, session.error!),
          TextButton.icon(
            onPressed: session.loading
                ? null
                : ref.read(partnerSessionProvider.notifier).refresh,
            icon: const Icon(Icons.refresh),
            label: Text(
              AppLocalizations.of(context).partnerAccountsRefreshAccount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(
    BuildContext context,
    String status,
    String? reason,
    PartnerSession session,
  ) {
    final (title, description, icon) = switch (status) {
      'rejected' => (
        AppLocalizations.of(context).partnerAccountsRejectedTitle,
        AppLocalizations.of(context).partnerAccountsRejectedDescription,
        Icons.info_outline,
      ),
      'suspended' => (
        AppLocalizations.of(context).partnerAccountsSuspendedTitle,
        AppLocalizations.of(context).partnerAccountsSuspendedDescription,
        Icons.pause_circle_outline,
      ),
      _ => (
        AppLocalizations.of(context).partnerAccountsReceivedTitle,
        AppLocalizations.of(context).partnerAccountsReceivedDescription,
        Icons.hourglass_top_outlined,
      ),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      children: [
        Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (session.profile != null)
          Text(
            session.profile!.displayName,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 12),
        Text(description, textAlign: TextAlign.center),
        if (reason?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context).partnerAccountsReason(reason!),
                ),
              ),
            ),
          ),
        if (session.error != null) _notice(context, session.error!),
        const SizedBox(height: 24),
        if (session.profile != null)
          FilledButton.icon(
            onPressed: session.loading
                ? null
                : ref.read(partnerSessionProvider.notifier).refresh,
            icon: const Icon(Icons.refresh),
            label: Text(
              session.loading
                  ? AppLocalizations.of(context).partnerAccountsRefreshing
                  : AppLocalizations.of(context).partnerAccountsCheckStatus,
            ),
          ),
        TextButton(
          onPressed: session.loading
              ? null
              : session.profile != null
              ? ref.read(partnerSessionProvider.notifier).logout
              : ref.read(partnerSessionProvider.notifier).clearNotice,
          child: Text(
            session.profile != null
                ? AppLocalizations.of(context).shellSignOut
                : AppLocalizations.of(context).partnerAccountsBackToLogin,
          ),
        ),
      ],
    );
  }

  Widget _notice(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      messageFor(text, l10n: AppLocalizations.of(context)),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
