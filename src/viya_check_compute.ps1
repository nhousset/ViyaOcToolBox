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

# --- Etape 3: Verifier la connexion et le namespace ---
# (Cette section ne change pas)
Write-Host "--- Verification de la session OpenShift existante ---" -ForegroundColor Cyan
if (-not (Test-OcConnection -OcPath $params.OcPath)) {
    Write-Host "`nERREUR : Vous ne semblez pas etre connecte a OpenShift." -ForegroundColor Red; Write-Host "Veuillez d'abord lancer le script 'start_login.bat' pour vous connecter." -ForegroundColor Yellow
    Read-Host "`nAppuyez sur Entree pour fermer."
    exit 1
}
Write-Host "Session OpenShift active detectee." -ForegroundColor Green
if (-not [string]::IsNullOrWhiteSpace($params.DefaultNamespace)) {
    & $params.OcPath "project" $params.DefaultNamespace | Out-Null
    if (-not $?) { Write-Host "Echec lors du changement vers le namespace '$($params.DefaultNamespace)'." -ForegroundColor Red; Read-Host "Appuyez sur Entree..."; exit 1 }
    Write-Host "Positionne sur le namespace '$($params.DefaultNamespace)'." -ForegroundColor Green
} else {
    Write-Host "ERREUR : Le parametre DEFAULT_NAMESPACE est requis dans config.ini pour ce script." -ForegroundColor Red
    Read-Host "`nAppuyez sur Entree pour fermer."
    exit 1
}

# --- Boucle principale du menu ---
while ($true) {
    Clear-Host
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "  Selection d'un pod Compute / Launcher"
    Write-Host "------------------------------------------------" -ForegroundColor Green

    # --- MODIFICATION MAJEURE : On recupere les objets pods via JSON ---
    
    # 1. On recupere tous les pods du namespace en format JSON
    # et on les convertit en objets PowerShell. C'est tres puissant.
    $allPods = & $params.OcPath get pods -n $params.DefaultNamespace -o json | ConvertFrom-Json
    
    # 2. On filtre ces objets en PowerShell pour ne garder que ceux qui nous interessent
    $filteredPods = $allPods.items | Where-Object { $_.metadata.name -match "compute|launcher|workload-orchestrator" }
    
    if (-not $filteredPods) {
        Write-Host "`nAucun pod correspondant trouve dans le namespace '$($params.DefaultNamespace)'." -ForegroundColor Yellow
        Read-Host "`nAppuyez sur Entree pour quitter."
        break
    }

    # 3. On construit le menu detaille et colore
    Write-Host "`nVeuillez selectionner un pod :" -ForegroundColor Yellow
    # Affichage des en-tetes pour aligner les colonnes
    Write-Host ("  {0,-4} {1,-65} {2,-15} {3}" -f "#", "NOM DU POD", "STATUT", "REDEMARRAGES")
    Write-Host ("  {0,-4} {1,-65} {2,-15} {3}" -f "--", "----------", "------", "------------")

    for ($i = 0; $i -lt $filteredPods.Length; $i++) {
        $pod = $filteredPods[$i]
        $podName = $pod.metadata.name
        $podStatus = $pod.status.phase
        
        # Calcul du nombre total de redemarrages de tous les conteneurs du pod
        $totalRestarts = ($pod.status.containerStatuses | Measure-Object -Property restartCount -Sum).Sum
        
        # Affichage de la ligne du menu
        Write-Host -NoNewline ("  [{0}]" -f ($i+1)) -ForegroundColor Green # Numero en couleur
        Write-Host (" {0,-65} {1,-15} {2}" -f $podName, $podStatus, $totalRestarts)
    }
    Write-Host "  [Q] Quitter"

    # --- Le reste du script (selection et menu secondaire) ne change pas ---
    $choice = (Read-Host "`nVotre choix").ToUpper()

    if ($choice -eq 'Q') {
        break 
    }

    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $filteredPods.Length) {
        $selectedIndex = [int]$choice - 1
        # On recupere le nom du pod a partir de l'objet selectionne
        $selectedPodName = $filteredPods[$selectedIndex].metadata.name
        
        Clear-Host
        Write-Host "------------------------------------------------" -ForegroundColor Green
        Write-Host "  Pod selectionne : $selectedPodName"
        Write-Host "------------------------------------------------" -ForegroundColor Green
        Write-Host "`nMenu d'actions pour ce pod (a developper) :" -ForegroundColor Yellow
        Write-Host "  [1] Action A"
        Write-Host "  [2] Action B"
        Write-Host "  [R] Revenir a la liste des pods"
        
        $actionChoice = (Read-Host "`nVotre choix").ToUpper()
        if ($actionChoice -eq 'R') {
            continue 
        }

        Write-Host "`nFonctionnalite non implementee."
        Read-Host "`nAppuyez sur Entree pour revenir a la liste des pods..."

    } else {
        Write-Host "`nChoix invalide." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}

Write-Host "`nAu revoir !"