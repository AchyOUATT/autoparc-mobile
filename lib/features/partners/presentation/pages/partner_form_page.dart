import '../../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/partner.dart';
import '../../data/partner_repository.dart';
import '../../../../core/api/api_exception.dart';

// ════════════════════════════════════════════════════════════════════
// Formulaire création / édition d'un partenaire (staff)
// ════════════════════════════════════════════════════════════════════

class PartnerFormPage extends ConsumerStatefulWidget {
  /// null → création ; non-null → édition.
  final Partner? existing;

  const PartnerFormPage({super.key, this.existing});

  @override
  ConsumerState<PartnerFormPage> createState() => _PartnerFormPageState();
}

class _PartnerFormPageState extends ConsumerState<PartnerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _company;
  late final TextEditingController _contact;
  late final TextEditingController _phone;
  late final TextEditingController _wa;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _company = TextEditingController(text: widget.existing?.companyName);
    _contact = TextEditingController(text: widget.existing?.contactName);
    _phone = TextEditingController(text: widget.existing?.phone);
    _wa = TextEditingController(text: widget.existing?.whatsapp);
    _email = TextEditingController(text: widget.existing?.email);
    _notes = TextEditingController(text: widget.existing?.notes);
    _isActive = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _company.dispose();
    _contact.dispose();
    _phone.dispose();
    _wa.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = ref.read(partnerRepositoryProvider);
    final data = {
      'company_name': _company.text.trim(),
      if (_contact.text.trim().isNotEmpty) 'contact_name': _contact.text.trim(),
      'phone': _phone.text.trim(),
      if (_wa.text.trim().isNotEmpty) 'whatsapp': _wa.text.trim(),
      if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      'is_active': _isActive,
    };

    try {
      if (_isEdit) {
        await repo.updatePartner(widget.existing!.id, data);
      } else {
        await repo.createPartner(data);
      }
      if (mounted) context.pop(true); // true = refresh la liste
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messageFor(e, l10n: AppLocalizations.of(context))),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? AppLocalizations.of(context).partnersEditTitle
              : AppLocalizations.of(context).partnersCreateTitle,
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(AppLocalizations.of(context).partnersSave),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Informations entreprise ─────────────────────────────
            _SectionTitle(AppLocalizations.of(context).partnersCompanySection),
            TextFormField(
              controller: _company,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).partnersCompanyName,
                prefixIcon: Icon(Icons.business_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context).partnersRequiredField
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).partnersContactName,
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 24),
            // ── Contacts ────────────────────────────────────────────
            _SectionTitle(AppLocalizations.of(context).partnersContactsSection),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).partnersPhone,
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+225 07 00 00 00 00',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context).partnersRequiredField
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _wa,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                ).partnersWhatsappDifferent,
                prefixIcon: Icon(Icons.chat_outlined),
                hintText: '+225 07 00 00 00 00',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).partnersEmail,
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (!v.contains('@'))
                  return AppLocalizations.of(context).partnersInvalidEmail;
                return null;
              },
            ),

            const SizedBox(height: 24),
            // ── Notes ───────────────────────────────────────────────
            _SectionTitle(AppLocalizations.of(context).partnersNotesSection),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).partnersInternalNotes,
                prefixIcon: Icon(Icons.notes_outlined),
                hintText: AppLocalizations.of(context).partnersNotesHint,
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),
            // ── Statut ──────────────────────────────────────────────
            SwitchListTile.adaptive(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: Text(AppLocalizations.of(context).partnersActive),
              subtitle: Text(AppLocalizations.of(context).partnersInactiveHelp),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
