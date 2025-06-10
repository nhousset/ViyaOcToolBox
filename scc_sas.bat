@echo off
TITLE Liste des SCCs SAS

ECHO Lancement du script pour lister les SCCs SAS...
ECHO.

SET "SCRIPT_PATH=%~dp0\src\scc_sas.ps1"

powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est termine.
pause