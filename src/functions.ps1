<#
.SYNOPSIS
    Bibliothèque de fonctions partagées pour les scripts OpenShift.
#>

# FONCTION 1 : Lit le fichier de configuration (INCHANGÉE)
function Get-AppConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigFilePath
    )
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

# FONCTION 2 : Prépare les paramètres spécifiques au script 
function Initialize-ScriptParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ConfigData
    )
    
    # Logique que vous vouliez ajouter :
    $ocPath = $ConfigData.get_Item('OC_EXECUTABLE_PATH')
    if ([string]::IsNullOrWhiteSpace($ocPath)) { $ocPath = "oc.exe" }

    # On crée un objet personnalisé pour retourner toutes les variables proprement
    $scriptParams = [PSCustomObject]@{
        DefaultNamespace = $ConfigData.get_Item('DEFAULT_NAMESPACE')
        OcPath           = $ocPath
        AppLabel         = $ConfigData.get_Item('APP_LABEL')
    }

    return $scriptParams
}


# --- Fonction pour vérifier si une session OpenShift est active --- 
function Test-OcConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$OcPath
    )
    & $OcPath status | Out-Null
    return $?
}

# On exporte maintenant les 3 fonctions
Export-ModuleMember -Function Get-AppConfiguration, Initialize-ScriptParameters, Test-OcConnection