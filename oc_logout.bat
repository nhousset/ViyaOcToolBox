@echo off
TITLE Déconnexion OpenShift

ECHO Lancement du script de déconnexion PowerShell...
ECHO.

SET "SCRIPT_PATH=%~dp0\src\logout_oc.ps1"

powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est terminé.
pause