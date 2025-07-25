# --- Étape 1: Importer la bibliothèque de fonctions ---
. "$PSScriptRoot\functions.ps1"

$params = Initialize-And-Validate-Connection


Write-Host "`n--- Liste des pods en cours d'exécution (Running) ---" -ForegroundColor Cyan
$getPodsArguments = @("get", "pods", "--field-selector=status.phase=Running")

Execute-OcCommand $getPodsArguments
