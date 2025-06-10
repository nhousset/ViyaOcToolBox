@echo off
TITLE Liste des Routes OpenShift

ECHO Lancement du script pour lister les routes...
ECHO.

SET "SCRIPT_PATH=%~dp0\src\routes_list.ps1"

powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est termine.
pause