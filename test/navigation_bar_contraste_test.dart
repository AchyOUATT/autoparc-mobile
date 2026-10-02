import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/widgets/navigation_bar_theme.dart';

/// La lisibilité de la barre de navigation, dans les deux thèmes.
///
/// Le défaut que ce fichier verrouille ne se voyait pas en développement : les
/// couleurs de la barre étaient écrites en dur — `Colors.white` pour l'onglet
/// actif, `#B0CCDE` pour les autres — et choisies sur le fond bleu sombre du
/// thème clair. En thème sombre, `colorScheme.primary` devient une teinte
/// claire, et les mêmes couleurs tombaient à 1,70:1 et **1,02:1**. À 1,02:1,
/// l'onglet n'est pas difficile à lire : il n'est pas là.
///
/// Un test qui se contenterait de vérifier « la couleur vaut bien onPrimary »
/// ne protégerait rien — c'est exactement ce qu'affirmait l'ancien code pour
/// les icônes, à 55 % d'opacité, soit 2,79:1 en nuit. On mesure donc le
/// contraste réel, celui que l'œil subit, contre les seuils WCAG : 4,5:1 pour
/// un texte de 12 px, 3:1 pour une icône.
///
/// Les seuils sont éprouvés sur les deux thèmes **et** sur une poignée de
/// teintes de base : le jour où quelqu'un changera la couleur d'amorce de
/// l'application, ce test dira tout de suite si la barre reste lisible.
void main() {
  /// Luminance relative, au sens de WCAG 2.
  double luminance(Color c) {
    double canal(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
  }

  /// Compose une couleur semi-transparente sur son fond.
  ///
  /// Indispensable ici : les onglets inactifs sont peints en opacité, et
  /// mesurer leur contraste sans les aplatir donnerait un chiffre qui ne
  /// correspond à rien de ce qui s'affiche.
  Color aplatir(Color dessus, Color fond) => Color.from(
        alpha: 1.0,
        red: dessus.r * dessus.a + fond.r * (1 - dessus.a),
        green: dessus.g * dessus.a + fond.g * (1 - dessus.a),
        blue: dessus.b * dessus.a + fond.b * (1 - dessus.a),
      );

  double contraste(Color dessus, Color fond) {
    final a = luminance(aplatir(dessus, fond));
    final b = luminance(fond);
    return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
  }

  /// La couleur que la barre donne réellement à un onglet.
  Color couleurTexte(NavigationBarThemeData theme, {required bool actif}) =>
      theme.labelTextStyle!.resolve(
        actif ? {WidgetState.selected} : <WidgetState>{},
      )!.color!;

  Color couleurIcone(NavigationBarThemeData theme, {required bool actif}) =>
      theme.iconTheme!.resolve(
        actif ? {WidgetState.selected} : <WidgetState>{},
      )!.color!;

  /// Seuils WCAG AA.
  const seuilTexte = 4.5;
  const seuilIcone = 3.0;

  /// La teinte de l'application, et quelques autres pour que le test survive
  /// à un changement de charte.
  const teintes = <String, Color>{
    'bleu ardoise (actuelle)': Color(0xFF8AAFC8),
    'vert': Color(0xFF2E7D32),
    'orange': Color(0xFFE65100),
    'violet': Color(0xFF6A1B9A),
  };

  for (final brightness in Brightness.values) {
    group('Barre de navigation — thème ${brightness.name}', () {
      final couleurs = ColorScheme.fromSeed(
        seedColor: teintes['bleu ardoise (actuelle)']!,
        brightness: brightness,
      );
      final theme = barreNavigationTheme(couleurs);
      final fond = theme.backgroundColor!;

      test('le libellé de l\'onglet actif se lit', () {
        final ratio = contraste(couleurTexte(theme, actif: true), fond);

        expect(ratio, greaterThanOrEqualTo(seuilTexte),
            reason: 'Onglet actif à ${ratio.toStringAsFixed(2)}:1 sur $fond.');
      });

      /// Le défaut signalé par l'utilisateur.
      test('le libellé des onglets inactifs se lit', () {
        final ratio = contraste(couleurTexte(theme, actif: false), fond);

        expect(ratio, greaterThanOrEqualTo(seuilTexte),
            reason: 'Onglet inactif à ${ratio.toStringAsFixed(2)}:1 sur $fond. '
                'C\'est ce qui rendait la barre illisible en mode nuit.');
      });

      test('les icônes se lisent, actives comme inactives', () {
        for (final actif in [true, false]) {
          final ratio = contraste(couleurIcone(theme, actif: actif), fond);

          expect(ratio, greaterThanOrEqualTo(seuilIcone),
              reason: 'Icône ${actif ? 'active' : 'inactive'} à '
                  '${ratio.toStringAsFixed(2)}:1 sur $fond.');
        }
      });

      /// Lisible ne suffit pas : il faut aussi distinguer l'onglet courant.
      test('l\'onglet actif se distingue des autres', () {
        final actif = theme.labelTextStyle!.resolve({WidgetState.selected})!;
        final inactif = theme.labelTextStyle!.resolve(<WidgetState>{})!;

        expect(actif.fontWeight, isNot(inactif.fontWeight),
            reason: 'Si les deux se lisent aussi bien, c\'est la graisse qui '
                'doit dire lequel est ouvert.');
      });
    });
  }

  /// Le test qui survivra à un changement de charte.
  test('la barre reste lisible quelle que soit la teinte de base', () {
    for (final entree in teintes.entries) {
      for (final brightness in Brightness.values) {
        final couleurs = ColorScheme.fromSeed(
          seedColor: entree.value,
          brightness: brightness,
        );
        final theme = barreNavigationTheme(couleurs);
        final fond = theme.backgroundColor!;

        for (final actif in [true, false]) {
          final ratio = contraste(couleurTexte(theme, actif: actif), fond);

          expect(ratio, greaterThanOrEqualTo(seuilTexte),
              reason: '${entree.key}, ${brightness.name}, onglet '
                  '${actif ? 'actif' : 'inactif'} : '
                  '${ratio.toStringAsFixed(2)}:1.');
        }
      }
    }
  });

  /// Garde-fou contre le retour des couleurs écrites en dur.
  test('aucune couleur de la barre n\'est indépendante du thème', () {
    final clair = barreNavigationTheme(
      ColorScheme.fromSeed(seedColor: const Color(0xFF8AAFC8)),
    );
    final sombre = barreNavigationTheme(
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF8AAFC8),
        brightness: Brightness.dark,
      ),
    );

    for (final actif in [true, false]) {
      expect(
        couleurTexte(clair, actif: actif),
        isNot(couleurTexte(sombre, actif: actif)),
        reason: 'Une couleur identique dans les deux thèmes est une couleur '
            'écrite en dur : elle ne peut pas convenir aux deux fonds.',
      );
    }
  });
}
