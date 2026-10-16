import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

// ─────────────────────────────────────────────────────────────────────────────
// Signature de publication
// ─────────────────────────────────────────────────────────────────────────────
//
// La cle de signature ne vit pas dans le depot : `android/key.properties` et le
// fichier .jks sont ignores par git. Voir android/key.properties.example et la
// section « Publication » du README pour la creer.
//
// Google Play refuse tout bundle signe avec la cle de debug. Sans key.properties
// on retombe donc dessus — c'est ce qui permet a `flutter run --release` de
// fonctionner sans cle — mais on le dit haut et fort a chaque configuration, et
// la CI verifie le certificat du bundle avant de le publier. Un repli muet
// produirait un artefact que Play rejette apres coup, sans que rien n'ait
// signale l'absence de cle au moment ou elle comptait.
//
// Deux sources, dans cet ordre :
//
//  1. L'environnement — ANDROID_KEYSTORE_FILE, ANDROID_KEYSTORE_PASSWORD,
//     ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD. C'est ce qu'utilise la CI.
//
//     Elle ecrivait auparavant les mots de passe dans key.properties, par un
//     heredoc. Deux transformations s'intercalaient alors entre le secret et
//     Gradle : le shell developpait `$` et executait les accents graves, puis
//     java.util.Properties avalait les antislashs. Un mot de passe contenant l'un
//     de ces caracteres arrivait faux — pendant que l'epreuve de la cle, qui
//     lisait l'environnement, passait au vert. Lire la meme source que l'epreuve
//     supprime l'ecart.
//
//  2. android/key.properties — pour le poste de developpement. Attention : ce
//     format traite `\` comme un caractere d'echappement, il faut l'ecrire `\\`.
val fichierCle = rootProject.file("key.properties")
val cleDePublication = Properties().apply {
    if (fichierCle.exists()) {
        FileInputStream(fichierCle).use { load(it) }
    }
}

/** Valeur de l'environnement si elle existe, sinon de key.properties. */
fun parametreDeSignature(variable: String, cle: String): String? =
    System.getenv(variable)?.takeIf { it.isNotEmpty() }
        ?: cleDePublication.getProperty(cle)

val cheminDuMagasin   = parametreDeSignature("ANDROID_KEYSTORE_FILE", "storeFile")
val signatureDisponible = cheminDuMagasin != null

if (!signatureDisponible) {
    logger.lifecycle(
        "\n[AutoParc] Aucune cle de signature (ni ANDROID_KEYSTORE_FILE, ni " +
            "android/key.properties) : les builds release seront signes avec " +
            "la cle de DEBUG.\n" +
            "           Utilisable en local, refuse par Google Play. " +
            "Voir android/key.properties.example.\n"
    )
}

// -----------------------------------------------------------------------------
// Plancher de versionCode
// -----------------------------------------------------------------------------
//
// Le 20 septembre, un .aab construit sur un poste de developpement est parti
// chez Play. Il portait le `+1` de pubspec.yaml, soit versionCode 1, et l'URL
// de l'emulateur. Rien ne l'a signale : `flutter build appbundle` produit un
// artefact d'apparence normale, et le refus arrive apres le televersement, par
// des messages qui ne nomment ni le numero ni l'adresse.
//
// android/version_code_plancher.txt porte le plus haut versionCode que la CI
// ait jamais produit. Rien au dessus n'a pu etre publie : un build release qui
// le depasse est donc recevable, et un build qui ne le depasse pas s'arrete
// ici, avant de produire l'artefact.
//
// La verification ne porte que sur le bundle, pas sur l'APK. Play ne controle
// le versionCode que de ce qu'on lui televerse, et seul le .aab part chez lui ;
// un APK release se partage de la main a la main, et `flutter run --release`
// en construit un a chaque essai sur un telephone. Les bloquer n'eviterait
// aucun refus, et ferait desactiver le garde-fou.
val fichierPlancher = rootProject.file("version_code_plancher.txt")

gradle.taskGraph.whenReady {
    if (!fichierPlancher.exists()) return@whenReady

    // Le chemin du projet compte autant que le nom. AGP cree dans chaque
    // greffon Flutter des taches `bundleLibCompileToJarRelease` et
    // `bundleReleaseLocalLintAar` : treize modules, donc trente-neuf taches qui
    // commencent par « bundle » et finissent par « Release » dans n'importe
    // quel graphe release, y compris celui d'un simple APK. Filtrer sur le nom
    // seul declenchait le garde-fou sur `flutter run --release`. Seul `:app`
    // produit un artefact televersable, et il le nomme `bundleRelease`
    // (`bundle<Variante>Release` le jour ou des variantes apparaitraient).
    val publiable = allTasks.any { tache ->
        tache.project.path == ":app" && tache.name.startsWith("bundle")
    }
    if (!publiable) return@whenReady

    val plancher = fichierPlancher.readText().trim().toIntOrNull() ?: return@whenReady
    val code = flutter.versionCode

    if (code <= plancher) {
        throw GradleException(
            "\n[AutoParc] versionCode $code <= plancher $plancher.\n" +
                "           Google Play refuse tout bundle dont le code ne depasse\n" +
                "           pas celui du dernier envoi. Ce build porte le numero de\n" +
                "           pubspec.yaml, pas celui de la CI.\n\n" +
                "           Construire par le workflow Build Android, qui passe\n" +
                "           --build-number et l'URL de production. Pour un essai\n" +
                "           local : --build-number=" + (plancher + 1) + " ou plus.\n"
        )
    }
}

dependencies {
    // Desugaring — requis par flutter_local_notifications (API Java 8+ sur Android < 26)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Pas de dépendance Firebase déclarée ici : Authentication et Messaging
    // arrivent par leurs greffons Flutter, qui fixent eux-mêmes leurs versions.
    //
    // Cette section déclarait firebase-analytics, collé depuis l'assistant de
    // la console Firebase. Aucune ligne de Dart ne l'appelait, et il recueillait
    // pourtant d'office ouvertures, sessions, modèle d'appareil et pays — une
    // collecte à déclarer dans la politique de confidentialité et le formulaire
    // Play, pour un service dont personne ne lisait les chiffres. Retiré.
    //
    // La nomenclature firebase-bom qui l'accompagnait est partie avec lui : sans
    // dépendance à régler, elle ne pouvait plus que contredire les versions
    // choisies par les greffons.
}


android {
    namespace = "bf.autoparc.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Identifiant definitif : il ne peut plus changer une fois l'application publiee.
        applicationId = "bf.autoparc.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signatureDisponible) {
            create("release") {
                // Chemin relatif au dossier android/, ou absolu.
                storeFile     = rootProject.file(cheminDuMagasin!!)
                storePassword = parametreDeSignature("ANDROID_KEYSTORE_PASSWORD", "storePassword")
                keyAlias      = parametreDeSignature("ANDROID_KEY_ALIAS", "keyAlias")
                keyPassword   = parametreDeSignature("ANDROID_KEY_PASSWORD", "keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (signatureDisponible) "release" else "debug"
            )

            // R8 : reduit et obscurcit le code. `shrinkResources` supprime en
            // plus les ressources devenues inatteignables. Les regles de
            // conservation propres a Flutter et aux greffons sont fournies par
            // leurs propres fichiers, agreges automatiquement.
            isMinifyEnabled   = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
