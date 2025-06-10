# --- Etape 1: Importer la bibliotheque de fonctions ---
. "$PSScriptRoot\functions.ps1"

# --- Etape 2: Initialisation et configuration ---
try {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    $configFile = Join-Path $projectRoot "config\config.ini"
    $config = Get-AppConfiguration -ConfigFilePath $configFile
    $params = Initialize-ScriptParameters -ConfigData $config
} catch {
    Write-Host "ERREUR DE CONFIGURATION :" -ForegroundColor Red; Write-Host $_.Exception.Message; Read-Host "Appuyez sur Entree pour fermer."; exit 1
}

# --- Etape 3: Verifier la connexion et la presence du namespace ---
Write-Host "--- Verification de la session OpenShift existante ---" -ForegroundColor Cyan
if (-not (Test-OcConnection -OcPath $params.OcPath)) {
    Write-Host "`nERREUR : Vous ne semblez pas etre connecte a OpenShift." -ForegroundColor Red; Read-Host "`nAppuyez sur Entree pour fermer."; exit 1
}
if ([string]::IsNullOrWhiteSpace($params.DefaultNamespace)) {
    Write-Host "ERREUR : Le parametre DEFAULT_NAMESPACE est requis dans config.ini pour ce script." -ForegroundColor Red; Read-Host "`nAppuyez sur Entree pour fermer."; exit 1
}
Write-Host "Session OpenShift active detectee." -ForegroundColor Green


# --- Etape 4: Executer la commande pour lister les routes ---
Write-Host "`n--- Liste des routes pour le namespace '$($params.DefaultNamespace)' ---" -ForegroundColor Cyan

# On prepare les arguments pour la commande 'oc get routes -o wide'
$getRoutesArgs = @(
    "get",
    "routes",
    "-n",
    $params.DefaultNamespace,
    "-o",
    "wide"
)

# On execute la commande avec Start-Process pour une meilleure fiabilite
Start-Process -FilePath $params.OcPath -ArgumentList $getRoutesArgs -Wait -NoNewWindow