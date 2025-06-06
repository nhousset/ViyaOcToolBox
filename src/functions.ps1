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
