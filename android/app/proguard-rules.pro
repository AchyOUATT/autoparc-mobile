# Regles de conservation pour le build release (R8).
#
# Flutter, Firebase et la plupart des greffons fournissent leurs propres regles,
# agregees automatiquement par le plugin Gradle : il n'y a rien a recopier ici.
# Ce fichier ne couvre que ce que l'analyse statique de R8 ne peut pas voir.

# flutter_local_notifications planifie des rappels via des classes atteintes par
# reflexion depuis la couche Android. Sans cette regle, les notifications
# d'echeance — visite technique, assurance, vidange — disparaissent en release
# et seulement en release : le defaut ne se voit sur aucun build de debug.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class * extends com.dexterous.flutterlocalnotifications.** { *; }

# Les modeles serialises par Gson (utilise par flutter_local_notifications)
# perdent leurs noms de champs si on les renomme.
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Le moteur Flutter appelle ces points d'entree depuis le code natif.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Le moteur reference Play Core pour les « deferred components » — le
# telechargement de modules a la demande. L'application ne s'en sert pas, la
# bibliotheque n'est donc pas embarquee, et R8 s'arrete sur les classes
# manquantes : le build release echouait entierement, alors que ce code n'est
# jamais atteint. On lui dit de ne pas s'en alarmer plutot que d'embarquer une
# dependance inutile.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
