import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/contact/autoparc_contact_provider.dart';
import '../../../../core/utils/lien_externe.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/password_recovery_repository.dart';

class PasswordRecoveryPage extends ConsumerStatefulWidget {
  const PasswordRecoveryPage({
    super.key,
    this.initialEmail = '',
    this.partner = false,
  });

  final String initialEmail;
  final bool partner;

  @override
  ConsumerState<PasswordRecoveryPage> createState() =>
      _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends ConsumerState<PasswordRecoveryPage> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  late PasswordRecoveryAccountType _accountType;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final email = widget.initialEmail.trim();
    _email = TextEditingController(
      text: _emailPattern.hasMatch(email) ? email : '',
    );
    _accountType = widget.partner
        ? PasswordRecoveryAccountType.partner
        : PasswordRecoveryAccountType.client;
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || _sent || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(passwordRecoveryRepositoryProvider)
          .request(
            email: _email.text,
            accountType: _accountType,
            languageCode: Localizations.localeOf(context).languageCode,
          );
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, AppLocalizations.of(context)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _message(Object error, AppLocalizations l10n) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => l10n.authEmailInvalid,
        'network-request-failed' => l10n.authErrorNetwork,
        'too-many-requests' => l10n.passwordRecoveryRateLimited,
        _ => l10n.passwordRecoveryUnavailable,
      };
    }
    if (error is ApiException) {
      if (error.isNetworkFailure) return l10n.authErrorNetwork;
      if (error.isThrottled) return l10n.passwordRecoveryRateLimited;
    }
    return l10n.passwordRecoveryUnavailable;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contact = ref.watch(autoparcContactProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: (MediaQuery.textScalerOf(context).scale(20) * 2.4)
            .clamp(kToolbarHeight, 112)
            .toDouble(),
        title: Text(l10n.passwordRecoveryTitle, maxLines: 2),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.passwordRecoveryIntro),
                  const SizedBox(height: 20),
                  if (!widget.partner && !_sent) ...[
                    Text(l10n.passwordRecoveryAccountType),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        for (final type in [
                          PasswordRecoveryAccountType.client,
                          PasswordRecoveryAccountType.staff,
                        ])
                          ChoiceChip(
                            key: Key('password-recovery-${type.name}'),
                            label: Text(
                              type == PasswordRecoveryAccountType.client
                                  ? l10n.passwordRecoveryClient
                                  : l10n.passwordRecoveryStaff,
                            ),
                            selected: _accountType == type,
                            onSelected: _sending
                                ? null
                                : (_) => setState(() {
                                    _accountType = type;
                                    _error = null;
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.partner) ...[
                    Text(
                      l10n.passwordRecoveryPartner,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.passwordRecoveryPartnerHelp),
                    const SizedBox(height: 16),
                  ],
                  if (_accountType == PasswordRecoveryAccountType.client) ...[
                    Text(l10n.passwordRecoveryGoogleHelp),
                    const SizedBox(height: 16),
                  ],
                  if (_sent) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.passwordRecoveryConfirmation,
                        key: const Key('password-recovery-confirmation'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.passwordRecoveryBackToLogin),
                    ),
                  ] else
                    Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('password-recovery-email'),
                            controller: _email,
                            enabled: !_sending,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              labelText: l10n.authEmail,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                _emailPattern.hasMatch(value?.trim() ?? '')
                                ? null
                                : l10n.authEmailInvalid,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _error!,
                                key: const Key('password-recovery-error'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('password-recovery-send'),
                            onPressed: _sending ? null : _send,
                            child: _sending
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.passwordRecoverySend),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.passwordRecoverySupportTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.passwordRecoverySupportHelp),
                  const SizedBox(height: 8),
                  Text(contact.phoneDisplay),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('password-recovery-call'),
                    icon: const Icon(Icons.call_outlined),
                    label: Text(l10n.privateSalesCallAutoParc),
                    onPressed: () => ouvrirLien(
                      context,
                      contact.phoneUri,
                      valeurACopier: contact.phoneDisplay,
                      ceQuiNePeutPasSOuvrir: l10n.shellContactDialerTarget,
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('password-recovery-whatsapp'),
                    icon: const Icon(Icons.chat_outlined),
                    label: Text(l10n.privateSalesWhatsappAutoParc),
                    onPressed: () => ouvrirLien(
                      context,
                      contact.whatsappUri,
                      valeurACopier: contact.phoneDisplay,
                      ceQuiNePeutPasSOuvrir: 'WhatsApp',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
