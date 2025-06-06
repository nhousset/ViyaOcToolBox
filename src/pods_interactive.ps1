# --- Étape 1: Importer la bibliothèque de fonctions ---
. "$PSScriptRoot\functions.ps1"

# --- Étape 2: Initialisation et configuration du script ---
try {
    # Cette partie ne fait qu'appeler les fonctions, toute la logique est déportée
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    $configFile = Join-Path $projectRoot "config\config.ini"
    
    # 1. On lit TOUTE la configuration
    $config = Get-AppConfiguration -ConfigFilePath $configFile

    # 2. On demande à la fonction de nous préparer les variables (y compris ocPath !)
    $params = Initialize-ScriptParameters -ConfigData $config

} catch {
    Write-Host "❌ ERREUR DE CONFIGURATION :" -ForegroundColor Red; Write-Host $_.Exception.Message; Read-Host "Appuyez sur Entrée..."; exit 1
}


# --- Étape 3: Vérifier la connexion en utilisant la variable préparée ---
Write-Host "--- Vérification de la session OpenShift existante ---" -ForegroundColor Cyan

# On utilise la variable préparée par la fonction : $params.OcPath
if (-not (Test-OcConnection -OcPath $params.OcPath)) {
    Write-Host "`n❌ Vous ne semblez pas être connecté à OpenShift." -ForegroundColor Red
    Write-Host "Veuillez d'abord lancer le script 'start_login.bat' pour vous connecter." -ForegroundColor Yellow
    Read-Host "`nAppuyez sur Entrée pour fermer."
    exit 1
}
Write-Host "✅ Session OpenShift active détectée." -ForegroundColor Green


# --- Étape 4: Opérations sur le cluster ---
# On utilise les variables du conteneur '$params'
if (-not [string]::IsNullOrWhiteSpace($params.DefaultNamespace)) {
    & $params.OcPath "project" $params.DefaultNamespace | Out-Null
    if (-not $?) { Write-Host "❌ Échec lors du changement vers le namespace '$($params.DefaultNamespace)'." -ForegroundColor Red; Read-Host "Appuyez sur Entrée..."; exit 1 }
    Write-Host "✅ Positionné sur le namespace '$($params.DefaultNamespace)'." -ForegroundColor Green
}

# --- MENU INTERACTIF ---
# ... (La suite du script reste identique et utilise $params.OcPath et $params.AppLabel) ...
Write-Host "`n"
Write-Host "Quel statut de pod souhaitez-vous afficher ?" -ForegroundColor Yellow
Write-Host "  [1] Running"; Write-Host "  [2] Pending"; Write-Host "  [3] Succeeded"; Write-Host "  [4] Failed"; Write-Host "  [5] Tous les statuts"
$choice = Read-Host "Votre choix (1-5)"

$statusSelector = ""
switch ($choice) {
    '1' { $statusSelector = "--field-selector=status.phase=Running" }
    '2' { $statusSelector = "--field-selector=status.phase=Pending" }
    '3' { $statusSelector = "--field-selector=status.phase=Succeeded" }
    '4' { $statusSelector = "--field-selector=status.phase=Failed" }
    '5' { $statusSelector = "" }
    default { Write-Host "❌ Choix invalide." -ForegroundColor Red; Read-Host "Appuyez sur Entrée..."; exit 1 }
}

Write-Host "`n--- Liste des pods ---" -ForegroundColor Cyan
$getPodsArguments = @("get", "pods")
if (-not [string]::IsNullOrWhiteSpace($statusSelector)) { $getPodsArguments += $statusSelector }
if (-not [string]::IsNullOrWhiteSpace($params.AppLabel)) {
    $getPodsArguments += "-l $($params.AppLabel)"
    Write-Host "Filtre par label appliqué : '$($params.AppLabel)'" -ForegroundColor Yellow
}

# On utilise la variable préparée par la fonction : $params.OcPath
Start-Process -FilePath $params.OcPath -ArgumentList $getPodsArguments -Wait -NoNewWindow