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

# --- NOUVEAU : Boucle de menu infinie ---
while ($true) {
    # Nettoie l'ecran pour un affichage propre a chaque tour de boucle
    Clear-Host
    
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "  Menu Interactif - Liste des Pods"
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "`nQuel statut de pod souhaitez-vous afficher ?" -ForegroundColor Yellow
    Write-Host "  [1] Running"
    Write-Host "  [2] Pending"
    Write-Host "  [3] Succeeded (Termine avec succes)"
    Write-Host "  [4] Failed (En echec)"
    Write-Host "  [5] Tous les statuts"
    Write-Host "  [Q] Quitter"
    
    # On passe le choix en majuscule pour accepter 'q' ou 'Q'
    $choice = (Read-Host "`nVotre choix").ToUpper()

    # Si l'utilisateur choisit de quitter, on sort de la boucle 'while'
    if ($choice -eq 'Q') {
        break
    }

    $statusSelector = ""
    switch ($choice) {
        '1' { $statusSelector = "--field-selector=status.phase=Running" }
        '2' { $statusSelector = "--field-selector=status.phase=Pending" }
        '3' { $statusSelector = "--field-selector=status.phase=Succeeded" }
        '4' { $statusSelector = "--field-selector=status.phase=Failed" }
        '5' { $statusSelector = "" }
        default {
            Write-Host "`nChoix invalide." -ForegroundColor Red
            # Attend 2 secondes avant de ré-afficher le menu
            Start-Sleep -Seconds 2
            # 'continue' passe au tour de boucle suivant
            continue
        }
    }

    Write-Host "`n--- Liste des pods ---" -ForegroundColor Cyan
    $getPodsArguments = @("get", "pods")
    if (-not [string]::IsNullOrWhiteSpace($statusSelector)) { $getPodsArguments += $statusSelector }
    if (-not [string]::IsNullOrWhiteSpace($params.AppLabel)) {
        $getPodsArguments += "-l $($params.AppLabel)"
        Write-Host "Filtre par label applique : '$($params.AppLabel)'" -ForegroundColor Yellow
    }

    Start-Process -FilePath $params.OcPath -ArgumentList $getPodsArguments -Wait -NoNewWindow
    
    # Pause a la fin de chaque action pour que l'utilisateur puisse voir le resultat
    Read-Host "`nAppuyez sur Entree pour revenir au menu..."
}

Write-Host "`nAu revoir !"