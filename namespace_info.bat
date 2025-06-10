@echo off
TITLE Informations Namespace (YAML)

ECHO Lancement du script pour afficher les infos du namespace...
ECHO.

SET "SCRIPT_PATH=%~dp0\src\namespace_info.ps1"

powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est termine.
pause