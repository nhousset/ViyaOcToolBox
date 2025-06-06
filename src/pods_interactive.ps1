# --- Étape 1: Importer la bibliothèque de fonctions ---
. "$PSScriptRoot\functions.ps1"


# --- Étape 2: Bloc d'initialisation du script ---
try {
    # Cette partie reste ici car $PSScriptRoot est spécifique au script en cours
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    $configFile = Join-Path $projectRoot "config\config.ini"
    
    # 1. On lit TOUTE la configuration
    $config = Get-AppConfiguration -ConfigFilePath $configFile

    # 2. On demande à la nouvelle fonction de nous préparer les variables nécessaires
    $params = Initialize-ScriptParameters -ConfigData $config

} catch {
    Write-Host "❌ ERREUR DE CONFIGURATION :" -ForegroundColor Red; Write-Host $_.Exception.Message; Read-Host "Appuyez sur Entrée..."; exit 1
}


# --- Étape 3: Vérifier la connexion ---
# On utilise la variable préparée par la fonction : $params.OcPath
Write-Host "--- Vérification de la session OpenShift existante ---" -ForegroundColor Cyan
if (-not (Test-OcConnection -OcPath $params.OcPath)) {
    Write-Host "`n❌ Vous ne semblez pas être connecté à OpenShift." -ForegroundColor Red
    Write-Host "Veuillez d'abord lancer le script 'oc_login.bat' pour vous connecter." -ForegroundColor Yellow
    Read-Host "`nAppuyez sur Entrée pour fermer."
    exit 1
}
Write-Host "✅ Session OpenShift active détectée." -ForegroundColor Green


# --- Étape 4: Opérations sur le cluster ---
# On utilise les variables préparées : $params.DefaultNamespace et $params.OcPath
if (-not [string]::IsNullOrWhiteSpace($params.DefaultNamespace)) {
    & $params.OcPath "project" $params.DefaultNamespace | Out-Null
    if (-not $?) { Write-Host "❌ Échec lors du changement vers le namespace '$($params.DefaultNamespace)'." -ForegroundColor Red; Read-Host "Appuyez sur Entrée..."; exit 1 }
    Write-Host "✅ Positionné sur le namespace '$($params.DefaultNamespace)'." -ForegroundColor Green
}


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

# Pour être sûr, ajoutons une ligne de débogage pour voir ce que le script essaie de faire
Write-Host "DEBUG: Commande -> Path: [$ocPath] / Arguments: [$($getPodsArguments -join ' ')]" -ForegroundColor DarkGray

# CORRECTION FINALE : Utilisation de Start-Process
Start-Process -FilePath $ocPath -ArgumentList $getPodsArguments -Wait -NoNewWindow