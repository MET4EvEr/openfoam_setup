@echo off
rem ==============================================================================
rem One-Click OpenFOAM Environment Launcher for Windows (Command Prompt Wrapper)
rem ==============================================================================
rem
rem PURPOSE:
rem Provides a simple double-click or CLI launcher for Windows users.
rem Delegates execution directly to PowerShell (scripts\start_openfoam.ps1)
rem to reliably handle Windows paths with spaces, escape sequences, and colors.
rem ==============================================================================

setlocal
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start_openfoam.ps1"

if %ERRORLEVEL% neq 0 (
    echo.
    echo Script encountered an error (Exit Code: %ERRORLEVEL%).
    pause
)
endlocal
