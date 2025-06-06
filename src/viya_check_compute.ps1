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
Write-Host "--- Verification de la session OpenShift existante ---" -ForegroundColor Cyan
if (-not (Test-OcConnection -OcPath $params.OcPath)) {
    Write-Host "`nERREUR : Vous ne semblez pas etre connecte a OpenShift." -ForegroundColor Red
    Write-Host "Veuillez d'abord lancer le script 'oc_login.bat' pour vous connecter." -ForegroundColor Yellow
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
    Write-Host "  Selection d'un pod Compute"
    Write-Host "------------------------------------------------" -ForegroundColor Green

    # --- Etape 4: Lister les pods "compute-launcher" et "compute-workload" ---
    Write-Host "`nRecherche des pods 'compute-launcher' et 'compute-workload'..." -ForegroundColor Cyan
    
    # On recupere les pods, on garde uniquement leur nom, et on les stocke dans un tableau
    $podList = & $params.OcPath get pods -n $params.DefaultNamespace -o=custom-columns=NAME:.metadata.name --no-headers | Select-String -Pattern "compute-launcher|compute-workload"
    
    if (-not $podList) {
        Write-Host "`nAucun pod 'compute-launcher' ou 'compute-workload' trouve dans le namespace '$($params.DefaultNamespace)'." -ForegroundColor Yellow
        Read-Host "`nAppuyez sur Entree pour quitter."
        break
    }

    # Affichage de la liste numerotee
    Write-Host "Veuillez selectionner un pod :" -ForegroundColor Yellow
    for ($i = 0; $i -lt $podList.Length; $i++) {
        Write-Host "  [$($i+1)] $($podList[$i].Line)"
    }
    Write-Host "  [Q] Quitter"

    # --- Etape 5: Attendre le choix de l'utilisateur ---
    $choice = (Read-Host "`nVotre choix").ToUpper()

    if ($choice -eq 'Q') {
        break # Sort de la boucle while
    }

    # Verifier si le choix est un nombre valide
    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $podList.Length) {
        $selectedIndex = [int]$choice - 1
        $selectedPod = $podList[$selectedIndex].Line
        
        # --- Etape 6: Afficher le menu secondaire (a developper) ---
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
            continue # Revient au debut de la boucle 'while' pour reafficher la liste des pods
        }
        # Ici, vous ajouterez la logique pour les actions A, B, etc.
        Write-Host "`nFonctionnalite non implementee."
        Read-Host "`nAppuyez sur Entree pour revenir a la liste des pods..."

    } else {
        Write-Host "`nChoix invalide." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}

Write-Host "`nAu revoir !"