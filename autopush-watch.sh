#!/usr/bin/env bash
# =============================================================================
# MINHA CANTINA - AUTO-PUSH WATCHER CONTÍNUO DO MOBILE (FLUTTER)
# =============================================================================
# Monitora continuamente alterações no repositório Mobile.
# Salva, comita e envia (push) para o GitHub (minha-cantina-mobile) automaticamente.
#
# Uso:
#   ./autopush-watch.sh          -> Executa no terminal em tempo real
#   ./autopush-watch.sh start    -> Inicia em segundo plano (background daemon)
#   ./autopush-watch.sh stop     -> Para o serviço em segundo plano
#   ./autopush-watch.sh status   -> Verifica se o serviço está ativo
#   ./autopush-watch.sh logs     -> Acompanha os logs em tempo real
# =============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$REPO_DIR/.autopush-watch.pid"
LOG_FILE="$REPO_DIR/autopush-watch.log"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

CHECK_INTERVAL=4
DEBOUNCE_WAIT=3

sync_mobile() {
    if [ ! -d "$REPO_DIR/.git" ]; then
        return 0
    fi

    cd "$REPO_DIR" || return 0
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    [ -z "$branch" ] && branch="main"

    local status
    status=$(git status --porcelain 2>/dev/null)

    if [ -n "$status" ]; then
        echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}🔍 Alteração detetada no Mobile. Aguardando ${DEBOUNCE_WAIT}s para agrupar salvamentos...${NC}"
        sleep "$DEBOUNCE_WAIT"

        local changed_files
        changed_files=$(git status --porcelain 2>/dev/null | awk '{print $NF}' | xargs -n1 basename 2>/dev/null | paste -sd, - 2>/dev/null)
        if [ -z "$changed_files" ]; then
            changed_files="ficheiros"
        elif [ ${#changed_files} -gt 60 ]; then
            changed_files="${changed_files:0:57}..."
        fi

        local commit_msg="auto(mobile): atualizar $changed_files ($(date '+%H:%M:%S'))"
        git add -A >/dev/null 2>&1
        GIT_POST_COMMIT_SKIP_PUSH=1 git commit -m "$commit_msg" >/dev/null 2>&1

        echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${BLUE}🚀 [Auto-Push] Enviando Mobile para origin/$branch...${NC}"
        if git push origin "$branch" >/dev/null 2>&1; then
            echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}✅ [Auto-Push] Mobile sincronizado com sucesso no GitHub!${NC}"
        else
            echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}⚠️ [Auto-Push] Falha ao enviar Mobile para origin/$branch. Tentará no próximo ciclo.${NC}"
        fi
    fi
}

start_foreground() {
    echo -e "${BOLD}${GREEN}===================================================================${NC}"
    echo -e "${BOLD}${GREEN}   MINHA CANTINA - AUTO-PUSH CONTÍNUO DO MOBILE ATIVO              ${NC}"
    echo -e "${BOLD}${GREEN}===================================================================${NC}"
    echo -e "Monitorando alterações no Mobile a cada ${CHECK_INTERVAL}s. Pressione Ctrl+C para encerrar.\n"

    while true; do
        sync_mobile
        sleep "$CHECK_INTERVAL"
    done
}

start_background() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${YELLOW}ℹ️ O serviço autopush do Mobile já está em execução (PID: $pid).${NC}"
            return 0
        fi
        rm -f "$PID_FILE"
    fi

    echo -e "${BLUE}Iniciando autopush do Mobile em segundo plano...${NC}"
    nohup "$REPO_DIR/autopush-watch.sh" run </dev/null >> "$LOG_FILE" 2>&1 &
    local new_pid=$!
    echo "$new_pid" > "$PID_FILE"
    disown "$new_pid" 2>/dev/null || true
    sleep 1

    if kill -0 "$new_pid" 2>/dev/null; then
        echo -e "${GREEN}✅ Autopush do Mobile iniciado com sucesso (PID: $new_pid).${NC}"
        echo -e "Logs em: ${BOLD}$LOG_FILE${NC}"
    else
        echo -e "${RED}❌ Erro ao iniciar autopush do Mobile. Verifique $LOG_FILE${NC}"
        rm -f "$PID_FILE"
        exit 1
    fi
}

stop_background() {
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}ℹ️ Nenhum autopush do Mobile em execução.${NC}"
        return 0
    fi

    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        echo -e "${BLUE}Parando autopush do Mobile (PID: $pid)...${NC}"
        kill "$pid" 2>/dev/null || true
        sleep 1
        kill -9 "$pid" 2>/dev/null || true
        rm -f "$PID_FILE"
        echo -e "${GREEN}✅ Autopush do Mobile parado com sucesso.${NC}"
    else
        echo -e "${YELLOW}ℹ️ O processo (PID: $pid) já não estava ativo.${NC}"
        rm -f "$PID_FILE"
    fi
}

status_background() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}✅ Autopush do Mobile ATIVO (PID: $pid)${NC}"
            echo -e "Últimas linhas de log ($LOG_FILE):"
            tail -n 10 "$LOG_FILE" 2>/dev/null || true
            return 0
        fi
        rm -f "$PID_FILE"
    fi
    echo -e "${YELLOW}⚪ Autopush do Mobile está PARADO.${NC}"
}

tail_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}ℹ️ Ficheiro de log ainda não existe ($LOG_FILE).${NC}"
        exit 0
    fi
    tail -f "$LOG_FILE"
}

case "${1:-}" in
    start)
        start_background
        ;;
    stop)
        stop_background
        ;;
    status)
        status_background
        ;;
    logs)
        tail_logs
        ;;
    run)
        while true; do
            sync_mobile
            sleep "$CHECK_INTERVAL"
        done
        ;;
    *)
        start_foreground
        ;;
esac
