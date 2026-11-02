@echo off
setlocal enabledelayedexpansion

:: =============================================================================
:: MINHA CANTINA - AUTO-PUSH FRONTEND MOBILE (WINDOWS BATCH / CMD)
:: =============================================================================

cd /d "%~dp0"

for /f "tokens=*" %%i in ('git symbolic-ref --short HEAD 2^>nul') do set BRANCH=%%i
if "%BRANCH%"=="" set BRANCH=main

echo ===================================================================
echo [Auto-Push Mobile] Repositorio: mobile [Branch: %BRANCH%]
echo ===================================================================

set STATUS=
for /f "tokens=*" %%i in ('git status --porcelain') do set STATUS=%%i

if "%STATUS%"=="" (
    echo [INFO] Nenhuma alteracao pendente no Frontend Mobile.
    echo [INFO] Verificando se ha commits locais por enviar...
    git push origin %BRANCH%
    if !errorlevel! equ 0 (
        echo [OK] Mobile sincronizado com origin/%BRANCH%.
    ) else (
        echo [ERRO] Falha ao enviar para o GitHub.
    )
    exit /b 0
)

set COMMIT_MSG=%*
if "%COMMIT_MSG%"=="" (
    set COMMIT_MSG=chore: atualizacao automatica mobile windows (%date% %time%)
)

echo [1/3] Adicionando ficheiros alterados no Mobile...
git add -A

echo [2/3] Criando commit: "%COMMIT_MSG%"
set GIT_POST_COMMIT_SKIP_PUSH=1
git commit -m "%COMMIT_MSG%"

echo [3/3] Enviando para origin/%BRANCH%...
git push origin %BRANCH%

if !errorlevel! equ 0 (
    echo [SUCESSO] Frontend Mobile enviado com sucesso para o GitHub!
) else (
    echo [ERRO] Falha ao enviar Mobile para o GitHub.
)
exit /b !errorlevel!
