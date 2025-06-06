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
    Write-Host "`nERREUR : Vous ne semblez pas etre connecte a OpenShift." -ForegroundColor Red; Write-Host "Veuillez d'abord lancer le script 'start_login.bat' pour vous connecter." -ForegroundColor Yellow; Read-Host "`nAppuyez sur Entree pour fermer."; exit 1
}
Write-Host "Session OpenShift active detectee." -ForegroundColor Green
if (-not [string]::IsNullOrWhiteSpace($params.DefaultNamespace)) {
    & $params.OcPath "project" $params.DefaultNamespace | Out-Null
    if (-not $?) { Write-Host "Echec lors du changement vers le namespace '$($params.DefaultNamespace)'." -ForegroundColor Red; Read-Host "Appuyez sur Entree..."; exit 1 }
    Write-Host "Positionne sur le namespace '$($params.DefaultNamespace)'." -ForegroundColor Green
} else {
    Write-Host "ERREUR : Le parametre DEFAULT_NAMESPACE est requis dans config.ini pour ce script." -ForegroundColor Red; Read-Host "`nAppuyez sur Entree pour fermer."; exit 1
}

# --- Boucle principale du menu ---
while ($true) {
    Clear-Host
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "  Selection d'un pod Compute / Launcher"
    Write-Host "------------------------------------------------" -ForegroundColor Green

    # --- On recupere les objets pods via JSON ---
    $allPods = & $params.OcPath get pods -n $params.DefaultNamespace -o json | ConvertFrom-Json
    $filteredPods = $allPods.items | Where-Object { $_.metadata.name -match "compute|launcher|workload-orchestrator" }
    
    if (-not $filteredPods) {
        Write-Host "`nAucun pod correspondant trouve dans le namespace '$($params.DefaultNamespace)'." -ForegroundColor Yellow
        Read-Host "`nAppuyez sur Entree pour quitter."
        break
    }

    # --- MODIFICATION MAJEURE : On construit le menu tres detaille ---
    Write-Host "`nVeuillez selectionner un pod :" -ForegroundColor Yellow
    
    # Affichage des en-tetes pour aligner les colonnes
    $headerFormat = "  {0,-4} {1,-55} {2,-8} {3,-10} {4,-10} {5,-10} {6,-15} {7}"
    Write-Host ($headerFormat -f "#", "NOM DU POD", "READY", "STATUT", "RESTARTS", "AGE", "IP", "NODE")
    Write-Host ($headerFormat -f "--", "----------", "-----", "------", "----------", "---", "--", "----")

    for ($i = 0; $i -lt $filteredPods.Length; $i++) {
        $pod = $filteredPods[$i]
        
        # Extraction des nouvelles informations
        $podName = $pod.metadata.name
        $podStatus = $pod.status.phase
        
        $readyContainers = ($pod.status.containerStatuses | Where-Object { $_.ready }).Count
        $totalContainers = $pod.spec.containers.Count
        $readyString = "$readyContainers/$totalContainers"
        
        $totalRestarts = ($pod.status.containerStatuses | Measure-Object -Property restartCount -Sum).Sum
        
        $podIP = $pod.status.podIP
        $nodeName = $pod.spec.nodeName
        
        # Calcul simplifie de l'age du pod
        $creationTime = [datetime]$pod.metadata.creationTimestamp
        $age = (Get-Date) - $creationTime
        $ageString = ""
        if ($age.Days -gt 0) { $ageString = "$($age.Days)d" }
        elseif ($age.Hours -gt 0) { $ageString = "$($age.Hours)h" }
        elseif ($age.Minutes -gt 0) { $ageString = "$($age.Minutes)m" }
        else { $ageString = "$($age.Seconds)s" }

        # Affichage de la ligne du menu
        Write-Host -NoNewline ("  [{0}]" -f ($i+1)) -ForegroundColor Green # Numero en couleur
        Write-Host ($headerFormat -f "", $podName, $readyString, $podStatus, $totalRestarts, $ageString, $podIP, $nodeName)
    }
    Write-Host "  [Q] Quitter"

    # --- Le reste du script (selection et menu secondaire) ne change pas ---
    $choice = (Read-Host "`nVotre choix").ToUpper()

    if ($choice -eq 'Q') {
        break 
    }

    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $filteredPods.Length) {
        $selectedIndex = [int]$choice - 1
        $selectedPodName = $filteredPods[$selectedIndex].metadata.name
        
        Clear-Host
        Write-Host "------------------------------------------------" -ForegroundColor Green
        Write-Host "  Pod selectionne : $selectedPodName"
        Write-Host "------------------------------------------------" -ForegroundColor Green
        Write-Host "`nMenu d'actions pour ce pod (a developper) :" -ForegroundColor Yellow
        Write-Host "  [1] Voir les logs"
        Write-Host "  [2] Decrire le pod"
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