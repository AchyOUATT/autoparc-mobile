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

dependencies {
    // Desugaring — requis par flutter_local_notifications (API Java 8+ sur Android < 26)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.18.0"))

    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
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
