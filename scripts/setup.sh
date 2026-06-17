#!/bin/bash
# setup.sh - Setup inicial isolado para Gemma 4 26B Remote Server
# Este script verifica pré-requisitos e prepara o ambiente sem afetar projetos existentes

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

echo -e "${BLUE}=== Setup Isolado - Gemma 4 26B Remote Server ===${NC}"
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

# Função para verificar pré-requisitos
check_prerequisites() {
    echo -e "${BLUE}Verificando pré-requisitos...${NC}"
    
    local errors=0
    
    # Verificar UV
    if ! command -v uv &> /dev/null; then
        echo -e "${RED}✗ UV não encontrado${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ UV encontrado: $(uv --version)${NC}"
    fi
    
    # Verificar modelo
    if [ ! -f "$MODEL_PATH" ]; then
        echo -e "${RED}✗ Modelo não encontrado: $MODEL_PATH${NC}"
        errors=$((errors + 1))
    else
        local model_size=$(du -h "$MODEL_PATH" | cut -f1)
        echo -e "${GREEN}✓ Modelo encontrado: $MODEL_PATH ($model_size)${NC}"
    fi
    
    # Verificar backend
    if [ ! -d "$BACKEND_PATH" ]; then
        echo -e "${RED}✗ Backend não encontrado: $BACKEND_PATH${NC}"
        errors=$((errors + 1))
    else
        if [ ! -f "$BACKEND_PATH/llama-server" ]; then
            echo -e "${RED}✗ llama-server não encontrado em: $BACKEND_PATH${NC}"
            errors=$((errors + 1))
        else
            echo -e "${GREEN}✓ Backend encontrado: $BACKEND_PATH${NC}"
        fi
    fi
    
    # Verificar Vulkan ICD
    if [ ! -f "$VK_ICD_FILENAMES" ]; then
        echo -e "${RED}✗ Vulkan ICD não encontrado: $VK_ICD_FILENAMES${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ Vulkan ICD encontrado${NC}"
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "${RED}ERRO: $errors pré-requisitos falharam${NC}"
        exit 1
    fi
    
    echo ""
}

# Função para verificar porta disponível
check_port() {
    echo -e "${BLUE}Verificando porta $SERVER_PORT...${NC}"
    
    if ss -tulpn | grep -q ":$SERVER_PORT "; then
        echo -e "${YELLOW}⚠ Porta $SERVER_PORT já está em uso${NC}"
        echo -e "${YELLOW}  Processo: $(ss -tulpn | grep ":$SERVER_PORT " | awk '{print $7}')${NC}"
        echo -e "${YELLOW}  Se este é o nosso servidor, use stop-server.sh primeiro${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Porta $SERVER_PORT disponível${NC}"
    fi
    
    echo ""
}

# Função para criar diretórios
create_directories() {
    echo -e "${BLUE}Criando diretórios isolados...${NC}"
    
    # Diretório de logs
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        echo -e "${GREEN}✓ Criado: $LOG_DIR${NC}"
    else
        echo -e "${GREEN}✓ Já existe: $LOG_DIR${NC}"
    fi
    
    # Diretório de estado
    if [ ! -d "$STATE_DIR" ]; then
        mkdir -p "$STATE_DIR"
        echo -e "${GREEN}✓ Criado: $STATE_DIR${NC}"
    else
        echo -e "${GREEN}✓ Já existe: $STATE_DIR${NC}"
    fi
    
    # Verificar permissões de escrita
    if [ ! -w "$LOG_DIR" ]; then
        echo -e "${RED}✗ Sem permissão de escrita em: $LOG_DIR${NC}"
        exit 1
    fi
    
    if [ ! -w "$STATE_DIR" ]; then
        echo -e "${RED}✗ Sem permissão de escrita em: $STATE_DIR${NC}"
        exit 1
    fi
    
    echo ""
}

# Função para verificar isolamento
check_isolation() {
    echo -e "${BLUE}Verificando isolamento...${NC}"
    
    # Verificar que não estamos a usar PM2
    if pgrep -f "pm2" > /dev/null; then
        echo -e "${YELLOW}⚠ PM2 está a correr (outros projetos)${NC}"
        echo -e "${GREEN}✓ Este projeto não usa PM2 (isolamento garantido)${NC}"
    else
        echo -e "${GREEN}✓ PM2 não está a correr${NC}"
    fi
    
    # Verificar que não estamos a escrever em /srv/ai
    if echo "$LOG_DIR" | grep -q "/srv/ai"; then
        echo -e "${RED}✗ LOG_DIR está em /srv/ai (viola isolamento)${NC}"
        exit 1
    fi
    
    if echo "$STATE_DIR" | grep -q "/srv/ai"; then
        echo -e "${RED}✗ STATE_DIR está em /srv/ai (viola isolamento)${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Isolamento verificado${NC}"
    echo ""
}

# Função para testar conectividade básica
test_connectivity() {
    echo -e "${BLUE}Testando conectividade básica...${NC}"
    
    # Verificar IP local
    local local_ip=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}✓ IP local: $local_ip${NC}"
    
    # Verificar se consegue pingar gateway
    local gateway=$(ip route | grep default | awk '{print $3}')
    if ping -c 1 -W 2 "$gateway" &> /dev/null; then
        echo -e "${GREEN}✓ Gateway acessível: $gateway${NC}"
    else
        echo -e "${YELLOW}⚠ Gateway não acessível: $gateway${NC}"
    fi
    
    echo ""
}

# Função para mostrar resumo
show_summary() {
    echo -e "${BLUE}=== Resumo do Setup ===${NC}"
    echo ""
    echo "Projeto: Gemma 4 26B Remote Server"
    echo "Diretório: $PROJECT_DIR"
    echo ""
    echo "Configuração:"
    echo "  Porta: $SERVER_PORT"
    echo "  Host: $SERVER_HOST"
    echo "  Modelo: $MODEL_NAME"
    echo "  Backend: $BACKEND_TYPE"
    echo "  NGL: $NGL"
    echo "  Context: $CTX_SIZE"
    echo ""
    echo "Paths (READ-ONLY):"
    echo "  Modelo: $MODEL_PATH"
    echo "  Backend: $BACKEND_PATH"
    echo ""
    echo "Paths (Isolados):"
    echo "  Logs: $LOG_DIR"
    echo "  Estado: $STATE_DIR"
    echo ""
    echo -e "${GREEN}✓ Setup concluído com sucesso${NC}"
    echo ""
    echo "Próximos passos:"
    echo "  1. Iniciar servidor: bash scripts/start-server.sh"
    echo "  2. Verificar status: bash scripts/status-server.sh"
    echo "  3. Configurar Claude Code no laptopdev"
    echo ""
}

# Main
main() {
    load_config
    check_prerequisites
    check_port
    create_directories
    check_isolation
    test_connectivity
    show_summary
}

# Executar main
main
