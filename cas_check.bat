@echo off
TITLE SAS CAS Services Check

ECHO Lancement du script de verification des services CAS...
ECHO.

SET "SCRIPT_PATH=%~dp0\src\cas_services_check.ps1"

powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est termine.
pause