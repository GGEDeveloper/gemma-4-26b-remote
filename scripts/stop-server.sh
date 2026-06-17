#!/bin/bash
# stop-server.sh - Parar llama-server isolado para Gemma 4 26B
# Este script para o servidor sem afetar projetos existentes

set -e  # Exit on error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório do projeto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$PROJECT_DIR/config/.env.gemma-remote"
PID_FILE="$PROJECT_DIR/state/server.pid"

echo -e "${BLUE}=== Parar Servidor - Gemma 4 26B Remote ===${NC}"
echo ""

# Função para carregar configuração
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}ERRO: Ficheiro de configuração não encontrado: $CONFIG_FILE${NC}"
        exit 1
    fi
    source "$CONFIG_FILE"
    echo -e "${GREEN}✓ Configuração carregada${NC}"
}

# Função para verificar se servidor está a correr
check_running() {
    echo -e "${BLUE}Verificando se servidor está a correr...${NC}"
    
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}⚠ PID file não encontrado (servidor não está a correr)${NC}"
        exit 0
    fi
    
    local pid=$(cat "$PID_FILE")
    
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Processo não existe (limpando PID file)${NC}"
        rm -f "$PID_FILE"
        exit 0
    fi
    
    echo -e "${GREEN}✓ Servidor está a correr (PID: $pid)${NC}"
    echo ""
}

# Função para parar servidor
stop_server() {
    echo -e "${BLUE}Parando servidor...${NC}"
    
    local pid=$(cat "$PID_FILE")
    
    # Enviar SIGTERM (graceful shutdown)
    echo -e "${YELLOW}  Enviando SIGTERM (graceful shutdown)...${NC}"
    kill -TERM "$pid" 2>/dev/null || true
    
    # Esperar até 10 segundos
    local max_wait=10
    local wait=0
    
    while [ $wait -lt $max_wait ]; do
        if ! ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Servidor parado gracefulmente${NC}"
            rm -f "$PID_FILE"
            echo ""
            return 0
        fi
        sleep 1
        wait=$((wait + 1))
        echo -n "."
    done
    
    echo ""
    echo -e "${YELLOW}⚠ Timeout: servidor não respondeu ao SIGTERM${NC}"
    
    # Enviar SIGKILL
    echo -e "${YELLOW}  Enviando SIGKILL (force kill)...${NC}"
    kill -KILL "$pid" 2>/dev/null || true
    
    # Verificar se morreu
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Servidor forçado a parar${NC}"
        rm -f "$PID_FILE"
    else
        echo -e "${RED}✗ ERRO: Não foi possível matar o processo${NC}"
        exit 1
    fi
    
    echo ""
}

# Função para verificar porta
check_port() {
    echo -e "${BLUE}Verificando porta $SERVER_PORT...${NC}"
    
    if ss -tulpn | grep -q ":$SERVER_PORT "; then
        echo -e "${YELLOW}⚠ Porta $SERVER_PORT ainda está em uso${NC}"
        echo -e "${YELLOW}  Processo: $(ss -tulpn | grep ":$SERVER_PORT " | awk '{print $7}')${NC}"
        echo -e "${YELLOW}  Pode ser outro processo - verificar manualmente${NC}"
    else
        echo -e "${GREEN}✓ Porta $SERVER_PORT libertada${NC}"
    fi
    
    echo ""
}

# Função para mostrar status final
show_status() {
    echo -e "${BLUE}=== Status Final ===${NC}"
    echo ""
    echo "Servidor: Parado"
    echo "PID file: Removido"
    echo "Porta: $SERVER_PORT (deveria estar livre)"
    echo ""
    echo -e "${GREEN}✓ Servidor parado com sucesso${NC}"
    echo ""
}

# Main
main() {
    load_config
    check_running
    stop_server
    check_port
    show_status
}

# Executar main
main
