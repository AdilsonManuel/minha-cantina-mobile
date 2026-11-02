# =============================================================================
# MINHA CANTINA - AUTO-PUSH FRONTEND MOBILE (WINDOWS POWERSHELL)
# =============================================================================
param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string]$Message = ""
)

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $RepoDir

$branch = git symbolic-ref --short HEAD 2>$null
if (-not $branch) { $branch = "main" }

Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "🚀 [Auto-Push Mobile] Branch: $branch" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan

$status = git status --porcelain
if (-not $status) {
    Write-Host "ℹ️ Nenhuma alteração pendente no Frontend Mobile." -ForegroundColor Yellow
    Write-Host "Verificando se há commits locais por enviar..." -ForegroundColor Cyan
    git push origin $branch
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Mobile sincronizado com origin/$branch." -ForegroundColor Green
    } else {
        Write-Host "❌ Falha ao enviar para o GitHub." -ForegroundColor Red
    }
    exit 0
}

if (-not $Message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Message = "chore: atualização automática mobile windows ($timestamp)"
}

Write-Host "📦 [1/3] Adicionando ficheiros alterados no Mobile..." -ForegroundColor Cyan
git add -A

Write-Host "📝 [2/3] Criando commit: `"$Message`"" -ForegroundColor Cyan
$env:GIT_POST_COMMIT_SKIP_PUSH = "1"
git commit -m "$Message"
Remove-Item Env:\GIT_POST_COMMIT_SKIP_PUSH -ErrorAction SilentlyContinue

Write-Host "🚀 [3/3] Enviando para origin/$branch..." -ForegroundColor Cyan
git push origin $branch

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Frontend Mobile enviado com sucesso para o GitHub!" -ForegroundColor Green
} else {
    Write-Host "❌ Falha ao enviar Mobile para o GitHub." -ForegroundColor Red
}
