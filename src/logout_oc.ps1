# --- Étape 1: Importer la bibliothèque de fonctions ---
. "$PSScriptRoot\functions.ps1"

# --- Étape 2: Initialisation du script ---
try {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    $configFile = Join-Path $projectRoot "config" "config.ini"
    $config = Get-AppConfiguration -ConfigFilePath $configFile
    # On a juste besoin de savoir où est oc.exe
    $params = Initialize-ScriptParameters -ConfigData $config
} catch {
    Write-Host "❌ ERREUR DE CONFIGURATION :" -ForegroundColor Red; Write-Host $_.Exception.Message; Read-Host "Appuyez sur Entrée..."; exit 1
}

# --- Étape 3: Exécuter 'oc logout' ---
Write-Host "--- Tentative de déconnexion ---" -ForegroundColor Cyan
& $params.OcPath logout

if ($?) {
    Write-Host "`n✅ Vous êtes maintenant déconnecté." -ForegroundColor Green
} else {
    Write-Host "`n❌ La déconnexion a échoué." -ForegroundColor Red
}