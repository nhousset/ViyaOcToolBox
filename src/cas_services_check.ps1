# --- Étape 1: Importer la bibliothèque de fonctions ---
. "$PSScriptRoot\functions.ps1"

$params = Initialize-And-Validate-Connection

# --- Boucle de menu ---
while ($true) {
    Clear-Host
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "  Verification des services SAS CAS"
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "`nChoisissez un service a verifier :" -ForegroundColor Yellow
    Write-Host "  [1] Service HTTP (sas-cas-server-default-http)"
    Write-Host "  [2] Service Binaire (sas-cas-server-default-bin)"
	
	Write-Host "  [3] Service HTTP (sas-cas-server-experimentation-http)"
    Write-Host "  [4] Service Binaire (sas-cas-server-experimentation-bin)"
	
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
		'3' {
            Write-Host "`n--- Infos sur le service CAS HTTP ---" -ForegroundColor Cyan
            $getSvcHttpArgs = @("-n", $params.DefaultNamespace, "get", "svc", "sas-cas-server-experimentation-http")
            Start-Process -FilePath $params.OcPath -ArgumentList $getSvcHttpArgs -Wait -NoNewWindow
        }
        '4' {
            Write-Host "`n--- Infos sur le service CAS Binaire ---" -ForegroundColor Cyan
            $getSvcBinArgs = @("-n", $params.DefaultNamespace, "get", "svc", "sas-cas-server-experimentation-bin")
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
