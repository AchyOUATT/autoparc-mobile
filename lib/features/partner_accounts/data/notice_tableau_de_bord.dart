import 'package:shared_preferences/shared_preferences.dart';

/// La ligne « votre accueil est maintenant votre tableau de bord », une fois.
///
/// Les partenaires déjà connectés AVANT cette version voient leur page
/// d'ouverture changer sans qu'on leur ait posé de question ; une ligne, une
/// fois, et « OK ». La préférence est posée à la fermeture, pas à l'affichage :
/// une application tuée avant l'appui remontre la ligne, ce qui est le bon
/// sens.
///
/// Elle est aussi posée à la NAISSANCE d'une session — connexion, inscription
/// (`PartnerSessionNotifier._authenticate`) : qui vient de s'inscrire n'a
/// jamais eu d'autre accueil, et « maintenant » lui annoncerait un changement
/// qui n'a pas eu lieu. Seule une session restaurée d'un coffre antérieur lit
/// donc la ligne.
class NoticeTableauDeBord {
  static const _cle = 'tableau_de_bord_presente';

  static Future<bool> estVue() async =>
      (await SharedPreferences.getInstance()).getBool(_cle) ?? false;

  static Future<void> marquerVue() async =>
      (await SharedPreferences.getInstance()).setBool(_cle, true);
}
