@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-config.ps1" %*
rem `endlocal` detruit les variables de la portee : il faut l'enchainer sur la
rem meme ligne pour que %EXITCODE% soit substitue AVANT son execution, sinon
rem `exit /b` recoit un argument vide et renvoie toujours 0 (le code retour de
rem --verify etait avale).
set "EXITCODE=%ERRORLEVEL%"
endlocal & exit /b %EXITCODE%
