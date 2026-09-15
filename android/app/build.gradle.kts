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
val fichierCle = rootProject.file("key.properties")
val signatureDisponible = fichierCle.exists()
val cleDePublication = Properties().apply {
    if (signatureDisponible) {
        FileInputStream(fichierCle).use { load(it) }
    }
}

if (!signatureDisponible) {
    logger.lifecycle(
        "\n[AutoParc] android/key.properties est absent : les builds release " +
            "seront signes avec la cle de DEBUG.\n" +
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
                // Chemin relatif au dossier android/, ou absolu — c'est ainsi
                // que la CI pointe vers le fichier qu'elle vient de decoder.
                storeFile     = rootProject.file(cleDePublication["storeFile"] as String)
                storePassword = cleDePublication["storePassword"] as String
                keyAlias      = cleDePublication["keyAlias"] as String
                keyPassword   = cleDePublication["keyPassword"] as String
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
