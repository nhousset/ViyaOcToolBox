@echo off
TITLE Compute Pod Interaction

ECHO Lancement du script interactif Compute...
ECHO.

SET "SCRIPT_PATH=%~dp0\src\compute_interactive.ps1"

powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est termine.
pause