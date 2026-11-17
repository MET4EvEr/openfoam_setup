@echo off
rem ==============================================================================
rem Safe OpenFOAM Container Shutdown Script for Windows
rem ==============================================================================
rem
rem PURPOSE:
rem Stops and removes the OpenFOAM container service while reassuring the user
rem that their simulation cases and results in openfoam_course_workspace remain safe.
rem ==============================================================================

setlocal
cd /d "%~dp0"

echo Stopping OpenFOAM container service...
docker compose down
if errorlevel 1 goto :error

echo.
echo ====================================================================
echo  OpenFOAM service has been stopped successfully.
echo ====================================================================
echo All your simulation cases, meshes, and results in:
echo   %CD%\openfoam_course_workspace
echo are safely saved on your computer and preserved across sessions.
echo --------------------------------------------------------------------
pause
goto :end

:error
echo.
echo Warning: docker compose down encountered an issue.
pause

:end
endlocal
