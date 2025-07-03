@echo off
TITLE Liste des Pods OpenShift

ECHO Lancement du script de listing des pods...
ECHO.

REM %~dp0 est un chemin magique qui pointe vers le dossier du .bat lui-même (ici, src\)
REM MODIFICATION : On pointe vers le nouveau script list_pods.ps1
SET "SCRIPT_PATH=%~dp0\src\getSvc.ps1"

REM Exécute le script PowerShell
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est terminé.
pause
