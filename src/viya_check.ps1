<#
.SYNOPSIS
    Script interactif pour effectuer des verifications specifiques a Viya sur OpenShift.
.DESCRIPTION
    Ce script verifie la connexion puis propose un menu pour lancer des commandes
    complexes de listing et de filtrage de pods dans le namespace 'viya-ti'.
#>

# --- Etape 1: Importer la bibliotheque de fonctions ---
. "$PSScriptRoot\functions.ps1"

# --- Etape 2: Initialisation et configuration ---
try {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    $configFile = Join-Path $projectRoot "config\config.ini"
    $config = Get-AppConfiguration -ConfigFilePath $configFile
    # On a juste besoin de savoir ou est oc.exe
    $params = Initialize-ScriptParameters -ConfigData $config
} catch {
    Write-Host "ERREUR DE CONFIGURATION :" -ForegroundColor Red; Write-Host $_.Exception.Message; Read-Host "Appuyez sur Entree pour fermer."; exit 1
}

# --- Etape 3: Verifier la connexion (une seule fois au debut) ---
Write-Host "--- Verification de la session OpenShift existante ---" -ForegroundColor Cyan
if (-not (Test-OcConnection -OcPath $params.OcPath)) {
    Write-Host "`nERREUR : Vous ne semblez pas etre connecte a OpenShift." -ForegroundColor Red
    Write-Host "Veuillez d'abord lancer le script 'start_login.bat' pour vous connecter." -ForegroundColor Yellow
    Read-Host "`nAppuyez sur Entree pour fermer."
    exit 1
}
Write-Host "Session OpenShift active detectee." -ForegroundColor Green
# Petite pause pour voir le message de connexion
Start-Sleep -Seconds 1

# --- Boucle de menu infinie ---
while ($true) {
    Clear-Host
    
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "  Menu de verification Viya"
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "`nChoisissez une option :" -ForegroundColor Yellow
    Write-Host "  [1] Verifier les pods strategiques (checkcore)"
    Write-Host "  [2] Verifier les pods non termines (checksas)"
    Write-Host "  [Q] Quitter"
    
    $choice = (Read-Host "`nVotre choix").ToUpper()

    if ($choice -eq 'Q') {
        break
    }

    # Arguments de base pour les commandes oc
    $baseOcArgs = @("-n", "viya-ti", "get", "pods", "--no-headers")

    switch ($choice) {
        '1' {
            # Equivalent de : oc ... | grep -i "crunch|cas-|..." | sort
            Write-Host "`n--- Lancement de 'checkcore' : Liste des pods strategiques ---" -ForegroundColor Cyan
            $pattern = "crunch|cas-|rabbit|consul|auth|compute|logon|cache|redis"
            & $params.OcPath $baseOcArgs | Select-String -Pattern $pattern -CaseSensitive:$false | Sort-Object
        }
        '2' {
            # Equivalent de : oc ... | grep -v -e "1/1" -e "Completed" ... | sort
            Write-Host "`n--- Lancement de 'checksas' : Liste des pods non termines ou en erreur ---" -ForegroundColor Cyan
            $pattern = "1/1|Completed|import-data|3/3|2/2|4/4|5/5"
            # L'option -NotMatch est l'equivalent de 'grep -v'
            & $params.OcPath $baseOcArgs | Select-String -Pattern $pattern -NotMatch | Sort-Object
        }
        default {
            Write-Host "`nChoix invalide." -ForegroundColor Red
            Start-Sleep -Seconds 2
            continue
        }
    }
    
    Read-Host "`nAppuyez sur Entree pour revenir au menu..."
}

Write-Host "`nAu revoir !"