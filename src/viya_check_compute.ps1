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
    # ... (Le début de la boucle est identique)

    # --- On recupere les objets pods via JSON ---
    $allPods = & $params.OcPath get pods -n $params.DefaultNamespace -o json | ConvertFrom-Json
    $filteredPods = $allPods.items | Where-Object { $_.metadata.name -match "compute|launcher|workload-orchestrator" }
    
    if (-not $filteredPods) {
        Write-Host "`nAucun pod correspondant trouve dans le namespace '$($params.DefaultNamespace)'." -ForegroundColor Yellow
        Read-Host "`nAppuyez sur Entree pour quitter."
        break
    }

    # --- On construit le menu detaille et colore ---
    Write-Host "`nVeuillez selectionner un pod :" -ForegroundColor Yellow
    
    # Affichage des en-tetes
    $headerFormat = "  {0,-4} {1,-55} {2,-8} {3,-10} {4,-10} {5,-10} {6,-15} {7}"
    Write-Host ($headerFormat -f "#", "NOM DU POD", "READY", "STATUT", "RESTARTS", "AGE", "IP", "NODE")
    Write-Host ($headerFormat -f "--", "----------", "-----", "------", "----------", "---", "--", "----")

    for ($i = 0; $i -lt $filteredPods.Length; $i++) {
        $pod = $filteredPods[$i]
        
        # --- MODIFICATION ICI : Calcul plus robuste de la colonne READY ---
        $readyContainers = 0
        # On verifie d'abord si la propriete .containerStatuses existe avant de l'utiliser
        if ($pod.status.containerStatuses) {
            $readyContainers = @($pod.status.containerStatuses | Where-Object { $_.ready }).Count
        }
        # On s'assure que .spec.containers est bien un tableau pour le .Count
        $totalContainers = @($pod.spec.containers).Count
        $readyString = "$readyContainers/$totalContainers"
        # --- Fin de la modification ---

        $podName = $pod.metadata.name
        $podStatus = $pod.status.phase
        $totalRestarts = 0
        if ($pod.status.containerStatuses) {
             $totalRestarts = ($pod.status.containerStatuses | Measure-Object -Property restartCount -Sum).Sum
        }
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
        Write-Host -NoNewline ("  [{0}]" -f ($i+1)) -ForegroundColor Green
        Write-Host ($headerFormat -f "", $podName, $readyString, $podStatus, $totalRestarts, $ageString, $podIP, $nodeName)
    }
    Write-Host "  [Q] Quitter"

    # --- Le reste du script est identique ---
    # ...
}

Write-Host "`nAu revoir !"