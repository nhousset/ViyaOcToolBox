<#
.SYNOPSIS
    Script PowerShell pour se connecter à un cluster OpenShift en utilisant oc.exe.
.DESCRIPTION
    Ce script est le moteur logique. Il lit les paramètres depuis config.ini
    et exécute la commande 'oc login'. Il est conçu pour être lancé via un .bat.
#>

# --- Étape 1: Définir les chemins et lire la configuration ---
try {
    # Trouve le répertoire où se trouve le script pour localiser config.ini
    $scriptDir = $PSScriptRoot
    $configFile = Join-Path $scriptDir "config.ini"

    if (-not (Test-Path $configFile)) {
        throw "Le fichier de configuration '$configFile' est introuvable."
    }

    # Initialise une table de hachage pour stocker la configuration
    $config = @{}
    Get-Content $configFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
            $key, $value = $line -split '=', 2
            $config[$key.Trim()] = $value.Trim()
        }
    }

    # --- Étape 2: Extraire et valider les paramètres ---
    $serverUrl = $config['SERVER_URL']
    $token = $config['TOKEN']
    $skipTls = [bool]::Parse($config['INSECURE_SKIP_TLS_VERIFY'])
    $ocPath = $config.get_Item('OC_EXECUTABLE_PATH')
    
    if ([string]::IsNullOrWhiteSpace($ocPath)) {
        $ocPath = "oc.exe" # Utilise 'oc.exe' du PATH si non spécifié
    }
    
    if ([string]::IsNullOrWhiteSpace($serverUrl) -or [string]::IsNullOrWhiteSpace($token)) {
        throw "SERVER_URL ou TOKEN est manquant dans config.ini."
    }

} catch {
    Write-Host "❌ ERREUR DE CONFIGURATION :" -ForegroundColor Red
    Write-Host $_.Exception.Message
    # Met en pause pour que l'utilisateur puisse lire l'erreur avant la fermeture
    Read-Host "Appuyez sur Entrée pour fermer."
    exit 1
}


# --- Étape 3: Construire et exécuter la commande 'oc login' ---
Write-Host "--- Tentative de connexion via oc.exe ---" -ForegroundColor Cyan

$ocArguments = @(
    "login",
    $serverUrl,
    "--token=$token"
)

if ($skipTls) {
    $ocArguments += "--insecure-skip-tls-verify=true"
}

Write-Host "▶️  Exécution de la commande : $ocPath $($ocArguments -join ' ')" -ForegroundColor Gray

# Exécution de la commande
& $ocPath $ocArguments

# Vérifie si la dernière commande a réussi
if ($?) {
    Write-Host "`n✅ Connexion réussie !" -ForegroundColor Green
} else {
    Write-Host "`n❌ Échec de la connexion." -ForegroundColor Red
    Write-Host "Vérifiez les messages d'erreur de 'oc.exe' ci-dessus, votre URL et votre token."
}
