# --- Étape 1: Importer la bibliothèque de fonctions ---
. "$PSScriptRoot\functions.ps1"

$params = Initialize-And-Validate-Connection


# On prépare les arguments pour la commande : oc get svc -n <namespace>
$getSvcArguments = @(
    "get",
    "svc",
    "-n",
    $params.DefaultNamespace
)

# On exécute la commande et on affiche le résultat
& $params.OcPath $getSvcArguments

if (-not $?) { 
    Write-Host "`n❌ Échec lors de la récupération des services." -ForegroundColor Red
}

Read-Host "`nAppuyez sur Entrée pour fermer."
exit 0
