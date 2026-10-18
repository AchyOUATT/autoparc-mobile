import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'langue.dart';

/// L'entrée du tiroir qui change la langue de l'interface.
///
/// ── POURQUOI ELLE N'EST PAS DANS `main.dart` ────────────────────────────────
///
/// Elle y est née, en widget privé, à côté du tiroir qui la porte. Elle en est
/// sortie pour une raison de mesure et non de rangement : `_AppShell` et
/// `_AppDrawer` sont privés, et `AutoParcApp` n'est pas montable dans un banc —
/// son shell initialise le service de notifications dans un
/// `addPostFrameCallback` et son routeur ouvre l'accueil, qui interroge le
/// garage. La bascule de langue serait donc restée la seule pièce du lot sans
/// banc : on aurait vérifié que le provider change l'affichage, et supposé que
/// la tuile appelle le provider.
///
/// Elle vit avec le reste de la mécanique de langue, et `tuile_langue_test.dart`
/// la touche pour de vrai.
///
/// Un `ListTile` avec la langue courante en sous-titre, et non deux boutons
/// radio posés à même le tiroir : le tiroir se referme à chaque appui, et deux
/// radios y auraient fait disparaître l'écran sous le doigt avant que l'on
/// voie l'effet. La boîte de dialogue, elle, reste ouverte le temps du choix et
/// montre la bascule derrière elle.
///
/// LES DEUX NOMS DE LANGUE NE SONT PAS TRADUITS, et c'est volontaire :
/// « Français » et « English » s'écrivent chacun dans leur propre langue. Un
/// anglophone qui ouvre une interface encore en français doit reconnaître
/// « English » sans rien lire d'autre ; traduire les intitulés lui donnerait
/// « Anglais », qu'il ne cherche pas.
class TuileLangue extends ConsumerWidget {
  const TuileLangue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langue = ref.watch(langueProvider);
    final l10n   = AppLocalizations.of(context);

    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: Text(l10n.shellLanguage),
      subtitle: Text(_nomDeLaLangue(langue)),
      onTap: () => _choisir(context, ref),
    );
  }

  static String _nomDeLaLangue(Locale locale) =>
      locale == localeAnglais ? 'English' : 'Français';

  Future<void> _choisir(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final choix = await showDialog<Locale>(
      context: context,
      // `RadioGroup` et non le couple `groupValue`/`onChanged` de chaque
      // `RadioListTile` : ces deux paramètres sont dépréciés depuis Flutter
      // 3.32, et ce dépôt mesure ses signalements d'analyse — en ajouter deux
      // pour un réglage de deux lignes n'était pas défendable.
      builder: (contexteDialogue) => RadioGroup<Locale>(
        groupValue: ref.read(langueProvider),
        onChanged: (choisie) => Navigator.pop(contexteDialogue, choisie),
        child: SimpleDialog(
          title: Text(l10n.shellLanguage),
          children: [
            for (final locale in const [localeFrancais, localeAnglais])
              RadioListTile<Locale>(
                value: locale,
                title: Text(_nomDeLaLangue(locale)),
              ),
          ],
        ),
      ),
    );

    if (choix == null) return;

    // `definir` pose l'état puis écrit sur le disque. Le tiroir n'est pas
    // refermé ici : le changement de langue reconstruit tout l'arbre, et
    // refermer en plus ferait sortir l'utilisateur du tiroir au moment même où
    // il vérifie que les intitulés ont changé.
    await ref.read(langueProvider.notifier).definir(choix);
  }
}
