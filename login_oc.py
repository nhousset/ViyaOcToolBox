import configparser
import os
import subprocess

def oc_login():
    """
    Lit les informations depuis config.ini et exécute 'oc login'.
    """
    config = configparser.ConfigParser()
    config_file = 'config.ini'

    # --- Étape 1: Lire la configuration ---
    if not os.path.exists(config_file):
        print(f"❌ Erreur : Le fichier de configuration '{config_file}' est introuvable.")
        return

    config.read(config_file)

    try:
        # Récupère les informations de la section [OpenShift]
        server = config['OpenShift']['SERVER_URL']
        token = config['OpenShift']['TOKEN']
        skip_tls = config.getboolean('OpenShift', 'INSECURE_SKIP_TLS_VERIFY')
        # .get() est utilisé pour les valeurs optionnelles, ne lève pas d'erreur si la clé manque
        oc_path = config.get('OpenShift', 'OC_EXECUTABLE_PATH', fallback='oc')
        if not oc_path: # Si la clé est vide dans le fichier, on utilise 'oc' par défaut
            oc_path = 'oc'

    except (KeyError, configparser.NoSectionError) as e:
        print(f"❌ Erreur de configuration : {e}. Vérifiez votre fichier '{config_file}'.")
        return

    # --- Étape 2: Construire la commande 'oc login' ---
    command = [
        oc_path,
        "login",
        server,
        f"--token={token}",
    ]

    if skip_tls:
        command.append("--insecure-skip-tls-verify=true")

    # --- Étape 3: Exécuter la commande ---
    print("--- Tentative de connexion via oc.exe ---")
    print(f"▶️  Exécution de la commande : {' '.join(command)}")

    try:
        # Exécute la commande et capture la sortie (stdout) et les erreurs (stderr)
        result = subprocess.run(command, capture_output=True, text=True, check=False)

        # Vérifie le code de retour de la commande
        if result.returncode == 0:
            print("\n✅ Connexion réussie !")
            # Affiche la sortie standard de la commande oc
            print("--- Sortie de oc.exe ---")
            print(result.stdout)
        else:
            print(f"\n❌ Échec de la connexion (code d'erreur : {result.returncode}).")
            # Affiche la sortie d'erreur de la commande oc, qui est souvent très utile
            print("--- Erreurs de oc.exe ---")
            print(result.stderr)

    except FileNotFoundError:
        print(f"\n❌ Erreur critique : L'exécutable '{oc_path}' est introuvable.")
        print("Vérifiez que 'oc.exe' est dans votre PATH ou spécifiez son chemin dans config.ini.")
    except Exception as e:
        print(f"\n❌ Une erreur inattendue est survenue : {e}")


# --- Point d'entrée du programme ---
if __name__ == "__main__":
    oc_login()
