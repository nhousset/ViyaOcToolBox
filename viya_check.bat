@echo off
TITLE Viya Check OpenShift

ECHO Lancement du script de verification Viya...
ECHO.

SET "SCRIPT_PATH=%~dp0\src\viya_check.ps1"

powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est termine.
pause