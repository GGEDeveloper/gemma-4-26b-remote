#!/bin/bash
# start-server.sh - Iniciar llama-server isolado para Gemma 4 26B
# Este script inicia o servidor sem afetar projetos existentes

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
LOG_OUT="$PROJECT_DIR/logs/server-out.log"
LOG_ERR="$PROJECT_DIR/logs/server-err.log"

echo -e "${BLUE}=== Iniciar Servidor - Gemma 4 26B Remote ===${NC}"
echo ""

# Função para carregar configuração
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}ERRO: Ficheiro de configuração não encontrado: $CONFIG_FILE${NC}"
        echo -e "${YELLOW}Execute 'bash scripts/setup.sh' primeiro${NC}"
        exit 1
    fi
    source "$CONFIG_FILE"
    echo -e "${GREEN}✓ Configuração carregada${NC}"
}

# Função para verificar se servidor já está a correr
check_already_running() {
    echo -e "${BLUE}Verificando se servidor já está a correr...${NC}"
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠ Servidor já está a correr (PID: $pid)${NC}"
            echo -e "${YELLOW}  Use 'bash scripts/stop-server.sh' para parar${NC}"
            exit 1
        else
            echo -e "${YELLOW}⚠ PID file existe mas processo não (limpando)${NC}"
            rm -f "$PID_FILE"
        fi
    fi
    
    # Verificar porta
    if ss -tulpn | grep -q ":$SERVER_PORT "; then
        echo -e "${RED}✗ Porta $SERVER_PORT já está em uso${NC}"
        echo -e "${YELLOW}  Processo: $(ss -tulpn | grep ":$SERVER_PORT " | awk '{print $7}')${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Servidor não está a correr${NC}"
    echo ""
}

# Função para verificar recursos
check_resources() {
    echo -e "${BLUE}Verificando recursos...${NC}"
    
    # Verificar modelo
    if [ ! -f "$MODEL_PATH" ]; then
        echo -e "${RED}✗ Modelo não encontrado: $MODEL_PATH${NC}"
        exit 1
    fi
    
    # Verificar backend
    if [ ! -f "$BACKEND_PATH/llama-server" ]; then
        echo -e "${RED}✗ llama-server não encontrado: $BACKEND_PATH/llama-server${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Recursos verificados${NC}"
    echo ""
}

# Função para iniciar servidor
start_server() {
    echo -e "${BLUE}Iniciando servidor...${NC}"
    echo ""
    echo "Configuração:"
    echo "  Modelo: $MODEL_NAME"
    echo "  Porta: $SERVER_PORT"
    echo "  Host: $SERVER_HOST"
    echo "  NGL: $NGL"
    echo "  Context: $CTX_SIZE"
    echo "  Backend: $BACKEND_TYPE"
    echo ""
    
    # Exportar variáveis de ambiente Vulkan
    export VK_ICD_FILENAMES="$VK_ICD_FILENAMES"
    export GGML_VK_DEVICE="$GGML_VK_DEVICE"
    
    # Iniciar servidor em background
    cd "$BACKEND_PATH"
    nohup ./llama-server \
        --model "$MODEL_PATH" \
        --host "$SERVER_HOST" \
        --port "$SERVER_PORT" \
        --n-gpu-layers "$NGL" \
        --ctx-size "$CTX_SIZE" \
        --n-predict "$N_PREDICT" \
        --log-file "$LOG_OUT" \
        2> "$LOG_ERR" &
    
    local pid=$!
    echo $pid > "$PID_FILE"
    
    echo -e "${GREEN}✓ Servidor iniciado (PID: $pid)${NC}"
    echo ""
}

# Função para verificar startup
verify_startup() {
    echo -e "${BLUE}Verificando startup...${NC}"
    
    local pid=$(cat "$PID_FILE")
    local max_wait=30
    local wait=0
    
    while [ $wait -lt $max_wait ]; do
        if ! ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${RED}✗ Servidor crashou (ver logs)${NC}"
            echo -e "${YELLOW}  Tail de erro:${NC}"
            tail -20 "$LOG_ERR"
            rm -f "$PID_FILE"
            exit 1
        fi
        
        if ss -tulpn | grep -q ":$SERVER_PORT "; then
            echo -e "${GREEN}✓ Servidor está a responder na porta $SERVER_PORT${NC}"
            echo ""
            return 0
        fi
        
        sleep 1
        wait=$((wait + 1))
        echo -n "."
    done
    
    echo ""
    echo -e "${RED}✗ Timeout: servidor não respondeu em ${max_wait}s${NC}"
    rm -f "$PID_FILE"
    exit 1
}

# Função para mostrar status final
show_status() {
    echo -e "${BLUE}=== Status do Servidor ===${NC}"
    echo ""
    
    local pid=$(cat "$PID_FILE")
    echo "PID: $pid"
    echo "Porta: $SERVER_PORT"
    echo "Host: $SERVER_HOST"
    echo ""
    
    echo "Logs:"
    echo "  Stdout: $LOG_OUT"
    echo "  Stderr: $LOG_ERR"
    echo ""
    
    echo "API Endpoints:"
    echo "  Health: http://$SERVER_HOST:$SERVER_PORT/health"
    echo "  Models: http://$SERVER_HOST:$SERVER_PORT/v1/models"
    echo "  Chat: http://$SERVER_HOST:$SERVER_PORT/v1/chat/completions"
    echo ""
    
    echo -e "${GREEN}✓ Servidor iniciado com sucesso${NC}"
    echo ""
    echo "Comandos úteis:"
    echo "  Status: bash scripts/status-server.sh"
    echo "  Parar: bash scripts/stop-server.sh"
    echo "  Logs: tail -f logs/server-out.log"
    echo ""
}

# Main
main() {
    load_config
    check_already_running
    check_resources
    start_server
    verify_startup
    show_status
}

# Executar main
main
