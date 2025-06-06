@echo off
TITLE Liste des Pods OpenShift

ECHO Lancement du script de listing des pods...
ECHO.

SET "SCRIPT_PATH=%~dp0\src\pods_interactive.ps1"

REM Exécute le script PowerShell
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est terminé.
pause