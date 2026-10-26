import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/partner_repository.dart';
import 'partner_listings_page.dart';
import 'partner_session.dart';

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

  @override
  void dispose() {
    for (final controller in [_company, _contact, _email, _phone, _whatsapp, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final notifier = ref.read(partnerSessionProvider.notifier);
    if (_register) {
      await notifier.register({
        'company_name': _company.text.trim(), 'contact_name': _contact.text.trim(),
        'email': _email.text.trim(), 'phone': _phone.text.trim(),
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
      appBar: AppBar(title: const Text('Espace partenaire'), actions: [
        if (profile != null) IconButton(tooltip: 'Se déconnecter', onPressed: session.loading ? null : ref.read(partnerSessionProvider.notifier).logout,
          icon: const Icon(Icons.logout)),
      ]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620),
        child: session.loading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : profile != null
            ? _profile(context, profile, session)
            : session.deniedStatus != null
              ? _status(context, session.deniedStatus!, session.reviewReason, session)
              : _login(context, session),
      ))),
    );
  }

  Widget _login(BuildContext context, PartnerSession session) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
    child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Icon(Icons.storefront_outlined, size: 52, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 16),
      Text(_register ? 'Présentez votre entreprise' : 'Développez votre activité', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(_register ? 'Après validation de votre compte, publiez vos véhicules, pièces et accessoires.'
        : 'Gérez vos annonces de vente et de location dans votre espace professionnel.'),
      const SizedBox(height: 24),
      SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Connexion')), ButtonSegment(value: true, label: Text('Inscription'))],
        selected: {_register}, onSelectionChanged: session.loading ? null : (value) => setState(() { _register = value.first; _form.currentState?.reset(); })),
      const SizedBox(height: 20),
      if (_register) ...[
        _field(_company, 'Nom de l’entreprise', 'partner-company', icon: Icons.business_outlined),
        _field(_contact, 'Nom du responsable', 'partner-contact', icon: Icons.person_outline),
        _field(_phone, 'Téléphone professionnel', 'partner-phone', keyboard: TextInputType.phone, icon: Icons.phone_outlined),
        _field(_whatsapp, 'WhatsApp (facultatif)', 'partner-whatsapp', required: false, keyboard: TextInputType.phone, icon: Icons.chat_outlined),
      ],
      _field(_email, 'Adresse email', 'partner-email', keyboard: TextInputType.emailAddress, icon: Icons.alternate_email,
        validator: (value) => value == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim()) ? 'Indiquez une adresse email valide.' : null),
      Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(
        key: const Key('partner-password'), controller: _password, obscureText: _obscure,
        autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
        decoration: InputDecoration(labelText: 'Mot de passe', border: const OutlineInputBorder(),
          helperText: _register ? '12 caractères minimum, avec des lettres et des chiffres.' : null,
          suffixIcon: IconButton(tooltip: _obscure ? 'Afficher le mot de passe' : 'Masquer le mot de passe', icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscure = !_obscure))),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Indiquez votre mot de passe.';
          if (_register && (value.length < 12 || !RegExp(r'[a-zA-Z]').hasMatch(value) || !RegExp(r'\d').hasMatch(value))) return 'Utilisez au moins 12 caractères, des lettres et des chiffres.';
          return null;
        },
      )),
      if (_register) Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(
        key: const Key('partner-confirmation'), controller: _confirmation, obscureText: true,
        decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', border: OutlineInputBorder()),
        validator: (value) => value != _password.text ? 'Les mots de passe ne correspondent pas.' : null,
      )),
      if (session.error != null) _notice(context, session.error!),
      if (session.restoreFailed) TextButton.icon(onPressed: ref.read(partnerSessionProvider.notifier).restore,
        icon: const Icon(Icons.refresh), label: const Text('Réessayer de restaurer ma session')),
      FilledButton.icon(key: const Key('partner-submit'), onPressed: session.loading ? null : _submit,
        icon: const Icon(Icons.arrow_forward), label: Text(_register ? 'Demander mon compte partenaire' : 'Se connecter')),
      const SizedBox(height: 16),
      const Text('La publication devient disponible après validation de votre entreprise.', textAlign: TextAlign.center),
    ])),
  );

  Widget _field(TextEditingController controller, String label, String key, {bool required = true, TextInputType? keyboard, IconData? icon, String? Function(String?)? validator}) =>
    Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(key: Key(key), controller: controller, keyboardType: keyboard,
      textCapitalization: keyboard == null ? TextCapitalization.words : TextCapitalization.none,
      decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon), border: const OutlineInputBorder()),
      validator: validator ?? (value) => required && (value?.trim().isEmpty ?? true) ? 'Ce champ est obligatoire.' : null));

  Widget _profile(BuildContext context, PartnerProfile profile, PartnerSession session) {
    if (!profile.approved) return _status(context, profile.status, profile.reviewReason, session);
    return RefreshIndicator(onRefresh: ref.read(partnerSessionProvider.notifier).refresh, child: ListView(
      padding: const EdgeInsets.all(24), children: [
        // CETTE PUCE VIENT DU COFFRE pendant la fenêtre optimiste : la page
        // s'ouvre sur le profil enregistré, sans attendre le réseau, et le
        // statut affiché peut donc être périmé d'une exécution. On le dit,
        // plutôt que d'annoncer « Compte approuvé » sur la foi d'un
        // enregistrement que rien n'a encore confirmé.
        //
        // Elle REMPLACE le libellé au lieu de s'y ajouter : la page est
        // éprouvée jusqu'à un fort grossissement de texte, et une ligne de
        // plus y coûterait de la hauteur pour rien.
        Align(alignment: Alignment.centerLeft, child: session.sessionAConfirmer
          ? const Chip(avatar: Icon(Icons.sync, size: 18), label: Text('Statut à confirmer…'))
          : const Chip(avatar: Icon(Icons.verified_outlined, size: 18), label: Text('Compte approuvé'))),
        const SizedBox(height: 12),
        Text(profile.companyName, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Créez une annonce, ajoutez vos photos puis publiez-la. Vos coordonnées accompagneront vos annonces.'),
        const SizedBox(height: 24),
        for (final kind in PartnerListingKind.values) Padding(padding: const EdgeInsets.only(bottom: 14), child: Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            leading: Icon(switch(kind) { PartnerListingKind.vehicles => Icons.directions_car_outlined, PartnerListingKind.parts => Icons.build_outlined, PartnerListingKind.accessories => Icons.shopping_bag_outlined }, size: 32),
            title: Text(kind.label), subtitle: Text(kind == PartnerListingKind.vehicles ? 'Vente et location' : 'Prix, disponibilité et stock'),
            trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PartnerListingsPage(kind: kind))),
          ),
        )),
        if (session.error != null) _notice(context, session.error!),
        TextButton.icon(onPressed: session.loading ? null : ref.read(partnerSessionProvider.notifier).refresh, icon: const Icon(Icons.refresh), label: const Text('Actualiser mon compte')),
      ],
    ));
  }

  Widget _status(BuildContext context, String status, String? reason, PartnerSession session) {
    final (title, description, icon) = switch(status) {
      'rejected' => ('Demande refusée', 'Votre demande n’a pas été approuvée. Consultez le motif ci-dessous.', Icons.info_outline),
      'suspended' => ('Compte suspendu', 'La gestion et la publication de vos annonces sont suspendues.', Icons.pause_circle_outline),
      _ => ('Inscription reçue', 'Votre entreprise est en attente de validation. Vous pourrez gérer vos annonces après approbation.', Icons.hourglass_top_outlined),
    };
    return ListView(padding: const EdgeInsets.fromLTRB(24, 48, 24, 32), children: [
      Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 24),
      Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      if (session.profile != null) Text(session.profile!.companyName, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(description, textAlign: TextAlign.center),
      if (reason?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 20), child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Motif : $reason')))),
      if (session.error != null) _notice(context, session.error!),
      const SizedBox(height: 24),
      if (session.profile != null) FilledButton.icon(onPressed: session.loading ? null : ref.read(partnerSessionProvider.notifier).refresh,
        icon: const Icon(Icons.refresh), label: Text(session.loading ? 'Actualisation…' : 'Vérifier mon statut')),
      TextButton(onPressed: session.loading ? null : session.profile != null ? ref.read(partnerSessionProvider.notifier).logout : ref.read(partnerSessionProvider.notifier).clearNotice,
        child: Text(session.profile != null ? 'Se déconnecter' : 'Revenir à la connexion')),
    ]);
  }

  Widget _notice(BuildContext context, String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(text,
    style: TextStyle(color: Theme.of(context).colorScheme.error)));
}
