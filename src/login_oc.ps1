<#
.SYNOPSIS
    Script PowerShell pour se connecter à un cluster OpenShift et changer de namespace.
.DESCRIPTION
    Ce script lit un config.ini dans le dossier parent 'config/', exécute 'oc login',
    puis 'oc project' si un namespace par défaut est spécifié.
#>

# --- Étape 1: Définir les chemins et lire la configuration ---
try {
    # $PSScriptRoot est le dossier du script (src). On remonte d'un niveau pour trouver la racine.
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    
    # MODIFICATION ICI : Ajout du sous-dossier 'config' dans le chemin
    $configFile = Join-Path $projectRoot "config\config.ini"

    if (-not (Test-Path $configFile)) {
        throw "Le fichier de configuration '$configFile' est introuvable."
    }

    # Lecture du fichier .ini
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
Write-Host "▶️  Exécution : $ocPath $($loginArguments -join ' ')" -ForegroundColor Gray
& $ocPath $loginArguments

# --- Étape 4: Si la connexion réussit, changer de namespace ---
if ($?) {
    Write-Host "`n✅ Connexion réussie !" -ForegroundColor Green
    
    if (-not [string]::IsNullOrWhiteSpace($defaultNamespace)) {
        Write-Host "`n--- Changement de namespace par défaut ---" -ForegroundColor Cyan
        $projectArguments = @("project", $defaultNamespace)

        Write-Host "▶️  Exécution : $ocPath $($projectArguments -join ' ')" -ForegroundColor Gray
        & $ocPath $projectArguments

        if ($?) {
            Write-Host "✅ Positionné sur le namespace '$defaultNamespace'." -ForegroundColor Green
        } else {
            Write-Host "❌ Échec lors du changement vers le namespace '$defaultNamespace'." -ForegroundColor Red
        }
    }

} else {
    Write-Host "`n❌ Échec de la connexion." -ForegroundColor Red
    Write-Host "Vérifiez les messages d'erreur de 'oc.exe' ci-dessus, votre URL et votre token."
}