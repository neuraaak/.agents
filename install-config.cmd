@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-config.ps1"
set "EXITCODE=%ERRORLEVEL%"
endlocal
exit /b %EXITCODE%
