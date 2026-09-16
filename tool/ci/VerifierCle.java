import java.io.File;
import java.io.FileInputStream;
import java.security.KeyStore;
import java.security.UnrecoverableKeyException;

/**
 * Éprouve la clé de signature comme le fait le plugin Android, avant lui.
 *
 * Une première épreuve se contentait de `keytool -list`, qui n'utilise que le
 * mot de passe du magasin. Elle passait au vert pendant que la compilation
 * échouait : dans un magasin PKCS12, un mot de passe de clé erroné ouvre le
 * magasin sans difficulté, et n'est refusé qu'au moment d'extraire la clé
 * privée — c'est-à-dire au moment où Gradle signe, après plusieurs minutes de
 * compilation, avec un message qui ne nomme pas la cause.
 *
 * Ce programme fait les deux opérations, dans l'ordre, et dit laquelle échoue.
 * Aucun mot de passe n'est affiché.
 *
 *   java tool/ci/VerifierCle.java <magasin> <alias>
 *
 * Les mots de passe se lisent dans ANDROID_KEYSTORE_PASSWORD et ANDROID_KEY_PASSWORD —
 * les variables mêmes que lit android/app/build.gradle.kts. Une version
 * précédente lisait des variables à part pendant que Gradle lisait un fichier
 * déformé par le shell : les deux ne voyaient pas le même mot de passe.
 *
 * Codes de sortie : 0 tout va bien, 1 fichier absent ou tronqué, 2 magasin
 * illisible, 3 alias absent, 4 clé privée refusée.
 */
public class VerifierCle {

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage : java VerifierCle.java <magasin> <alias>");
            System.exit(64);
        }

        final File fichier = new File(args[0]);
        final String alias = args[1];
        final String motDePasseMagasin = System.getenv().getOrDefault("ANDROID_KEYSTORE_PASSWORD", "");
        final String motDePasseCle = System.getenv().getOrDefault("ANDROID_KEY_PASSWORD", "");

        // Un secret base64 tronqué au copier-coller donne un fichier de quelques
        // octets : le cas le plus fréquent, et le plus déroutant, puisque le
        // décodage lui-même n'échoue pas.
        if (!fichier.isFile() || fichier.length() < 1000) {
            erreur("La clé décodée fait " + fichier.length()
                + " octets : le secret ANDROID_KEYSTORE_BASE64 est incomplet.");
            System.exit(1);
        }
        System.out.println("Clé décodée : " + fichier.length() + " octets.");

        final KeyStore magasin = KeyStore.getInstance("PKCS12");
        try (FileInputStream entree = new FileInputStream(fichier)) {
            magasin.load(entree, motDePasseMagasin.toCharArray());
        } catch (Exception e) {
            erreur("Le magasin refuse de s'ouvrir : ANDROID_KEYSTORE_PASSWORD est incorrect, "
                + "ou le fichier est corrompu. (" + e.getClass().getSimpleName() + ")");
            System.exit(2);
        }
        System.out.println("Magasin : ouvert avec ANDROID_KEYSTORE_PASSWORD.");

        if (!magasin.containsAlias(alias)) {
            erreur("L'alias « " + alias + " » est absent. Alias présents : "
                + String.join(", ", java.util.Collections.list(magasin.aliases())));
            System.exit(3);
        }
        System.out.println("Alias : « " + alias + " » présent.");

        try {
            magasin.getKey(alias, motDePasseCle.toCharArray());
        } catch (UnrecoverableKeyException e) {
            // Le cas qui a motivé ce programme.
            String indice = motDePasseCle.equals(motDePasseMagasin)
                ? "Les deux mots de passe sont pourtant identiques : la clé a peut-être été créée avec un autre."
                : "ANDROID_KEY_PASSWORD diffère de ANDROID_KEYSTORE_PASSWORD. Dans un magasin PKCS12 ils "
                    + "doivent être identiques — vérifier notamment un espace ou un retour à la ligne en fin de valeur.";
            erreur("La clé privée refuse ANDROID_KEY_PASSWORD. " + indice);
            System.exit(4);
        }
        System.out.println("Clé privée : ouverte avec ANDROID_KEY_PASSWORD.");
        System.out.println("Signature prête.");
    }

    /** Annotation GitHub Actions : l'erreur remonte en tête du résumé d'exécution. */
    private static void erreur(String message) {
        System.out.println("::error::" + message);
    }
}
