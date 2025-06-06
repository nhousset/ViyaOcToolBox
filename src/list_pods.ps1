<#
.SYNOPSIS
    Script pour lister les pods en cours d'exécution (Running) sur OpenShift.
.DESCRIPTION
    Ce script se connecte, change de namespace (si défini dans config.ini),
    puis exécute 'oc get pods' pour n'afficher que les pods actifs.
#>

# --- Étape 1: Définir les chemins et lire la configuration ---
try {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    $configFile = Join-Path $projectRoot "config" "config.ini"

    if (-not (Test-Path $configFile)) {
        throw "Le fichier de configuration '$configFile' est introuvable."
    }

    $config = @{}
    Get-Content $configFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
            $key, $value = $line -split '=', 2
            $config[$key.Trim()] = $value.Trim()
        }
    }

    # --- Étape 2: Extraire les paramètres ---
    $serverUrl = $config['SERVER_URL']
    $token = $config['TOKEN']
    $defaultNamespace = $config.get_Item('DEFAULT_NAMESPACE')
    $skipTls = [bool]::Parse($config['INSECURE_SKIP_TLS_VERIFY'])
    $ocPath = $config.get_Item('OC_EXECUTABLE_PATH')
    
    if ([string]::IsNullOrWhiteSpace($ocPath)) { $ocPath = "oc.exe" }
    if ([string]::IsNullOrWhiteSpace($serverUrl) -or [string]::IsNullOrWhiteSpace($token)) {
        throw "SERVER_URL ou TOKEN est manquant dans config.ini."
    }

} catch {
    Write-Host "❌ ERREUR DE CONFIGURATION :" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Read-Host "Appuyez sur Entrée pour fermer."
    exit 1
}


# --- Étape 3: Exécuter 'oc login' ---
Write-Host "--- Tentative de connexion via oc.exe ---" -ForegroundColor Cyan
$loginArguments = @("login", $serverUrl, "--token=$token")
if ($skipTls) { $loginArguments += "--insecure-skip-tls-verify=true" }
# Exécute la commande de login, mais sans afficher sa sortie pour garder la console propre
& $ocPath $loginArguments | Out-Null

# --- Étape 4: Si la connexion réussit, continuer ---
if ($?) {
    Write-Host "✅ Connexion réussie." -ForegroundColor Green
    
    # Change de namespace si un namespace par défaut a été défini
    if (-not [string]::IsNullOrWhiteSpace($defaultNamespace)) {
        & $ocPath "project" $defaultNamespace | Out-Null
        if (-not $?) {
            Write-Host "❌ Échec lors du changement vers le namespace '$defaultNamespace'." -ForegroundColor Red
            Read-Host "Appuyez sur Entrée pour fermer."
            exit 1
        }
        Write-Host "✅ Positionné sur le namespace '$defaultNamespace'." -ForegroundColor Green
    }
    
    # --- NOUVELLE PARTIE : Lister les pods 'Running' ---
    Write-Host "`n--- Liste des pods en cours d'exécution (Running) ---" -ForegroundColor Cyan
    
    $getPodsArguments = @(
        "get",
        "pods",
        "--field-selector=status.phase=Running"
    )
    
    # Exécute la commande et affiche directement le résultat
    & $ocPath $getPodsArguments

} else {
    Write-Host "`n❌ Échec de la connexion." -ForegroundColor Red
    Write-Host "Vérifiez votre URL et votre token dans config.ini."
}