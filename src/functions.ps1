<#
.SYNOPSIS
    Bibliotheque de fonctions partagees pour les scripts OpenShift.
#>

# FONCTION 1 : Lit le fichier de configuration
function Get-AppConfiguration {
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][string]$ConfigFilePath)
    if (-not (Test-Path $ConfigFilePath)) { throw "Le fichier de configuration '$ConfigFilePath' est introuvable." }
    $configHashtable = @{}
    Get-Content $ConfigFilePath | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
            $key, $value = $line -split '=', 2
            $configHashtable[$key.Trim()] = $value.Trim()
        }
    }
    return $configHashtable
}

# FONCTION 2 : Prepare les parametres specifiques au script
function Initialize-ScriptParameters {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][hashtable]$ConfigData)
    
    $ocPath = $ConfigData.get_Item('OC_EXECUTABLE_PATH')
    if ([string]::IsNullOrWhiteSpace($ocPath)) { $ocPath = "oc.exe" }

    $scriptParams = [PSCustomObject]@{
        ServerUrl        = $ConfigData.get_Item('SERVER_URL')
        Token            = $ConfigData.get_Item('TOKEN')
        SkipTls          = [bool]::Parse($ConfigData.get_Item('INSECURE_SKIP_TLS_VERIFY'))
        DefaultNamespace = $ConfigData.get_Item('DEFAULT_NAMESPACE')
        OcPath           = $ocPath
        AppLabel         = $ConfigData.get_Item('APP_LABEL')
    }
    return $scriptParams
}

# FONCTION 3 : Teste la connexion
function Test-OcConnection {
    [CmdletBinding()]
    param ([Parameter(Mandatory=$true)][string]$OcPath)
    & $OcPath status | Out-Null
    return $?
}


function Initialize-And-Validate-Connection {
    <#
    .SYNOPSIS
        Initialise les paramètres de configuration et vérifie la connexion à OpenShift.
    .DESCRIPTION
        Cette fonction charge la configuration, prépare les variables nécessaires
        et s'assure qu'une session OpenShift est active.
    .OUTPUTS
        Un objet [pscustomobject] contenant les paramètres si tout réussit.
        $null en cas d'erreur.
    #>
    try {
        # --- Initialisation ---
        $projectRoot = Split-Path -Path $PSScriptRoot -Parent
        $configFile = Join-Path $projectRoot "config\config.ini"
        
        # 1. Lire la configuration
        $config = Get-AppConfiguration -ConfigFilePath $configFile

        # 2. Préparer les variables nécessaires
        $scriptParams = Initialize-ScriptParameters -ConfigData $config
        
        # --- Vérification de la connexion ---
        Write-Host "--- Vérification de la session OpenShift existante ---" -ForegroundColor Cyan
        if (-not (Test-OcConnection -OcPath $scriptParams.OcPath)) {
            Write-Host "`n❌ Vous ne semblez pas être connecté à OpenShift." -ForegroundColor Red
            Write-Host "Veuillez d'abord lancer le script 'oc_login.bat' pour vous connecter." -ForegroundColor Yellow
            return $null # Stoppe la fonction et retourne null
        }
        Write-Host "✅ Session OpenShift active détectée." -ForegroundColor Green
        
        # Retourne l'objet avec les paramètres si tout va bien
        return $scriptParams
    }
    catch {
        Write-Host "❌ ERREUR DE CONFIGURATION :" -ForegroundColor Red
        Write-Host $_.Exception.Message
        return $null # Stoppe la fonction et retourne null en cas d'erreur
    }
}

function Set-OpenShiftProject {
    <#
    .SYNOPSIS
        Change le projet (namespace) actif dans OpenShift.
    .PARAMETER OcPath
        Chemin vers l'exécutable 'oc'.
    .PARAMETER Namespace
        Le nom du namespace à sélectionner.
    #>
    param(
        [string]$OcPath,
        [string]$Namespace
    )

    if ([string]::IsNullOrWhiteSpace($Namespace)) {
        Write-Host "ℹ️ Aucun namespace par défaut n'est spécifié, le changement est ignoré." -ForegroundColor Yellow
        return
    }

    Write-Host "`n--- Changement de namespace ---" -ForegroundColor Cyan
    & $OcPath "project" $Namespace | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Échec lors du changement vers le namespace '$Namespace'." -ForegroundColor Red
        Read-Host "Appuyez sur Entrée..."
        exit 1 # Erreur critique, on quitte le script
    }
    
    Write-Host "✅ Positionné sur le namespace '$Namespace'." -ForegroundColor Green
}

function Execute-OcCommand {
    <#
    .SYNOPSIS
        Exécute une commande 'oc' de manière fiable avec les arguments fournis.
    .PARAMETER OcPath
        Chemin vers l'exécutable 'oc'.
    .PARAMETER Arguments
        Un tableau de chaînes de caractères représentant les arguments de la commande.
    #>
    param(
        [string]$OcPath,
        [string[]]$Arguments
    )
    
    try {
        Start-Process -FilePath $OcPath -ArgumentList $Arguments -Wait -NoNewWindow -ErrorAction Stop
    }
    catch {
        Write-Host "`n❌ Une erreur est survenue lors de l'exécution de la commande 'oc'." -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}
