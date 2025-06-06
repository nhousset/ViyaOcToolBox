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
    Write-Host "`nERREUR : Vous ne semblez pas etre connecte a OpenShift." -ForegroundColor Red
    Write-Host "Veuillez d'abord lancer le script 'start_login.bat' pour vous connecter." -ForegroundColor Yellow
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

# --- Boucle principale du menu de selection de pod ---
while ($true) {
    Clear-Host
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "  Selection d'un pod Compute / Launcher"
    Write-Host "------------------------------------------------" -ForegroundColor Green

    # --- Logique d'affichage detaille ---
    
    # 1. On recupere les noms des pods qui nous interessent avec le NOUVEAU filtre
    # MODIFICATION ICI : Le pattern de Select-String a ete mis a jour.
    $podNameList = (& $params.OcPath get pods -n $params.DefaultNamespace -o=custom-columns=NAME:.metadata.name --no-headers | Select-String -Pattern "compute|launcher|workload-orchestrator").Line
    
    if (-not $podNameList) {
        Write-Host "`nAucun pod correspondant trouve dans le namespace '$($params.DefaultNamespace)'." -ForegroundColor Yellow
        Read-Host "`nAppuyez sur Entree pour quitter."
        break
    }

    # 2. On affiche un tableau detaille de ces pods
    Write-Host "`nPods correspondants trouves :" -ForegroundColor Cyan
    & $params.OcPath get pods -n $params.DefaultNamespace $podNameList -o wide
    Write-Host "------------------------------------------------"

    # 3. On affiche la liste numerotee pour la selection
    Write-Host "`nVeuillez selectionner un pod dans la liste ci-dessus :" -ForegroundColor Yellow
    for ($i = 0; $i -lt $podNameList.Length; $i++) {
        Write-Host "  [$($i+1)] $($podNameList[$i])"
    }
    Write-Host "  [Q] Quitter"

    # --- Le reste du script (selection et menu secondaire) ne change pas ---
    $choice = (Read-Host "`nVotre choix").ToUpper()

    if ($choice -eq 'Q') {
        break 
    }

    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $podNameList.Length) {
        $selectedIndex = [int]$choice - 1
        $selectedPod = $podNameList[$selectedIndex]
        
        Clear-Host
        Write-Host "------------------------------------------------" -ForegroundColor Green
        Write-Host "  Pod selectionne : $selectedPod"
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