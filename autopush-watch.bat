@echo off
REM =============================================================================
REM MINHA CANTINA - AUTO-PUSH WATCHER MOBILE (WINDOWS .BAT)
REM =============================================================================

setlocal enabledelayedexpansion
title Minha Cantina - AutoPush Watcher (Mobile)

set "REPO_DIR=%~dp0"
cd /d "%REPO_DIR%"

echo ===================================================================
echo   MINHA CANTINA - AUTO-PUSH WATCHER MOBILE (WINDOWS)
echo ===================================================================
echo Monitorando alteracoes no Mobile a cada 4 segundos...
echo Pressione Ctrl+C para encerrar.
echo.

:loop
for /f "tokens=*" %%i in ('git status --porcelain 2^>nul') do (
    set "STATUS=%%i"
    goto has_changes
)
goto wait_interval

:has_changes
echo [%TIME%] Alteracao detetada no Mobile. Agrupando alteracoes...
timeout /t 3 /nobreak >nul

git add -A >nul 2>&1
set "COMMIT_MSG=auto(mobile): atualizacao automatica (%DATE% %TIME%)"
set "GIT_POST_COMMIT_SKIP_PUSH=1"
git commit -m "%COMMIT_MSG%" >nul 2>&1

for /f %%b in ('git symbolic-ref --short HEAD 2^>nul') do set "BRANCH=%%b"
if not defined BRANCH set "BRANCH=main"

echo [%TIME%] Enviando Mobile para origin/%BRANCH%...
git push origin %BRANCH% >nul 2>&1
if !errorlevel! equ 0 (
    echo [%TIME%] [OK] Mobile sincronizado com sucesso no GitHub!
) else (
    echo [%TIME%] [AVISO] Falha ao enviar Mobile. Nova tentativa no proximo ciclo.
)

:wait_interval
timeout /t 4 /nobreak >nul
goto loop
