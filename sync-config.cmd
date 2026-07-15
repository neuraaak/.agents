@echo off
setlocal

cd /d "%~dp0"

echo === Sync config Claude ===

REM --- 1. Stash temporaire (fichiers suivis + non suivis) ---
set "STASHED=0"
git stash push --include-untracked --message "sync-config-temp" >nul 2>&1
git stash list | findstr /c:"sync-config-temp" >nul 2>&1
if %errorlevel%==0 (
    set "STASHED=1"
    echo [1/3] Modifications mises de cote ^(stash^).
) else (
    echo [1/3] Aucune modification a mettre de cote.
)

REM --- 2. Recuperation et reset sur origin/main ---
echo [2/3] Fetch + reset sur origin/main...
git fetch origin
if errorlevel 1 goto :error
git reset --hard origin/main
if errorlevel 1 goto :error

REM --- 3. Reapplication du stash ---
if "%STASHED%"=="1" (
    echo [3/3] Reapplication des modifications...
    git stash pop
    if errorlevel 1 (
        echo.
        echo ATTENTION: conflit lors du stash pop. Le stash est conserve.
        echo Resolvez les conflits puis lancez: git stash drop
        goto :end
    )
) else (
    echo [3/3] Rien a reappliquer.
)

echo.
echo === Termine ===
goto :end

:error
echo.
echo ERREUR pendant fetch/reset. Verifiez l'etat du repo.
if "%STASHED%"=="1" echo Vos modifications sont toujours dans le stash ^(git stash list^).

:end
endlocal
