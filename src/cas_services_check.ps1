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
Write-Host "Session OpenShift active detectee sur le namespace par defaut: $($params.DefaultNamespace)" -ForegroundColor Green
Start-Sleep -Seconds 1

# --- Boucle de menu ---
while ($true) {
    Clear-Host
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "  Verification des services SAS CAS"
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "`nChoisissez un service a verifier :" -ForegroundColor Yellow
    Write-Host "  [1] Service HTTP (sas-cas-server-default-http)"
    Write-Host "  [2] Service Binaire (sas-cas-server-default-bin)"
    Write-Host "  [Q] Quitter"
    
    $choice = (Read-Host "`nVotre choix").ToUpper()

    if ($choice -eq 'Q') { break }

    switch ($choice) {
        '1' {
            Write-Host "`n--- Infos sur le service CAS HTTP ---" -ForegroundColor Cyan
            $getSvcHttpArgs = @("-n", $params.DefaultNamespace, "get", "svc", "sas-cas-server-default-http")
            Start-Process -FilePath $params.OcPath -ArgumentList $getSvcHttpArgs -Wait -NoNewWindow
        }
        '2' {
            Write-Host "`n--- Infos sur le service CAS Binaire ---" -ForegroundColor Cyan
            $getSvcBinArgs = @("-n", $params.DefaultNamespace, "get", "svc", "sas-cas-server-default-bin")
            Start-Process -FilePath $params.OcPath -ArgumentList $getSvcBinArgs -Wait -NoNewWindow
        }
        default {
            Write-Host "`nChoix invalide." -ForegroundColor Red
            Start-Sleep -Seconds 2
            continue
        }
    }
    Read-Host "`nAppuyez sur Entree pour revenir au menu..."
}
Write-Host "`nAu revoir !"