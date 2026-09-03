import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Redirection + feedback après connexion réussie
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && !next.isLoading &&
          (prev == null || !prev.isAuthenticated)) {
        // ScaffoldMessenger au-dessus du navigateur → survit à la navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bienvenue, ${next.displayName} !'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        context.go('/');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            // Align topCenter : la colonne occupe toute la hauteur disponible
            // sans centrage vertical qui gaspille de l'espace sur petit écran.
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── En-tête logo ──────────────────────────────
                      if (!isLandscape) ...[
                        const SizedBox(height: 32),
                        Icon(Icons.directions_car,
                            size: 56,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          'AutoParc',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vente · Location · Pièces · Accessoires',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car,
                                size: 22,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('AutoParc',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // ── Onglets Staff / Client ────────────────────
                      TabBar(
                        controller: _tabs,
                        tabs: const [
                          Tab(icon: Icon(Icons.badge),  text: 'Personnel'),
                          Tab(icon: Icon(Icons.person), text: 'Client'),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── Erreur globale ────────────────────────────
                      if (auth.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Formulaires ───────────────────────────────
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _StaffLoginForm(isLoading: auth.isLoading),
                            _ClientLoginForm(isLoading: auth.isLoading),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Formulaire staff (Sanctum) ─────────────────────────────────────

class _StaffLoginForm extends ConsumerStatefulWidget {
  final bool isLoading;
  const _StaffLoginForm({required this.isLoading});

  @override
  ConsumerState<_StaffLoginForm> createState() => _StaffLoginFormState();
}

class _StaffLoginFormState extends ConsumerState<_StaffLoginForm> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).loginStaff(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView : évite que le bouton soit masqué par le clavier
    // sur les petits écrans (< 600 px de hauteur).
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email professionnel',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mot de passe trop court' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: widget.isLoading ? null : _submit,
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width:  20,
                      child:  CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Se connecter'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Formulaire client (Firebase email/password + Google) ───────────

class _ClientLoginForm extends ConsumerStatefulWidget {
  final bool isLoading;
  const _ClientLoginForm({required this.isLoading});

  @override
  ConsumerState<_ClientLoginForm> createState() => _ClientLoginFormState();
}

class _ClientLoginFormState extends ConsumerState<_ClientLoginForm> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure      = true;
  bool _isRegister   = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (_isRegister) {
      ref.read(authProvider.notifier).registerClient(email, pass);
    } else {
      ref.read(authProvider.notifier).signInClientEmail(email, pass);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // ── Toggle connexion / inscription ──────────────────────
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Se connecter'),
                  icon: Icon(Icons.login),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('S\'inscrire'),
                  icon: Icon(Icons.person_add),
                ),
              ],
              selected: {_isRegister},
              onSelectionChanged: (s) => setState(() {
                _isRegister = s.first;
                _formKey.currentState?.reset();
              }),
            ),

            const SizedBox(height: 20),

            // ── Email ───────────────────────────────────────────────
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),

            const SizedBox(height: 16),

            // ── Mot de passe ────────────────────────────────────────
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              textInputAction: _isRegister
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: (_) { if (!_isRegister) _submit(); },
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
            ),

            // ── Confirmation (inscription uniquement) ───────────────
            if (_isRegister) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v != _passCtrl.text
                        ? 'Les mots de passe ne correspondent pas'
                        : null,
              ),
            ],

            const SizedBox(height: 24),

            // ── Bouton principal ────────────────────────────────────
            FilledButton(
              onPressed: widget.isLoading ? null : _submit,
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isRegister ? 'Créer mon compte' : 'Se connecter'),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ou'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // ── Google Sign-In ──────────────────────────────────────
            OutlinedButton.icon(
              onPressed: widget.isLoading
                  ? null
                  : () => ref.read(authProvider.notifier).signInWithGoogle(),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Continuer avec Google'),
            ),

            const SizedBox(height: 16),

            // ── Parcourir sans compte ───────────────────────────────
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Parcourir le catalogue sans compte'),
            ),
          ],
        ),
      ),
    );
  }
}
