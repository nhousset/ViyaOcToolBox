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


# --- Étape 4: S'assurer que le namespace est défini ---
# On vérifie que le namespace est bien présent dans la configuration avant de continuer
if ([string]::IsNullOrWhiteSpace($params.DefaultNamespace)) {
    Write-Host "❌ Le paramètre 'DefaultNamespace' n'est pas défini dans le fichier de configuration." -ForegroundColor Red
    Read-Host "Appuyez sur Entrée pour fermer."
    exit 1
}
# On se positionne sur le projet, c'est une bonne pratique même si la commande suivante spécifie le namespace
& $params.OcPath "project" $params.DefaultNamespace | Out-Null
if (-not $?) { Write-Host "❌ Échec lors du changement vers le namespace '$($params.DefaultNamespace)'." -ForegroundColor Red; Read-Host "Appuyez sur Entrée..."; exit 1 }
Write-Host "✅ Positionné sur le namespace '$($params.DefaultNamespace)'." -ForegroundColor Green


# --- Étape 5: Lister les services du namespace ---
Write-Host "`n--- Liste des services pour le namespace '$($params.DefaultNamespace)' ---" -ForegroundColor Cyan

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
