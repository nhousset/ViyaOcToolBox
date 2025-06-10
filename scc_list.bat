@echo off
TITLE List SCC

ECHO.

SET "SCRIPT_PATH=%~dp0\src\scc_list.ps1"

powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

ECHO.
ECHO Le script PowerShell est termine.
pause