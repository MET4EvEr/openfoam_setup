@echo off
rem ==============================================================================
rem Native Host ParaView Launcher for Windows (Command Prompt Wrapper)
rem ==============================================================================
rem
rem USAGE:
rem   open_paraview.bat                                    (Opens default test_cavity)
rem   open_paraview.bat openfoam_course_workspace\my_case  (Opens custom case)
rem ==============================================================================

setlocal
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\open_paraview.ps1" %*
if errorlevel 1 goto :error
goto :end

:error
echo.
echo ====================================================================
echo  Failed to launch ParaView.
echo ====================================================================
pause

:end
endlocal
