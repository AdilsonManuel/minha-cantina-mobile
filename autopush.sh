#!/usr/bin/env bash
# =============================================================================
# MINHA CANTINA - AUTO-PUSH FRONTEND MOBILE (FLUTTER)
# =============================================================================
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Auto-Push Frontend Mobile: $(basename "$REPO_DIR") [Branch: $BRANCH] ===${NC}"

STATUS=$(git status --porcelain)

if [ -z "$STATUS" ]; then
    echo -e "${YELLOW}ℹ️ Nenhuma alteração pendente no Frontend Mobile.${NC}"
    echo -e "${BLUE}Verificando se há commits locais por enviar...${NC}"
    git push origin "$BRANCH" && echo -e "${GREEN}✅ Mobile sincronizado com origin/$BRANCH.${NC}"
    exit 0
fi

COMMIT_MSG="$*"
if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="chore: atualização automática mobile ($(date '+%Y-%m-%d %H:%M:%S'))"
fi

echo -e "${BLUE}📦 Adicionando ficheiros alterados no Mobile...${NC}"
git add -A

echo -e "${BLUE}📝 Criando commit: \"$COMMIT_MSG\"${NC}"
GIT_POST_COMMIT_SKIP_PUSH=1 git commit -m "$COMMIT_MSG"

echo -e "${BLUE}🚀 Enviando para origin/$BRANCH...${NC}"
git push origin "$BRANCH"

echo -e "${GREEN}✅ Frontend Mobile enviado com sucesso para o GitHub!${NC}"
