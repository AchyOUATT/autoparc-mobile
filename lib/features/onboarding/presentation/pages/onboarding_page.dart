import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/onboarding_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Données des écrans
// ─────────────────────────────────────────────────────────────────────────────

class _Slide {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

const _slides = [
  _Slide(
    icon:  Icons.directions_car_filled,
    color: Color(0xFF1A3C5E),
    title: 'Explorez le catalogue',
    body:  'Véhicules, pièces et accessoires en un seul endroit.\n'
           'Filtrez par type, carrosserie, ville ou disponibilité pour trouver exactement ce qu\'il vous faut.',
  ),
  _Slide(
    icon:  Icons.inbox_outlined,
    color: Color(0xFF2E7D32),
    title: 'Exprimez vos besoins',
    body:  'Vous ne trouvez pas votre bonheur ?\n'
           'Créez une alerte et recevez une notification dès qu\'un véhicule ou une pièce correspond à votre recherche.',
  ),
  _Slide(
    icon:  Icons.garage_outlined,
    color: Color(0xFF6A1B9A),
    title: 'Votre garage personnel',
    body:  'Ajoutez vos véhicules pour retrouver instantanément les pièces détachées compatibles.\n'
           'Votre historique vous suit à chaque visite.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _ctrl = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish() async {
    await OnboardingService.markDone();
    if (mounted) context.go('/');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() => _finish();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final slide = _slides[_page];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Bouton Passer ─────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _isLast ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _isLast ? null : _skip,
                  child: const Text('Passer'),
                ),
              ),
            ),

            // ── PageView ──────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i], size: size),
              ),
            ),

            // ── Indicateur + bouton ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width:  active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? slide.color : cs.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Bouton principal
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: slide.color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _next,
                      child: Text(
                        _isLast ? 'Commencer' : 'Suivant',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contenu d'un écran
// ─────────────────────────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  final Size   size;
  const _SlidePage({required this.slide, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width:  size.width * 0.45,
            height: size.width * 0.45,
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: size.width * 0.22,
              color: slide.color,
            ),
          ),
          const SizedBox(height: 48),

          // Titre
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: slide.color,
            ),
          ),
          const SizedBox(height: 16),

          // Corps
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
