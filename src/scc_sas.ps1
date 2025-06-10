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

# --- Etape 3: Verifier la connexion ---
Write-Host "--- Verification de la session OpenShift existante ---" -ForegroundColor Cyan
if (-not (Test-OcConnection -OcPath $params.OcPath)) {
    Write-Host "`nERREUR : Vous ne semblez pas etre connecte a OpenShift." -ForegroundColor Red; Read-Host "`nAppuyez sur Entree pour fermer."; exit 1
}
Write-Host "Session OpenShift active detectee." -ForegroundColor Green

# --- Etape 4: Verifier les SCCs specifiques a SAS ---

# Liste des SCCs SAS a rechercher, basee sur la documentation
$sasSccNames = @(
    "sas-restricted",
    "sas-anyuid",
    "sas-privileged",
    "sas-cas-server",
    "sas-compute-server",
    "sas-java",
    "sas-programming-environment",
    "sas-model-publish-kaniko",
    "sas-model-repository",
    "sas-microanalytic-score",
    "sas-esp-project",
    "sas-opendistro",
    "sas-pyconfig"
)

Write-Host "`n--- Recherche des SCCs SAS specifiques sur le cluster ---" -ForegroundColor Cyan

# On recupere le nom de toutes les SCCs presentes sur le cluster
$allSccsOnCluster = (& $params.OcPath get scc -o=custom-columns=NAME:.metadata.name --no-headers)

# On filtre la liste pour ne garder que les SCCs SAS qui existent reellement
$foundSasSccs = $allSccsOnCluster | Where-Object { $sasSccNames -contains $_ }

if ($foundSasSccs) {
    Write-Host "Les SCCs SAS suivantes ont ete trouvees sur le cluster :" -ForegroundColor Green
    # On demande les details pour les SCCs trouvees
    $getSccArgs = @("get", "scc") + $foundSasSccs + @("-o", "wide")
    Start-Process -FilePath $params.OcPath -ArgumentList $getSccArgs -Wait -NoNewWindow
} else {
    Write-Host "Aucune des SCCs SAS recherchees n'a ete trouvee sur ce cluster." -ForegroundColor Yellow
}