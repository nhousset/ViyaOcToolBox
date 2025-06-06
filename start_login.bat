@echo off
TITLE Connexion OpenShift

ECHO Lancement du script de connexion PowerShell...
ECHO.

REM %~dp0 est un chemin magique qui pointe vers le dossier du .bat lui-même
SET "SCRIPT_PATH=%~dp0\login_oc.ps1"

REM Exécute le script PowerShell
REM -ExecutionPolicy Bypass : Permet au script de s'exécuter même si la politique est restreinte
REM -File : Spécifie le script à lancer
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est terminé.
pause
