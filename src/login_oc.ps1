<#
.SYNOPSIS
    Script PowerShell pour se connecter à un cluster OpenShift.
.DESCRIPTION
    Ce script utilise la bibliothèque de fonctions pour se connecter au cluster
    et se positionner sur le namespace par défaut.
#>

# --- Étape 1: Importer la bibliothèque de fonctions ---
. "$PSScriptRoot\functions.ps1"

# --- Étape 2: Initialisation et configuration du script ---
try {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    $configFile = Join-Path $projectRoot "config\config.ini"
    
    # 1. On lit la configuration
    $config = Get-AppConfiguration -ConfigFilePath $configFile

    # 2. On prépare toutes nos variables d'un coup
    $params = Initialize-ScriptParameters -ConfigData $config

    # 3. On valide que les paramètres nécessaires pour le login sont présents
    if ([string]::IsNullOrWhiteSpace($params.ServerUrl) -or [string]::IsNullOrWhiteSpace($params.Token)) {
        throw "SERVER_URL ou TOKEN est manquant dans config.ini."
    }

} catch {
    Write-Host "❌ ERREUR DE CONFIGURATION :" -ForegroundColor Red; Write-Host $_.Exception.Message; Read-Host "Appuyez sur Entrée..."; exit 1
}


# --- Étape 3: Exécuter 'oc login' ---
Write-Host "--- Tentative de connexion via oc.exe ---" -ForegroundColor Cyan
$loginArguments = @("login", $params.ServerUrl, "--token=$($params.Token)")
if ($params.SkipTls) { $loginArguments += "--insecure-skip-tls-verify=true" }
Write-Host "▶️  Exécution : $($params.OcPath) $($loginArguments -join ' ')" -ForegroundColor Gray
& $params.OcPath $loginArguments

# --- Étape 4: Si la connexion réussit, changer de namespace ---
if ($?) {
    Write-Host "`n✅ Connexion réussie !" -ForegroundColor Green
    
    if (-not [string]::IsNullOrWhiteSpace($params.DefaultNamespace)) {
        Write-Host "`n--- Changement de namespace par défaut ---" -ForegroundColor Cyan
        & $params.OcPath "project" $params.DefaultNamespace
    }
} else {
    Write-Host "`n❌ Échec de la connexion." -ForegroundColor Red
    Write-Host "Vérifiez les messages d'erreur de 'oc.exe' ci-dessus, votre URL et votre token."
}