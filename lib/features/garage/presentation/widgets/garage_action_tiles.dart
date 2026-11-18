import 'package:flutter/material.dart';

/// Garde chaque fragment d'un sous-titre d'un seul tenant.
///
/// Les espaces À L'INTÉRIEUR d'un fragment deviennent insécables ; seuls les
/// séparateurs « · » restent des points de coupure. Sans cela, « Dans 25 j »
/// ou « 140 ch » se coupaient en laissant « j » ou « ch » seuls sur la ligne
/// suivante.
String keepTogether(String text) => text
    .split(' · ')
    .map((fragment) => fragment.replaceAll(' ', '\u00A0'))
    .join(' · ');

/// L'importance visuelle d'une action de la fiche véhicule.
///
/// Deux actions seulement sont mises en avant — contrôler le véhicule et
/// trouver ses pièces — parce que ce sont celles qu'on vient chercher. Les
/// autres restent à portée, sans réclamer l'attention.
enum GarageActionEmphasis { primary, secondary, standard }

/// Une action de la fiche : une icône, un titre court, un sous-titre.
class GarageAction {
  final Key? key;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final GarageActionEmphasis emphasis;

  /// Un état à signaler devant le sous-titre (échéance proche, contrôle à
  /// reprendre). L'icône porte la couleur ; le texte garde celle du fond,
  /// pour que le contraste ne dépende pas de l'alerte.
  final IconData? statusIcon;
  final Color? statusColor;

  const GarageAction({
    this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasis = GarageActionEmphasis.standard,
    this.statusIcon,
    this.statusColor,
  });
}

/// La forme d'une tuile, choisie selon la place dont elle dispose.
enum GarageTileLayout {
  /// En ligne, pleine largeur : icône à gauche, chevron à droite.
  wide,

  /// Dans une colonne de grille confortable : icône à côté du titre.
  compact,

  /// Dans une colonne de grille étroite : icône au-dessus du titre, pour que
  /// le titre garde toute la largeur et ne se coupe jamais au milieu d'un mot.
  stacked,
}

/// Une tuile d'action, dans l'une des formes de [GarageTileLayout].
///
/// La surface entière est la cible tactile, jamais moins de 56 points de
/// haut : au-dessus des 48 recommandés, même au texte normal.
class GarageActionTile extends StatelessWidget {
  final GarageAction action;
  final GarageTileLayout layout;

  const GarageActionTile({
    super.key,
    required this.action,
    this.layout = GarageTileLayout.wide,
  });

  static const double minHeight = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final wide = layout == GarageTileLayout.wide;

    final (
      Color fond,
      Color texte,
      Color pastille,
      Color icone,
      BorderSide bord,
    ) = switch (action.emphasis) {
      GarageActionEmphasis.primary => (
        cs.primaryContainer,
        cs.onPrimaryContainer,
        cs.primary,
        cs.onPrimary,
        BorderSide.none,
      ),
      GarageActionEmphasis.secondary => (
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        cs.secondary,
        cs.onSecondary,
        BorderSide.none,
      ),
      GarageActionEmphasis.standard => (
        cs.surface,
        cs.onSurface,
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        BorderSide(color: cs.outlineVariant),
      ),
    };

    final taille = wide ? 40.0 : 36.0;
    final badge = Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: pastille,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(action.icon, size: wide ? 22 : 20, color: icone),
    );

    final titre = Text(
      action.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        color: texte,
        fontWeight: FontWeight.w600,
      ),
    );

    final sousTitre = Row(
      children: [
        if (action.statusIcon != null) ...[
          Icon(action.statusIcon, size: 14, color: action.statusColor ?? texte),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            action.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: texte),
          ),
        ),
      ],
    );

    final contenu = wide
        ? Row(
            children: [
              badge,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titre, const SizedBox(height: 2), sousTitre],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: texte),
            ],
          )
        : layout == GarageTileLayout.compact
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  badge,
                  const SizedBox(width: 10),
                  Expanded(child: titre),
                ],
              ),
              const SizedBox(height: 6),
              sousTitre,
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge,
              const SizedBox(height: 8),
              titre,
              const SizedBox(height: 2),
              sousTitre,
            ],
          );

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          key: action.key,
          color: fond,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: bord,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: action.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 12 : 10,
                  vertical: 10,
                ),
                child: contenu,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Les actions principales, l'une sous l'autre, en pleine largeur.
class GaragePrimaryActions extends StatelessWidget {
  final List<GarageAction> actions;

  const GaragePrimaryActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        GarageActionTile(action: actions[i]),
      ],
    ],
  );
}

/// Les actions courantes en grille de deux colonnes, de hauteur égale par
/// rangée.
///
/// La forme suit la largeur d'une colonne rapportée à l'échelle du texte :
/// côte à côte quand le titre a la place, empilée quand la colonne est
/// étroite, et une seule colonne de tuiles larges quand même l'empilement
/// couperait les titres (320 points avec le texte agrandi, par exemple).
class GarageActionGrid extends StatelessWidget {
  final List<GarageAction> actions;

  const GarageActionGrid({super.key, required this.actions});

  static const double spacing = 8;

  /// La forme des tuiles pour une largeur disponible et une échelle de texte.
  /// `null` : une seule colonne de tuiles larges.
  static GarageTileLayout? layoutFor(double width, double textScale) {
    final colonne = (width - spacing) / 2;
    if (colonne >= 150 * textScale) return GarageTileLayout.compact;
    if (colonne >= 110 * textScale) return GarageTileLayout.stacked;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final forme = layoutFor(
          constraints.maxWidth,
          MediaQuery.textScalerOf(context).scale(10) / 10,
        );

        if (forme == null) {
          return GaragePrimaryActions(actions: actions);
        }

        const colonnes = 2;
        final rangees = <Widget>[];
        for (var i = 0; i < actions.length; i += colonnes) {
          final cellules = <Widget>[];
          for (var c = 0; c < colonnes; c++) {
            if (c > 0) cellules.add(const SizedBox(width: spacing));
            final index = i + c;
            cellules.add(
              Expanded(
                child: index < actions.length
                    ? GarageActionTile(action: actions[index], layout: forme)
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (rangees.isNotEmpty) rangees.add(const SizedBox(height: spacing));
          rangees.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cellules,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rangees,
        );
      },
    );
  }
}

/// Le titre d'une section de la fiche, annoncé comme tel aux lecteurs
/// d'écran.
class GarageSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const GarageSectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
