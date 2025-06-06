<#
.SYNOPSIS
    Script interactif pour lister les pods sur OpenShift selon un statut choisi.
.DESCRIPTION
    Ce script vérifie si une connexion OpenShift est active. Si oui, il demande
    à l'utilisateur de choisir un statut de pod à afficher.
#>

# --- Étape 1 & 2: Configuration et lecture des paramètres ---
try {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    $configFile = Join-Path $projectRoot "config\config.ini"
    if (-not (Test-Path $configFile)) { throw "Le fichier de configuration '$configFile' est introuvable." }
    $config = @{}
    Get-Content $configFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
            $key, $value = $line -split '=', 2
            $config[$key.Trim()] = $value.Trim()
        }
    }
    
    # On a toujours besoin de ces paramètres, mais plus de ceux pour le login (TOKEN, SERVER_URL)
    $defaultNamespace = $config.get_Item('DEFAULT_NAMESPACE')
    $ocPath = $config.get_Item('OC_EXECUTABLE_PATH')
    $appLabel = $config.get_Item('APP_LABEL')
    
    if ([string]::IsNullOrWhiteSpace($ocPath)) { $ocPath = "oc.exe" }

} catch {
    Write-Host "❌ ERREUR DE CONFIGURATION :" -ForegroundColor Red; Write-Host $_.Exception.Message; Read-Host "Appuyez sur Entrée..."; exit 1
}


# --- Étape 3: Vérification de la session OpenShift (REMPLACE LE LOGIN) ---
Write-Host "--- Vérification de la session OpenShift existante ---" -ForegroundColor Cyan

# 'oc status' est une commande légère qui échoue si on n'est pas connecté.
& $ocPath status | Out-Null

if (-not $?) {
    Write-Host "`n❌ Vous ne semblez pas être connecté à OpenShift." -ForegroundColor Red
    Write-Host "Veuillez d'abord lancer le script 'start_login.bat' pour vous connecter." -ForegroundColor Yellow
    Read-Host "`nAppuyez sur Entrée pour fermer."
    exit 1
}

Write-Host "✅ Session OpenShift active détectée." -ForegroundColor Green



# --- MENU INTERACTIF ---
Write-Host "`n"
Write-Host "Quel statut de pod souhaitez-vous afficher ?" -ForegroundColor Yellow
Write-Host "  [1] Running"
Write-Host "  [2] Pending"
Write-Host "  [3] Succeeded (Terminé avec succès)"
Write-Host "  [4] Failed (En échec)"
Write-Host "  [5] Tous les statuts"
$choice = Read-Host "Votre choix (1-5)"

$statusSelector = ""
switch ($choice) {
    '1' { $statusSelector = "--field-selector=status.phase=Running" }
    '2' { $statusSelector = "--field-selector=status.phase=Pending" }
    '3' { $statusSelector = "--field-selector=status.phase=Succeeded" }
    '4' { $statusSelector = "--field-selector=status.phase=Failed" }
    '5' { $statusSelector = "" }
    default {
        Write-Host "❌ Choix invalide. Le script va se terminer." -ForegroundColor Red
        Read-Host "Appuyez sur Entrée pour fermer."
        exit 1
    }
}

# --- Dernière étape : Lister les pods selon le choix ---
Write-Host "`n--- Liste des pods ---" -ForegroundColor Cyan

$getPodsArguments = @("get", "pods")
if (-not [string]::IsNullOrWhiteSpace($statusSelector)) { $getPodsArguments += $statusSelector }
if (-not [string]::IsNullOrWhiteSpace($appLabel)) {
    $getPodsArguments += "-l $appLabel"
    Write-Host "Filtre par label appliqué : '$appLabel'" -ForegroundColor Yellow
}

& $ocPath $getPodsArguments