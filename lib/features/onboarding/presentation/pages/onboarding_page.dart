import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/onboarding_service.dart';
import '../../../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Données des écrans
// ─────────────────────────────────────────────────────────────────────────────

/// Une diapositive : son icône, sa couleur, et DE QUOI LIRE ses deux textes.
///
/// [titre] et [corps] sont des fonctions et non des chaînes. La raison est
/// l'ordre de construction : cette liste est un objet de niveau supérieur,
/// construit au premier accès, c'est-à-dire avant qu'aucun `BuildContext`
/// n'existe — donc avant que la langue active soit connue. Des chaînes posées
/// ici seraient restées dans la langue du premier rendu, et un changement de
/// langue n'aurait rien changé à la démonstration.
class _Slide {
  final IconData icon;
  final Color color;
  final String Function(AppLocalizations) titre;
  final String Function(AppLocalizations) corps;

  const _Slide({
    required this.icon,
    required this.color,
    required this.titre,
    required this.corps,
  });
}

/// Les trois diapositives : l'icône, la couleur et les deux CLÉS de chacune.
///
/// La liste portait les textes et elle était `const` : une constante est
/// construite avant qu'aucun `BuildContext` n'existe, donc avant que la langue
/// soit connue, et les six chaînes y seraient restées françaises pour tout le
/// monde. Elle porte désormais des FONCTIONS de lecture, appliquées au moment
/// du rendu — ce qui la rend `final` et non `const`, le prix assumé de ce lot.
const _slides = <_Slide>[
  _Slide(
    icon: Icons.directions_car_filled,
    color: Color(0xFF1A3C5E),
    titre: _titreCatalogue,
    corps: _corpsCatalogue,
  ),
  _Slide(
    icon: Icons.inbox_outlined,
    color: Color(0xFF2E7D32),
    titre: _titreBesoins,
    corps: _corpsBesoins,
  ),
  _Slide(
    icon: Icons.garage_outlined,
    color: Color(0xFF6A1B9A),
    titre: _titreGarage,
    corps: _corpsGarage,
  ),
];

// Les six lectures, écrites une par une plutôt qu'en fermetures anonymes : une
// fermeture n'est pas une constante, et la liste ci-dessus cesserait d'être
// `const`. Ces fonctions de niveau supérieur, elles, en sont.
String _titreCatalogue(AppLocalizations l) => l.onboardingCatalogTitle;
String _corpsCatalogue(AppLocalizations l) => l.onboardingCatalogBody;
String _titreBesoins(AppLocalizations l) => l.onboardingNeedsTitle;
String _corpsBesoins(AppLocalizations l) => l.onboardingNeedsBody;
String _titreGarage(AppLocalizations l) => l.onboardingGarageTitle;
String _corpsGarage(AppLocalizations l) => l.onboardingGarageBody;

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
    final cs = Theme.of(context).colorScheme;
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
                  child: Text(AppLocalizations.of(context).onboardingSkip),
                ),
              ),
            ),

            // ── PageView ──────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) =>
                    _SlidePage(slide: _slides[i], size: size),
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
                        width: active ? 24 : 8,
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
                        _isLast
                            ? AppLocalizations.of(context).onboardingStart
                            : AppLocalizations.of(context).onboardingNext,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
  final Size size;
  const _SlidePage({required this.slide, required this.size});

  @override
  Widget build(BuildContext context) {
    // ── ELLE DÉFILE, ET C'EST UN DÉBORDEMENT MESURÉ ────────────────────────
    //
    // Cette diapositive était un `Padding` autour d'une `Column` centrée :
    // une boîte qui ne défile pas. À 320 points d'écran et à l'échelle 1,3 —
    // le deuxième cran des réglages Android, « Grande police » —, EN FRANÇAIS,
    // elle dépassait de 152 points :
    //
    //     A RenderFlex overflowed by 152 pixels on the bottom.
    //
    // Le cercle illustré prend 45 % de la largeur, le titre et le corps
    // grossissent avec le réglage, et la hauteur disponible ne bouge pas. La
    // fin du corps était donc hors d'atteinte sous une bande rayée, sur le
    // PREMIER écran qu'un nouvel utilisateur voit.
    //
    // LE DÉFAUT EST ANTÉRIEUR À LA TRADUCTION : le texte français n'a pas
    // changé d'un signe, et l'anglais déborde de la même façon. C'est le banc
    // « Les écrans de la vague 2 » de `accueil_langues_test.dart` qui est neuf.
    //
    // Le `ConstrainedBox` préserve l'apparence : en imposant au contenu une
    // hauteur MINIMALE égale à la hauteur reçue, le `MainAxisAlignment.center`
    // garde son effet tant que ça tient, et le défilement n'apparaît que
    // lorsque ça ne tient plus.
    return LayoutBuilder(
      builder: (context, contraintes) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: contraintes.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration
                Container(
                  width: size.width * 0.45,
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
                  slide.titre(AppLocalizations.of(context)),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: slide.color,
                  ),
                ),
                const SizedBox(height: 16),

                // Corps
                Text(
                  slide.corps(AppLocalizations.of(context)),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
