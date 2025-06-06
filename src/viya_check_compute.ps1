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
        
        # --- MODIFICATION ICI : Calcul plus robuste de la colonne READY ---
        $readyContainers = 0
        # On verifie d'abord si la propriete .containerStatuses existe avant de l'utiliser
        if ($pod.status.containerStatuses) {
            $readyContainers = @($pod.status.containerStatuses | Where-Object { $_.ready }).Count
        }
        # On s'assure que .spec.containers est bien un tableau pour le .Count
        $totalContainers = @($pod.spec.containers).Count
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
        $selectedPodObject = $filteredPods[$selectedIndex]
        $selectedPodName = $selectedPodObject.metadata.name
        
        # --- DEBUT DE LA MODIFICATION : Menu d'actions ameliore ---
        
        # Boucle pour le menu d'actions, pour pouvoir y revenir
        while ($true) {
            Clear-Host
            Write-Host "------------------------------------------------" -ForegroundColor Green
            Write-Host "  Pod selectionne : $selectedPodName"
            Write-Host "------------------------------------------------" -ForegroundColor Green
            Write-Host "`nMenu d'actions pour ce pod :" -ForegroundColor Yellow
            Write-Host "  [1] Voir les logs"
            Write-Host "  [2] Decrire le pod (oc describe)"
            Write-Host "  [R] Revenir a la liste des pods"
            
            $actionChoice = (Read-Host "`nVotre choix").ToUpper()

            # On utilise un switch pour plus de clarte
            switch ($actionChoice) {
                '1' { # --- VOIR LES LOGS ---
                    Write-Host "`n--- Logs pour le pod : $selectedPodName ---" -ForegroundColor Cyan
                    $containers = $selectedPodObject.spec.containers
                    
                    $logArguments = @("logs", $selectedPodName, "-n", $params.DefaultNamespace)
                    
                    # Si le pod a plus d'un conteneur, on demande lequel choisir
                    if ($containers.Length -gt 1) {
                        Write-Host "`nCe pod a plusieurs conteneurs. Lequel choisir ?" -ForegroundColor Yellow
                        for ($j = 0; $j -lt $containers.Length; $j++) {
                            Write-Host "  [$($j+1)] $($containers[$j].name)"
                        }
                        $containerChoice = Read-Host "Choix du conteneur"
                        if ($containerChoice -match '^\d+$' -and [int]$containerChoice -ge 1 -and [int]$containerChoice -le $containers.Length) {
                            $selectedContainer = $containers[[int]$containerChoice - 1].name
                            $logArguments += "-c", $selectedContainer
                        } else {
                            Write-Host "Choix de conteneur invalide." -ForegroundColor Red
                            Start-Sleep -Seconds 2
                            continue # Revient au menu d'actions
                        }
                    }
                    
                    # On ajoute --tail pour ne pas afficher des logs infinis
                    $logArguments += "--tail=100"
                    Start-Process -FilePath $params.OcPath -ArgumentList $logArguments -Wait -NoNewWindow
                    Read-Host "`nAppuyez sur Entree pour revenir au menu d'actions..."
                }
                '2' { # --- DECRIRE LE POD ---
                    Write-Host "`n--- Description du pod : $selectedPodName ---" -ForegroundColor Cyan
                    $describeArguments = @("describe", "pod", $selectedPodName, "-n", $params.DefaultNamespace)
                    Start-Process -FilePath $params.OcPath -ArgumentList $describeArguments -Wait -NoNewWindow
                    Read-Host "`nAppuyez sur Entree pour revenir au menu d'actions..."
                }
                'R' {
                    # On sort de la boucle du menu d'actions pour revenir a la liste des pods
                    break
                }
                default {
                    Write-Host "`nChoix invalide." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            } # Fin du switch
        } # Fin de la boucle du menu d'actions
        # --- FIN DE LA MODIFICATION ---
        
    } else {
        Write-Host "`nChoix invalide." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}

Write-Host "`nAu revoir !"