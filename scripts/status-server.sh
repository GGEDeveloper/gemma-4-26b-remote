#!/bin/bash
# status-server.sh - Verificar status do llama-server isolado
# Este script verifica o status sem afetar o servidor

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

echo -e "${BLUE}=== Status do Servidor - Gemma 4 26B Remote ===${NC}"
echo ""

# Função para carregar configuração
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}ERRO: Ficheiro de configuração não encontrado: $CONFIG_FILE${NC}"
        exit 1
    fi
    source "$CONFIG_FILE"
}

# Função para verificar PID
check_pid() {
    echo -e "${BLUE}Verificando PID...${NC}"
    
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}⚠ PID file não encontrado${NC}"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    echo -e "${GREEN}✓ PID file encontrado: $pid${NC}"
    
    if ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Processo está a correr (PID: $pid)${NC}"
        echo -e "  Command: $(ps -p $pid -o cmd=)${NC}"
        echo -e "  CPU: $(ps -p $pid -o %cpu=)%${NC}"
        echo -e "  MEM: $(ps -p $pid -o %mem=)%${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Processo não existe (PID file stale)${NC}"
        return 1
    fi
}

# Função para verificar porta
check_port() {
    echo ""
    echo -e "${BLUE}Verificando porta $SERVER_PORT...${NC}"
    
    if ss -tulpn | grep -q ":$SERVER_PORT "; then
        echo -e "${GREEN}✓ Porta $SERVER_PORT está em uso${NC}"
        ss -tulpn | grep ":$SERVER_PORT " | awk '{print "  Process: " $7}'
        return 0
    else
        echo -e "${YELLOW}⚠ Porta $SERVER_PORT não está em uso${NC}"
        return 1
    fi
}

# Função para testar API
test_api() {
    echo ""
    echo -e "${BLUE}Testando API...${NC}"
    
    # Testar health endpoint
    if curl -s "http://127.0.0.1:$SERVER_PORT/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Health endpoint acessível${NC}"
    else
        echo -e "${YELLOW}⚠ Health endpoint não responde${NC}"
    fi
    
    # Testar models endpoint
    if curl -s "http://127.0.0.1:$SERVER_PORT/v1/models" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Models endpoint acessível${NC}"
        local models=$(curl -s "http://127.0.0.1:$SERVER_PORT/v1/models" | grep -o '"id":"[^"]*"' | head -1)
        if [ -n "$models" ]; then
            echo -e "  Modelo: $models${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Models endpoint não responde${NC}"
    fi
}

# Função para verificar logs
check_logs() {
    echo ""
    echo -e "${BLUE}Verificando logs...${NC}"
    
    if [ -f "$LOG_OUT" ]; then
        local out_size=$(du -h "$LOG_OUT" | cut -f1)
        echo -e "${GREEN}✓ Log stdout existe ($out_size)${NC}"
    else
        echo -e "${YELLOW}⚠ Log stdout não existe${NC}"
    fi
    
    if [ -f "$LOG_ERR" ]; then
        local err_size=$(du -h "$LOG_ERR" | cut -f1)
        echo -e "${GREEN}✓ Log stderr existe ($err_size)${NC}"
        
        # Verificar se há erros recentes
        if tail -20 "$LOG_ERR" | grep -qi "error\|fatal\|failed"; then
            echo -e "${YELLOW}⚠ Erros detectados no log stderr (últimas 20 linhas)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Log stderr não existe${NC}"
    fi
}

# Função para verificar recursos
check_resources() {
    echo ""
    echo -e "${BLUE}Verificando recursos...${NC}"
    
    # Verificar VRAM (AMD)
    if [ -f "/sys/class/drm/card0/device/mem_info_vram_used" ]; then
        local vram_used=$(cat /sys/class/drm/card0/device/mem_info_vram_used)
        local vram_total=$(cat /sys/class/drm/card0/device/mem_info_vram_total)
        local vram_mb=$((vram_used / 1024 / 1024))
        local vram_total_mb=$((vram_total / 1024 / 1024))
        echo -e "${GREEN}✓ VRAM: ${vram_mb}MB / ${vram_total_mb}MB${NC}"
    fi
    
    # Verificar RAM
    local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_available_mb=$((mem_available / 1024))
    local mem_total_mb=$((mem_total / 1024))
    echo -e "${GREEN}✓ RAM disponível: ${mem_available_mb}MB / ${mem_total_mb}MB${NC}"
}

# Função para mostrar resumo
show_summary() {
    echo ""
    echo -e "${BLUE}=== Resumo ===${NC}"
    echo ""
    
    local running=false
    
    if check_pid > /dev/null 2>&1; then
        running=true
    fi
    
    if check_port > /dev/null 2>&1; then
        running=true
    fi
    
    if [ "$running" = true ]; then
        echo -e "${GREEN}Status: ONLINE${NC}"
        echo ""
        echo "API Endpoints:"
        echo "  Health: http://127.0.0.1:$SERVER_PORT/health"
        echo "  Models: http://127.0.0.1:$SERVER_PORT/v1/models"
        echo "  Chat: http://127.0.0.1:$SERVER_PORT/v1/chat/completions"
        echo ""
        echo "Para acesso externo (laptopdev):"
        echo "  Substituir 127.0.0.1 por 192.168.1.130"
        echo ""
    else
        echo -e "${YELLOW}Status: OFFLINE${NC}"
        echo ""
        echo "Para iniciar:"
        echo "  bash scripts/start-server.sh"
        echo ""
    fi
    
    echo "Logs:"
    echo "  Stdout: $LOG_OUT"
    echo "  Stderr: $LOG_ERR"
    echo ""
}

# Main
main() {
    load_config
    check_pid || true
    check_port || true
    test_api || true
    check_logs
    check_resources
    show_summary
}

# Executar main
main
