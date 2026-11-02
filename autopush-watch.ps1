# =============================================================================
# MINHA CANTINA - AUTO-PUSH WATCHER MOBILE (POWERSHELL)
# =============================================================================

$RepoDir = $PSScriptRoot
Set-Location $RepoDir

Write-Host "===================================================================" -ForegroundColor Green
Write-Host "   MINHA CANTINA - AUTO-PUSH WATCHER MOBILE (POWERSHELL)           " -ForegroundColor Green
Write-Host "===================================================================" -ForegroundColor Green
Write-Host "Monitorando alteracoes no Mobile a cada 4 segundos..." -ForegroundColor Cyan
Write-Host "Pressione Ctrl+C para encerrar.`n" -ForegroundColor Yellow

while ($true) {
    $status = git status --porcelain 2>$null
    if ($status) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] Alteracao detetada no Mobile. Aguardando 3s para agrupar..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3

        git add -A | Out-Null
        $commitMsg = "auto(mobile): atualizacao automatica ($timestamp)"
        $env:GIT_POST_COMMIT_SKIP_PUSH = "1"
        git commit -m "$commitMsg" | Out-Null
        $env:GIT_POST_COMMIT_SKIP_PUSH = $null

        $branch = git symbolic-ref --short HEAD 2>$null
        if (-not $branch) { $branch = "main" }

        Write-Host "[$timestamp] Enviando Mobile para origin/$branch..." -ForegroundColor Cyan
        git push origin $branch 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[$timestamp] [OK] Mobile sincronizado com sucesso no GitHub!" -ForegroundColor Green
        } else {
            Write-Host "[$timestamp] [AVISO] Falha ao enviar Mobile. Nova tentativa no proximo ciclo." -ForegroundColor Red
        }
    }
    Start-Sleep -Seconds 4
}
