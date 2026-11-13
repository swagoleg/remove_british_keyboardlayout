@echo off
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0KeyboardGuard.ps1" -Mode Repair
set "guardExitCode=%ERRORLEVEL%"
echo.
pause
exit /b %guardExitCode%
